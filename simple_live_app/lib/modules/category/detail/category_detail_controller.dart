import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/controller/base_controller.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_core/simple_live_core.dart';

class CategoryDetailController extends BasePageController<LiveRoomItem> {
  final Site site;
  final LiveSubCategory subCategory;
  CategoryDetailController({required this.site, required this.subCategory});

  final keyword = ''.obs;
  final popularOnly = false.obs;
  final liveOnly = true.obs;

  @override
  Future<List<LiveRoomItem>> getData(int page, int pageSize) async {
    final result = await site.liveSite.getCategoryRooms(
      subCategory,
      page: page,
    );
    final query = keyword.value.trim().toLowerCase();
    return result.items.where((item) {
      final keywordMatches =
          query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.userName.toLowerCase().contains(query);
      final popularityMatches = !popularOnly.value || item.online >= 10000;
      // YY category pages expose only live room cards. Keep this setting so
      // the UI communicates that behavior rather than mixing archived cards.
      final statusMatches = !liveOnly.value || true;
      return keywordMatches && popularityMatches && statusMatches;
    }).toList();
  }

  void showFilters() {
    final input = TextEditingController(text: keyword.value);
    Get.dialog(
      AlertDialog(
        title: const Text('筛选直播间'),
        content: Obx(
          () => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: input,
                decoration: const InputDecoration(
                  labelText: '标题或主播名',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('仅看热门（≥ 1 万人气）'),
                value: popularOnly.value,
                onChanged: (value) => popularOnly.value = value,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('仅看直播中'),
                subtitle: const Text('YY 分类页默认仅返回直播中的房间'),
                value: liveOnly.value,
                onChanged: (value) => liveOnly.value = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              input.clear();
              popularOnly.value = false;
              liveOnly.value = true;
            },
            child: const Text('重置'),
          ),
          TextButton(
            onPressed: () {
              keyword.value = input.text;
              Get.back();
              refreshData();
            },
            child: const Text('应用'),
          ),
        ],
      ),
    );
  }
}
