# Omnivium 项目进度与审查报告

> 最后更新：2026-05-16 | 版本：4.0 | 本文档是项目唯一进度追踪源

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
| 整体完成度 | ~65%（按上架标准） |
| flutter analyze | ✅ 0 Error |
| 国际化 | ✅ ARB/l10n 官方方案，417 key，4 语言 |

### 已实现的核心能力

- AI 多模型对话（OpenAI / Claude / Gemini / Kimi / DeepSeek / 智谱 / MiniMax）
- Agent 调度引擎（意图分类 → 三通道处理 → 流式输出 → 权限确认）
- Agent 状态机（10 状态、11 条合法转换、3 次恢复上限）
- Matrix 协议通信（登录/注册/单聊/群聊/E2EE 加密/密钥验证）
- 记忆系统（三层架构 + 时间衰减 + 重要性排序 + 多语言正则提取）
- 上下文预算管理（128K Token 预算分配）
- 联网搜索（Serper.dev API）
- 内联卡片运行时（CardLifecycle 状态管理）
- 主题系统（深色/浅色/跟随系统 + 30+ 颜色 Token）
- 国际化（Flutter 官方 gen_l10n，417 key，中/英/日/韩 4 语言）
- 流式输出控制器（广播 Stream + Buffer 管理）
- 安全存储（flutter_secure_storage，API Key / Token 加密存储）
- 运行时权限管理（permission_handler）
- 隐私同意流程（PrivacyConsentService + 版本化同意机制）
- 链接预览（OG 标签抓取 + 缓存 + 预览卡片）
- 视频播放器（media_kit 集成，支持本地/网络视频）
- 快捷指令管理（自定义添加/编辑/删除/排序/分类，Hive 持久化）
- AI 生成工作台（8 种模板，流式生成，多模型切换）
- 深度链接（app_links，支持 omnivium:// 和 https://omnivium.app）
- 笔记/待办（note_service + productivity_view）
- Agent Replay（agent_replay_view）
- 错误上报（Sentry + AppLogger 结构化日志）
- 推送通知（Firebase FCM + 本地通知）
- Supabase 集成（Auth + 数据同步）
- 证书固定框架（NetworkSecurityService + Trust-on-first-use）
- 魔法数字可配置（RemoteConfigService）

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
| 7 | 推送通知基础 | ✅ 完成 | Firebase FCM + 本地通知 |
| 8 | 隐私合规 | ✅ 完成 | PrivacyConsentService + 版本化同意 |
| 9 | permission_handler | ✅ 完成 | PermissionService |
| 10 | 应用图标 (App Icon) | ⚠️ 默认 | 需品牌 Logo 设计后替换（见 MANUAL_SETUP.md） |
| 11 | 开发者账号与发布配置 | ❌ 待办 | 需注册（见 MANUAL_SETUP.md） |

### 🟠 P1 — 核心体验（7/10 完成）

| # | 任务 | 状态 | 说明 |
|---|------|------|------|
| 1 | 语音模式 STT+TTS UI 集成 | ⚠️ 服务层完成 | VoiceService 完整，VoiceView 需集成 |
| 2 | 发现页真实数据 | ❌ Mock | 依赖后端 API |
| 3 | 添加好友页 | ✅ 完成 | add_friend_view.dart |
| 4 | 联系人/好友列表页 | ✅ 完成 | contacts_view.dart |
| 5 | AI 搜索结果页 | ✅ 完成 | search_view.dart |
| 6 | 消息列表页 | ✅ 完成 | message_list_view.dart |
| 7 | 语音/视频通话 | ❌ 空回调 | 需 WebRTC |
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

### 🔵 P3 — 工程质量（5/13 完成）

| # | 任务 | 状态 | 说明 |
|---|------|------|------|
| 1 | 测试体系 | ⚠️ 10 个测试文件 | 需要全覆盖 |
| 2 | HomeView 巨型文件 | ⚠️ 输入区已拆出 | 仍需继续拆分 |
| 3 | 统一 SessionManager | ⚠️ 已实现未接入 | |
| 4 | 路由系统 | ❌ 缺失 | 无命名路由/路由守卫 |
| 5 | 状态管理规范化 | ⚠️ 混用 | 全局变量 + ChangeNotifier |
| 6 | 国际化重构 | ✅ 完成 | 已迁移到 Flutter 官方 gen_l10n + ARB |
| 7 | 错误上报 | ✅ 完成 | Sentry + AppLogger |
| 8 | 可观测性 | ✅ 完成 | AppLogger 结构化日志 |
| 9 | CI/CD 流水线 | ❌ 缺失 | |
| 10 | 模块权限系统 | ❌ 缺失 | ModulePermissions 未实现 |
| 11 | 代码生成工具链 | ❌ 缺失 | 无 freezed / json_serializable |
| 12 | 环境/Flavor 配置 | ❌ 缺失 | 无 dev/staging/prod |
| 13 | 分析集成 | ❌ 缺失 | 无 Firebase Analytics |

