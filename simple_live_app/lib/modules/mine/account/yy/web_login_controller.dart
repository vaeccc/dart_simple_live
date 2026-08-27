import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/services/yy_account_service.dart';

class YyWebLoginController extends GetxController {
  static const _loginPage = 'https://www.yy.com/ent/index/index.html';
  final CookieManager _cookieManager = CookieManager.instance();

  void onWebViewCreated(InAppWebViewController controller) {
    controller.loadUrl(
      // YY's mobile site attempts to hand the session off to its native app.
      // The desktop portal contains the official QR-login popup instead.
      urlRequest: URLRequest(url: WebUri(_loginPage)),
    );
  }

  void loadError() {
    SmartDialog.showToast('YY 登录页加载失败，请检查网络后重试');
  }

  /// Saves the cookies created after the user completes YY's QR login in the
  /// official web page. Empty cookies never replace an existing session.
  Future<void> completeLogin() async {
    final cookies = await _cookieManager.getCookies(
      url: WebUri('https://www.yy.com'),
    );
    if (cookies.isEmpty) {
      SmartDialog.showToast('暂未检测到 YY 登录状态，请完成扫码后重试');
      return;
    }
    final value = cookies
        .map((cookie) => '${cookie.name}=${cookie.value}')
        .join(';');
    await YyAccountService.instance.setCookie(value);
    SmartDialog.showToast('YY 登录已保存');
    Get.back();
  }
}
