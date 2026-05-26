# Telegram Android 源码深度审查报告

> 审查日期：2026-05-26 | 审查对象：Telegram Android (DrKLO/Telegram) | 审查方式：逐文件源码分析

---

## 一、项目规模

| 指标 | 数值 |
|------|------|
| Java 文件总数 | ~1100 |
| Kotlin 文件 | 0（纯 Java） |
| C/C++ 原生文件 | ~200+ |
| 最大单类 | ChatActivity 30000+行 |
| 数据库版本 | 173（渐进迁移） |
| 数据表数量 | 70+ |
| BaseFragment 子类 | 100+ |
| Service | 15 |
| BroadcastReceiver | 20+ |
| ContentProvider | 2 |
| Widget | 3种（聊天/联系人/Feed） |

---

## 二、架构特征

### 2.1 整体架构：自定义 MVC 变体

```
┌──────────────────────────────────────────────┐
│                  UI 层                        │
│  LaunchActivity (主 Activity)                 │
│    └── ActionBarLayout (自定义 Fragment 容器)  │
│          ├── BaseFragment (所有页面基类)        │
│          │     ├── ChatActivity (30000+行)     │
│          │     ├── DialogsActivity            │
│          │     └── ... 100+ Fragment 子类      │
│          └── Cells (140+ 列表项组件)           │
└──────────────────────────────────────────────┘
         ↕ NotificationCenter (200+事件常量)
┌──────────────────────────────────────────────┐
│              Controller 层                    │
│  AccountInstance (多账户实例)                  │
│    ├── MessagesController (消息)              │
│    ├── ContactsController (联系人)            │
│    ├── MediaDataController (媒体数据)         │
│    ├── NotificationsController (通知)         │
│    ├── DownloadController (下载)              │
│    ├── LocationController (位置)              │
│    ├── TranslateController (翻译)             │
│    ├── BillingController (计费)               │
│    └── ... 21 个 BaseController 子类          │
└──────────────────────────────────────────────┘
         ↕
┌──────────────────────────────────────────────┐
│              数据/网络层                       │
│  MessagesStorage (SQLite 持久化, 70+表)       │
│  ConnectionsManager (MTProto 网络, C++实现)   │
│  FileLoader / ImageLoader (四级LRU缓存)       │
│  SharedConfig / UserConfig (配置)             │
└──────────────────────────────────────────────┘
         ↕ JNI
┌──────────────────────────────────────────────┐
│              C/C++ 原生层                     │
│  tgnet (MTProto 连接)                        │
│  tgcalls/webrtc (音视频通话)                  │
│  opus/ffmpeg (编解码)                         │
│  boringssl (加密)                             │
│  sqlite (数据库)                              │
│  rlottie (Lottie 动画)                        │
│  tde2e (端对端加密)                           │
│  rnnoise (AI降噪)                             │
└──────────────────────────────────────────────┘
```

### 2.2 关键架构特征

1. **纯 Java 编写**，0 Kotlin 文件
2. **不使用 Android Fragment API**，自研 BaseFragment + ActionBarLayout 导航框架
3. **NotificationCenter 事件总线**：200+ 事件常量，Controller 与 UI 解耦通信
4. **单例 Controller 模式**：按账户编号索引的数组单例
5. **多账户支持**：最多 4-5 个账户，独立数据库/连接/通知
6. **巨型类模式**：ChatActivity 30000+行，LaunchActivity 8500+行
7. **C++/Java 混合**：MTProto 网络层、加密层完全在 C++ 中实现
8. **内嵌第三方源码**：WebRTC、ZXing、RecyclerView 均以源码形式嵌入

---

## 三、主要包结构

### 3.1 org.telegram.messenger — 核心业务逻辑层（120+文件）

| 子包/类 | 用途 |
|---------|------|
| ApplicationLoader | Application 入口类 |
| BaseController | 所有 Controller 基类 |
| AccountInstance | 多账户实例管理器 |
| MessagesController | 消息核心控制器 |
| MessagesStorage | SQLite 数据库持久化层 |
| ContactsController | 联系人管理 |
| MediaController | 媒体播放控制 |
| MediaDataController | 贴纸/表情/动画表情数据 |
| DownloadController | 下载管理 |
| NotificationsController | 通知管理 |
| SendMessagesHelper | 消息发送辅助 |
| SecretChatHelper | 端对端加密聊天 |
| LocationController | 位置分享 |
| TranslateController | 翻译功能 |
| BillingController | Google Play 计费 |
| NotificationCenter | 事件总线（观察者模式核心） |
| UserConfig / SharedConfig | 用户/全局配置 |
| ImageLoader | 四级 LRU 图片加载器 |
| FileLoader | 文件上传下载 |
| NativeLoader | 原生库加载器 |
| voip/ | VoIP 语音/视频通话 |
| camera/ | 相机控制 |

