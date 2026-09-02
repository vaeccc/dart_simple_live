# Simple Live

<p align="center">
  <img width="128" src="assets/logo.png" alt="Simple Live logo">
</p>

<p align="center">简简单单地看直播。</p>

## 下载

正式安装包统一发布在 [GitHub Releases](https://github.com/vaeccc/dart_simple_live/releases)。请勿将 Actions 的 debug 构建作为日常使用版本。

| 平台 | 下载内容 | 说明 |
| --- | --- | --- |
| Android APP | `simple-live-app-*-arm64-v8a.apk` | 大多数 Android 手机、平板请选择此版本。 |
| Android TV | `simple-live-tv-*-arm64-v8a.apk` | 大多数 Android TV / 电视盒子请选择此版本。 |
| iOS / iPadOS | `simple-live-ios-ipados-*-unsigned.ipa` | ARM64 Release IPA，未签名，需自行重签名后才可安装。 |

其他 Android 架构仅在设备明确需要时选择。iOS/iPadOS IPA 不包含 Apple 证书、描述文件或 Apple ID，Windows 不能直接将其安装到 iPhone/iPad。

## 支持的平台

- 虎牙直播
- 斗鱼直播
- 哔哩哔哩直播
- 抖音直播
- YY 直播

客户端包括 Flutter APP、Android TV，以及仍在完善中的 Windows、macOS、Linux 客户端。

## 虎牙与 YY

### 虎牙

- 支持主播/房间搜索、公开直播播放和多 CDN 播放线路。
- APP 使用虎牙官方网页登录/二维码登录，不保存账号密码。
- 登录会话使用安全存储保存；可以退出并清除会话。
- 已登录后可将虎牙官方关注列表合并到本地关注。

### YY

- 支持主播昵称、标题、房间号搜索及 YY 房间链接解析。
- 支持公开直播播放；播放器会优先尝试 HLS，再切换 FLV，并在地址过期时有限次数重新获取播放信息。
- APP 支持 YY 网页登录与关注同步。

弹幕不属于登录、搜索、关注同步或播放链路的前置条件；某个平台的弹幕不可用不会阻止正常观看。

## 局域网同步

同步只在同一局域网内进行，不使用远程同步服务。APP、TV 需保持在同一 Wi-Fi/局域网，并允许本地网络访问。

1. 在 APP 或 TV 打开“数据同步”。
2. 等待发现另一台设备；APP 也可扫描 TV 显示的二维码或手动输入 IP。
3. 选择目标设备后，按需同步数据。

可同步的数据：

- 关注列表：**默认合并**。接收端保留已有关注，只新增不存在的直播间，不会因为另一设备的列表较少而删除本机关注。
- 观看历史：保留更新时间较新的记录。
- 弹幕屏蔽词：合并去重。
- 登录会话：哔哩哔哩、YY、虎牙均为手动触发的明确操作；虎牙可从 APP 或已登录的 TV 同步到当前选定设备。

账号同步会传输登录 Cookie。请只在自己信任的局域网和设备之间使用，操作完成后可在账号设置中退出登录并清除本地会话。

## 项目结构

- `simple_live_core`：站点解析、播放地址与核心模型。
- `simple_live_console`：基于核心库的命令行程序。
- `simple_live_app`：Flutter 手机/平板客户端。
- `simple_live_tv_app`：Flutter Android TV 客户端。

## 开发与验证

项目当前使用 Flutter `3.38`。常用验证命令：

```bash
dart format .
dart analyze
dart test

cd simple_live_app
flutter analyze
flutter test

cd ../simple_live_tv_app
flutter analyze
flutter test
```

仓库仅维护 `master` 正式开发与发布分支。GitHub Actions 会执行核心、APP、TV 的分析、测试和构建校验；正式发布仅生成正式 APK 与 unsigned iOS IPA。

## 参考

- [AllLive](https://github.com/xiaoyaocz/AllLive)
- [dart_tars_protocol](https://github.com/xiaoyaocz/dart_tars_protocol)
- [wbt5/real-url](https://github.com/wbt5/real-url)
- [lovelyyoshino/Bilibili-Live-API](https://github.com/lovelyyoshino/Bilibili-Live-API/blob/master/API.WebSocket.md)
- [TarsCloud/Tars](https://github.com/TarsCloud/Tars)

## 声明

本项目基于公开资料开发，仅供学习和交流编程技术使用。请遵守相关平台规则及当地法律法规，不得用于商业或违法用途。如有侵权，请联系维护者处理。
