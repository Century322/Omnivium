# Omnivium 项目完整清单

> 生成时间：2026-05-21 | 测试状态：1027 全部通过 | 总文件数：153 | 总代码行数：~42,394

---

## 一、项目概览

| 指标 | 值 |
|------|-----|
| 项目名称 | Omnivium — AI 驱动超级生活平台 |
| 技术栈 | Flutter 3.41+ / Dart ^3.11.5 |
| 目标平台 | Android + iOS + Web |
| 测试 | 1027 通过 / 0 失败 |
| 国际化 | 420+ key / 4 语言（中/英/日/韩） |
| 主题 | 深色/浅色/跟随系统 |
| 整体完成度 | ~80% |

---

## 二、铁律合规性（RUNTIME_ARCHITECTURE.md FROZEN）

| 铁律 | 状态 | 说明 |
|------|------|------|
| 1. Core Never Knows Implementation | ✅ 合规 | 核心层无具体实现导入 |
| 2. Everything Is Message | ✅ 已修复 | sendMessage 统一入口 + EventBus 超时保护 |
| 3. Capability Over Plugin | ✅ 合规 | 所有调用走 CapabilityRouter |
| 4. Failure Is Normal | ✅ 已修复 | CapabilityRouter 强制超时 + EventBus handler 超时 |
| 5. Distributed First | ✅ 已修复 | RuntimeMessage/Stream/Task 均已加 scope + version + source |
| 6. Runtime Owns Time | ✅ 已修复 | CapabilityRouter.invoke 强制 timeout + Scheduler 超时 |

---

## 三、核心层文件清单（core/）

### 3.1 应用核心服务（core/）

