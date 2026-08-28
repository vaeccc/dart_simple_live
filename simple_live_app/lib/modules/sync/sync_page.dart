import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/routes/route_path.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';

/// Synchronize with a device on the same local network.
class SyncPage extends StatelessWidget {
  const SyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据同步'),
        actions: [
          Visibility(
            visible: GetPlatform.isAndroid || GetPlatform.isIOS,
            child: TextButton.icon(
              onPressed: () async {
                final result = await Get.toNamed(RoutePath.kSyncScan);
                if (result is String && result.isNotEmpty) {
                  Get.toNamed(RoutePath.kLocalSync, arguments: result);
                }
              },
              icon: const Icon(Remix.qr_scan_line),
              label: const Text('扫一扫'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: AppStyle.edgeInsetsA12,
        children: [
          Padding(
            padding: AppStyle.edgeInsetsA12.copyWith(top: 0),
            child: Text('局域网同步', style: Get.textTheme.titleSmall),
          ),
          SettingsCard(
            child: ListTile(
              title: const Text('局域网同步'),
              subtitle: const Text('连接同一网络内的电视或手机，同步数据'),
              leading: const Icon(Remix.device_line),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Get.toNamed(RoutePath.kLocalSync),
            ),
          ),
        ],
      ),
    );
  }
}
