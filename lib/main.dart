import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'package:yuugao/CloudMusic/yuugao.dart';
import 'package:yuugao/app.dart';
import 'package:yuugao/services/audio_handler.dart';
import 'package:yuugao/services/audio_service.dart' as audio;
import 'package:yuugao/services/cache_service.dart';
import 'package:yuugao/services/metadata_cache_service.dart';

/// 全局 HttpOverrides：对 网易云 CDN 域名自动注入 Referer / UA，
/// 覆盖 flutter_cache_manager / just_audio 等无法自定义 headers 的内部请求。
class _NeteaseHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _NeteaseHttpClient(super.createHttpClient(context));
  }
}

class _NeteaseHttpClient implements HttpClient {
  final HttpClient _inner;
  _NeteaseHttpClient(this._inner);

  static const _referer = 'https://music.163.com';
  static const _ua =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0 Safari/537.36';

  static bool _isNetEase(Uri url) => url.host.contains('music.126.net');

  /// 对请求注入防盗链 headers（仅限网易云 CDN 域名）。
  void _inject(HttpClientRequest req, Uri url) {
    if (_isNetEase(url)) {
      req.headers.set('Referer', _referer);
      req.headers.set('User-Agent', _ua);
    }
  }

  /// 构造一个对 [_inner] 同名 URL 方法的包装调用，自动注入 headers。
  Future<HttpClientRequest> _wrap(
    Future<HttpClientRequest> Function(Uri) innerCall,
    Uri url,
  ) =>
      innerCall(url).then((r) {
        _inject(r, url);
        return r;
      });

  /// 将 (host, port, path) 三元组转为 Uri 后委托给对应的 Url 方法。
  Uri _uri(String host, int port, String path) =>
      Uri(scheme: 'https', host: host, port: port, path: path);

  // ── 请求方法 ──

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) =>
      _wrap((u) => _inner.openUrl(method, u), url);

  @override
  Future<HttpClientRequest> open(String m, String h, int p, String pa) =>
      openUrl(m, _uri(h, p, pa));

  @override
  Future<HttpClientRequest> getUrl(Uri url) => _wrap(_inner.getUrl, url);

  @override
  Future<HttpClientRequest> get(String h, int p, String pa) =>
      getUrl(_uri(h, p, pa));

  @override
  Future<HttpClientRequest> postUrl(Uri url) => _wrap(_inner.postUrl, url);

  @override
  Future<HttpClientRequest> post(String h, int p, String pa) =>
      postUrl(_uri(h, p, pa));

  @override
  Future<HttpClientRequest> putUrl(Uri url) => _wrap(_inner.putUrl, url);

  @override
  Future<HttpClientRequest> put(String h, int p, String pa) =>
      putUrl(_uri(h, p, pa));

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => _wrap(_inner.deleteUrl, url);

  @override
  Future<HttpClientRequest> delete(String h, int p, String pa) =>
      deleteUrl(_uri(h, p, pa));

  @override
  Future<HttpClientRequest> patchUrl(Uri url) => _wrap(_inner.patchUrl, url);

  @override
  Future<HttpClientRequest> patch(String h, int p, String pa) =>
      patchUrl(_uri(h, p, pa));

  @override
  Future<HttpClientRequest> headUrl(Uri url) => _wrap(_inner.headUrl, url);

  @override
  Future<HttpClientRequest> head(String h, int p, String pa) =>
      headUrl(_uri(h, p, pa));

  // ── 其余属性和方法全部委托 ──

  @override
  bool autoUncompress = true;
  // 注：autoUncompress 实际无法委托，但 keep-alive 默认 true 一般正确；
  // 如需和内部同步可改为 getter：
  // @override
  // bool get autoUncompress => _inner.autoUncompress;
  // @override
  // set autoUncompress(bool v) => _inner.autoUncompress = v;

  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String Function(Uri)? findProxy;
  @override
  set authenticate(Future<bool> Function(Uri, String, String?)? f) =>
      _inner.authenticate = f;
  @override
  set authenticateProxy(
    Future<bool> Function(String, int, String, String?)? f,
  ) => _inner.authenticateProxy = f;
  @override
  set badCertificateCallback(bool Function(X509Certificate, String, int)? cb) =>
      _inner.badCertificateCallback = cb;
  @override
  set keyLog(dynamic Function(String)? cb) => _inner.keyLog = cb;
  @override
  String? userAgent;
  @override
  set connectionFactory(
    Future<ConnectionTask<Socket>> Function(Uri, String?, int?)? f,
  ) => _inner.connectionFactory = f;
  @override
  void addCredentials(
    Uri url,
    String realm,
    HttpClientCredentials credentials,
  ) => _inner.addCredentials(url, realm, credentials);
  @override
  void addProxyCredentials(
    String host,
    int port,
    String realm,
    HttpClientCredentials credentials,
  ) => _inner.addProxyCredentials(host, port, realm, credentials);
  @override
  void close({bool force = false}) => _inner.close(force: force);
}

/// 入口：初始化网络、后台播放、缓存，然后启动 App。
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 全局注入 网易云 CDN 防盗链 headers（覆盖所有 dart:io HttpClient 实例）
  HttpOverrides.global = _NeteaseHttpOverrides();

  // ── 音频会话配置 ──
  // 必须早于 AudioService.init()，否则 Android 不视此 App 为音乐播放器：
  // 通知栏不显示、后台优先级低、易被 Doze 杀死。
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  // 后台播放 — 直接使用 audio_service。
  // 注：AudioServiceConfig 不支持 const 构造函数，不能加 const。
  // androidStopForegroundOnPause: false 确保暂停时前台服务不被系统回收，
  // 其通知栏本身即不可滑动关闭，无需同时设置 androidNotificationOngoing。
  await AudioService.init(
    builder: () => YuugaoAudioHandler(audio.AudioService.instance),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.yuugao.playback',
      androidNotificationChannelName: 'yuugao 播放',
      androidNotificationChannelDescription: '显示播放控制与当前歌曲信息',
      androidNotificationIcon: 'drawable/ic_notification',
      androidStopForegroundOnPause: false,
      androidResumeOnClick: true,
    ),
  );

  // API 层初始化（cookie 持久化路径）
  final docs = await getApplicationDocumentsDirectory();
  await MusicManager().init(cookiePath: '${docs.path}/.cookies');

  // 缓存索引
  await CacheService.instance.init();

  // 元数据缓存
  await MetadataCacheService.instance.init();

  // ── 图片缓存配置 ──
  // 限制内存中的图片缓存大小（默认 200MB 太大，50MB 足够封面缩略图）。
  PaintingBinding.instance.imageCache.maximumSize = 200;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50 MB

  runApp(const ProviderScope(child: YuugaoApp()));
}