| 文件 | 行数 | 功能 | 连接状态 | 状态 |
|------|------|------|----------|------|
| main.dart | 597 | 应用入口，初始化所有服务 | → 所有核心服务 | ✅ |
| app_provider.dart | 133 | 全局状态管理，桥接 Runtime | → OmniviumSDK, AgentOrchestrator | ✅ |
| app_navigator.dart | 125 | 统一导航 + 深链接 + 路由守卫 | → 所有视图 | ✅ |
| app_capability_service.dart | 60 | App 层通过 CapabilityRouter 调用能力 | → OmniviumSDK.container.capabilityRouter | ✅ |
| app_data_gateway.dart | 79 | 数据网关，统一数据访问 | → ApiProxyService | ✅ |
| app_logger.dart | 54 | 日志服务 | → Sentry | ✅ |
| app_lock_service.dart | 175 | 应用锁（生物识别/PIN） | → BiometricService | ✅ |
| audit_log_service.dart | 105 | 审计日志 | → DatabaseService | ✅ |
| auth_service.dart | 239 | 认证服务（Supabase） | → Supabase, MatrixService | ✅ |
| biometric_service.dart | 58 | 生物识别 | → flutter_secure_storage | ✅ |
| connectivity_service.dart | 127 | 网络连接状态 | → AppProvider | ✅ |
| database_service.dart | 260 | Hive 数据库 | → 所有需要持久化的服务 | ✅ |
| database_persistence_backend.dart | 64 | Runtime 持久化后端（Hive） | → Runtime MemoryPlugin | ✅ |
| deep_link_service.dart | 73 | 深度链接处理 | → AppNavigator | ✅ |
| encryption_service.dart | 56 | AES-256-GCM 加密 | → SecureStorageService | ✅ |
| encrypted_file_storage.dart | 146 | 加密文件存储 | → SecureStorageService | ✅ |
| file_download_service.dart | 134 | 文件下载 | → ApiProxyService | ✅ |
| file_log.dart | 125 | 文件日志 | → AppLogger | ✅ |
| haptic_service.dart | 52 | 触觉反馈 | → UI 层 | ✅ |
| identity_bridge.dart | 151 | Runtime 身份 ↔ App 身份桥接 | → AppProvider, OmniviumSDK | ✅ |
| lite_mode.dart | 88 | 低端设备降级模式 | → AppProvider | ✅ |
| lru_cache.dart | 95 | LRU 缓存 | → 图片缓存 | ✅ |
| model_provider.dart | 159 | AI 模型切换 | → ApiProxyService | ✅ |
| navigation_provider.dart | 65 | 导航状态 | → AppProvider | ✅ |
| network_security_service.dart | 187 | SSL Pinning + 证书固定 | → ApiProxyService | ✅ |
| network_security_io.dart | 25 | 网络安全 IO 实现 | → network_security_service | ✅ |
| network_security_stub.dart | 5 | 网络安全 Web stub | → network_security_service | ✅ |
| note_provider.dart | 59 | 笔记状态 | → NoteService | ✅ |
| note_service.dart | 205 | 笔记 CRUD | → DatabaseService | ✅ |
| notification_center.dart | 140 | 通知中心 | → PushNotificationService | ✅ |
| notification_queue.dart | 130 | 通知队列 | → NotificationCenter | ✅ |
| permission_service.dart | 99 | 权限管理 | → permission_handler | ✅ |
| privacy_consent_service.dart | 108 | 隐私同意管理 | → SecureStorageService | ✅ |
| quick_command_provider.dart | 68 | 快捷命令状态 | → QuickCommandService | ✅ |
| quick_command_service.dart | 169 | 快捷命令服务 | → DatabaseService | ✅ |
| remote_config_service.dart | 138 | 远程配置（Supabase） | → Supabase | ✅ |
| remote_ui_engine.dart | 421 | 远程 UI 引擎（服务端驱动 UI） | → ApiProxyService | ✅ |
| secure_storage_service.dart | 31 | 安全存储 | → flutter_secure_storage | ✅ |
| secure_flag_service.dart | 39 | 安全标志（截屏保护等） | → AppLockService | ✅ |
| security_check_service.dart | 26 | 安全检查 | → SecureFlagService | ✅ |
| security_check_service_io.dart | 127 | 安全检查 IO 实现 | → security_check_service | ✅ |
| security_check_service_stub.dart | 3 | 安全检查 Web stub | → security_check_service | ✅ |
| service_locator.dart | 38 | GetIt 依赖注入 | → 所有核心服务 | ✅ |
| session_provider.dart | 386 | 会话状态管理 | → AuthService, MatrixProvider | ✅ |
| srp_service.dart | 161 | SRP 安全远程密码协议 | → AuthService | ✅ |
| supabase_sync_service.dart | 208 | Supabase 数据同步 | → Supabase | ✅ |
| totp_service.dart | 79 | TOTP 两步验证 | → EncryptionService | ✅ |
| voice_service.dart | 205 | 语音服务（STT/TTS） | → speech_to_text, flutter_tts | ✅ |
| push_notification_service.dart | 201 | 推送通知 | → Firebase Messaging | ✅ |
| push_notification_service_io.dart | 68 | 推送 IO 实现 | → push_notification_service | ✅ |
| push_notification_service_stub.dart | 3 | 推送 Web stub | → push_notification_service | ✅ |
| vodozemac_init.dart | 1 | Vodozemac 初始化（Matrix E2EE） | → matrix | ✅ |
| vodozemac_init_io.dart | 5 | Vodozemac IO 实现 | → vodozemac_init | ✅ |
| vodozemac_init_web.dart | 1 | Vodozemac Web 实现 | → vodozemac_init | ✅ |
| link_preview_service.dart | 134 | 链接预览 | → ApiProxyService | ✅ |
| api_proxy_service.dart | 470 | API 代理（Cloudflare Worker） | → 所有需要后端的服务 | ✅ |

### 3.2 Agent 系统（core/agent/）

| 文件 | 行数 | 功能 | 连接状态 | 状态 |
|------|------|------|----------|------|
| agent_orchestrator.dart | 440 | Agent 编排器（意图分类+任务规划+执行） | → AppCapabilityService, ChatService, SkillRegistry | ✅ |
| agent_state.dart | 83 | Agent 状态定义 | → AgentOrchestrator | ✅ |
| agent_state_machine.dart | 97 | 10 状态 11 转换状态机 | → AgentOrchestrator | ✅ |
| agent_memory_service.dart | 260 | 三层记忆（用户/对话/主题）+ 时间衰减 | → DatabaseService, EmbeddingService | ✅ |
| conversation_manager.dart | 130 | 对话历史管理 | → AgentOrchestrator | ✅ |
| embedding_service.dart | 123 | 文本向量化 | → ApiProxyService | ✅ |
| stream_event_handler.dart | 109 | 流式事件处理 | → AgentOrchestrator | ✅ |

### 3.3 Matrix 通信（core/matrix/）

