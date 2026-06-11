import 'package:cookie_jar/cookie_jar.dart';
// import 'package:shared_preferences/shared_preferences.dart';

class MusicFileCookieJar extends PersistCookieJar {
  MusicFileCookieJar._(String storagePath) : super(storage: FileStorage(storagePath));

  static Future<MusicFileCookieJar> create({required String cookiePath}) async {
    return MusicFileCookieJar._(cookiePath);
  }
}

class MusicWebCookieJar implements WebCookieJar {
  final _cookies = <String, Cookie>{};

  MusicWebCookieJar._();

  static Future<MusicWebCookieJar> create() async {
    return MusicWebCookieJar._();
  }

  @override
  Future<void> saveFromResponse(Uri uri, List<Cookie> cookies) async {
    for (var cookie in cookies) {
      _cookies['${uri.host}_${cookie.name}'] = cookie;
    }
  }

  @override
  Future<List<Cookie>> loadForRequest(Uri uri) async {
    final result = <Cookie>[];
    for (var entry in _cookies.entries) {
      if (entry.key.startsWith(uri.host)) {
        result.add(entry.value);
      }
    }
    return result;
  }

  @override
  Future<void> delete(Uri uri, [bool withDomainSharedCookie = false]) async {
    _cookies.removeWhere((key, _) {
      if (key.startsWith(uri.host)) return true;
      if (withDomainSharedCookie && key.contains('_')) {
        final cookieDomain = key.split('_')[0];
        if (uri.host.contains(cookieDomain)) return true;
      }
      return false;
    });
  }

  @override
  Future<void> deleteAll() async {
    _cookies.clear();
  }

  @override
  bool get ignoreExpires => false;
}

