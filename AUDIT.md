# Omnivium 项目状态报告

> 最后更新：2026-05-25 | 版本：13.0 | 本文档是项目唯一进度追踪源
> 合并自：AUDIT.md v7 + PROJECT_INVENTORY.md + ROADMAP.md

---

## 一、项目现状概览

| 维度 | 数据 |
|------|------|
| 项目定位 | AI 驱动的超级生活平台（社交 + AI + 内容） |
| 技术栈 | Flutter 3.41+ / Dart ^3.11.5 |
| 目标平台 | Android + iOS + Web |
| 包名 | com.omnivium.mobile |
| 规划页面 | 40+ 页面 |
| 已实现页面 | 26 个视图 |
| 整体完成度 | ~82%（按上架标准） |
| flutter analyze | ✅ 0 Error |
| flutter test | ✅ 1339 通过 / 73 个测试文件 |
| 国际化 | ✅ ARB/l10n 官方方案，681 key，4 语言（中/英/日/韩） |
| 主题 | 深色/浅色/跟随系统 + 8 种强调色预设 |
| 总文件数 | 153+ |
| 总代码行数 | ~42,000+ |

### 已实现的核心能力

- AI 多模型对话（OpenAI / Claude / Gemini / Kimi / DeepSeek / 智谱 / MiniMax）
- Agent 调度引擎（意图分类 → 三通道处理 → 流式输出 → 权限确认）
- Agent 状态机（10 状态、11 条合法转换、3 次恢复上限）
- Matrix 协议通信（登录/注册/单聊/群聊/E2EE 加密/密钥验证）
- WebRTC 语音/视频通话（信令 + 媒体流 + 静音/扬声器切换）
- 记忆系统（三层架构 + 时间衰减 + 重要性排序 + 多语言正则提取）
- 上下文预算管理（128K Token 预算分配）
- 联网搜索（Serper.dev API）
- 内联卡片运行时（CardLifecycle 状态管理）
- 主题系统（深色/浅色/跟随系统 + 8 种强调色预设 + 动态色值方法）
- 国际化（Flutter 官方 gen_l10n，681 key，中/英/日/韩 4 语言）
- 流式输出控制器（广播 Stream + Buffer 管理）
- 安全存储（flutter_secure_storage，API Key / Token 加密存储）
- 运行时权限管理（permission_handler）
- 隐私同意流程（PrivacyConsentService + 版本化同意机制）
- 视频播放器（media_kit 集成，支持本地/网络视频）
- 快捷指令管理（自定义添加/编辑/删除/排序/分类，Hive 持久化）
- AI 生成工作台（8 种模板，流式生成，多模型切换）
- 深度链接（app_links，支持 omnivium:// 和 https://omnivium.app）
- 笔记/待办（note_service + productivity_view）
- Agent Replay（agent_replay_view）
- 错误上报（Sentry + AppLogger 结构化日志）
- 推送通知（Firebase FCM + 本地通知 + 推送载荷加密）
- Supabase 集成（Auth + 数据同步 + 云端合并）
- 应用层加密（AES-256-GCM 请求/响应加密）
- 两步验证（TOTP，Google Authenticator 兼容）
- SRP 安全远程密码协议（srp_service.dart）
- 应用锁（PIN 码 + 生物识别，app_lock_service.dart）
- 加密文件存储（AES-256，encrypted_file_storage.dart）
- 截屏/录屏保护框架（secure_flag_service.dart）
- 证书固定框架（NetworkSecurityService + 动态远程 pin）
- HMAC 请求签名 + 时间戳防重放
- 多端点故障转移（连续3次失败自动切换备用后端）
- 429 限流友好处理（RateLimitException + 用户提示）
- Firebase Analytics（analytics_service.dart 关键操作埋点）
- CI/CD（GitHub Actions：Lint → Test → Build Android/iOS + Dart 混淆）

---

## 二、已完成项

### 🔴 P0 — 上架必需（9/11 完成）

