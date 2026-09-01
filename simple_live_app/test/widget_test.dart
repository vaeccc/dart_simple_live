// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';

import 'package:simple_live_app/main.dart';

class _TestAppSettingsController extends AppSettingsController {
  // The production initializer needs Hive-backed services, which this widget
  // shell test intentionally does not start.
  // ignore: must_call_super
  @override
  void onInit() {}
}

void main() {
  testWidgets('application shell builds with configured settings', (
    WidgetTester tester,
  ) async {
    Get.testMode = true;
    Get.put<AppSettingsController>(_TestAppSettingsController());
    await tester.pumpWidget(const MyApp());

    expect(find.byType(GetMaterialApp), findsOneWidget);
    Get.reset();
  });
}