| 文件 | 行数 | 功能 | 连接状态 | 状态 |
|------|------|------|----------|------|
| matrix_service.dart | 294 | Matrix SDK 封装（登录/注册/聊天/密钥） | → matrix SDK | ✅ |
| matrix_provider.dart | 226 | Matrix 状态管理 | → MatrixService, AppProvider | ✅ |

### 3.4 AI 提供商（core/providers/）

| 文件 | 行数 | 功能 | 连接状态 | 状态 |
|------|------|------|----------|------|
| ai_provider.dart | 274 | AI 模型提供商（7+ 模型） | → ApiProxyService, ChatService | ✅ |

### 3.5 记忆系统（core/memory/）

| 文件 | 行数 | 功能 | 连接状态 | 状态 |
|------|------|------|----------|------|
| context_budget.dart | 88 | 上下文预算管理 | → AgentMemoryService | ✅ |

### 3.6 通知（core/notification/）

| 文件 | 行数 | 功能 | 连接状态 | 状态 |
|------|------|------|----------|------|
| app_notification.dart | 74 | 通知数据模型 | → NotificationCenter | ✅ |
| notification_provider.dart | 161 | 通知状态管理 | → NotificationCenter | ✅ |

### 3.7 搜索模块（modules/search/）

| 文件 | 行数 | 功能 | 连接状态 | 状态 |
|------|------|------|----------|------|
| web_search_skill.dart | 90 | 联网搜索 Skill（Serper.dev） | → AgentOrchestrator | ✅ |

---

## 四、Runtime 层文件清单（core/runtime/）

### 4.1 Vocabulary 原语（core/runtime/vocabulary/）

| 文件 | 行数 | 功能 | 连接状态 | 状态 |
|------|------|------|----------|------|
| runtime_message.dart | 56 | RuntimeMessage 消息协议 | → 所有 Runtime 组件 | ✅ |
| runtime_event.dart | 72 | RuntimeEvent 事件协议 | → EventBus | ✅ |
| runtime_stream.dart | 62 | RuntimeStream 流协议 | → StreamingController | ✅ |
| runtime_task.dart | 45 | RuntimeTask 任务协议 | → Scheduler | ✅ |
| runtime_route.dart | 55 | 四级寻址（capability+pluginId+instanceId+nodeId） | → 所有 Runtime 组件 | ✅ |
| runtime_identity.dart | 32 | Runtime 身份 | → CapabilityRouter, EventBus | ✅ |
| runtime_permission.dart | 59 | 权限+隔离级别+预算 | → CapabilityRouter, PolicyEngine | ✅ |
| runtime_session.dart | 42 | 会话管理 | → RuntimeContainer | ✅ |
| runtime_metadata.dart | 47 | 消息元数据（traceId+spanId+tags） | → RuntimeMessage, RuntimeEvent | ✅ |
| capability_context.dart | 61 | 能力调用上下文（deadline+cancellation） | → CapabilityRouter | ✅ |
| failure_policy.dart | 105 | 失败策略（retry+timeout+circuitBreaker+fallback+deadLetter） | → Scheduler, CapabilityRouter | ✅ |

### 4.2 Kernel 内核（core/runtime/kernel/）

| 文件 | 行数 | 功能 | 连接状态 | 状态 |
|------|------|------|----------|------|
| runtime_container.dart | 247 | Runtime 容器（所有组件的组装点） | → 所有 Runtime 组件 | ✅ |
| runtime_clock.dart | 17 | Runtime 时钟 | → RuntimeContainer | ✅ |
| runtime_config.dart | 58 | Runtime 配置 | → RuntimeContainer | ✅ |
| runtime_context.dart | 23 | Runtime 上下文接口 | → RuntimeContainer | ✅ |
| runtime_state.dart | 50 | Runtime 状态快照 | → RuntimeContainer | ✅ |

### 4.3 Plugin 插件系统（core/runtime/plugin/）

| 文件 | 行数 | 功能 | 连接状态 | 状态 |
|------|------|------|----------|------|
| plugin_descriptor.dart | 123 | 插件描述符（三层协议 Layer 1） | → PluginRegistry | ✅ |
| plugin_handler.dart | ~100 | 插件执行器（三层协议 Layer 3） | → CapabilityRouter | ✅ |
| plugin_lifecycle.dart | 64 | 插件生命周期状态机（三层协议 Layer 2） | → PluginRegistry | ✅ |
| plugin_registry.dart | ~150 | 插件注册表 | → RuntimeContainer | ✅ |

