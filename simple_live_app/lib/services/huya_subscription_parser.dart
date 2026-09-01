/// Normalizes the data shapes used by Huya's subscribed-streamer page.
///
/// It intentionally accepts only entries containing a numeric room id and a
/// presenter name. Unknown markup/API fields are skipped instead of making a
/// failed subscription refresh affect playback or the local follow database.
class HuyaSubscriptionParser {
  static List<HuyaSubscriptionRoom> parseJson(dynamic value) {
    final rooms = <HuyaSubscriptionRoom>[];
    final seen = <String>{};

    void visit(dynamic node) {
      if (node is List) {
        for (final item in node) {
          visit(item);
        }
        return;
      }
      if (node is! Map) return;
      final roomId = _first(node, const [
        'iRoomId',
        'roomId',
        'room_id',
        'profileRoom',
      ]);
      final userName = _first(node, const [
        'sNick',
        'nick',
        'userName',
        'name',
      ]);
      if (RegExp(r'^\d+$').hasMatch(roomId) &&
          userName.isNotEmpty &&
          seen.add(roomId)) {
        rooms.add(
          HuyaSubscriptionRoom(
            roomId: roomId,
            userName: userName,
            face: _first(node, const [
              'sAvatar',
              'avatar',
              'avatarUrl',
              'sVideoCaptureUrl',
            ]),
          ),
        );
      }
      for (final child in node.values) {
        visit(child);
      }
    }

    visit(value);
    return rooms;
  }

  /// Fallback for the official `/myfollow` web page when it is server-rendered
  /// rather than returned as JSON.
  static List<HuyaSubscriptionRoom> parseHtml(String html) {
    final rooms = <HuyaSubscriptionRoom>[];
    final seen = <String>{};
    final cards = RegExp(
      r'''<(?:li|div)[^>]*(?:live-room|room-card|subscribe)[^>]*>([\s\S]*?)</(?:li|div)>''',
      caseSensitive: false,
    ).allMatches(html);
    for (final card in cards) {
      final body = card.group(1) ?? '';
      final roomId =
          RegExp(
            r'''href=["'](?:https?://www\.huya\.com)?/(\d+)["']''',
          ).firstMatch(body)?.group(1) ??
          RegExp(
            r'''data-(?:roomid|room-id)=["'](\d+)["']''',
          ).firstMatch(body)?.group(1) ??
          '';
      final userName =
          RegExp(
            r'''(?:data-nick|title)=["']([^"']+)["']''',
            caseSensitive: false,
          ).firstMatch(body)?.group(1)?.trim() ??
          '';
      if (!RegExp(r'^\d+$').hasMatch(roomId) ||
          userName.isEmpty ||
          !seen.add(roomId)) {
        continue;
      }
      final face =
          RegExp(
            r'''<img[^>]+(?:data-original|src)=["']([^"']+)["']''',
            caseSensitive: false,
          ).firstMatch(body)?.group(1)?.trim() ??
          '';
      rooms.add(
        HuyaSubscriptionRoom(
          roomId: roomId,
          userName: _decode(userName),
          face: face.startsWith('//') ? 'https:$face' : face,
        ),
      );
    }
    return rooms;
  }

  static String _first(Map value, List<String> keys) {
    for (final key in keys) {
      final text = value[key]?.toString().trim() ?? '';
      if (text.isNotEmpty && text != 'null') return text;
    }
    return '';
  }

  static String _decode(String value) => value
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&#39;', "'")
      .replaceAll('&quot;', '"');
}

class HuyaSubscriptionRoom {
  const HuyaSubscriptionRoom({
    required this.roomId,
    required this.userName,
    required this.face,
  });

  final String roomId;
  final String userName;
  final String face;
}
