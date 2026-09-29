import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:simple_live_core/simple_live_core.dart';
import 'package:simple_live_tv_app/app/app_focus_node.dart';

part 'follow_user.g.dart';

@HiveType(typeId: 1)
class FollowUser {
  FollowUser({
    required this.id,
    required this.roomId,
    required this.siteId,
    required this.userName,
    required this.face,
    required this.addTime,
    this.roomTitle = "",
  });

  ///id=siteId_roomId
  @HiveField(0)
  String id;

  @HiveField(1)
  String roomId;

  @HiveField(2)
  String siteId;

  @HiveField(3)
  String userName;

  @HiveField(4)
  String face;

  @HiveField(5)
  DateTime addTime;

  /// 最近一次获取到的直播间标题，用于关注列表和跨设备同步。
  @HiveField(6)
  String roomTitle;

  /// 直播状态
  /// 0=未知(加载中) 1=未开播 2=直播中
  Rx<int> liveStatus = 0.obs;

  /// 当前直播间详情，仅用于 TV 端展示，不持久化到关注数据。
  Rx<LiveRoomDetail?> roomDetail = Rx<LiveRoomDetail?>(null);

  /// 首页直播间卡片的焦点，仅用于 TV 端交互，不持久化。
  final AppFocusNode focusNode = AppFocusNode();

  factory FollowUser.fromJson(Map<String, dynamic> json) => FollowUser(
        id: json['id'],
        roomId: json['roomId'],
        siteId: json['siteId'],
        userName: json['userName'],
        face: json['face'],
        addTime: DateTime.parse(json['addTime']),
        roomTitle: json['roomTitle'] ?? "",
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'roomId': roomId,
        'siteId': siteId,
        'userName': userName,
        'face': face,
        'addTime': addTime.toString(),
        'roomTitle': roomTitle,
      };
}
