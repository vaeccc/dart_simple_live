import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/services/follow_service.dart';
import 'package:simple_live_app/services/subscription_sync_service.dart';
import 'package:simple_live_app/services/yy_account_service.dart';

class YyWebLoginController extends GetxController {
  static const _loginPage = 'https://www.yy.com/';
  final CookieManager _cookieManager = CookieManager.instance();

  void onWebViewCreated(InAppWebViewController controller) {
    controller.loadUrl(
      // YY's mobile site attempts to hand the session off to its native app.
      // The desktop portal contains the official QR-login popup instead.
      urlRequest: URLRequest(url: WebUri(_loginPage)),
    );
  }

  /// The YY desktop portal hosts its QR login inside an embedded dialog. Open
  /// it explicitly so users do not have to find the small desktop-page button
  /// on a phone screen.
  Future<void> onLoadStop(InAppWebViewController controller, Uri? url) async {
    await controller.evaluateJavascript(
      source: '''
        (function openYyLogin(attempt) {
          if (window.user && typeof window.user.isLoginSync === 'function' &&
              window.user.isLoginSync()) {
            return;
          }
          if (window.user && typeof window.user.showYYLoginBox === 'function') {
            window.user.showYYLoginBox();
            return;
          }
          if (attempt < 20) {
            window.setTimeout(function () { openYyLogin(attempt + 1); }, 300);
          }
        })(0);
      ''',
    );
  }

  void loadError() {
    SmartDialog.showToast('YY 登录页加载失败，请检查网络后重试');
  }

  /// Saves the cookies created after the user completes YY's QR login in the
  /// official web page. Empty cookies never replace an existing session.
  Future<void> completeLogin() async {
    final cookies = <Cookie>[];
    for (final url in const ['https://www.yy.com', 'https://udb.yy.com']) {
      cookies.addAll(await _cookieManager.getCookies(url: WebUri(url)));
    }
    final cookieValues = <String, String>{};
    for (final cookie in cookies) {
      cookieValues.putIfAbsent(cookie.name, () => cookie.value);
    }
    if (!cookieValues.containsKey('yyuid')) {
      SmartDialog.showToast('暂未检测到 YY 登录状态，请完成扫码后重试');
      return;
    }
    final value = cookieValues.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join(';');
    await YyAccountService.instance.setCookie(value);
    final result = await SubscriptionSyncService.instance
        .syncLoggedInPlatforms();
    await FollowService.instance.loadData();
    if (result.platforms.contains('YY')) {
      SmartDialog.showToast('YY 登录已保存，已导入 ${result.added} 个订阅');
    } else {
      SmartDialog.showToast('YY 登录已保存；订阅可在“关注”页点击“同步订阅”重试');
    }
    Get.back();
  }
}