### 4.4 内置插件（core/runtime/plugins/）

| 文件 | 行数 | 功能 | 连接状态 | 状态 |
|------|------|------|----------|------|
| logger_plugin.dart | 62 | 日志插件 | → PluginRegistry | ✅ |
| storage_plugin.dart | 109 | 存储插件 | → PersistenceBackend | ✅ |
| config_plugin.dart | 97 | 配置插件 | → PersistenceBackend | ✅ |
| metrics_plugin.dart | 90 | 指标插件 | → PluginRegistry | ✅ |
| notification_plugin.dart | 68 | 通知插件 | → PluginRegistry | ✅ |
| memory_plugin.dart | 198 | 记忆插件 | → PersistenceBackend | ✅ |
| persistence_backend.dart | 37 | 持久化后端接口 | → StoragePlugin, ConfigPlugin | ✅ |
| fake_agent_plugin.dart | 185 | 测试用假 Agent 插件 | → 测试 | ✅ |
| chaos_agent_plugin.dart | 190 | 混沌工程测试插件 | → 测试 | ✅ |

### 4.5 核心组件（core/runtime/）

| 文件 | 行数 | 功能 | 连接状态 | 状态 |
|------|------|------|----------|------|
| capability_router.dart | 247 | 能力路由器（铁律3核心） | → PluginRegistry, PolicyEngine | ✅ |
| event_bus.dart | 221 | 事件总线（10s handler 超时） | → RuntimeContainer | ✅ |
| scheduler.dart | 186 | 任务调度器（优先级+预算+超时） | → RuntimeContainer | ✅ |
| streaming_controller.dart | 60 | 流式控制器 | → AgentOrchestrator | ✅ |
| card_runtime.dart | 108 | Card Runtime（UI 卡片运行时） | → RemoteUIEngine | ✅ |
| invariants/runtime_invariants.dart | 167 | Runtime 不变量检查 | → 测试 | ✅ |
| benchmark/runtime_benchmark.dart | 208 | Runtime 性能基准 | → 测试 | ✅ |

### 4.6 Governance 治理（core/runtime/governance/）

| 文件 | 行数 | 功能 | 连接状态 | 状态 |
|------|------|------|----------|------|
| policy_engine.dart | 165 | 策略引擎（访问控制） | → CapabilityRouter | ✅ |
| resource_controller.dart | 241 | 资源控制器（令牌桶） | → CapabilityRouter | ✅ |
| event_journal.dart | 150 | 事件日志（不可变审计） | → RuntimeContainer | ✅ |
| snapshot_service.dart | 136 | 状态快照 | → RuntimeContainer | ✅ |

### 4.7 Observability 可观测性（core/runtime/observability/）

| 文件 | 行数 | 功能 | 连接状态 | 状态 |
|------|------|------|----------|------|
| trace_service.dart | 125 | 分布式追踪 | → RuntimeContainer | ✅ |
| metrics_service.dart | 146 | 指标收集 | → RuntimeContainer | ✅ |
| timeline_service.dart | 131 | 时间线记录 | → RuntimeContainer | ✅ |

### 4.8 Stability 稳定性（core/runtime/stability/）

| 文件 | 行数 | 功能 | 连接状态 | 状态 |
|------|------|------|----------|------|
| security.dart | 370 | 安全工具（哈希+签名+验证） | → Sandbox | ✅ |
| runtime_spec.dart | 241 | Runtime 规范验证 | → 测试 | ✅ |

### 4.9 Sandbox 沙箱/文明系统（core/runtime/sandbox/）

| 文件 | 行数 | 功能 | 连接状态 | 状态 |
|------|------|------|----------|------|
| sandbox_runtime.dart | 464 | 沙箱运行时（隔离执行环境） | → ConstitutionalGuard | ✅ |
| constitutional_guard.dart | 750 | 宪法守卫（10 条法律执行） | → SandboxRuntime | ✅ |
| constitutional_trace.dart | 413 | 宪法追踪图 | → ConstitutionalGuard | ✅ |
| constitutional_sovereign.dart | 679 | 主权身份+共识+联邦声誉 | → ConstitutionalGuard | ✅ |
| constitutional_civilization.dart | 728 | 文明系统（立法+司法+经济） | → ConstitutionalGuard | ✅ |
| constitutional_civilization_layer.dart | 655 | 文明传输+外交+资源经济 | → ConstitutionalGuard | ✅ |
| civilization_kernel.dart | 436 | 文明内核 | → SandboxRuntime | ✅ |
| civilization_network.dart | 717 | 文明网络（拜占庭检测+八卦协议） | → ConstitutionalGuard | ✅ |
| sovereign_identity.dart | 447 | 主权身份（HMAC-SHA256 签名） | → ConstitutionalGuard | ✅ |
| runtime_law.dart | 271 | 10 条宪法法律 + 修正案 | → ConstitutionalGuard | ✅ |

