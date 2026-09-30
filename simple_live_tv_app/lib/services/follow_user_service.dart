import 'dart:async';
import 'package:get/get.dart';
import 'package:simple_live_tv_app/app/constant.dart';
import 'package:simple_live_tv_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_tv_app/app/controller/base_controller.dart';
import 'package:simple_live_tv_app/app/event_bus.dart';
import 'package:simple_live_tv_app/app/log.dart';
import 'package:simple_live_tv_app/app/sites.dart';
import 'package:simple_live_tv_app/app/utils.dart';
import 'package:simple_live_tv_app/models/db/follow_user.dart';
import 'package:simple_live_tv_app/services/db_service.dart';

class FollowUserService extends BasePageController<FollowUser> {
  static FollowUserService get instance => Get.find<FollowUserService>();
  StreamSubscription<dynamic>? subscription;

  RxList<FollowUser> livingList = RxList<FollowUser>();
  Timer? updateTimer;
  bool needUpdate = true;
  @override
  void onInit() {
    subscription = EventBus.instance.listen(Constant.kUpdateFollow, (p0) {
      needUpdate = false;
      refreshData();
    });

    if (list.isEmpty) {
      refreshData();
    }
    initTimer();
    super.onInit();
  }

  void initTimer() {
    if (AppSettingsController.instance.autoUpdateFollowEnable.value) {
      updateTimer?.cancel();
      updateTimer = Timer.periodic(
        Duration(
          minutes:
              AppSettingsController.instance.autoUpdateFollowDuration.value,
        ),
        (timer) {
          Log.logPrint("Update Follow Timer");
          refreshData();
        },
      );
    } else {
      updateTimer?.cancel();
    }
  }

  var updatedCount = 0;
  var updating = false.obs;
  var _updateTotal = 0;
  static const _statusRequestTimeout = Duration(seconds: 15);
  static const _statusRetryCount = 2;
  var _updateGeneration = 0;
  @override
  Future<List<FollowUser>> getData(int page, int pageSize) async {
    if (page > 1) {
      return [];
    }

    var followList = DBService.instance.getFollowList();
    if (needUpdate) {
      startUpdateStatus(followList);
    }
    needUpdate = true;
    if (followList.isEmpty) {
      updating.value = false;
    }
    return followList;
  }

  void sortList() {
    list.sort((a, b) => b.liveStatus.value.compareTo(a.liveStatus.value));
    updateLivingList();
  }

  void updateLivingList() {
    livingList.assignAll(list.where((x) => x.liveStatus.value == 2));
  }

  Future<void> startUpdateStatus(List<FollowUser> followList) async {
    if (followList.isEmpty) {
      updating.value = false;
      return;
    }
    if (updating.value) {
      return;
    }

    updatedCount = 0;
    _updateTotal = followList.length;
    final generation = ++_updateGeneration;
    updating.value = true;

    final configuredThreadCount =
        AppSettingsController.instance.updateFollowThreadCount.value;
    final threadCount = configuredThreadCount <= 0 ? 4 : configuredThreadCount;

    var tasks = <Future>[];
    for (var i = 0; i < threadCount; i++) {
      tasks.add(
        Future(() async {
          var start = i * followList.length ~/ threadCount;
          var end = (i + 1) * followList.length ~/ threadCount;

          // 确保 end 不超出列表长度
          if (end > followList.length) {
            end = followList.length;
          }
          var items = followList.sublist(start, end);
          for (var item in items) {
            await updateLiveStatus(
              item,
              total: _updateTotal,
              generation: generation,
            );
          }
        }),
      );
    }
    await Future.wait(tasks);
  }

  Future<void> updateLiveStatus(
    FollowUser item, {
    required int total,
    required int generation,
  }) async {
    try {
      var site = Sites.allSites[item.siteId]!;
      final detail = await _requestWithRetry(
        () => site.liveSite.getRoomDetail(roomId: item.roomId),
      );
      if (generation != _updateGeneration || !list.contains(item)) return;
      item.roomDetail.value = detail;
      item.liveStatus.value = detail.status ? 2 : 1;
      if (detail.title.isNotEmpty && item.roomTitle != detail.title) {
        item.roomTitle = detail.title;
        await DBService.instance.addFollow(item);
      }
      //sortList();
      //updateLivingList();
    } catch (e) {
      Log.logPrint(e);
    } finally {
      if (generation == _updateGeneration) {
        updatedCount++;
        if (updatedCount >= total) {
          sortList();
          updating.value = false;
        }
      }
    }
  }

  Future<T> _requestWithRetry<T>(Future<T> Function() request) async {
    Object? lastError;
    for (var attempt = 0; attempt < _statusRetryCount; attempt++) {
      try {
        return await request().timeout(_statusRequestTimeout);
      } catch (error) {
        lastError = error;
        if (attempt + 1 < _statusRetryCount) {
          await Future<void>.delayed(
            Duration(milliseconds: 300 * (attempt + 1)),
          );
        }
      }
    }
    throw lastError!;
  }

  void removeItem(FollowUser item, {bool refresh = true}) async {
    var result =
        await Utils.showAlertDialog("确定要取消关注${item.userName}吗?", title: "取消关注");
    if (!result) {
      return;
    }
    await DBService.instance.followBox.delete(item.id);
    if (refresh) {
      refreshData();
    } else {
      list.remove(item);
      livingList.remove(item);
    }
  }

  @override
  void onClose() {
    updateTimer?.cancel();
    subscription?.cancel();

    super.onClose();
  }
}