### 3.2 org.telegram.tgnet — MTProto 网络层

| 类 | 用途 |
|----|------|
| ConnectionsManager | 连接管理器（JNI 调用 C++） |
| TLRPC | 超大型类，所有 TL 序列化/反序列化对象 |
| TLClassStore | TL 类注册表 |
| NativeByteBuffer | 原生字节缓冲区 |
| tl/ 子包 | 按功能分类的 TL 方法 |

### 3.3 org.telegram.ui — UI 层（600+文件）

| 子包 | 文件数 | 用途 |
|------|--------|------|
| ActionBar/ | ~30 | 自定义导航框架 |
| Cells/ | ~140 | UI Cell 组件 |
| Components/ | ~380+ | 可复用 UI 组件（最大子包） |
| Components/Paint/ | ~30+ | 绘图编辑器 |
| Components/Premium/ | ~50+ | Premium 订阅功能 |
| Business/ | ~15 | 商业功能 |
| Stories/ | ~50+ | Stories 功能 |
| Stars/ | ~22 | Stars 虚拟货币 |
| bots/ | ~20 | Bot WebView |

### 3.4 其他包

| 包 | 用途 |
|----|------|
| org.telegram.PhoneFormat | 电话号码格式化（4文件） |
| org.telegram.SQLite | SQLite 封装（4文件） |
| org.webrtc | WebRTC 定制版（100+文件） |
| com.google.zxing | 二维码扫描（内嵌源码） |

---

## 四、聊天功能审查

### 4.1 消息类型（35种）

| 常量 | 值 | 说明 |
|------|---|------|
| TYPE_TEXT | 0 | 纯文本 |
| TYPE_PHOTO | 1 | 照片 |
| TYPE_VOICE | 2 | 语音消息 |
| TYPE_VIDEO | 3 | 视频 |
| TYPE_GEO | 4 | 地理位置/实时位置 |
| TYPE_ROUND_VIDEO | 5 | 圆形视频消息 |
| TYPE_GIF | 8 | GIF动画 |
| TYPE_FILE | 9 | 文件/文档 |
| TYPE_CONTACT | 12 | 联系人 |
| TYPE_STICKER | 13 | 静态贴纸 |
| TYPE_MUSIC | 14 | 音乐 |
| TYPE_ANIMATED_STICKER | 15 | 动态贴纸 |
| TYPE_PHONE_CALL | 16 | 电话记录 |
| TYPE_POLL | 17 | 投票/待办 |
| TYPE_GIFT_PREMIUM | 18 | Premium礼物 |
| TYPE_EMOJIS | 19 | 仅表情 |
| TYPE_STORY | 23 | Story引用 |
| TYPE_STORY_MENTION | 24 | Story提及 |
| TYPE_GIVEAWAY | 26 | 抽奖 |
| TYPE_PAID_MEDIA | 29 | 付费媒体(Stars) |
| TYPE_GIFT_STARS | 30 | Stars礼物 |
| ... | ... | 共35种 |

### 4.2 消息操作（50+种）

回复、转发、编辑、删除、置顶/取消置顶、复制、保存到相册、分享文件、添加贴纸、收藏贴纸、复制链接、举报、翻译、语音转文字、查看回复/线程、统计、事实核查、发送礼物、编辑待办、添加到待办、评价通话、隐藏赞助消息、举报广告、移除广告、立即发送定时消息、编辑定时时间、撤销投票、停止投票、重试发送、取消发送、复制电话号码、拨打电话、添加联系人、应用本地化/主题文件、建议编辑价格/时间/消息等

### 4.3 聊天模式（8种）

默认、定时消息、置顶消息、保存的消息、快速回复、编辑商业链接、搜索、建议

### 4.4 输入区域功能

- 附件菜单：照片/视频、文件、联系人、位置、投票、GIF、颜色、Bot WebView
- Bot 命令菜单 + 自定义键盘
- @提及 + #标签 + 内联Bot建议
- 文本格式化：加粗/斜体/下划线/剧透/等宽/删除线/引用块/自定义表情
- 回复/编辑/转发/定时发送/静默发送/自毁计时器

