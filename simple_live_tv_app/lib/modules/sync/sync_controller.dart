import 'package:simple_live_tv_app/app/controller/base_controller.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:simple_live_tv_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_tv_app/requests/http_client.dart';
import 'package:simple_live_tv_app/services/db_service.dart';
import 'package:simple_live_tv_app/services/sync_service.dart';

/// Route binding retained for the local-network sync page.
class SyncController extends BaseController {
  @override
  void onInit() {
    super.onInit();
    SyncService.instance.refreshClients();
  }

  Future<void> syncFollow(SyncClient client) => _sync(
    client,
    '/sync/follow',
    DBService.instance.getFollowList().map((item) => item.toJson()).toList(),
    '关注列表',
  );

  Future<void> syncHistory(SyncClient client) => _sync(
    client,
    '/sync/history',
    DBService.instance.getHistores().map((item) => item.toJson()).toList(),
    '观看记录',
  );

  Future<void> syncBlockedWords(SyncClient client) => _sync(
    client,
    '/sync/blocked_word',
    AppSettingsController.instance.shieldList.toList(),
    '屏蔽词',
  );

  Future<void> _sync(
    SyncClient client,
    String path,
    dynamic data,
    String label,
  ) async {
    try {
      SmartDialog.showLoading(msg: '同步中...');
      final response = await HttpClient.instance.postJson(
        'http://${client.address}:${client.port}$path',
        data: data,
        queryParameters: const {'overlay': '0'},
      );
      if (response is! Map || response['status'] != true) {
        throw response is Map ? response['message'] ?? '远端拒绝同步' : '远端响应无效';
      }
      SmartDialog.showToast('已同步$label到${client.name}');
    } catch (_) {
      SmartDialog.showToast('同步失败，请确认设备仍在同一局域网');
    } finally {
      SmartDialog.dismiss();
    }
  }
}