### 4.10 Distributed 分布式（core/runtime/distributed/）

| 文件 | 行数 | 功能 | 连接状态 | 状态 |
|------|------|------|----------|------|
| distributed_runtime.dart | 200 | 分布式运行时 | → OmniviumSDK | ✅ |
| node_discovery.dart | 260 | 节点发现 | → DistributedRuntime | ✅ |
| distributed_invariants.dart | 141 | 分布式不变量 | → 测试 | ✅ |
| distributed_trace.dart | 284 | 分布式追踪 | → DistributedRuntime | ✅ |
| hybrid_logical_clock.dart | 133 | 混合逻辑时钟 | → DistributedRuntime | ✅ |
| session_lease_manager.dart | 153 | 会话租约管理 | → DistributedRuntime | ✅ |
| transport/runtime_transport.dart | 205 | 传输层接口 | → WebSocketTransport | ✅ |
| transport/websocket_transport.dart | 220 | WebSocket 传输 | → RuntimeTransport | ✅ |
| protocol/wire_protocol.dart | 244 | Wire 协议 | → ProtocolHandler | ✅ |
| protocol/protocol_handler.dart | 380 | 协议处理器 | → DistributedRuntime | ✅ |
| persistence/write_ahead_log.dart | 330 | WAL 预写日志 | → DistributedRuntime | ✅ |
| recovery/recovery_manager.dart | 324 | 恢复管理器 | → DistributedRuntime | ✅ |
| lease/unified_lease.dart | 271 | 统一租约 | → SessionLeaseManager | ✅ |
| vocabulary/distributed_vocabulary.dart | 4 | 分布式词汇 barrel | → 所有分布式组件 | ✅ |
| vocabulary/cluster_event.dart | 71 | 集群事件 | → NodeDiscovery | ✅ |
| vocabulary/remote_capability_binding.dart | 78 | 远程能力绑定 | → DistributedRuntime | ✅ |
| vocabulary/distributed_session_lease.dart | 70 | 分布式会话租约 | → SessionLeaseManager | ✅ |

### 4.11 SDK（core/runtime/sdk/）

| 文件 | 行数 | 功能 | 连接状态 | 状态 |
|------|------|------|----------|------|
| omnivium_sdk.dart | 376 | SDK 入口（插件注册+能力调用） | → AppProvider, AgentOrchestrator | ✅ |
| runtime_observatory.dart | 302 | Runtime 观测台 | → OmniviumSDK | ✅ |
| runtime_cli.dart | 306 | Runtime CLI | → OmniviumSDK | ✅ |

---

## 五、展示层文件清单（presentation/）

### 5.1 视图（presentation/views/）

| 文件 | 行数 | 功能 | 连接状态 | 状态 |
|------|------|------|----------|------|
| home_view.dart | 588 | 主页（4 Tab：聊天/联系人/发现/设置） | → AppProvider | ✅ |
| contacts_view.dart | 274 | 联系人列表 | → AppProvider, MatrixService | ✅ |
| message_list_view.dart | 358 | 消息列表 | → AppProvider | ✅ |
| settings_view.dart | 750 | 设置页 | → 所有核心服务 | ✅ |
| discover_view.dart | 413 | 发现页（文章/新闻） | → ApiProxyService | ✅ |
| search_view.dart | 375 | 搜索页（AI 搜索+本地搜索） | → AgentOrchestrator | ✅ |
| voice_view.dart | 551 | 语音模式 | → VoiceService, AgentOrchestrator | ✅ |
| ai_workbench_view.dart | 539 | AI 工作台（8 模板） | → AgentOrchestrator | ✅ |
| productivity_view.dart | 464 | 生产力（笔记+待办+日程） | → NoteService | ✅ |
| file_manager_view.dart | 192 | 文件管理 | → FileDownloadService | ✅ |
| storage_view.dart | 213 | 存储管理 | → DatabaseService | ✅ |
| add_friend_view.dart | 340 | 添加好友 | → MatrixService | ✅ |
| friend_profile_view.dart | 300 | 好友资料 | → MatrixService | ✅ |
| matrix_login_view.dart | 186 | Matrix 登录/注册 | → AuthService | ✅ |
| key_verification_view.dart | 392 | 密钥验证（E2EE） | → MatrixService | ✅ |
| my_id_view.dart | 425 | 我的主权 ID | → SovereignIdentity | ✅ |
| ai_permission_view.dart | 340 | AI 权限管理 | → AppCapabilityService | ✅ |
| ai_operation_log_view.dart | 341 | AI 操作审计日志 | → AuditLogService | ✅ |
| agent_replay_view.dart | 109 | Agent 回放 | → AgentOrchestrator | ✅ |
| about_view.dart | 89 | 关于页 | → 静态 | ✅ |
| faq_view.dart | 75 | FAQ | → 静态 | ✅ |
| privacy_policy_view.dart | 39 | 隐私政策 | → 静态 | ✅ |
| terms_of_service_view.dart | 38 | 服务条款 | → 静态 | ✅ |

