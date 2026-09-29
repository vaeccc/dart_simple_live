import 'package:flutter_test/flutter_test.dart';
import 'package:simple_live_tv_app/app/controller/base_controller.dart';

class _TestPageController extends BasePageController<int> {
  final Map<int, List<int>> pages;
  _TestPageController(this.pages);

  @override
  Future<List<int>> getData(int page, int pageSize) async =>
      pages[page] ?? <int>[];
}

void main() {
  test('first page replaces list and advances page number', () async {
    final controller = _TestPageController({1: [1, 2], 2: [3]});
    await controller.refreshData();
    expect(controller.list, [1, 2]);
    expect(controller.currentPage, 2);
    await controller.loadData();
    expect(controller.list, [1, 2, 3]);
    expect(controller.currentPage, 3);
  });

  test('empty pages keep correct state', () async {
    final empty = _TestPageController({1: <int>[]});
    await empty.refreshData();
    expect(empty.pageEmpty.value, isTrue);
    expect(empty.currentPage, 1);

    final nextEmpty = _TestPageController({1: [1, 2], 2: <int>[]});
    await nextEmpty.refreshData();
    await nextEmpty.loadData();
    expect(nextEmpty.list, [1, 2]);
    expect(nextEmpty.currentPage, 2);
    expect(nextEmpty.pageEmpty.value, isFalse);
    expect(nextEmpty.canLoadMore.value, isFalse);
  });
}