### 4.5 聊天类型

私聊、Bot、加密聊天、群组、超级群组、频道、论坛、Mono论坛

### 4.6 反应系统

- 长按弹出反应面板
- 双击快速反应
- 自定义表情反应
- Stars付费反应
- 反应动画效果
- 反应标签（保存消息）

### 4.7 翻译功能

- 翻译按钮（聊天顶部）
- 自动翻译整个聊天
- 语言检测（ML Kit）
- 翻译弹窗

### 4.8 消息调度与自动删除

- 定时发送（选择日期时间）
- 周期性定时
- 立即发送定时消息
- 自动删除（TTL计时器）
- 加密聊天自毁

### 4.9 聊天文件夹

- 自定义文件夹/标签
- 文件夹标签页视图
- 下拉切换聊天/文件夹
- 保存消息标签系统

### 4.10 置顶消息

- 顶部置顶消息栏
- 置顶计数器
- 置顶列表查看
- 置顶线视图

### 4.11 管理员工具

- 创建者/管理员权限体系
- 20+种权限控制（发送贴纸/投票/链接/图片等）
- 慢速模式
- 加入请求审批
- 反垃圾
- 话题管理
- Mono论坛管理

---

## 五、媒体与通话

### 5.1 相机功能

- 夜间模式（Camera2 CONTROL_SCENE_MODE_NIGHT）
- HDR（GLSL着色器 + HDRInfo）
- 美颜磨皮（高通皮肤平滑着色器，0-100）
- 13项滤镜参数（增强/曝光/对比度/色温/饱和度/褪色/高光/阴影/暗角/颗粒/锐化/色调分离/模糊）
- 定时器、双摄像头

### 5.2 照片编辑器

- 6种画笔（径向/箭头/椭圆/霓虹/模糊/橡皮擦）
- 贴纸添加+AI抠图创建
- 文字（多字体/对齐/自定义表情）
- 径向+线性模糊
- 形状自动识别（ShapeDetector）
- 人脸检测（Google Mobile Vision）
- 撤销/重做
- 颜色选择+持久化

### 5.3 视频编辑器

- 裁剪/旋转/静音/压缩
- 三态压缩（GIF/标清/高清）
- 144p-4K分辨率
- 24fps帧率

### 5.4 音视频播放

- 音频：6档速度+连续滑块、波形进度条、后台播放、Spring动画
- 视频：ExoPlayer、画中画、多质量流(HLS/DASH/SS)、Chromecast、帧预览

### 5.5 语音消息

- 原生波形生成（5-bit压缩）
- 降噪（NoiseSuppressor + AcousticEchoCanceler）
- 语音转文字（Premium，Lottie动画）
- 实时音频可视化

### 5.6 贴纸/表情系统

- 动画贴纸（Lottie/TGS）
- 自定义贴纸创建（AI抠图）
- Premium专属贴纸
- 面具贴纸
- 表情键盘（GIF标签页+热门+搜索+颜色选择+表情包管理）
- 复合表情（性别/肤色组合）

### 5.7 VoIP通话

- 256字节端到端加密密钥
- 降噪+回声消除
- 屏幕共享
- 画中画
- 蓝牙耳机
- 近距离传感器
- 表情验证码（防中间人）

### 5.8 群组通话

- 发言人/听众角色
- 录制功能
- RTMP直播推流
- 屏幕共享
- 平板网格布局
- 画中画迷你视频窗
- 通话中聊天

---

## 六、安全与加密

| 层级 | 实现 |
|------|------|
| 传输层 | MTProto 2.0（C++原生，DH密钥交换） |
| 端到端加密 | 秘密聊天（AES-CTR/CBC，协议层151） |
| VoIP加密 | 256字节加密密钥 |
| 本地加密 | 密码锁（PIN/密码/生物识别）+ salt |
| 推送加密 | AES-IGE 解密推送payload |
| 代理 | SOCKS5 + MTProto代理 + 自动轮换 |
| 两步验证 | 密码+恢复邮箱+Passkey |
| 自毁消息 | TTL计时器 + 自动删除 |
| 会话管理 | 远程登出 + 未确认登录提示 |
| 隐私设置 | 6类规则（最后上线/头像/手机号/转发/语音/群组邀请） |
| 证书固定 | BoringSSL原生层实现 |