| # | 任务 | 状态 | 完成说明 |
|---|------|------|----------|
| 1 | Android 运行时权限声明 | ✅ 完成 | AndroidManifest.xml，已移除多余 WAKE_LOCK |
| 2 | iOS 隐私权限描述 | ✅ 完成 | Info.plist |
| 3 | Android Release 签名配置 | ✅ 完成 | build.gradle.kts + ProGuard + minify |
| 4 | API Key 安全存储 | ✅ 完成 | SecureStorageService |
| 5 | 启动页品牌化 | ✅ 完成 | Android 深色背景 + 居中图标 |
| 6 | 引导页 Onboarding | ✅ 完成 | 隐私同意流程 |
| 7 | 推送通知基础 | ✅ 完成 | Firebase FCM + 本地通知 + 推送加密 |
| 8 | 隐私合规 | ✅ 完成 | PrivacyConsentService + 版本化同意 |
| 9 | permission_handler | ✅ 完成 | PermissionService |
| 10 | 应用图标 (App Icon) | ⚠️ 默认 | 需品牌 Logo 设计后替换 |
| 11 | 开发者账号与发布配置 | ❌ 待办 | 需注册 |

### 🟠 P1 — 核心体验（7/10 完成）

| # | 任务 | 状态 | 说明 |
|---|------|------|------|
| 1 | 语音模式 STT+TTS UI 集成 | ⚠️ 服务层完成 | VoiceService 完整，VoiceView 需集成 |
| 2 | 发现页真实数据 | ❌ Mock | 依赖后端 API |
| 3 | 添加好友页 | ✅ 完成 | add_friend_view.dart |
| 4 | 联系人/好友列表页 | ✅ 完成 | contacts_view.dart |
| 5 | AI 搜索结果页 | ✅ 完成 | search_view.dart |
| 6 | 消息列表页 | ✅ 完成 | message_list_view.dart |
| 7 | 语音/视频通话 | ⚠️ 基础实现 | call_service.dart WebRTC 信令+媒体流完整，需端到端测试 |
| 8 | 图片/视频/文件发送 | ⚠️ 部分可用 | home_view 有内联实现 |
| 9 | 深度链接 | ✅ 完成 | deep_link_service.dart + app_links |
| 10 | 本地数据库迁移 | ⚠️ 部分完成 | Hive 已实现，核心逻辑未全部迁移 |

### 🟡 P2 — 重要功能（7/8 完成）

| # | 任务 | 状态 | 说明 |
|---|------|------|------|
| 1 | 链接预览 | ✅ 完成 | link_preview_service + link_preview_card |
| 2 | 视频播放器 | ✅ 完成 | media_kit |
| 3 | 快捷指令管理 | ✅ 完成 | quick_command_service + view |
| 4 | AI 生成工作台 | ✅ 完成 | ai_workbench_view（8 模板） |
| 5 | 笔记/待办/日程 | ✅ 完成 | note_service + productivity_view |
| 6 | Agent Replay | ✅ 完成 | agent_replay_view |
| 7 | 广场/内容模块 | ⏸️ 暂缓 | 依赖后端 API |
| 8 | 主动提醒系统 | ❌ 缺失 | Agent 主动推送 |

### 🔵 P3 — 工程质量（11/13 完成）

| # | 任务 | 状态 | 说明 |
|---|------|------|------|
| 1 | 测试体系 | ⚠️ 73 文件/1339 用例 | View 层已加强，集成测试框架已搭建 |
| 2 | HomeView 巨型文件 | ✅ 完成 | 从 904 降至 661，提取 3 个 mixin + UserAvatar |
| 3 | 统一 SessionManager | ✅ 完成 | SessionManager 已创建并接入 AppProvider |
| 4 | 路由系统 | ✅ 完成 | AppNavigator 统一导航 + 深链接 + 路由守卫 |
| 5 | 状态管理规范化 | ✅ 完成 | ThemeProvider/LocaleProvider 纳入 AppProvider，全局变量指向统一实例 |
| 6 | 国际化重构 | ✅ 完成 | 已迁移到 Flutter 官方 gen_l10n + ARB |
| 7 | 错误上报 | ✅ 完成 | Sentry + AppLogger |
| 8 | 可观测性 | ✅ 完成 | AppLogger 结构化日志 |
| 9 | CI/CD 流水线 | ✅ 完成 | GitHub Actions（Lint→Test→Build+混淆） |
| 10 | 模块权限系统 | ⏸ 暂缓 | 当前全开放，后续按需添加 |
| 11 | 代码生成工具链 | ⏸ 暂缓 | dart_style 与 Dart 3.11 不兼容，等升级后使用 |
| 12 | 环境/Flavor 配置 | ⏸ 暂缓 | 开发阶段暂不需要 |
| 13 | 分析集成 | ✅ 完成 | Firebase Analytics（analytics_service.dart） |