---

## 三、安全风险

| # | 风险 | 严重度 | 状态 | 说明 |
|---|------|--------|------|------|
| S1 | API Key 明文存储 | 🔴 高 | ✅ 已修复 | SecureStorage |
| S2 | Matrix Token 明文存储 | 🔴 高 | ✅ 已修复 | SecureStorage |
| S3 | Synapse 注册共享密钥硬编码 | 🔴 高 | ❌ 待修 | homeserver.yaml |
| S4 | 开放无验证注册 | 🟠 中 | ❌ 待修 | 无 CAPTCHA |
| S5 | HTTP 通信 | 🟠 中 | ✅ 已修复 | AndroidManifest 禁止明文 |
| S6 | 无证书锁定 | 🟡 低 | ⚠️ 框架就绪 | NetworkSecurityService 已实现，需预置哈希 |
| S7 | 无输入验证 | 🟠 中 | ❌ 待修 | XSS / 注入过滤 |
| S8 | Sentry DSN 硬编码 | 🟡 低 | ⚠️ 可接受 | DSN 是公开的，但可能被滥用 |
| S9 | workers.dev 开发域名 | 🟠 中 | ❌ 待修 | 需换为 api.omnivium.app |

---

## 四、已接入依赖

| 依赖 | 版本 | 用途 |
|------|------|------|
| cupertino_icons | ^1.0.8 | iOS 风格图标 |
| lucide_icons | ^0.257.0 | Lucide 图标库 |
| http | ^1.2.1 | HTTP 请求 |
| shared_preferences | ^2.3.3 | 本地键值存储 |
| flutter_secure_storage | ^9.2.4 | 加密存储 |
| share_plus | ^12.0.2 | 系统分享 |
| image_picker | ^1.1.2 | 图片选择 |
| file_picker | ^9.2.1 | 文件选择 |
| matrix | ^7.0.0 | Matrix 协议 SDK |
| record | ^6.2.0 | 语音录制 |
| audioplayers | ^6.6.0 | 音频播放 |
| path_provider | ^2.1.5 | 文件路径 |
| permission_handler | ^11.3.1 | 运行时权限 |
| cached_network_image | ^3.4.1 | 网络图片缓存 |
| connectivity_plus | ^6.1.4 | 网络状态检测 |
| url_launcher | ^6.3.1 | 打开外部链接 |
| package_info_plus | ^8.3.0 | 应用版本信息 |
| hive_flutter | ^1.1.0 | 本地数据库 |
| speech_to_text | ^7.0.0 | 语音识别 |
| flutter_tts | ^4.2.2 | 语音合成 |
| html | ^0.15.5 | HTML 解析 |
| media_kit | ^1.1.11 | 视频播放引擎 |
| media_kit_video | ^1.2.5 | 视频播放 UI |
| media_kit_libs_video | ^1.0.5 | 视频播放原生库 |
| firebase_core | ^3.12.1 | Firebase 核心 |
| firebase_messaging | ^15.2.4 | 推送通知 |
| flutter_local_notifications | ^18.0.1 | 本地通知 |
| supabase_flutter | ^2.8.4 | Supabase 认证+数据 |
| sentry_flutter | ^8.13.0 | 错误上报 |
| app_links | ^6.3.3 | 深度链接 |
| crypto | ^3.0.5 | 加密工具 |
| sqflite | ^2.4.1 | SQLite 数据库 |
| flutter_vodozemac | ^0.5.0 | Matrix E2EE 加密 |

---

## 五、架构问题

### 5.1 HomeView 巨型文件
home_view.dart 仍有 3200+ 行，需继续拆分。

### 5.2 状态管理碎片化
三种状态传递方式并存：AppProvider 构造函数传递、themeProvider/localeProvider 全局变量、MatrixProvider 在 HomeView 中创建。

### 5.3 SessionManager 未接入
session_manager.dart 已实现但未在主流程中使用。

### 5.4 测试覆盖不足
10 个测试文件存在，但核心逻辑（Agent、AI Provider、Matrix）缺少测试。

---

## 六、统计

| 优先级 | 总数 | 已完成 | 待完成 |
|--------|------|--------|--------|
| 🔴 P0 上架必需 | 11 | 9 | 2 |
| 🟠 P1 核心体验 | 10 | 7 | 3 |
| 🟡 P2 重要功能 | 8 | 7 | 1 |
| 🔵 P3 工程质量 | 13 | 5 | 8 |
| 🟣 P4 体验优化 | 11 | 0 | 11 |
| **总计** | **53** | **28** | **25** |

| 安全风险 | 总数 | 已修复 | 待修复 |
|----------|------|--------|--------|
| 🔴 高 | 3 | 2 | 1 |
| 🟠 中 | 4 | 1 | 3 |
| 🟡 低 | 2 | 0 | 2 |
