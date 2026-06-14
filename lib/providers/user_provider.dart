import 'dart:async';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yuugao/CloudMusic/yuugao.dart';
import 'package:yuugao/CloudMusic/api/user/entity/login_entity.dart';
import 'package:yuugao/CloudMusic/api/user/entity/user_info_entity.dart';
import 'package:yuugao/CloudMusic/common/cookie_holder.dart';
import 'package:yuugao/CloudMusic/common/music_interceptors.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class UserState {
  final AuthStatus status;
  final LoginProfile? profile;
  final UserInfoProfile? userProfile;
  final UserInfoAccount? account;
  final String? error;

  const UserState({
    this.status = AuthStatus.unknown,
    this.profile,
    this.userProfile,
    this.account,
    this.error,
  });

  /// 当前登录用户 uid（优先 userInfo，其次登录返回的 profile）
  int? get uid => userProfile?.userId ?? profile?.userId;

  String get nickname =>
      userProfile?.nickname ?? profile?.nickname ?? '游客';

  String get avatarUrl =>
      userProfile?.avatarUrl ?? profile?.avatarUrl ?? '';

  UserState copyWith({
    AuthStatus? status,
    LoginProfile? profile,
    UserInfoProfile? userProfile,
    UserInfoAccount? account,
    String? error,
  }) {
    return UserState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      userProfile: userProfile ?? this.userProfile,
      account: account ?? this.account,
      error: error,
    );
  }
}

class UserNotifier extends Notifier<UserState> {
  @override
  UserState build() => const UserState();

  late final _api = BujuanMusicManager();

  /// 启动时检查 cookie 是否仍有效（已持久化登录态时自动恢复）。
  Future<void> restore() async {
    try {
      final info = await _api.userInfo();
      if (info?.account?.id != null && (info!.account!.id ?? 0) > 0) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          userProfile: info.profile,
          account: info.account,
        );
        return;
      }
    } catch (_) {}
    state = state.copyWith(status: AuthStatus.unauthenticated);
  }

  /// 手机号登录（密码或验证码二选一）。
  Future<bool> loginByPhone({
    required String phone,
    String? password,
    String? captcha,
  }) async {
    try {
      final res = await _api.loginCellPhone(
        phone: phone,
        password: password == null ? null : encryptPassword(password),
        captcha: captcha,
      );
      if (res?.code == 200) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          profile: res!.profile,
          error: null,
        );
        await _refreshUserInfo();
        unawaited(_prefetchUserData()); // 后台预加载
        return true;
      }
      state = state.copyWith(error: '登录失败 (code=${res?.code})');
      return false;
    } catch (e) {
      state = state.copyWith(error: '登录异常: $e');
      return false;
    }
  }

  Future<bool> sendSmsCode(String phone) async {
    final res = await _api.sendSmsCode(phone: phone);
    return res?.data == true || res?.code == 200;
  }

  Future<void> _refreshUserInfo() async {
    try {
      final info = await _api.userInfo();
      if (info != null) {
        state = state.copyWith(
          userProfile: info.profile,
          account: info.account,
        );
      }
    } catch (_) {}
  }

  /// 获取二维码登录 key 与展示用 url。
  Future<({String key, String qrUrl})?> createQr() async {
    final keyRes = await _api.qrCodeKey();
    final key = keyRes?.unikey ?? '';
    if (key.isEmpty) return null;
    return (key: key, qrUrl: _api.qrCode(key: key));
  }

  /// 轮询二维码状态。返回 code：800 过期 / 801 等待 / 802 已扫 / 803 授权成功。
  Future<int> pollQr(String key) async {
    final res = await _api.checkQrCode(key: key);
    final code = res?.code ?? 0;
    if (code == 803) {
      // 服务器把登录 cookie 放在 JSON body 而非 Set-Cookie 头，
      // 需手动解析并写入 CookieJar，否则后续 userInfo 等接口无鉴权。
      await _saveQrCookies(res?.cookie);
      // 先拉取用户信息再标记已登录，否则 _AuthGate 立即切到 HomePage，
      // HomePage.initState 中 fetchAll 会因为 uid 仍为 null 而失败。
      await _refreshUserInfo();
      state = state.copyWith(status: AuthStatus.authenticated, error: null);
      unawaited(_prefetchUserData()); // 后台预加载喜欢列表和歌单
    }
    return code;
  }

  /// 解析 QR 授权返回的 cookie 串并保存到全局 CookieJar。
  Future<void> _saveQrCookies(String? cookieStr) async {
    if (cookieStr == null || cookieStr.trim().isEmpty) return;
    final jar = globalCookieJar;
    if (jar == null) return;
    // 使用与 Dio baseUrl 一致的 host（即 defaultUrl = 'https://music.163.com'），
    // 但带上 path '/' 确保 cookie_jar 的 path 匹配逻辑能覆盖所有 API 子路径。
    final uri = Uri.parse('$defaultUrl/');
    final cookies = <Cookie>[];
    for (final part in cookieStr.split(';')) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      final eq = trimmed.indexOf('=');
      if (eq <= 0) continue;
      final name = trimmed.substring(0, eq).trim();
      final value = trimmed.substring(eq + 1).trim();
      if (name.isNotEmpty && value.isNotEmpty) {
        // 显式设置 domain 和 path，避免依赖 cookie_jar 对 null 的默认处理。
        cookies.add(Cookie(name, value)
          ..domain = Uri.parse(defaultUrl).host
          ..path = '/');
      }
    }
    if (cookies.isNotEmpty) {
      await jar.saveFromResponse(uri, cookies);
    }
  }

  /// 登录成功后后台预加载喜欢列表和歌单，加速首页渲染。
  Future<void> _prefetchUserData() async {
    final uid = state.uid;
    if (uid == null) return;
    try {
      await Future.wait([
        _api.userLikeList(uid: uid.toString()),
        _api.userPlaylist(uid: uid.toString()),
      ]);
    } catch (_) {
      // 预加载失败不影响主流程
    }
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {}
    state = const UserState(status: AuthStatus.unauthenticated);
  }
}

final userProvider =
    NotifierProvider<UserNotifier, UserState>(UserNotifier.new);
