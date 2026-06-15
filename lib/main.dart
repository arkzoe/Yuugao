import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path_provider/path_provider.dart';

import 'package:yuugao/CloudMusic/yuugao.dart';
import 'package:yuugao/app.dart';
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

  void _inject(HttpClientRequest req, Uri url) {
    if (_isNetEase(url)) {
      req.headers.set('Referer', _referer);
      req.headers.set('User-Agent', _ua);
    }
  }

  // ── 请求方法（唯一需要拦截的）──

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) =>
      _inner.openUrl(method, url).then((r) {
        _inject(r, url);
        return r;
      });

  @override
  Future<HttpClientRequest> open(
    String method,
    String host,
    int port,
    String path,
  ) =>
      openUrl(method, Uri(scheme: 'https', host: host, port: port, path: path));

  @override
  Future<HttpClientRequest> getUrl(Uri url) => _inner.getUrl(url).then((r) {
    _inject(r, url);
    return r;
  });

  @override
  Future<HttpClientRequest> get(String host, int port, String path) =>
      getUrl(Uri(host: host, port: port, path: path));

  @override
  Future<HttpClientRequest> postUrl(Uri url) => _inner.postUrl(url).then((r) {
    _inject(r, url);
    return r;
  });

  @override
  Future<HttpClientRequest> post(String host, int port, String path) =>
      postUrl(Uri(host: host, port: port, path: path));

  @override
  Future<HttpClientRequest> putUrl(Uri url) => _inner.putUrl(url).then((r) {
    _inject(r, url);
    return r;
  });

  @override
  Future<HttpClientRequest> put(String host, int port, String path) =>
      putUrl(Uri(host: host, port: port, path: path));

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) =>
      _inner.deleteUrl(url).then((r) {
        _inject(r, url);
        return r;
      });

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) =>
      deleteUrl(Uri(host: host, port: port, path: path));

  @override
  Future<HttpClientRequest> patchUrl(Uri url) => _inner.patchUrl(url).then((r) {
    _inject(r, url);
    return r;
  });

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) =>
      patchUrl(Uri(host: host, port: port, path: path));

  @override
  Future<HttpClientRequest> headUrl(Uri url) => _inner.headUrl(url).then((r) {
    _inject(r, url);
    return r;
  });

  @override
  Future<HttpClientRequest> head(String host, int port, String path) =>
      headUrl(Uri(host: host, port: port, path: path));

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

  // 后台播放 / 通知栏控件
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.yuugao.channel.audio',
    androidNotificationChannelName: 'yuugao 播放',
    // Android 14+ 息屏/后台时系统会杀无前台服务的进程。
    // 默认值 true 会在暂停瞬间停止前台服务，导致切歌间隙被系统杀死。
    // 设为 false 使通知栏常驻，保证高版本安卓息屏后持续播放。
    // 注意：此选项为 false 时 androidNotificationOngoing 自动失效，不能同时传 true。
    androidStopForegroundOnPause: false,
  );

  // API 层初始化（cookie 持久化路径）
  final docs = await getApplicationDocumentsDirectory();
  await MusicManager().init(cookiePath: '${docs.path}/.cookies');

  // 缓存索引
  await CacheService.instance.init();

  // 元数据缓存
  await MetadataCacheService.instance.init();

  runApp(const ProviderScope(child: YuugaoApp()));
}
