import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/constant.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_core/simple_live_core.dart';

/// Owns the Huya web-login session. Passwords are handled only by Huya's
/// official page and never enter this application.
class HuyaAccountService extends GetxService {
  static HuyaAccountService get instance => Get.find<HuyaAccountService>();

  static const _cookieKey = 'huya_session_cookie';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String cookie = '';
  final logined = false.obs;
  final sessionReady = false.obs;

  @override
  void onInit() {
    super.onInit();
    restoreSession();
  }

  Future<void> restoreSession() async {
    cookie = await _storage.read(key: _cookieKey) ?? '';
    logined.value = cookie.isNotEmpty;
    _applyToSite();
    sessionReady.value = true;
  }

  Future<void> setCookie(String value) async {
    cookie = value.trim();
    logined.value = cookie.isNotEmpty;
    _applyToSite();
    if (cookie.isEmpty) {
      await _storage.delete(key: _cookieKey);
    } else {
      await _storage.write(key: _cookieKey, value: cookie);
    }
  }

  Future<void> logout() => setCookie('');

  void _applyToSite() {
    final site = Sites.allSites[Constant.kHuya]?.liveSite;
    if (site is HuyaSite) site.cookie = cookie;
  }
}
