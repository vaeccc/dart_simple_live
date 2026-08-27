import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/constant.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_core/simple_live_core.dart';

/// Keeps the YY web-login session in platform encrypted storage.
///
/// Passwords are never requested or retained by the application.
class YyAccountService extends GetxService {
  static YyAccountService get instance => Get.find<YyAccountService>();

  static const _cookieKey = 'yy_session_cookie';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String cookie = '';
  final logined = false.obs;
  final sessionReady = false.obs;

  @override
  void onInit() {
    super.onInit();
    _restoreCookie();
  }

  Future<void> _restoreCookie() async {
    cookie = await _storage.read(key: _cookieKey) ?? '';
    logined.value = cookie.isNotEmpty;
    _applyToSite();
    sessionReady.value = true;
  }

  Future<void> setCookie(String value) async {
    cookie = value;
    logined.value = value.isNotEmpty;
    _applyToSite();
    if (value.isEmpty) {
      await _storage.delete(key: _cookieKey);
    } else {
      await _storage.write(key: _cookieKey, value: value);
    }
  }

  Future<void> logout() => setCookie('');

  void _applyToSite() {
    final site = Sites.allSites[Constant.kYy]?.liveSite;
    if (site is YySite) site.cookie = cookie;
  }
}