---

## 七、UI/UX系统

### 7.1 主题

- 暗/亮/自动（3种自动模式：定时/亮度传感器/系统/地理位置日落日出）
- 完整主题编辑器（自定义所有颜色值）
- 每聊天独立主题
- 8+预设聊天主题
- 自定义应用图标
- 主题分享链接

### 7.2 动画

- Spring动画（AndroidX DynamicAnimation，广泛使用）
- 灭霸粒子效果（消息消失）
- 剧透文字粒子效果
- 表情全屏动画覆盖层
- 自定义贝塞尔插值器
- Confetti效果

### 7.3 通知系统

- Bulletin系统（替代Snackbar，Spring动画）
- 按对话分组
- Wear OS语音回复
- 智能通知
- 声音节流
- 通知渠道+分组
- 通知内图片

### 7.4 小组件

- 聊天列表小组件
- 联系人小组件
- Feed小组件

### 7.5 其他UI

- 底部弹窗系统（多标签+列表）
- 上下文菜单（ActionBarPopupWindow）
- 滑动手势（滑动回复/滑动接听）
- 浮动日期
- 未读消息分隔
- 空状态视图
- 引导页（OpenGL渲染）

---

## 八、基础设施

### 8.1 数据库

- 自编译SQLite（WAL模式、安全删除、内存临时表）
- 70+张表，173个版本迁移
- 专用后台线程（DispatchQueue）
- 损坏恢复机制
- 每账户独立数据库文件

### 8.2 缓存

- 四级LRU内存缓存（主80%+小图20%+壁纸+Lottie 5MB）
- 基于内存类别动态计算缓存大小
- 引用计数防止误回收
- 磁盘缓存+断点续传
- 按聊天缓存清理

### 8.3 网络

- C++原生MTProto实现
- 多数据中心支持
- IPv4/IPv6自动选择
- DNS缓存
- 代理轮换
- 12种请求标志
- 5种连接状态

### 8.4 后台处理

- FCM/HCM推送（AES-IGE加密）
- Keep-Alive前台服务
- 推送唤醒网络
- 推送数据端到端加密

### 8.5 多账户

- 数组单例模式（MAX_ACCOUNT_COUNT=4，Premium=5）
- AccountInstance门面类
- 独立数据库/SharedPreferences/NotificationCenter

---

## 九、特色功能模块

| 功能 | 文件数 | 关键特性 |
|------|--------|----------|
| Stories | 90+ | 双摄像头、拼图、草稿、6张DB表、上传Service |
| Bot平台 | 24 | WebApp 4种模式、生物识别、传感器、位置、下载 |
| 商业功能 | 21 | 自动回复、营业时间、聊天机器人、快速回复、商业链接 |
| Stars | 21 | 余额管理、付费反应、礼物系统、Bot收入 |
| Premium | 50+ | Google Play订阅、自定义图标、高级贴纸、Boost |
| 统计 | 12 | 自建图表库（8种图表类型） |
| Instant View | 2 | 客户端生成(WebView+instant.js)+服务端生成 |
| 数据导入 | 2 | WhatsApp/Line等，前台Service+进度 |
| Android Auto | 1 | MediaBrowserService音乐浏览 |
| 国际化 | 1 | 18种复数规则，远程语言包 |

---

## 十、构建系统

- Gradle + Android Gradle Plugin
- CMake 用于原生 C/C++ 代码
- NDK r21 (21.4.7075529)
- compileSdkVersion 35, targetSdkVersion 35, minSdkVersion 21
- Java 8 兼容 + coreLibraryDesugaring
- 多渠道分发：Google Play / Huawei / Standalone / HockeyApp
- Docker 可复现构建

### 主要 Gradle 依赖

androidx.core, androidx.palette, androidx.exifinterface, androidx.dynamicanimation, androidx.biometric, play-services-cast/maps/auth/vision/wearable/location/wallet, firebase-messaging/config/datatransport/appindexing, stripe-android, mp4parser, nanohttpd, mlkit-language-id, billingclient, gson, guava, play-integrity, credentials, recaptcha, desugar_jdk_libs

### 原生链接库

rnnoise, openh264, voipandroid, tgvoip, tgcalls, tgnet, flac, rlottie, sqlite, swscale, avformat, avcodec, swresample, libvpx, libdav1d, tde2e, ssl, crypto, GLESv2, EGL, OpenSLES, breakpad
