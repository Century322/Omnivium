# Telegram vs Omnivium 对比与学习参考

> 最后更新：2026-05-24 | 合并自：TELEGRAM_LEARN.md + FULL_COMPARISON.md
> 本文档为外部参考文档，不作为项目进度追踪源

---

## 一、规模对比

| 维度 | Telegram | Omnivium | 差距 |
|------|----------|----------|------|
| 语言 | Java/Kotlin + C/C++ | Dart (Flutter) | 不同技术栈 |
| 控制器/服务 | 85 个 | 37 个 | 2.3x |
| UI Cell 组件 | 140 个 | 0（融入 widget） | - |
| 可复用组件 | ~381 个 | 22 个 | 17x |
| 页面/屏幕 | ~347 个 | 26 个 | 13x |
| UI 总文件 | ~868 个 | 47 个 | 18x |
| 测试文件 | 4-5 (androidTest) | 66 (unit+widget) | 我们更多 |
| CI/CD | 无 | GitHub Actions | 我们更好 |
| ProGuard | 仅收缩，禁用混淆 | 完整 R8 优化+混淆 | 我们更好 |

---

## 二、安全特性对比

| 安全特性 | Telegram | Omnivium | 状态 |
|---------|----------|----------|------|
| 自研握手协议 | MTProto 2.0（DH-2048 + RSA-2048） | 无（依赖 TLS） | 🔴 长期目标 |
| 消息密钥推导 | SHA-256 KDF，每消息独立密钥 | 无（依赖 Matrix Megolm） | 🟠 中 |
| 端到端加密聊天 | 自研 AES-256-IGE | Matrix Megolm | ✅ 已有 |
| 加密文件存储 | AES-256-CTR/CBC，密钥分离 | AES-256 加密文件存储 | ✅ 已实现 |
| SRP 零知识密码 | PBKDF2 100K 迭代 | SRP 安全远程密码 | ✅ 已实现 |
| 应用锁 PIN/密码 | SHA-256+salt，暴力破解保护 | PIN 码 + 生物识别 | ✅ 已实现 |
| 自动锁定 | 1m/5m/1h/5h | app_lock_service | ⚠️ 框架已有 |
| 生物识别解锁 | AndroidKeyStore+BiometricPrompt | local_auth + biometric_service | ✅ 已实现 |
| SSL 证书固定 | 硬编码服务器公钥指纹 | 动态 SSL Pinning（SHA-256） | ⚠️ 框架就绪，待配真实 hash |
| 安全本地存储 | SP+AndroidKeyStore | flutter_secure_storage | ✅ 已有 |
| 应用层加密 | 多层（传输/存储/消息） | AES-256-GCM | ✅ 已有（密钥不再同步服务器） |
| HMAC 请求签名 | 协议内置 | HMAC-SHA256 | ✅ 已有 |
| TOTP 两步验证 | 无 | 有 | ✅ 我们更好 |
| Root/越狱检测 | 无 | 有 | ✅ 我们更好 |
| 端到端加密通话 | tde2e（Ed25519+区块链状态） | WebRTC + Matrix 信令 | ⚠️ 基础实现 |
| 防截屏保护 | FLAG_SECURE | secure_flag_service | ⚠️ 框架已有 |
| 密钥可视化验证 | Emoji 对比 | SAS Emoji/数字验证 | ✅ 已有 |
| 模拟器检测 | 无 | 有 | ✅ 我们更好 |

### 已修复的安全问题

| 问题 | 原状态 | 当前状态 |
|------|--------|---------|
| 加密密钥同步到服务器 | 🔴 极高 | ✅ 已删除 `_syncKeyToServer()` |
| 无应用锁 | 🔴 高 | ✅ app_lock_service.dart 已实现 |
| 无加密文件存储 | 🔴 高 | ✅ encrypted_file_storage.dart 已实现 |
| 无 SRP 密码验证 | 🟠 中 | ✅ srp_service.dart 已实现 |
| 无生物识别解锁 | 🟠 中 | ✅ biometric_service.dart 已实现 |
| 无防截屏保护 | 🟠 中 | ⚠️ secure_flag_service.dart 框架已有 |

### 仍需修复的安全问题

| 问题 | 严重程度 | 修复方案 |
|------|---------|---------|
| TOTP 密钥生成不安全 | 🔴 高 | 改用 Random.secure() |
| 无自动锁定超时 | 🟠 中 | 完善 app_lock_service 自动锁定逻辑 |

---

## 三、控制器/服务对比

### Telegram 有我们也有（27/85 = 31.8%）

