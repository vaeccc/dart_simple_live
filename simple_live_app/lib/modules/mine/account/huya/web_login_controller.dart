import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/services/follow_service.dart';
import 'package:simple_live_app/services/huya_account_service.dart';
import 'package:simple_live_app/services/subscription_sync_service.dart';

class HuyaWebLoginController extends GetxController {
  static const _loginPage = 'https://www.huya.com/';
  final CookieManager _cookieManager = CookieManager.instance();

  void onWebViewCreated(InAppWebViewController controller) {
    controller.loadUrl(urlRequest: URLRequest(url: WebUri(_loginPage)));
  }

  void loadError() {
    SmartDialog.showToast('虎牙登录页加载失败，请检查网络后重试');
  }

  /// Collects only cookies written by Huya's official desktop login page.
  /// No cookie value is logged.
  Future<void> completeLogin() async {
    final cookies = <Cookie>[];
    for (final url in const [
      'https://www.huya.com',
      'https://i.huya.com',
      'https://udblgn.huya.com',
    ]) {
      cookies.addAll(await _cookieManager.getCookies(url: WebUri(url)));
    }
    final values = <String, String>{};
    for (final cookie in cookies) {
      if (cookie.value.isNotEmpty)
        values.putIfAbsent(cookie.name, () => cookie.value);
    }
    if (!_hasLoginCookie(values.keys)) {
      SmartDialog.showToast('暂未检测到虎牙登录状态，请完成官方登录后重试');
      return;
    }
    await HuyaAccountService.instance.setCookie(
      values.entries.map((entry) => '${entry.key}=${entry.value}').join('; '),
    );
    final result = await SubscriptionSyncService.instance
        .syncLoggedInPlatforms();
    await FollowService.instance.loadData();
    if (result.platforms.contains('虎牙')) {
      SmartDialog.showToast('虎牙登录已保存，已导入 ${result.added} 个订阅');
    } else {
      SmartDialog.showToast('虎牙登录已保存；可在“关注”页重新同步订阅');
    }
    Get.back();
  }

  static bool _hasLoginCookie(Iterable<String> names) {
    return names.any((name) {
      final lower = name.toLowerCase();
      return lower == 'udb_uid' ||
          lower == 'udb_passport' ||
          lower == 'huya_uid' ||
          lower == 'hy_login';
    });
  }
}
