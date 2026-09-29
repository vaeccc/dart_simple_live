import 'dart:async';

import 'package:canvas_danmaku/models/danmaku_content_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:simple_live_core/simple_live_core.dart';
import 'package:simple_live_tv_app/app/constant.dart';
import 'package:simple_live_tv_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_tv_app/app/event_bus.dart';
import 'package:simple_live_tv_app/app/log.dart';
import 'package:simple_live_tv_app/app/sites.dart';
import 'package:simple_live_tv_app/app/utils.dart';
import 'package:simple_live_tv_app/models/db/follow_user.dart';
import 'package:simple_live_tv_app/models/db/history.dart';
import 'package:simple_live_tv_app/modules/live_room/player/player_controller.dart';
import 'package:simple_live_tv_app/services/db_service.dart';
import 'package:simple_live_tv_app/services/follow_user_service.dart';

class LiveRoomController extends PlayerController with WidgetsBindingObserver {
  final Site pSite;
  final String pRoomId;
  late LiveDanmaku liveDanmaku;
  LiveRoomController({
    required this.pSite,
    required this.pRoomId,
  }) {
    rxSite = pSite.obs;
    rxRoomId = pRoomId.obs;
    liveDanmaku = site.liveSite.getDanmaku();
  }
  final FocusNode focusNode = FocusNode();
  late Rx<Site> rxSite;
  Site get site => rxSite.value;
  late Rx<String> rxRoomId;
  String get roomId => rxRoomId.value;

  Rx<LiveRoomDetail?> detail = Rx<LiveRoomDetail?>(null);
  var online = 0.obs;
  var followed = false.obs;
  var liveStatus = false.obs;

  /// 清晰度数据
  RxList<LivePlayQuality> qualites = RxList<LivePlayQuality>();

  /// 当前清晰度
  var currentQuality = -1;
  var currentQualityInfo = "".obs;

  /// 线路数据
  RxList<String> playUrls = RxList<String>();

  Map<String, String>? playHeaders;

  /// 当前线路
  var currentLineIndex = -1;
  var currentLineInfo = "".obs;

  int _roomRequestVersion = 0;
  int _playbackRequestVersion = 0;
  bool _handlingMediaFailure = false;
  bool _suppressMediaEvents = false;

  /// 是否处于后台
  var isBackground = false;

  var datetime = "00:00".obs;
  Timer? _clockTimer;

