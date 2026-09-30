import 'package:simple_live_tv_app/models/db/follow_user.dart';
import 'package:simple_live_tv_app/services/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

FollowUser buildFollowUser({
  String userName = '主播',
  String face = 'local-face',
  String roomTitle = '',
}) {
  return FollowUser(
    id: 'bilibili_1',
    roomId: '1',
    siteId: 'bilibili',
    userName: userName,
    face: face,
    addTime: DateTime(2026, 1, 1),
    roomTitle: roomTitle,
  );
}

void main() {
  test('old follow data defaults roomTitle to empty', () {
    final user = FollowUser.fromJson({
      'id': 'bilibili_1',
      'roomId': '1',
      'siteId': 'bilibili',
      'userName': '主播',
      'face': 'face',
      'addTime': '2026-01-01T00:00:00.000',
    });

    expect(user.roomTitle, isEmpty);
  });

  test('follow merge fills missing fields without overwriting local data', () {
    final local = buildFollowUser();
    final incoming = buildFollowUser(
      userName: '同步主播',
      face: 'remote-face',
      roomTitle: '正在直播的标题',
    );

    expect(local.mergeMissingFieldsFrom(incoming), isTrue);
    expect(local.userName, '主播');
    expect(local.face, 'local-face');
    expect(local.roomTitle, '正在直播的标题');
    expect(local.mergeMissingFieldsFrom(incoming), isFalse);
  });

  test('sync tries the default port and nine fallback ports', () {
    expect(
      SyncService.httpPortCandidates().toList(),
      List.generate(10, (index) => SyncService.defaultHttpPort + index),
    );
  });
}
