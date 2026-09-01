import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/modules/mine/account/huya/web_login_controller.dart';

class HuyaWebLoginPage extends GetView<HuyaWebLoginController> {
  const HuyaWebLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('虎牙网页登录'),
        actions: [
          TextButton(
            onPressed: controller.completeLogin,
            child: const Text('完成登录'),
          ),
        ],
      ),
      body: InAppWebView(
        initialSettings: InAppWebViewSettings(
          userAgent:
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
              '(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
          javaScriptEnabled: true,
          domStorageEnabled: true,
          thirdPartyCookiesEnabled: true,
          mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
        ),
        onWebViewCreated: controller.onWebViewCreated,
        onReceivedError: (_, __, ___) => controller.loadError(),
        onReceivedHttpError: (_, __, error) {
          if ((error.statusCode ?? 0) >= 400) controller.loadError();
        },
      ),
    );
  }
}
