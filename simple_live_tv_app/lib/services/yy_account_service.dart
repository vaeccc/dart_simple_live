import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:simple_live_core/simple_live_core.dart';
import 'package:simple_live_tv_app/app/constant.dart';
import 'package:simple_live_tv_app/app/sites.dart';

/// Persists the YY web session using Android encrypted storage.
class YyAccountService extends GetxService {
  static YyAccountService get instance => Get.find<YyAccountService>();

  static const _cookieKey = 'yy_session_cookie';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String cookie = '';
  final logined = false.obs;

  @override
  void onInit() {
    super.onInit();
    _restoreCookie();
  }

  Future<void> _restoreCookie() async {
    cookie = await _storage.read(key: _cookieKey) ?? '';
    logined.value = cookie.isNotEmpty;
    _applyToSite();
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

  void _applyToSite() {
    final site = Sites.allSites[Constant.kYy]?.liveSite;
    if (site is YySite) site.cookie = cookie;
  }
}