### 🟣 P4 — 体验优化与代码质量（8/11 完成）

| # | 任务 | 状态 | 说明 |
|---|------|------|------|
| 1 | 强调色自定义 | ✅ 完成 | 8 种预设色，设置页可切换，全局动态生效 |
| 2 | 亮色模式颜色修复 | ✅ 完成 | 208 处 AppColors.accent 硬编码替换为 acc(context)，9 处 background 替换为 bg(context) |
| 3 | call_screen 国际化 | ✅ 完成 | 14 处中文硬编码改为 t() |
| 4 | TextEditingController 内存泄漏 | ✅ 完成 | 9 处 Dialog 使用 try/finally 确保 dispose |
| 5 | StreamSubscription + setState 修复 | ✅ 完成 | call_screen subscription 保存取消；home_view/friend_chat_panel setState mounted 检查 |
| 6 | 4 区域独立强调色 | ❌ 取消 | 当前8种强调色已够用，不需要各区域不同色 |
| 7 | 内置多套主题 | ❌ 取消 | 深色/浅色+8种强调色已够用，后续按需添加 |
| 8 | 主题文件导入/导出 | ❌ 待做 | JSON 格式主题文件，可分享 |
| 9 | 聊天壁纸系统 | ❌ 待做 | 预设壁纸 + 自定义图片 + 半透明覆盖层 |
| 10 | 应用图标更换 | ❌ 待做 | 像 Telegram 可在设置中更换桌面图标 |
| 11 | async gap 后 ! 操作符 | ✅ 完成 | 6 个文件 8 处添加 mounted 检查，防止 dispose 后 setState 崩溃 |
| 12 | 安全区颜色闪烁 | ✅ 完成 | 原生Android深浅主题颜色对齐 + 加载画面AnnotatedRegion |
| 13 | 全项目国际化补全 | ✅ 完成 | 21处硬编码文本修复，4语言ARB新增14个翻译键 |

### 🔧 P5 — 安全与构建（4/7 完成）

| # | 任务 | 状态 | 说明 |
|---|------|------|------|
| 1 | CI 构建 Dart 混淆 | ✅ 完成 | flutter-ci.yml 已有 --obfuscate --split-debug-info |
| 2 | SSL Pinning 预置哈希 | ❌ 待做 | _productionPins 为空，需部署后配置真实 hash |
| 3 | ProGuard 规则优化 | ✅ 完成 | 移除过度 keep 规则，仅保留必要类 |
| 4 | Cloudflare 账户 ID 暴露 | ❌ 待做 | 子域名暴露账户 ID，需自定义域名 |
| 5 | NDK ABI 过滤器 | ✅ 完成 | 仅打包 arm64-v8a + armeabi-v7a，减小 APK 体积 |

### 🚀 P6 — 自动化部署（0/2 完成）

| # | 任务 | 状态 | 说明 |
|---|------|------|------|
| 1 | Fastlane 配置 | ❌ 待做 | 自动部署到 Google Play / App Store |
| 2 | iOS 签名自动化 | ❌ 待做 | CI 使用 --no-codesign，需配置自动签名 |

### 🧪 P7 — 自动化测试（1/2 完成）

| # | 任务 | 状态 | 说明 |
|---|------|------|------|
| 1 | 集成测试框架 | ✅ 完成 | integration_test 已搭建，App 启动+导航测试 |
| 2 | Firebase Test Lab | ❌ 待做 | 多设备自动运行测试 |

---

## 三、安全风险

