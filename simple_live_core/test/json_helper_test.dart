import 'package:simple_live_core/src/common/json_helper.dart';
import 'package:test/test.dart';

void main() {
  test('invalid and empty provider values return safe defaults', () {
    expect(jsonMap(null), isNull);
    expect(jsonMap('invalid'), isNull);
    expect(jsonList(null), isEmpty);
    expect(jsonList(<String, dynamic>{}), isEmpty);
    expect(jsonString(null), isEmpty);
    expect(jsonInt('not-a-number'), 0);
    expect(jsonBool('unknown'), isFalse);
    expect(jsonDecodeOrNull(''), isNull);
    expect(jsonDecodeOrNull('{invalid'), isNull);
  });

  test('provider primitive values are normalized consistently', () {
    expect(jsonMap({'room': 1}), {'room': 1});
    expect(jsonList([1, 2]), [1, 2]);
    expect(jsonString(123), '123');
    expect(jsonInt(12.8), 12);
    expect(jsonInt('42'), 42);
    expect(jsonBool(1), isTrue);
    expect(jsonBool('false'), isFalse);
    expect(jsonDecodeOrNull('{"ok":true}'), {'ok': true});
  });
}
