# 开发与维护

本仓库由多个 Dart / Flutter 子项目组成，共享 `simple_live_core`。

## 项目结构

| 目录 | 用途 |
| --- | --- |
| `simple_live_core` | 聚合直播核心库：平台接口、播放地址、弹幕与数据模型 |
| `simple_live_app` | 手机、平板及桌面 Flutter 客户端 |
| `simple_live_tv_app` | Android TV 客户端 |
| `simple_live_console` | 基于 Core 的命令行工具 |
| `.github/workflows` | CI、Debug 构建和正式 Release 工作流 |

## 工具链

- Flutter：`3.38.3`
- Dart：`>=3.10.0 <4.0.0`
- Android CI Java：17

APP 与 TV 的 `.fvmrc` 固定 Flutter 版本。应用项目应提交 `pubspec.lock` 以保证构建可复现；核心库作为 library 不提交 lockfile。

## 验证分层

Core 的 required CI 运行确定性的 YY 解析器测试。完整的 `simple_live_core/test/simple_live_core_test.dart` 会访问真实直播平台并等待实时弹幕，因此属于网络集成测试，不作为稳定门禁。

APP：

```bash
cd simple_live_app
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

TV：

```bash
cd simple_live_tv_app
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Console：

```bash
cd simple_live_console
dart pub get
dart analyze
dart test
```

## 发布工作流

- `build-android-apk.yml`：手动发布 APP 正式 APK，并构建/附加未签名 iOS/iPadOS IPA。
- `publish_tv_app_release.yaml`：推送 `release_*` 标签时构建并附加 TV APK。
- `build-debug-test.yml`：手动生成 APP/TV Debug 测试包。
- `build-ios.yml`：手动生成未签名 iOS/iPadOS IPA，不创建正式 Release。
- `ci.yml`：只做验证，不发布安装包。

## 维护约定

1. 平台解析、UI、同步协议与发布脚本尽量拆成独立 PR。
2. 登录 Cookie、Token、密码和授权头不得写入日志。
3. 局域网同步涉及设备发现、HTTP 服务和第三方账号登录态，协议改动应单独评审并做 APP/TV 兼容验证。
4. 不提交 `build/`、`.dart_tool/`、签名文件和本机配置。
5. 依赖真实平台接口的集成测试与离线解析器测试分层维护。