| # | 风险 | 严重度 | 状态 | 说明 |
|---|------|--------|------|------|
| S1 | API Key 明文存储 | 🔴 高 | ✅ 已修复 | SecureStorage |
| S2 | Matrix Token 明文存储 | 🔴 高 | ✅ 已修复 | SecureStorage |
| S3 | Synapse 注册共享密钥硬编码 | 🔴 高 | ❌ 待修 | homeserver.yaml |
| S4 | 开放无验证注册 | 🟠 中 | ❌ 待修 | 无 CAPTCHA |
| S5 | HTTP 通信 | 🟠 中 | ✅ 已修复 | AndroidManifest 禁止明文 + 应用层 AES-256-GCM 加密 |
| S6 | 无证书锁定 | 🟡 低 | ⚠️ 框架就绪 | 假hash已清除，待部署后配置真实hash，后端已有 /config/ssl-pins 端点 |
| S7 | 无输入验证 | 🟠 中 | ❌ 待修 | XSS / 注入过滤 |
| S8 | Sentry DSN 硬编码 | 🟡 低 | ⚠️ 可接受 | DSN 是公开的，但可能被滥用 |
| S9 | workers.dev 开发域名 | 🟠 中 | ❌ 待修 | 需换为 api.omnivium.app |

### 已完成安全加固

| 修复 | 说明 |
|------|------|
| 加密密钥同步到服务器 | ✅ 已删除 `_syncKeyToServer()`，密钥只存本地 |
| Matrix Token 验证 | worker.js 新增 verifyMatrixToken()，向 Matrix 服务器验证 token 有效性，缓存5分钟 |
| JWT 降级漏洞 | 无公钥时直接拒绝，不再跳过签名验证 |
| HMAC 请求签名 | 客户端每个请求带 X-Timestamp + X-Request-Signature，服务端验证时间戳±5分钟 |
| SSL Pinning 假hash | 清除伪造的证书指纹，无有效pin时不启用pinning，后端新增 /config/ssl-pins 端点 |
| 429 限流处理 | 新增 RateLimitException，读取 Retry-After 头，聊天气泡显示友好等待时间 |
| 应用层加密 | AES-256-GCM 加密请求/响应体，密钥存 SecureStorage |
| 两步验证 | TOTP（Google Authenticator 兼容），登录后验证码输入 |
| 应用锁 | PIN 码 + 生物识别，app_lock_service.dart |
| 加密文件存储 | AES-256 加密，encrypted_file_storage.dart |
| 截屏/录屏保护框架 | secure_flag_service.dart |
| SRP 安全远程密码 | srp_service.dart |
| 数据云端同步 | SupabaseSyncService 接入 SessionProvider/NoteService，Matrix userId 关联，增量合并 |
| 多端点故障转移 | 连续3次失败自动切换备用后端，成功时重置计数 |
| 推送加密 | FCM 推送载荷加密，客户端收到后解密再显示 |

---

## 四、已接入依赖

| 依赖 | 版本 | 用途 |
|------|------|------|
| cupertino_icons | ^1.0.8 | iOS 风格图标 |
| lucide_icons | ^0.257.0 | Lucide 图标库 |
| go_router | ^14.8.1 | 路由导航 |
| http | ^1.2.1 | HTTP 请求 |
| shared_preferences | ^2.3.3 | 本地键值存储 |
| flutter_secure_storage | ^9.2.4 | 加密存储 |
| share_plus | ^12.0.2 | 系统分享 |
| image_picker | ^1.1.2 | 图片选择 |
| file_picker | ^9.2.1 | 文件选择 |
| matrix | ^7.0.0 | Matrix 协议 SDK |
| flutter_vodozemac | ^0.5.0 | Matrix E2EE 加密 |
| record | ^6.2.0 | 语音录制 |
| audioplayers | ^6.6.0 | 音频播放 |
| path_provider | ^2.1.5 | 文件路径 |
| permission_handler | ^11.3.1 | 运行时权限 |
| cached_network_image | ^3.4.1 | 网络图片缓存 |
| connectivity_plus | ^6.1.4 | 网络状态检测 |
| url_launcher | ^6.3.1 | 打开外部链接 |
| package_info_plus | ^8.3.0 | 应用版本信息 |
| hive_flutter | ^1.1.0 | 本地数据库 |
| sqflite | ^2.4.1 | SQLite 数据库 |
| speech_to_text | ^7.0.0 | 语音识别 |
| flutter_tts | ^4.2.2 | 语音合成 |
| html | ^0.15.5 | HTML 解析 |
| media_kit | ^1.1.11 | 视频播放引擎 |
| media_kit_video | ^1.2.5 | 视频播放 UI |
| media_kit_libs_video | ^1.0.5 | 视频播放原生库 |
| firebase_core | ^3.12.1 | Firebase 核心 |
| firebase_messaging | ^15.2.4 | 推送通知 |
| firebase_analytics | ^11.6.2 | 使用分析 |
| flutter_local_notifications | ^18.0.1 | 本地通知 |
| supabase_flutter | ^2.8.4 | Supabase 认证+数据 |
| sentry_flutter | ^8.13.0 | 错误上报 |
| app_links | ^6.3.3 | 深度链接 |
| crypto | ^3.0.5 | HMAC/SHA 加密工具 |
| encrypt | ^5.0.3 | AES-256-GCM 加密 |
| local_auth | ^2.3.0 | 生物识别 |
| get_it | ^8.0.3 | 依赖注入 |
| qr_flutter | ^4.1.0 | 二维码生成 |
| flutter_webrtc | ^0.12.6 | WebRTC 通话 |

