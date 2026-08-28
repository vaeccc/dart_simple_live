import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:simple_live_tv_app/app/app_focus_node.dart';
import 'package:simple_live_tv_app/app/app_style.dart';
import 'package:simple_live_tv_app/services/sync_service.dart';
import 'package:simple_live_tv_app/widgets/app_scaffold.dart';
import 'package:simple_live_tv_app/widgets/button/highlight_button.dart';

/// Displays the local-network endpoint exposed by the TV.
class SyncPage extends StatelessWidget {
  const SyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Column(
        children: [
          AppStyle.vGap24,
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppStyle.hGap48,
              HighlightButton(
                focusNode: AppFocusNode(),
                iconData: Icons.arrow_back,
                text: '返回',
                autofocus: true,
                onTap: () => Navigator.of(context).pop(),
              ),
              AppStyle.hGap32,
              Text(
                '数据同步',
                style: AppStyle.titleStyleWhite.copyWith(
                  fontSize: 36.w,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          AppStyle.vGap24,
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '局域网同步',
                    style: AppStyle.titleStyleWhite.copyWith(
                      fontSize: 32.w,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppStyle.vGap16,
                  Obx(
                    () => Visibility(
                      visible: SyncService.instance.httpRunning.value,
                      child: QrImageView(
                        data: SyncService.instance.ipAddress.value,
                        version: QrVersions.auto,
                        backgroundColor: Colors.white,
                        padding: AppStyle.edgeInsetsA24,
                        size: 420.0.w,
                      ),
                    ),
                  ),
                  AppStyle.vGap24,
                  Obx(
                    () => Text(
                      SyncService.instance.httpRunning.value
                          ? '服务已启动：${SyncService.instance.ipAddress.value.split(';').map((e) => '$e:${SyncService.httpPort}').join('；')}'
                          : 'HTTP 服务未启动：${SyncService.instance.httpErrorMsg}，请尝试重启应用',
                      style: AppStyle.textStyleWhite,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  AppStyle.vGap12,
                  Obx(
                    () => Visibility(
                      visible: SyncService.instance.httpRunning.value,
                      child: Text(
                        '请用 APP 扫描二维码或输入 IP 地址进行连接\n连接后可选择要同步到电视的数据',
                        style: AppStyle.textStyleWhite,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
