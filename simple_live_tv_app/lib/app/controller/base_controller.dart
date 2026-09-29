import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:simple_live_tv_app/app/app_error.dart';

import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class BaseController extends GetxController {
  /// 加载中，更新页面
  var pageLoadding = false.obs;

  /// 加载中
  var loadding = false.obs;

  /// 空白页面
  var pageEmpty = false.obs;

  /// 页面错误
  var pageError = false.obs;

  /// 未登录
  var notLogin = false.obs;

  /// 错误信息
  var errorMsg = "".obs;

  /// 显示错误
  /// * [msg] 错误信息
  /// * [showPageError] 显示页面错误
  /// * 只在第一页加载错误时showPageError=true，后续页加载错误时使用Toast弹出通知
  void handleError(Object exception, {bool showPageError = false}) {
    var msg = exceptionToString(exception);
    if (exception is AppError && exception.notLogin) {
      notLogin.value = true;
      pageError.value = false;
      return;
    }
    if (showPageError) {
      pageError.value = true;
      errorMsg.value = msg;
    } else {
      SmartDialog.showToast(exceptionToString(msg));
    }
  }

  String exceptionToString(Object exception) {
    if (exception is AppError) {
      return exception.toString();
    }
    return exception.toString().replaceAll("Exception:", "");
  }

  void onLogin() {}
  void onLogout() {}
}

class BasePageController<T> extends BaseController {
  final ScrollController scrollController = ScrollController();
  final EasyRefreshController easyRefreshController = EasyRefreshController();
  int currentPage = 1;
  int count = 0;
  int maxPage = 0;
  int pageSize = 24;
  var canLoadMore = false.obs;
  var list = <T>[].obs;

  Future<void> refreshData() async {
    if (loadding.value) return;
    currentPage = 1;
    canLoadMore.value = false;
    list.clear();
    await loadData();
  }

  Future<void> loadData() async {
    if (loadding.value) return;

    final pageToLoad = currentPage;
    final isFirstPage = pageToLoad == 1;
    try {
      loadding.value = true;
      pageError.value = false;
      pageEmpty.value = false;
      notLogin.value = false;
      pageLoadding.value = isFirstPage;

      final result = await getData(pageToLoad, pageSize);

      if (isFirstPage) {
        list.assignAll(result);
      } else {
        list.addAll(result);
      }

      if (result.isNotEmpty) {
        currentPage = pageToLoad + 1;
        canLoadMore.value = true;
      } else {
        canLoadMore.value = false;
      }
      pageEmpty.value = isFirstPage && list.isEmpty;
    } catch (e) {
      handleError(e, showPageError: isFirstPage);
      pageEmpty.value = isFirstPage && list.isEmpty;
    } finally {
      loadding.value = false;
      pageLoadding.value = false;
    }
  }

  Future<List<T>> getData(int page, int pageSize) async {
    return [];
  }

  void scrollToTopOrRefresh() {
    if (scrollController.offset > 0) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.linear,
      );
    } else {
      easyRefreshController.callRefresh();
    }
  }
}