---

## 五、架构问题

### 5.1 HomeView 巨型文件
home_view.dart 当前 661 行（从 3200+ → 904 → 661），已提取 3 个 mixin（ScrollMixin、MessageActionsMixin、ConversationMenuMixin）+ UserAvatar 组件。

### 5.2 状态管理碎片化
已规范化：ThemeProvider 和 LocaleProvider 纳入 AppProvider，全局变量 `themeProvider`/`localeProvider` 指向 AppProvider 的统一实例。

### 5.3 SessionManager 已接入
SessionManager 已创建并接入 AppProvider，作为 SessionProvider 的统一管理层，代理所有方法并添加会话生命周期事件通知。

### 5.4 测试覆盖不均
73 个测试文件 / 1339 用例，View 层已加强（21 个视图测试文件，从 16 个仅 1 用例提升到平均 4-8 用例），集成测试框架已搭建。

### 5.5 死代码（已清理）
- ~~`local_memory_manager.dart` / `memory_manager.dart`~~ — 已删除
- ~~`ab_test_service.dart`~~ — 已删除
- ~~`offline_service.dart`~~ — 已删除
- ~~`performance_monitor_service.dart`~~ — 已删除
- ~~`crash_recovery_service.dart`~~ — 已删除
- ~~`speech_service.dart`~~ — 已删除（合并到 VoiceService）

---

## 六、文件清单概要

### 核心层（core/）— ~60+ 服务文件

| 子模块 | 文件数 | 关键文件 |
|--------|--------|---------|
| 应用核心服务 | ~40 | auth_service, api_proxy_service, app_provider, session_provider, model_provider |
| Agent 系统 | 8 | agent_orchestrator, agent_state_machine, agent_memory_service, embedding_service |
| Matrix 通信 | 2 | matrix_service, matrix_provider |
| AI 提供商 | 1 | ai_provider |
| 记忆系统 | 1 | context_budget |
| 通知 | 2 | app_notification, notification_provider |
| Runtime 引擎 | ~50+ | 含 10 个子模块（kernel/plugin/governance/sandbox/distributed/observability/stability/vocabulary/sdk/benchmark） |

### 展示层（presentation/）

| 子模块 | 文件数 | 关键文件 |
|--------|--------|---------|
| 视图 | 26 | home_view, message_list_view, settings_view, call_screen, voice_view 等 |
| 组件 | 22 | friend_chat_panel, chat_input_area, ai_bubbles, app_drawer 等 |
| 主题 | 4 | app_colors, theme_provider, locale_provider, app_semantics |
| 工具 | 3 | format_utils, format_time, responsive |

### 国际化（l10n/）— 681 key / 4 语言

| 文件 | 说明 |
|------|------|
| app_en.arb / app_zh.arb / app_ja.arb / app_ko.arb | 4 语言 ARB 源文件 |
| app_localizations*.dart | 生成的本地化代码 |

### 连接拓扑

