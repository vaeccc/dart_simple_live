import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/modules/mine/account/yy/web_login_controller.dart';

class YyWebLoginPage extends GetView<YyWebLoginController> {
  const YyWebLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YY 扫码登录'),
        actions: [
          TextButton(
            onPressed: controller.completeLogin,
            child: const Text('完成登录'),
          ),
        ],
      ),
      body: InAppWebView(
        initialSettings: InAppWebViewSettings(
          userAgent: 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/131.0.0.0 Mobile Safari/537.36',
        ),
        onWebViewCreated: controller.onWebViewCreated,
      ),
    );
  }
}
