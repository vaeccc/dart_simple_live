import 'package:get/get.dart';
import 'package:simple_live_app/app/constant.dart';
import 'package:simple_live_app/models/db/follow_user.dart';
import 'package:simple_live_app/requests/http_client.dart';
import 'package:simple_live_app/services/bilibili_account_service.dart';
import 'package:simple_live_app/services/db_service.dart';
import 'package:simple_live_app/services/yy_account_service.dart';

/// Imports subscriptions only from platforms that have an authenticated app
/// account. The import is additive so it never removes users or custom tags
/// from the local follow list.
class SubscriptionSyncService extends GetxService {
  static SubscriptionSyncService get instance =>
      Get.find<SubscriptionSyncService>();

  Future<SubscriptionSyncResult> syncLoggedInPlatforms() async {
    var added = 0;
    final platforms = <String>[];
    final failures = <String>[];

    if (BiliBiliAccountService.instance.logined.value) {
      try {
        added += await _syncBilibili();
        platforms.add('哔哩哔哩');
      } catch (_) {
        failures.add('哔哩哔哩');
      }
    }
    if (YyAccountService.instance.logined.value) {
      try {
        added += await _syncYy();
        platforms.add('YY');
      } catch (_) {
        failures.add('YY');
      }
    }
    return SubscriptionSyncResult(
      added: added,
      platforms: platforms,
      failures: failures,
    );
  }

  Future<int> _syncBilibili() async {
    final account = BiliBiliAccountService.instance;
    final response = await HttpClient.instance.getJson(
      'https://api.live.bilibili.com/xlive/web-ucenter/v1/xfetter/FeedList',
      queryParameters: const {'page': 1, 'page_size': 100},
      header: {
        'Cookie': account.cookie,
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
        'Referer': 'https://live.bilibili.com/',
      },
    );
    _ensureSuccess(response, '哔哩哔哩订阅');
    return _saveRooms(_extractRooms(response), Constant.kBiliBili);
  }

  Future<int> _syncYy() async {
    final response = await HttpClient.instance.getJson(
      'https://www.yy.com/yyweb/user/queryLivePreview.json',
      queryParameters: {'_': DateTime.now().millisecondsSinceEpoch},
      header: {
        'Cookie': YyAccountService.instance.cookie,
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
        'Referer': 'https://www.yy.com/',
      },
    );
    _ensureSuccess(response, 'YY 订阅');
    return _saveRooms(_extractRooms(response), Constant.kYy);
  }

  void _ensureSuccess(dynamic response, String name) {
    if (response is! Map) {
      throw StateError('$name读取失败');
    }
    for (final key in const ['resultCode', 'code', 'ret']) {
      final value = response[key];
      if (value != null && value.toString() != '0') {
        throw StateError('$name读取失败');
      }
    }
  }

  Future<int> _saveRooms(List<_SubscriptionRoom> rooms, String siteId) async {
    var added = 0;
    for (final room in rooms) {
      final id = '${siteId}_${room.roomId}';
      if (DBService.instance.getFollowExist(id)) continue;
      await DBService.instance.addFollow(
        FollowUser(
          id: id,
          roomId: room.roomId,
          siteId: siteId,
          userName: room.userName,
          face: room.face,
          addTime: DateTime.now(),
        ),
      );
      added++;
    }
    return added;
  }

  /// The two platforms use different response field names. Traverse the public
  /// response and normalize only maps that contain both a live-room id and a
  /// presenter name; duplicate rooms are discarded.
  List<_SubscriptionRoom> _extractRooms(dynamic value) {
    final rooms = <_SubscriptionRoom>[];
    final seen = <String>{};

    void visit(dynamic item) {
      if (item is List) {
        for (final child in item) {
          visit(child);
        }
        return;
      }
      if (item is! Map) return;

      final roomId = _firstValue(item, const [
        'room_id',
        'roomid',
        'roomId',
        'live_room_id',
        'sid',
      ]);
      final userName = _firstValue(item, const [
        'uname',
        'user_name',
        'anchor_name',
        'nickname',
        'nick',
        'name',
      ]);
      if (RegExp(r'^\d+$').hasMatch(roomId) &&
          userName.isNotEmpty &&
          seen.add(roomId)) {
        rooms.add(
          _SubscriptionRoom(
            roomId: roomId,
            userName: userName,
            face: _firstValue(item, const [
              'face',
              'avatar',
              'face_url',
              'headurl',
              'thumb',
            ]),
          ),
        );
      }
      for (final child in item.values) {
        visit(child);
      }
    }

    visit(value);
    return rooms;
  }

  String _firstValue(Map value, List<String> keys) {
    for (final key in keys) {
      final text = value[key]?.toString().trim() ?? '';
      if (text.isNotEmpty && text != 'null') return text;
    }
    return '';
  }
}

class _SubscriptionRoom {
  const _SubscriptionRoom({
    required this.roomId,
    required this.userName,
    required this.face,
  });

  final String roomId;
  final String userName;
  final String face;
}

class SubscriptionSyncResult {
  const SubscriptionSyncResult({
    required this.added,
    required this.platforms,
    required this.failures,
  });

  final int added;
  final List<String> platforms;
  final List<String> failures;
}