### 5.2 组件（presentation/widgets/）

| 文件 | 行数 | 功能 | 连接状态 | 状态 |
|------|------|------|----------|------|
| friend_chat_panel.dart | 1190 | 聊天面板（消息+输入+工具栏） | → MatrixService, AgentOrchestrator | ✅ |
| chat_input_area.dart | 293 | 聊天输入区 | → FriendChatPanel | ✅ |
| ai_bubbles.dart | 185 | AI 消息气泡 | → FriendChatPanel | ✅ |
| app_drawer.dart | 375 | 侧边抽屉 | → HomeView | ✅ |
| home_header.dart | 227 | 主页头部 | → HomeView | ✅ |
| home_components.dart | 142 | 主页组件 | → HomeView | ✅ |
| home_dialogs.dart | 183 | 主页对话框 | → HomeView | ✅ |
| conversation_content.dart | 147 | 对话内容 | → FriendChatPanel | ✅ |
| model_sheets.dart | 136 | 模型选择底部表 | → AIProvider | ✅ |
| thought_chain_panel.dart | 197 | 思维链面板 | → FriendChatPanel | ✅ |
| library_panel.dart | 262 | 库面板 | → HomeView | ✅ |
| media_picker.dart | 218 | 媒体选择器 | → ChatInputArea | ✅ |
| video_player.dart | 183 | 视频播放器 | → FriendChatPanel | ✅ |
| voice_message.dart | 247 | 语音消息 | → FriendChatPanel | ✅ |
| link_preview_card.dart | 132 | 链接预览卡片 | → FriendChatPanel | ✅ |
| skeleton_loader.dart | 133 | 骨架屏加载 | → 所有列表视图 | ✅ |
| animated_toggle.dart | 104 | 动画切换 | → SettingsView | ✅ |
| incognito_icon.dart | 74 | 隐身图标 | → HomeHeader | ✅ |
| section_header.dart | 22 | 分节标题 | → SettingsView | ✅ |
| setting_item.dart | 59 | 设置项（48px 最小触摸+语义） | → SettingsView | ✅ |
| app_error_boundary.dart | 127 | 错误边界（友好提示+重试） | → Main.dart | ✅ |

### 5.3 主题（presentation/theme/）

| 文件 | 行数 | 功能 | 连接状态 | 状态 |
|------|------|------|----------|------|
| app_colors.dart | 72 | 颜色系统（深色/浅色） | → 所有 UI 组件 | ✅ |
| theme_provider.dart | 283 | 主题切换 | → AppProvider | ✅ |
| locale_provider.dart | 705 | 国际化（420+ key） | → 所有 UI 组件 | ✅ |
| app_semantics.dart | 102 | 无障碍语义工具 | → 关键交互组件 | ✅ |

### 5.4 工具（presentation/utils/）

| 文件 | 行数 | 功能 | 连接状态 | 状态 |
|------|------|------|----------|------|
| format_utils.dart | 11 | 格式化工具 | → UI 组件 | ✅ |
| format_time.dart | 14 | 时间格式化 | → UI 组件 | ✅ |
| responsive.dart | 27 | 响应式布局 | → UI 组件 | ✅ |

---

## 六、国际化文件（l10n/）

