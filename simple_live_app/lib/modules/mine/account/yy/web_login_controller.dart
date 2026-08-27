import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/services/yy_account_service.dart';

class YyWebLoginController extends GetxController {
  final CookieManager _cookieManager = CookieManager.instance();

  void onWebViewCreated(InAppWebViewController controller) {
    controller.loadUrl(
      urlRequest: URLRequest(url: WebUri('https://www.yy.com')),
    );
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
