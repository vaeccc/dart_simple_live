# Simple Live

<p align="center">
  <img width="128" src="assets/logo.png" alt="Simple Live logo">
</p>

<p align="center">简简单单地看直播。</p>

<p align="center">
  <a href="https://github.com/vaeccc/dart_simple_live/releases"><img src="https://img.shields.io/github/v/release/vaeccc/dart_simple_live?display_name=tag&sort=semver" alt="Latest release"></a>
  <a href="https://github.com/vaeccc/dart_simple_live/actions/workflows/ci.yml"><img src="https://github.com/vaeccc/dart_simple_live/actions/workflows/ci.yml/badge.svg?branch=master" alt="CI"></a>
  <a href="https://github.com/vaeccc/dart_simple_live/blob/master/LICENSE"><img src="https://img.shields.io/github/license/vaeccc/dart_simple_live" alt="License"></a>
</p>

Simple Live 是一个基于 Flutter 的多平台直播客户端，支持手机、平板、桌面端和 Android TV。项目将平台接口、播放地址、弹幕与数据模型集中在 `simple_live_core` 中，APP 和 TV 客户端共享核心能力。

## 2.0.1 版本下载

前往 [GitHub Releases](https://github.com/vaeccc/dart_simple_live/releases/tag/release_2.0.1_tv_2.0.1) 下载正式版。日常使用请下载 Releases 中的正式包，不要下载 Actions 里的 Debug 测试包。

| 设备 | 推荐文件 | 说明 |
| --- | --- | --- |
| Android 手机 / 平板 | `simple-live-app-v2.0.1-arm64-v8a.apk` | 绝大多数 Android 设备使用此版本。 |
| Android TV / 电视盒子 | `simple-live-tv-v2.0.1-arm64-v8a.apk` | 适用于电视和电视盒子，针对遥控器与横屏操作优化。 |
| iPhone / iPad | `simple-live-ios-ipados-v2.0.1-unsigned.ipa` | 未签名 IPA，需要自行签名后安装。 |

只有设备明确不支持 `arm64-v8a` 时，才尝试下载 `armeabi-v7a` 或 `x86_64` 架构的 APK。Android 如果提示禁止安装未知应用，请在系统设置中允许当前浏览器或文件管理器安装应用。

> iOS/iPadOS 安装包没有 Apple 签名，不能直接安装；需要使用自己的开发者证书、TestFlight 或其他合规方式签名处理。

## 支持的平台

- 虎牙直播
- 斗鱼直播
- 哔哩哔哩直播
- 抖音直播
- YY 直播

## 主要功能

- 浏览热门直播和直播分类。
- 按主播昵称、直播间标题、房间号或链接搜索。
- 多清晰度、多播放线路，播放失败时尝试备用线路。
- 关注主播、观看历史和弹幕屏蔽词。
- 关注列表显示直播间封面、直播间标题、主播和在线人数。
- TV 端支持遥控器焦点导航和横屏直播卡片布局。
- 虎牙、YY 网页登录及官方关注列表同步。
- APP 与 TV 之间通过局域网同步数据，不依赖远程同步服务器。

## 快速开始

1. 从 [Releases](https://github.com/vaeccc/dart_simple_live/releases/tag/release_2.0.1_tv_2.0.1) 下载适合设备的安装包。
2. 安装后选择直播平台，进入热门直播、直播分类或搜索直播。
3. 在“关注”中管理主播，刷新后可看到直播状态和直播间详情。
4. TV 端使用遥控器方向键移动焦点，按确认键打开直播间。

## 局域网数据同步

手机、平板和 TV 连接到同一个局域网后，可以互相同步数据。同步过程在局域网内完成，不使用远程同步服务器。

1. 在 TV 或 APP 中打开“数据同步”。
2. 等待设备自动发现，或在 APP 中扫描 TV 显示的二维码。
3. 选择目标设备和需要同步的内容。

支持同步：

- **关注列表**：自动合并，保留目标设备已有关注。
- **观看历史**：保留较新的记录。
- **屏蔽词**：同步屏蔽词列表。
- **登录账号**：哔哩哔哩、YY、虎牙登录状态需要手动选择同步。

账号同步会传输登录状态，请只在自己信任的局域网和设备之间使用；使用完毕后可在账号设置中退出登录。

## 账号与平台说明

虎牙和 YY 的公开直播通常无需登录即可观看。登录后可以访问受限内容，或导入平台官方关注列表。应用不会要求你提供平台密码；网页登录产生的登录状态仅用于对应平台功能。

各平台接口、地区限制、网络状况和主播开播状态都会影响搜索和播放结果。若某个房间无法播放，可以返回后重新打开，或尝试切换清晰度和播放线路。

## 常见问题

### Android 应该下载哪个架构？

优先选择 `arm64-v8a`。只有较老或特殊设备无法运行时，才选择 `armeabi-v7a` 或 `x86_64`。

### 为什么 iPhone/iPad 不能直接安装？

Release 中的 IPA 是未签名构建，不是 App Store 或 TestFlight 包，需要先使用 Apple 签名后安装。

### 为什么同步不到设备？

确认两台设备连接同一个 Wi-Fi，且路由器没有开启访客网络或 AP 隔离。iPhone/iPad 首次使用时，还需要允许应用访问“本地网络”。

### 为什么关注列表暂时没有直播间标题？

应用需要从对应平台刷新直播间详情。请在关注页面点击刷新，并等待状态更新完成；如果平台接口暂时不可用，会回退显示主播名称。

## 免责声明

本项目仅供学习和个人使用。请遵守各直播平台的服务条款及当地法律法规，不得将本项目用于商业或违法用途。直播内容、播放地址和平台接口由第三方平台提供，项目不保证其持续可用性。

## License

本项目采用 [MIT License](LICENSE)。