| 文件 | 行数 | 功能 | 状态 |
|------|------|------|------|
| app_localizations.dart | 3938 | 生成的本地化代码 | ✅ |
| app_localizations_en.dart | 1986 | 英文 | ✅ |
| app_localizations_zh.dart | 1919 | 中文 | ✅ |
| app_localizations_ja.dart | 1923 | 日文 | ✅ |
| app_localizations_ko.dart | 1924 | 韩文 | ✅ |
| app_en.arb | ~440 | 英文 ARB 源 | ✅ |
| app_zh.arb | ~440 | 中文 ARB 源 | ✅ |
| app_ja.arb | ~440 | 日文 ARB 源 | ✅ |
| app_ko.arb | ~440 | 韩文 ARB 源 | ✅ |

---

## 七、依赖清单（pubspec.yaml）

### 核心依赖

| 包名 | 版本 | 用途 |
|------|------|------|
| flutter | SDK | UI 框架 |
| matrix | ^0.35.0 | Matrix 协议（E2EE 聊天） |
| supabase_flutter | ^2.8.4 | Supabase（认证+数据同步） |
| firebase_messaging | ^15.2.4 | 推送通知 |
| flutter_local_notifications | ^18.0.1 | 本地通知 |
| sentry_flutter | ^8.13.0 | 崩溃追踪 |
| get_it | ^8.0.3 | 依赖注入 |
| local_auth | ^2.3.0 | 生物识别 |
| encrypt | ^5.0.3 | 加密 |
| crypto | any | 哈希+签名 |
| hive | any | 本地数据库 |
| flutter_secure_storage | any | 安全存储 |
| cached_network_image | any | 图片缓存 |
| lucide_icons | any | 图标 |
| speech_to_text | any | 语音识别 |
| flutter_tts | any | 语音合成 |
| permission_handler | any | 权限管理 |
| url_launcher | any | URL 启动 |
| share_plus | any | 分享 |
| app_links | any | 深度链接 |
| intl | any | 国际化 |

---

## 八、测试文件清单（test/）

共 66 个测试文件，1027 个测试用例全部通过。

主要测试覆盖：
- Runtime 核心：sdk_test, runtime_contract_test, system_plugins_test, governance_test
- 沙箱系统：sandbox_test, sandbox_hostile_test, constitutional_guard_test, civilization_kernel_test
- 分布式：distributed_test, chaos_engineering_test
- Agent：agent_orchestrator_model_test, skill_test
- 视图：about_view_test, add_friend_view_test, contacts_view_test 等
- 服务：ai_provider_test, app_provider_test, embedding_service_test 等

---

## 九、连接拓扑

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

Presentation Layer            Core Services
─────────────────            ──────────────
HomeView ──→ AppProvider      DatabaseService (Hive)
  ├→ ContactsView             SecureStorageService
  ├→ DiscoverView             ApiProxyService (Cloudflare Worker)
  ├→ SettingsView             AuthService (Supabase)
  └→ FriendChatPanel          VoiceService (STT/TTS)
       ├→ ChatInputArea        PushNotificationService
       ├→ AIBubbles            FileDownloadService
       └→ ThoughtChainPanel    NoteService
```

---

## 十、已知问题/待做项

###  P1 重要

| # | 问题 | 说明 |
|---|------|------|
| 2 | 语音/视频通话 | 需 WebRTC，当前空回调 |
| 3 | 广场/内容模块 | 6 个页面缺失，依赖后端 API |
| 4 | 主动提醒系统 | Agent 主动推送完全缺失 |
| 5 | CI/CD 流水线 | 缺失 |
| 6 | 代码生成工具链 | 无 freezed / json_serializable |
| 7 | 环境/Flavor 配置 | 无 dev/staging/prod |

### 🟡 P2 待做

| # | 问题 | 说明 |
|---|------|------|
| 8 | Firebase Analytics | 未接入 |
| 9 | PWA 离线支持 | 未实现 |
| 10 | Matrix 桥接 | 未实现 |

### 🔵 上架阻塞项

| # | 阻塞项 | 说明 |
|---|--------|------|
| 11 | 应用图标 | 需品牌 Logo 设计 |
| 12 | 开发者账号 | Google Play $25 / Apple $99/年 |
| 13 | 隐私政策部署 | 需部署到公开 URL |
| 14 | API 域名切换 | workers.dev → api.omnivium.app |
| 15 | SSL Pinning 真实 hash | 需部署后配置 |