| Telegram 控制器 | Omnivium 对应 |
|----------------|---------------|
| MessagesController | SessionProvider + AgentOrchestrator |
| ContactsController | ContactsView |
| MediaController | VoiceService + media_kit |
| NotificationsController | PushNotificationService + NotificationQueue |
| DownloadController | FileDownloadService |
| UserController | MatrixService |
| MessagesStorage | DatabaseService |
| SharedConfig | SharedPreferences + SecureStorage |
| FileLog | FileLog + AppLogger |
| NotificationCenter | NotificationCenter |
| LiteMode | LiteMode |
| LruCache | LruCache + ImageCacheManager |
| Theme / ThemeColors | ThemeProvider + AppColors |
| LocaleController | LocaleProvider + gen_l10n |
| AndroidUtilities | format_utils + responsive |
| BuildVars | RemoteConfigService |
| ImageLoader | CachedNetworkImage |
| FileLoader | FileDownloadService |
| ConnectionsManager | ApiProxyService + Matrix SDK |

### Telegram 有我们没有（58/85 = 68.2%）— 按重要程度

| 缺失控制器 | 功能 | 重要程度 |
|-----------|------|---------|
| VoIPService | 语音/视频通话 | 🔴 高（基础已有，需完善） |
| SecretChatHelper | 端到端加密聊天 | 🔴 高（Matrix Megolm 替代） |
| BotWebView | Bot 平台 | 🟠 中 |
| CameraController | 相机控制 | 🟠 中 |
| GroupCallController | 群通话 | 🟠 中 |
| ContactsSyncAdapter | 系统联系人同步 | 🟠 中 |
| CacheByChatsController | 按聊天缓存策略 | 🟠 中 |
| AutoDeleteController | 自动删除消息 | 🟡 低 |
| ReactionsController | 消息反应 | 🟡 低 |
| StickersController | 贴纸系统 | 🟡 低 |

---

## 四、构建配置对比

| 配置 | Telegram | Omnivium |
|------|----------|----------|
| 模块数 | 6 个 Gradle 模块 | 1 个 app 模块 |
| Build Types | 6 个 | 2 个 |
| Product Flavors | 3 个 | 0 个 |
| ProGuard | 仅收缩，禁用混淆 | 完整 R8 优化+混淆 |
| CI/CD | 无 | GitHub Actions（Lint→Test→Build+混淆） |
| 测试 | 4-5 androidTest | 66 unit+widget |
| 网络安全 | 允许明文流量 | 默认禁止明文 |

---

## 五、我们的独特优势（Telegram 没有）

| 能力 | 说明 |
|------|------|
| AI Agent 引擎 | 意图分类→三通道处理→流式输出→权限确认 |
| Agent 状态机 | 10 状态、11 条合法转换、3 次恢复上限 |
| 记忆系统 | 三层架构+时间衰减+重要性排序 |
| 上下文预算管理 | 128K Token 预算分配 |
| 技能系统 | SkillRegistry + WebSearchSkill |
| 流式输出控制器 | 广播 Stream + Buffer 管理 |
| 内联卡片运行时 | CardLifecycle 状态管理 |
| AI 生成工作台 | 8 种模板，多模型切换 |
| 远程 UI 引擎 | AI 工作台动态 UI |
| 动态 SSL Pinning | 远程更新 pin 列表 |
| 强调色自定义 | 8 种预设色，全局动态切换 |
| 设备安全检查 | Root/越狱/模拟器检测 |
| 完整 R8 混淆 | 代码保护比电报更好 |
| 禁止明文流量 | 网络安全配置比电报更严格 |

---

## 六、可学习点 Top 20

