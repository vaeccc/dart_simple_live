# Simple Live

<p align="center">
  <img width="128" src="assets/logo.png" alt="Simple Live logo">
</p>

<p align="center">简简单单地看直播。</p>

<p align="center">
  <a href="https://github.com/vaeccc/dart_simple_live/releases"><img src="https://img.shields.io/github/v/release/vaeccc/dart_simple_live?display_name=tag&sort=semver" alt="Latest release"></a>
  <a href="https://github.com/vaeccc/dart_simple_live/blob/master/LICENSE"><img src="https://img.shields.io/github/license/vaeccc/dart_simple_live" alt="License"></a>
</p>

Simple Live 是一个简洁的多平台直播客户端，支持手机、平板、桌面端和 Android TV。你可以在一个应用中浏览直播、搜索房间、管理关注并观看直播。

## 下载

当前正式版本：**2.0.3**

前往 [GitHub Releases](https://github.com/vaeccc/dart_simple_live/releases/tag/release_2.0.3_tv_2.0.3) 下载安装包。

| 设备 | 推荐安装包 |
| --- | --- |
| Android 手机 / 平板 | `simple-live-app-v2.0.3-arm64-v8a.apk` |
| Android TV / 电视盒子 | `simple-live-tv-v2.0.3-arm64-v8a.apk` |
| iPhone / iPad | `simple-live-ios-ipados-v2.0.3-unsigned.ipa` |

大多数 Android 设备请选择 `arm64-v8a`。只有设备明确不支持该架构时，才选择 `armeabi-v7a` 或 `x86_64`。

> iOS/iPadOS 安装包为未签名 IPA，不能直接作为 App Store 或 TestFlight 包安装，需要使用自己的 Apple 开发者证书或其他合规方式签名。

## 支持平台

- 虎牙直播
- 斗鱼直播
- 哔哩哔哩直播
- 抖音直播
- YY 直播

平台接口和直播内容由对应平台提供，实际可用内容可能受网络、地区、房间状态和平台接口变化影响。

## 主要功能

- 浏览热门直播和直播分类。
- 按主播昵称、直播间标题、房间号或链接搜索。
- 支持多清晰度和多播放线路。
- 关注主播、查看观看历史和管理弹幕屏蔽词。
- 关注列表显示直播间封面、标题、主播、平台和直播状态。
- 直播中与未开播状态清晰区分，方便快速找到正在直播的内容。
- TV 端支持遥控器焦点导航、横屏布局和电视直播卡片。
- 支持虎牙、YY 网页登录及官方关注列表同步。
- 支持 APP 与 TV 通过局域网同步关注、历史和屏蔽词等数据。

## 使用说明

安装后选择直播平台，即可进入热门直播、分类或搜索页面。打开直播间后可以切换清晰度和播放线路；如果当前线路无法播放，可以返回房间后重新尝试其他线路。

在“我的关注”中可以查看主播的直播状态和直播间信息。列表没有及时更新时，请点击刷新，等待平台数据同步完成。

TV 端使用遥控器方向键移动焦点，按确认键进入直播间；返回键用于返回上一级页面。

## 局域网同步

APP 和 TV 连接到同一个局域网后，可以在“数据同步”页面互相同步数据。同步在本地网络内完成，不依赖远程同步服务器。

1. 在 APP 或 TV 中打开“数据同步”。
2. 等待设备自动发现，或使用 APP 扫描 TV 显示的二维码。
3. 选择需要同步的设备和数据类型。

支持同步的内容包括：

- 关注列表
- 观看历史
- 弹幕屏蔽词
- 部分平台登录状态

账号同步会传输登录状态，请只在自己信任的局域网和设备之间使用。同步完成后，可以在平台账号设置中退出登录。

## 常见问题

### Android 应该下载哪个版本？

优先选择 `arm64-v8a`。较老的 32 位设备选择 `armeabi-v7a`，Android 模拟器或特殊设备可尝试 `x86_64`。

### 为什么关注列表没有标题或直播状态？

关注列表需要从对应平台刷新直播间详情。请点击刷新并等待更新完成；如果平台接口暂时不可用，可能会暂时显示不完整的信息。

### 为什么同步不到另一台设备？

请确认两台设备连接到同一个 Wi-Fi，并检查路由器是否开启了访客网络或 AP 隔离。iPhone/iPad 还需要允许应用访问“本地网络”。

### 为什么 iPhone/iPad 不能直接安装？

Release 中的 IPA 没有 Apple 签名，需要先使用开发者证书签名后再安装。

## 免责声明

本项目仅供学习和个人使用。请遵守各直播平台的服务条款及当地法律法规，不得将本项目用于商业或违法用途。直播内容、播放地址和平台接口由第三方平台提供，项目不保证其持续可用性。

## License

本项目采用 [MIT License](LICENSE)。