```
App Layer                    Runtime Layer                    Sandbox Layer
─────────                    ────────────                    ─────────────
AppProvider ──────────────→ OmniviumSDK ──────────────────→ ConstitutionalGuard
    │                          │                                  │
    ├→ AgentOrchestrator ──→ CapabilityRouter ──→ PluginHandler   ├→ RuntimeLaw (10条)
    │     │                    │                                  ├→ SovereignIdentity
    │     ├→ AppCapabilityService (agent.chat)                    ├→ ConstitutionalTrace
    │     └→ ChatService (fallback)                               ├→ AutonomousLegislature
    │                          │                                  ├→ RuntimeJudiciary
    ├→ MatrixProvider ──→ MatrixService                          ├→ ReputationEconomy
    ├→ AIProvider ──→ ApiProxyService                             └→ CivilizationNetwork
    ├→ SessionProvider ──→ AuthService
    ├→ NoteProvider ──→ NoteService          EventBus (10s timeout)
    └→ ThemeProvider ──→ AppColors               │
                                                ├→ Plugin Events
                                                ├→ Sandbox Events
                                                └→ Capability Events
```

---

## 七、测试体系与规划

### 当前状态

| 指标 | 值 |
|------|-----|
| 测试文件 | 73 个 |
| 测试用例 | 1337 个 |
| 测试框架 | flutter_test（仅此一个） |
| Mock 框架 | ❌ 无（mockito/mocktail 均未引入） |
| 集成测试 | ❌ 无（integration_test/ 不存在） |
| Golden Test | ❌ 无 |
| Firebase Test Lab | ❌ 未接入 |

### 测试分布问题

| 类别 | 文件数 | 用例数 | 问题 |
|------|--------|--------|------|
| Runtime 核心 | ~30 | ~700 | 覆盖密集 |
| 服务层 | ~15 | ~200 | 中等覆盖 |
| View 层 | ~21 | ~80 | 已加强，平均 4-8 用例/视图 |
| Widget 层 | ~7 | ~50 | 基础覆盖 |

### 测试规划

#### 第一阶段：基础设施（P7-1）

1. **引入 Mock 框架** — 添加 `mocktail` 到 dev_dependencies
2. **创建 integration_test/ 目录** — 添加 `integration_test` SDK 依赖
3. **创建测试工具类** — `test/helpers/` 下统一 Mock、测试包装器

#### 第二阶段：核心流程集成测试

| 测试场景 | 优先级 | 说明 |
|----------|--------|------|
| 登录/注册流程 | P0 | Matrix 登录、Supabase 认证、会话恢复 |
| 发送/接收消息 | P0 | 文本消息、加密消息、流式 AI 响应 |
| 添加好友 | P0 | 搜索用户、创建私聊房间 |
| 主题切换 | P1 | 深色/浅色/强调色切换持久化 |
| 通话流程 | P1 | 发起/接听/挂断/静音/扬声器 |
| 设置持久化 | P1 | 主题/语言/强调色/应用锁 |
| 推送通知 | P2 | 前台/后台通知接收 |
| 深度链接 | P2 | omnivium:// 和 https:// 跳转 |

#### 第三阶段：View 层单元测试加强

| 视图 | 当前用例 | 目标用例 | 重点测试 |
|------|---------|---------|---------|
| home_view | 1 | 10+ | Tab 切换、聊天列表加载、搜索 |
| message_list_view | 1 | 10+ | 消息渲染、滚动加载、加密状态 |
| settings_view | 0 | 8+ | 主题切换、强调色、语言切换 |
| call_screen | 0 | 8+ | 通话状态、静音/扬声器、挂断 |
| contacts_view | 1 | 6+ | 联系人列表、搜索、排序 |
| add_friend_view | 1 | 5+ | 搜索用户、发送邀请 |
| search_view | 1 | 6+ | AI 搜索、本地搜索、结果展示 |
| voice_view | 0 | 5+ | 语音识别、TTS、权限 |
| friend_chat_panel | 0 | 8+ | 消息发送、AI 模式、工具栏 |
| discover_view | 0 | 4+ | 内容加载、分类、刷新 |

#### 第四阶段：Firebase Test Lab（P7-2）

1. 配置 Firebase Test Lab 项目
2. 编写 `integration_test/` 测试用例
3. CI 中添加 Test Lab 步骤
4. 多设备矩阵测试（Pixel/Samsung/Android 12-15）