| 排名 | 学习点 | 领域 | 我们当前状态 | 难度 |
|------|--------|------|-------------|------|
| ⭐1 | LruCache 三级图片缓存 | 性能 | 无系统化缓存 | 高 |
| ⭐2 | NotificationCenter 事件总线 | 架构 | ChangeNotifier | 低 |
| ⭐3 | rLottie + BlobDrawable 动画引擎 | UI | 基本无动画 | 中 |
| ⭐4 | ChatMessageCell 消息气泡渲染 | UI | Widget 组合 | 高 |
| ⭐5 | PhotoViewer 全屏查看器 | UI | 无 | 高 |
| ⭐6 | 请求优先级+连接类型 | 网络 | 无优先级 | 中 |
| ⭐7 | Android KeyStore 生物识别 | 安全 | local_auth 已有 | 中 |
| ⭐8 | 键盘高度测量 | UI | viewInsets.bottom | 低 |
| ⭐9 | DispatchQueue 专用队列 | 架构 | Dart async/await | 中 |
| ⭐10 | 多模块构建+ABI版本编码 | 构建 | 单模块 | 低 |
| ⭐11 | 构建变体+local.properties | 构建 | --dart-define | 低 |
| ⭐12 | LiteMode 低端设备降级 | 性能 | LiteMode 已有框架 | 低 |
| ⭐13 | 复数形式国际化 | i18n | 仅简单 key | 低 |
| ⭐14 | 数据库版本迁移 | 存储 | DatabaseMigration 已有 | 低 |
| ⭐15 | RTL 布局 | i18n | 无 | 中 |
| ⭐16 | 代理配置+轮换 | 网络 | 无 | 中 |
| ⭐17 | End-to-End EncryptedFileDataSource | 安全 | encrypted_file_storage 已有 | 高 |
| ⭐18 | SecretChatHelper 消息重排序 | 协议 | 无 | 高 |
| ⭐19 | ActionBar 自定义导航栏 | UI | AppBar | 中 |
| ⭐20 | FileLog + ANRDetector | 工具 | FileLog 已有 | 低 |

---

## 七、详细学习参考

### 主题系统

| Telegram | 我们 | 可学习点 |
|----------|------|---------|
| `Theme.java` 静态颜色数组，200+ 颜色键 | AppColors + ThemeProvider，颜色键有限 | 定义全面的颜色键系统 |
| `.attheme` 主题文件，ZIP 格式可导出分享 | 代码内硬编码主题 | 支持主题文件导入/导出 |
| `EmojiThemes.java` 每个聊天独立主题 | 全局统一主题 | 每个聊天可自定义主题 |
| 壁纸系统，支持自定义/模糊壁纸 | 无 | 增加聊天壁纸设置 |

### 网络层

| Telegram | 我们 | 可学习点 |
|----------|------|---------|
| ConnectionsManager 区分 Generic/Download/Upload/Push | 一个连接处理所有 | 按功能划分连接优先级 |
| 请求优先级 PRIORITY_HIGH(3) ~ PRIORITY_LOW(0) | 无优先级 | 消息发送 > 图片加载 > 预缓存 |
| 断点续传 FileLoadOperation | 普通 HTTP 下载 | 大文件断点续传 |
| 前缀预加载，预加载文件头部几 KB | 无 | 媒体文件秒开 |

### 存储/缓存

| Telegram | 我们 | 可学习点 |
|----------|------|---------|
| 三级图片缓存：内存 LruCache x4 + 磁盘 + HTTP | 无系统化缓存 | LruCache 多级缓存引擎 |
| DispatchQueue 每个模块专用队列 | 可能随机线程 | 专用线程队列避免互相阻塞 |
| CacheByChatsController 按聊天缓存策略 | 无 | 用户可控制每个聊天的缓存策略 |
| DownloadController 按关系配置自动下载 | 无自动下载策略 | 按关系/网络类型配置 |

### 动画/微交互

| Telegram | 我们 | 可学习点 |
|----------|------|---------|
| RLottieDrawable Lottie 动画引擎 | 可能用 Flutter Lottie | 高性能动画渲染 |
| BlobDrawable 流体/水波纹效果 | 无 | 聊天气泡流体动画 |
| AnimatedEmojiDrawable 动画 Emoji | 普通文本 | 动画 Emoji 渲染 |
| AudioVisualizerDrawable 音频可视化 | 无 | 语音消息波形动画 |
| 毛玻璃效果 LiquidGlassEffect | 无 | 毛玻璃/模糊背景 |

### 通知系统

| Telegram | 我们 | 可学习点 |
|----------|------|---------|
| 通知队列管理、延迟推送、智能分组 | 基础 Firebase 推送 | 通知队列管理 |
| RemoteInput 通知栏直接回复 | 无 | 下拉通知直接回复 |
| 按聊天分组通知 | 无 | 相同聊天通知合并 |
| 每个聊天单独设置通知音 | 无 | 自定义通知音 |

### 消息气泡

| Telegram | 我们 | 可学习点 |
|----------|------|---------|
| ChatMessageCell 5000+ 行自包含设计 | 多 Widget 组合 | 复杂 UI 组件自包含 |
| 气泡分组 pinnedBottom/pinnedTop | 每个消息独立 | 聊天气泡合并显示 |
| MessageBackgroundDrawable 自定义绘制 | Container + BoxDecoration | 统一气泡绘制器 |
| Reactions 系统 | 无 | Emoji 反应动画 |
| 侧滑菜单回复/转发 | 无 | 滑动快捷操作 |