  void initTimer() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      var now = DateTime.now();
      datetime.value =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    });
  }

  /// 双击退出Flag
  bool doubleClickExit = false;

  /// 双击退出Timer
  Timer? doubleClickTimer;

  @override
  void onInit() {
    initTimer();
    showDanmakuState.value = AppSettingsController.instance.danmuEnable.value;
    followed.value = DBService.instance.getFollowExist("${site.id}_$roomId");

    loadData();

    super.onInit();
  }

  void refreshRoom() {
    //messages.clear();

    liveDanmaku.stop();

    loadData();
  }

  /// 初始化弹幕接收事件
  void initDanmau() {
    liveDanmaku.onMessage = onWSMessage;
  }

  /// 接收到WebSocket信息
  void onWSMessage(LiveMessage msg) {
    if (msg.type == LiveMessageType.chat) {
      // 关键词屏蔽检查
      for (var keyword in AppSettingsController.instance.shieldList) {
        Pattern? pattern;
        if (Utils.isRegexFormat(keyword)) {
          String removedSlash = Utils.removeRegexFormat(keyword);
          try {
            pattern = RegExp(removedSlash);
          } catch (e) {
            // should avoid this during add keyword
            Log.d("关键词：$keyword 正则格式错误");
          }
        } else {
          pattern = keyword;
        }
        if (pattern != null && msg.message.contains(pattern)) {
          Log.d("关键词：$keyword\n已屏蔽消息内容：${msg.message}");
          return;
        }
      }

      if (!liveStatus.value || isBackground) {
        return;
      }

      addDanmaku([
        DanmakuContentItem(
          msg.message,
          color: Color.fromARGB(255, msg.color.r, msg.color.g, msg.color.b),
        ),
      ]);
    } else if (msg.type == LiveMessageType.online) {
      online.value = msg.data;
    } else if (msg.type == LiveMessageType.superChat) {
      //superChats.add(msg.data);
    }
  }

  /// 加载直播间信息
  Future<void> loadData() async {
    final requestVersion = ++_roomRequestVersion;
    final requestSite = site;
    final requestRoomId = roomId;

    try {
      SmartDialog.showLoading(msg: "");
      pageLoadding.value = true;

      final roomDetail = await requestSite.liveSite.getRoomDetail(
        roomId: requestRoomId,
      );
      if (requestVersion != _roomRequestVersion) return;

      detail.value = roomDetail;
      addHistory();
      online.value = roomDetail.online;
      liveStatus.value = roomDetail.status || roomDetail.isRecord;

      if (liveStatus.value) {
        await getPlayQualites(requestVersion: requestVersion);
        if (requestVersion != _roomRequestVersion) return;
      }

      if (roomDetail.isRecord) {
        SmartDialog.showToast("当前主播未开播，正在轮播录像");
      }

      if (requestVersion != _roomRequestVersion) return;
      initDanmau();
      liveDanmaku.start(roomDetail.danmakuData);
    } catch (e) {
      if (requestVersion == _roomRequestVersion) {
        SmartDialog.showToast(e.toString());
      }
    } finally {
      if (requestVersion == _roomRequestVersion) {
        SmartDialog.dismiss(status: SmartStatus.loading);
        pageLoadding.value = false;
      }
    }
  }

  Future<void> getPlayQualites({required int requestVersion}) async {
    if (requestVersion != _roomRequestVersion || detail.value == null) return;

    qualites.clear();
    playUrls.clear();
    currentQuality = -1;
    currentLineIndex = -1;

    try {
      final playQualites = await site.liveSite.getPlayQualites(
        detail: detail.value!,
      );
      if (requestVersion != _roomRequestVersion) return;
      if (playQualites.isEmpty) {
        SmartDialog.showToast("无法读取播放清晰度");
        return;
      }

      qualites.assignAll(playQualites);
      final qualityLevel = AppSettingsController.instance.qualityLevel.value;
      if (qualityLevel == 2) {
        currentQuality = 0;
      } else if (qualityLevel == 0) {
        currentQuality = playQualites.length - 1;
      } else {
        currentQuality = (playQualites.length / 2).floor();
      }

      await getPlayUrl(expectedRoomRequestVersion: requestVersion);
    } catch (e) {
      if (requestVersion != _roomRequestVersion) return;
      Log.logPrint(e);
      SmartDialog.showToast("无法读取播放清晰度");
    }
  }

  Future<void> getPlayUrl({int? expectedRoomRequestVersion}) async {
    final roomVersion = expectedRoomRequestVersion ?? _roomRequestVersion;
    if (roomVersion != _roomRequestVersion ||
        detail.value == null ||
        currentQuality < 0 ||
        currentQuality >= qualites.length) {
      return;
    }

    final playbackVersion = ++_playbackRequestVersion;
    final quality = qualites[currentQuality];
    try {
      final playUrl = await site.liveSite.getPlayUrls(
        detail: detail.value!,
        quality: quality,
      );
      if (roomVersion != _roomRequestVersion ||
          playbackVersion != _playbackRequestVersion) {
        return;
      }
      if (playUrl.urls.isEmpty) {
        SmartDialog.showToast("无法读取播放地址");
        return;
      }

      currentQualityInfo.value = quality.quality;
      playUrls.assignAll(playUrl.urls);
      playHeaders = playUrl.headers;
      currentLineIndex = 0;
      currentLineInfo.value = "线路1";
      mediaErrorRetryCount = 0;
      await setPlayer();
    } catch (e) {
      if (roomVersion != _roomRequestVersion ||
          playbackVersion != _playbackRequestVersion) {
        return;
      }
      Log.logPrint(e);
      SmartDialog.showToast("无法读取播放地址");
    }
  }

  Future<void> changePlayLine(int index) async {
    if (index < 0 || index >= playUrls.length) {
      Log.w("忽略无效线路索引：$index/${playUrls.length}");
      return;
    }
    currentLineIndex = index;
    mediaErrorRetryCount = 0;
    await setPlayer();
  }

  Future<void> setPlayer() async {
    if (currentLineIndex < 0 || currentLineIndex >= playUrls.length) {
      Log.w("忽略播放器打开：线路索引$currentLineIndex无效");
      return;
    }

    final playbackVersion = _playbackRequestVersion;
    final targetUrl = playUrls[currentLineIndex];
    final headers = playHeaders == null
        ? null
        : Map<String, String>.from(playHeaders!);

    currentLineInfo.value = "线路${currentLineIndex + 1}";
    errorMsg.value = "";
    await initializePlayer();
    if (playbackVersion != _playbackRequestVersion) return;

    await player.open(Media(targetUrl, httpHeaders: headers));
    Log.d("播放地址：$targetUrl");
  }

  @override
  void mediaEnd() async {
    if (_suppressMediaEvents || _handlingMediaFailure) return;
    _handlingMediaFailure = true;
    try {
      if (currentLineIndex < 0 || currentLineIndex >= playUrls.length) return;

      if (mediaErrorRetryCount < 2) {
        Log.d("播放结束，尝试第${mediaErrorRetryCount + 1}次刷新");
        if (mediaErrorRetryCount == 1) {
          await Future.delayed(const Duration(seconds: 1));
        }
        mediaErrorRetryCount += 1;
        await setPlayer();
        return;
      }

      if (currentLineIndex + 1 < playUrls.length) {
        await changePlayLine(currentLineIndex + 1);
      } else {
        liveStatus.value = false;
      }
    } finally {
      _handlingMediaFailure = false;
    }
  }

  int mediaErrorRetryCount = 0;

  @override
  void mediaError(String error) async {
    if (_suppressMediaEvents || _handlingMediaFailure) return;
    _handlingMediaFailure = true;
    try {
      if (currentLineIndex < 0 || currentLineIndex >= playUrls.length) return;

      if (mediaErrorRetryCount < 2) {
        Log.d("播放失败，尝试第${mediaErrorRetryCount + 1}次刷新");
        if (mediaErrorRetryCount == 1) {
          await Future.delayed(const Duration(seconds: 1));
        }
        mediaErrorRetryCount += 1;
        await setPlayer();
        return;
      }

      if (currentLineIndex + 1 < playUrls.length) {
        await changePlayLine(currentLineIndex + 1);
      } else {
        errorMsg.value = "播放失败";
        SmartDialog.showToast("播放失败:$error");
      }
    } finally {
      _handlingMediaFailure = false;
    }
  }

  /// 添加历史记录
  void addHistory() {
    if (detail.value == null) {
      return;
    }
    var id = "${site.id}_$roomId";
    var history = DBService.instance.getHistory(id);
    if (history != null) {
      history.updateTime = DateTime.now();
    }
    history ??= History(
      id: id,
      roomId: roomId,
      siteId: site.id,
      userName: detail.value?.userName ?? "",
      face: detail.value?.userAvatar ?? "",
      updateTime: DateTime.now(),
    );

    DBService.instance.addOrUpdateHistory(history);
  }

  /// 关注用户
  void followUser() {
    if (detail.value == null) {
      return;
    }
    var id = "${site.id}_$roomId";
    DBService.instance.addFollow(
      FollowUser(
        id: id,
        roomId: roomId,
        siteId: site.id,
        userName: detail.value?.userName ?? "",
        face: detail.value?.userAvatar ?? "",
        addTime: DateTime.now(),
        roomTitle: detail.value?.title ?? "",
      ),
    );
    followed.value = true;
    EventBus.instance.emit(Constant.kUpdateFollow, id);
    SmartDialog.showToast("已关注");
  }

  /// 取消关注用户
  void removeFollowUser() async {
    if (detail.value == null) {
      return;
    }
    // if (!await Utils.showAlertDialog("确定要取消关注该用户吗？", title: "取消关注")) {
    //   return;
    // }

    var id = "${site.id}_$roomId";
    DBService.instance.deleteFollow(id);
    followed.value = false;
    EventBus.instance.emit(Constant.kUpdateFollow, id);
    SmartDialog.showToast("已取消关注");
  }

  void resetRoom(Site site, String roomId) async {
    if (this.site == site && this.roomId == roomId) {
      return;
    }

    _roomRequestVersion += 1;
    _playbackRequestVersion += 1;
    _suppressMediaEvents = true;

    rxSite.value = site;
    rxRoomId.value = roomId;

    // 清除全部消息
    liveDanmaku.stop();

    danmakuController?.clear();

    // 重新设置LiveDanmaku
    liveDanmaku = site.liveSite.getDanmaku();

    // 停止播放
    await player.stop();
    _suppressMediaEvents = false;

    // 刷新信息
    unawaited(loadData());
  }

  void nextChannel() {
    //读取正在直播的频道
    var liveChannels = FollowUserService.instance.livingList;
    if (liveChannels.isEmpty) {
      SmartDialog.showToast("没有正在直播的频道");
      return;
    }
    var index = liveChannels
        .indexWhere((element) => element.id == "${site.id}_$roomId");
    // if (index == -1) {
    //   //当前频道不在列表中

    //   return;
    // }
    index += 1;
    if (index >= liveChannels.length) {
      index = 0;
    }
    var nextChannel = liveChannels[index];

    resetRoom(Sites.allSites[nextChannel.siteId]!, nextChannel.roomId);
  }

  void prevChannel() {
    //读取正在直播的频道
    var liveChannels = FollowUserService.instance.livingList;
    if (liveChannels.isEmpty) {
      SmartDialog.showToast("没有正在直播的频道");
      return;
    }
    var index = liveChannels
        .indexWhere((element) => element.id == "${site.id}_$roomId");
    // if (index == -1) {
    //   //当前频道不在列表中

    //   return;
    // }
    index -= 1;
    if (index < 0) {
      index = liveChannels.length - 1;
    }
    var nextChannel = liveChannels[index];

    resetRoom(Sites.allSites[nextChannel.siteId]!, nextChannel.roomId);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      Log.d("进入后台");
      //进入后台，关闭弹幕
      danmakuController?.clear();
      isBackground = true;
    } else
    //返回前台
    if (state == AppLifecycleState.resumed) {
      Log.d("返回前台");
      isBackground = false;
    }
  }

  @override
  void onClose() {
    _roomRequestVersion += 1;
    _playbackRequestVersion += 1;
    _suppressMediaEvents = true;
    _clockTimer?.cancel();
    doubleClickTimer?.cancel();
    focusNode.dispose();
    liveDanmaku.stop();

    danmakuController = null;
    super.onClose();
  }
}
