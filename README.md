> ### 正式安装包请从 [GitHub Releases](https://github.com/vaeccc/dart_simple_live/releases) 下载。请勿使用 Actions 中的 debug 构建作为日常版本。


<p align="center">
    <img width="128" src="/assets/logo.png" alt="Simple Live logo">
</p>
<h2 align="center">Simple Live</h2>

<p align="center">
简简单单的看直播
</p>

## 支持直播平台：

- 虎牙直播

- 斗鱼直播

- 哔哩哔哩直播

- 抖音直播

- YY 直播

## 下载与版本

- APP 与 Android TV 都发布签名的正式 Release APK。
- 请按设备架构下载对应 APK；大多数手机和电视选择 `arm64-v8a`。
- Actions 中的 debug 产物只用于持续集成校验，不作为发布版本。

## YY 支持

- 浏览 YY 首页、分类和直播间，支持房间号搜索与播放。
- APP 支持 YY 网页扫码登录，并可同步已关注的直播间。
- APP 与 TV 在同一局域网时，可将 YY 登录会话同步到 TV；TV 会加密保存会话。

## 局域网数据同步

同步仅在同一局域网内进行，不依赖远程房间服务。

1. TV 打开“数据同步”，保持二维码或 IP 地址页面。
2. APP 打开“数据同步”，扫描二维码或输入 TV 的 IP 地址。
3. 连接设备后，按需同步关注列表、观看历史、弹幕屏蔽词、哔哩哔哩账号或 YY 账号。

请只在可信局域网使用账号同步功能。

## APP支持平台

- [x] Android
- [x] iOS
- [x] Windows `BETA`
- [x] MacOS `BETA`
- [x] Linux `BETA`
- [x] Android TV `BETA`

## 项目结构

- `simple_live_core` 项目核心库，实现获取各个网站的信息及弹幕。
- `simple_live_console` 基于simple_live_core的控制台程序。
- `simple_live_app` 基于核心库实现的Flutter APP客户端。
- `simple_live_tv_app` 基于核心库实现的Flutter Android TV客户端。

## 环境

Flutter : `3.38`

## 分支

项目仅维护 `master` 作为正式开发与发布分支。

## 参考及引用

[AllLive](https://github.com/xiaoyaocz/AllLive) `本项目的C#版，有兴趣可以看看`

[dart_tars_protocol](https://github.com/xiaoyaocz/dart_tars_protocol.git)

[wbt5/real-url](https://github.com/wbt5/real-url)

[lovelyyoshino/Bilibili-Live-API](https://github.com/lovelyyoshino/Bilibili-Live-API/blob/master/API.WebSocket.md)

[IsoaSFlus/danmaku](https://github.com/IsoaSFlus/danmaku)

[BacooTang/huya-danmu](https://github.com/BacooTang/huya-danmu)

[TarsCloud/Tars](https://github.com/TarsCloud/Tars)

[YunzhiYike/douyin-live](https://github.com/YunzhiYike/douyin-live)

[5ime/Tiktok_Signature](https://github.com/5ime/Tiktok_Signature)

## 声明

本项目的所有功能都是基于互联网上公开的资料开发，无任何破解、逆向工程等行为。

本项目仅用于学习交流编程技术，严禁将本项目用于商业目的。如有任何商业行为，均与本项目无关。

如果本项目存在侵犯您的合法权益的情况，请及时与开发者联系，开发者将会及时删除有关内容。

## Star History

<a href="https://www.star-history.com/#xiaoyaocz/dart_simple_live&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=xiaoyaocz/dart_simple_live&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=xiaoyaocz/dart_simple_live&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=xiaoyaocz/dart_simple_live&type=Date" />
 </picture>
</a>
