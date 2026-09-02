import 'dart:convert';

import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/app/controller/base_controller.dart';
import 'package:simple_live_app/app/log.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/models/sync_client_info_model.dart';
import 'package:simple_live_app/requests/sync_client_request.dart';
import 'package:simple_live_app/services/bilibili_account_service.dart';
import 'package:simple_live_app/services/db_service.dart';
import 'package:simple_live_app/services/huya_account_service.dart';
import 'package:simple_live_app/services/sync_service.dart';
import 'package:simple_live_app/services/yy_account_service.dart';

class SyncDeviceController extends BaseController {
  final SyncClinet client;
  final SyncClientInfoModel info;
  SyncDeviceController({required this.client, required this.info});
  SyncClientRequest request = SyncClientRequest();

  Future<bool> showOverlayDialog() async {
    var overlay = await Utils.showAlertDialog(
      "是否覆盖远端数据？",
      title: "数据覆盖",
      confirm: "覆盖",
      cancel: "不覆盖",
    );
    return overlay;
  }

  void syncFollowAndTag() async {
    try {
      SmartDialog.showLoading(msg: "同步中...");
      var users = DBService.instance.getFollowList();
      var tags = DBService.instance.getFollowTagList();
      var data = json.encode(users.map((e) => e.toJson()).toList());
      var dataT = json.encode(tags.map((e) => e.toJson()).toList());
      // Follow synchronization is intentionally additive. A device must never
      // lose its existing follows merely because another device has fewer.
      await request.syncFollow(client, data, overlay: false);
      if (info.type != 'tv') {
        await request.syncTag(client, dataT, overlay: false);
        SmartDialog.showToast("已合并关注列表和标签");
      } else {
        // TV only exposes the follow-list endpoint and does not use mobile tags.
        SmartDialog.showToast("已合并关注列表到电视");
      }
    } catch (e) {
      SmartDialog.showToast("同步失败:$e");
      Log.logPrint(e);
    } finally {
      SmartDialog.dismiss();
    }
  }

  void syncHistory() async {
    try {
      var overlay = await showOverlayDialog();
      SmartDialog.showLoading(msg: "同步中...");
      var histores = DBService.instance.getHistores();
      var data = json.encode(histores.map((e) => e.toJson()).toList());
      await request.syncHistory(client, data, overlay: overlay);
      SmartDialog.showToast("已同步历史记录");
    } catch (e) {
      SmartDialog.showToast("同步失败:$e");
      Log.logPrint(e);
    } finally {
      SmartDialog.dismiss();
    }
  }

  void syncBlockedWord() async {
    try {
      var overlay = await showOverlayDialog();
      SmartDialog.showLoading(msg: "同步中...");
      var shieldList = AppSettingsController.instance.shieldList;
      var data = json.encode(shieldList.toList());
      await request.syncBlockedWord(client, data, overlay: overlay);
      SmartDialog.showToast("已同步屏蔽词");
    } catch (e) {
      SmartDialog.showToast("同步失败:$e");
      Log.logPrint(e);
    } finally {
      SmartDialog.dismiss();
    }
  }

  void syncBiliAccount() async {
    try {
      if (!BiliBiliAccountService.instance.logined.value) {
        SmartDialog.showToast("未登录哔哩哔哩");
        return;
      }
      SmartDialog.showLoading(msg: "同步中...");

      await request.syncBiliAccount(
        client,
        BiliBiliAccountService.instance.cookie,
      );
      SmartDialog.showToast("已同步哔哩哔哩账号");
    } catch (e) {
      SmartDialog.showToast("同步失败:$e");
      Log.logPrint(e);
    } finally {
      SmartDialog.dismiss();
    }
  }

  void syncYyAccount() async {
    try {
      if (!YyAccountService.instance.logined.value) {
        SmartDialog.showToast("未登录 YY");
        return;
      }
      SmartDialog.showLoading(msg: "同步中...");
      await request.syncYyAccount(client, YyAccountService.instance.cookie);
      SmartDialog.showToast("已同步 YY 账号");
    } catch (e) {
      SmartDialog.showToast("同步失败:$e");
      Log.logPrint(e);
    } finally {
      SmartDialog.dismiss();
    }
  }

  void syncHuyaAccount() async {
    try {
      if (!HuyaAccountService.instance.logined.value) {
        SmartDialog.showToast('未登录虎牙');
        return;
      }
      SmartDialog.showLoading(msg: '同步中...');
      await request.syncHuyaAccount(client, HuyaAccountService.instance.cookie);
      SmartDialog.showToast('已同步虎牙账号');
    } catch (e) {
      SmartDialog.showToast('同步失败:$e');
      Log.logPrint(e);
    } finally {
      SmartDialog.dismiss();
    }
  }
}