---

## 八、统计

| 优先级 | 总数 | 已完成 | 待完成 |
|--------|------|--------|--------|
| 🔴 P0 上架必需 | 11 | 9 | 2 |
| 🟠 P1 核心体验 | 10 | 7 | 3 |
| 🟡 P2 重要功能 | 8 | 7 | 1 |
| 🔵 P3 工程质量 | 13 | 11 | 2 |
| 🟣 P4 体验优化 | 13 | 8 | 5 |
| 🔧 P5 安全与构建 | 5 | 4 | 1 |
| 🚀 P6 自动化部署 | 2 | 0 | 2 |
| 🧪 P7 自动化测试 | 2 | 1 | 1 |
| **总计** | **64** | **49** | **15** |

| 安全风险 | 总数 | 已修复 | 待修复 |
|----------|------|--------|--------|
| 🔴 高 | 3 | 2 | 1 |
| 🟠 中 | 4 | 1 | 3 |
| 🟡 低 | 2 | 0 | 2 |

---

## 九、变更记录

### 2026-05-25

- 修复 CI 失败：skip: !storageReady Bug（37 个测试被永久跳过→全部通过）、MissingPluginException 未捕获、AppProvider 构造函数参数错误、未使用变量 warning
- P3 测试体系加强：1027→1339 用例，66→73 文件，新增 5 个视图测试文件，增强 4 个已有测试
- P3 HomeView 拆分：904→661 行，提取 HomeScrollMixin、HomeMessageActionsMixin、HomeConversationMenuMixin + UserAvatar 组件
- P3 SessionManager：创建统一会话管理层，接入 AppProvider 替代直接使用 SessionProvider
- P3 状态管理规范化：ThemeProvider/LocaleProvider 纳入 AppProvider，全局变量指向统一实例
- P3 代码生成工具链：dart_style 与 Dart 3.11 不兼容，暂缓
- P4 async gap null 安全：6 个文件 8 处添加 mounted 检查（call_screen、ai_permission_view、voice_view、voice_message、message_list_view）
- P5 ProGuard 规则优化：移除过度 keep 规则，仅保留 Matrix SDK/Sentry/Firebase/SQLCipher 等必要类
- P5 NDK ABI 过滤器：仅打包 arm64-v8a + armeabi-v7a，减小 APK 体积
- P7 集成测试框架：搭建 integration_test，添加 App 启动+导航测试
- P4 安全区颜色闪烁修复：原生Android深浅主题颜色对齐 + 加载画面AnnotatedRegion
- P4 全项目国际化补全：21处硬编码文本修复，4语言ARB新增14个翻译键
- P4 AI输入区重构：合并STT/发送/停止为单一accent圆形按钮，移除AI语音页入口，优化监听动画
- P4 好友页面重构：Telegram模式-历史聊天=联系人列表，移除ContactsView/AddFriendView（-1434行），左上角创建群聊，右上角统一搜索
- SecureFlagService 添加 MissingPluginException 捕获 + 测试 MethodChannel mock

### 2026-05-24

- 合并 PROJECT_INVENTORY.md 和 ROADMAP.md 到本文档
- 修正测试数据：1027 用例 / 66 文件（原误报 1031 / 10 文件）
- 修正国际化数据：681 key（原误报 420+）
- 修正 home_view 行数：904 行（原误报 588）
- 修正 matrix 依赖版本：^7.0.0（PROJECT_INVENTORY 误报 ^0.35.0）
- 标记已完成项：Firebase Analytics、CI/CD、CI 混淆、call_screen 国际化、内存泄漏修复、setState mounted 检查
- 新增已完成项：强调色自定义（8 种预设色）、亮色模式颜色修复（208+9 处）
- 标记安全修复：_syncKeyToServer 已删除、应用锁已实现、加密文件存储已实现、SRP 已实现、截屏保护框架已实现
- 新增测试规划章节

### 2026-05-21

- 修复 6 个严重 Bug（SovereignIdentity 签名验证等）
- 修复 4 条铁律违规
- 清理 7 个死代码文件（~1429 行）
- 统一 3 个冗余系统（语音/签名/记忆）
