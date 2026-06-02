# Omnivium 重构规范与施工文档

> 版本: 3.3 | 日期: 2026-06-01
> 本文档是 Omnivium 项目重构的唯一权威参考，所有开发必须遵循本文档。
> v3.3 更新：完成 Phase 1-6 代码实现，修复登录鸡生蛋问题，CapabilityParams 类型安全，30+ Skill 注册

---

## 一、项目愿景

Omnivium 是一个 **AI 原生超级应用**。AI 不是附加功能，而是核心——所有功能都为 AI 服务，AI 可操控一切。

核心体验：
- 用户通过 Google/Apple/邮箱登录，获得统一身份
- AI 聊天、好友聊天、动态/短视频全部互通
- AI 可以发消息、加好友、建群、切模型、设定时任务、做工作流
- 定时任务支持自然语言（"10分钟后叫我"、"明天9点提醒我"）
- 轻客户端：模型列表、Skill 定义、UI 组件、权限策略全部从后端注入
- 声纹唤醒、语音交互（后续）

---

## 二、现有系统审计（v2.0 新增）

> 重构前必须清楚"现在有什么、什么能用、什么不能用"。

### 2.1 两套系统对照表

| 模块 | 旧系统（在用） | 新架构（做了一半） | 问题 |
|------|---------------|-------------------|------|
| 登录 | MatrixLoginView → MatrixProvider.login() → MatrixService | LoginPage → AuthBloc → AuthRepositoryImpl → AuthRemoteDataSource（空壳） | 新架构的 DataSource 全是 throw UnimplementedError，从未被 main.dart 引用 |
| 认证状态 | MatrixService.isLoggedIn | AuthBloc(AuthAuthenticated/AuthUnauthenticated) | 两套不通信 |
| DI | service_locator.dart（locator） | injection.dart（sl） | 同一个 GetIt.instance，但注册分散 |
| 状态管理 | AppProvider（ChangeNotifier 大杂烩） | Bloc（flutter_bloc） | 混用 |
| 聊天 | FriendChatPanel → 直接 Matrix SDK | ChatBloc → ChatRepositoryImpl → MatrixService | 两套并行，互不通信，状态不共享 |
| AI 聊天 | HomeView → AgentOrchestrator → 后端 AI API | AiChatBloc → 后端 AI API | 旧系统在用，新架构部分可用 |

### 2.2 已知 Bug 清单

| Bug | 文件 | 严重程度 | 状态 |
|-----|------|---------|------|
| 发送消息返回空 ID | chat_repository_impl.dart | 🔴 严重 | ✅ 已修复（提前返回 Left） |
| `_readFile()` 未实现 | chat_repository_impl.dart | 🔴 严重 | ✅ 已实现 |
| 打字指示器返回空流 | chat_repository_impl.dart | 🟡 中等 | ✅ 已修复（接入 Matrix onRoomUpdate） |
| 视频发送未实现 | - | 🟡 中等 | ✅ 已实现（MatrixCubit.sendVideo + FriendChatPanel._pickVideo） |
| 群组头像未上传 | create_group_view.dart | 🟡 中等 | ✅ 已修复（创建后上传头像） |
| `_timeline` 重复赋值 | friend_chat_panel.dart | 🔵 轻微 | ✅ 已修复 |
| 139 个 lint 问题 | 全项目 | 🔴 严重 | 58 个 Error、40 个 Warning、41 个 Info |
| 登录退出就失效 | main.dart:486 | 🔴 严重 | Matrix token 恢复链路脆弱 |

### 2.3 类型安全现状（v2.0 新增）

| 指标 | 数值 | 评估 |
|------|------|------|
| `dynamic` 关键词出现次数 | 0 处裸 dynamic params（Runtime Plugin 系统已迁移至 CapabilityParams） | ✅ 已修复 |
| `Map<String, dynamic>` 出现次数 | 仅 JSON 反序列化边界 | ✅ 合规 |
| `@freezed` 使用次数 | 10（ChatMessage, ChatRoom, Contact, CallState, Session, User, AgentModel, AgentSkill, SessionMessage, ConversationSession, UnifiedMessage） | ✅ 已迁移 |
| `@JsonSerializable` 使用次数 | 同 @freezed | ✅ 已迁移 |
| 所有 Model fromJson/toJson | freezed 生成 | ✅ 编译期保障 |
| analysis_options.yaml 严格规则 | very_good_analysis + avoid_dynamic_calls: error + strict-casts/inference/raw-types | ✅ 已配置 |
| CapabilityParams 类型安全 | Runtime Plugin 系统全部使用 CapabilityParams 替代 dynamic params | ✅ v3.3 新增 |

### 2.4 互通性现状（v2.0 新增）

| 互通维度 | 状态 | 说明 |
|----------|------|------|
| 统一消息模型 | ✅ 已创建 | UnifiedMessage freezed 模型已创建于 features/chat/data/models/ |
| AI → 好友聊天分享 | ✅ 已实现 | ShareToFriendSheet 组件 + message.share_to_friend handler |
| 好友聊天 → AI 分析 | ✅ 已实现 | 消息长按"让AI分析" + @AI 触发 + message.share_to_ai handler |
| Agent/Skill ↔ AI 聊天 | ✅ 紧密连接 | Orchestrator 驱动 AI 聊天，Skill 注入系统提示词 |
| Agent/Skill ↔ 好友聊天 | ✅ 已连接 | @AI/@omni 触发 + friend.add/model.switch Skill |
| AI 聊天与好友聊天 UI | ⚠️ 互斥切换 | `_isFriendChat` 布尔值，同一时间只能看一个 |

### 2.5 模型获取现状

模型列表**从后端 API 获取**，客户端没有硬编码。但后端 `worker.js` 的 `handleModels` 函数里，模型列表是**写死在代码里的**——只是根据环境变量（有没有 API Key）决定返回哪些。

新增模型需要改 worker.js 代码并重新部署，不是真正的"后端推送"。

---

## 三、架构总览

```
┌──────────────────────────────────────────────────────────┐
│                      客户端 (Flutter)                     │
│                                                          │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────────┐ │
│  │ AI 聊天  │ │ 好友聊天  │ │ 动态/视频 │ │   设置     │ │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └─────┬──────┘ │
│       │            │            │              │        │
│  ┌────▼────────────▼────────────▼──────────────▼──────┐ │
│  │              统一消息层 (UnifiedMessage)             │ │
│  └────────────────────┬───────────────────────────────┘ │
│                       │                                  │
│  ┌────────────────────▼───────────────────────────────┐ │
│  │              AI Agent 核心                           │ │
│  │  ┌──────────┐ ┌──────────┐ ┌────────────────────┐ │ │
│  │  │ 意图理解  │ │ 任务规划  │ │ Skill 组合与执行   │ │ │
│  │  └──────────┘ └──────────┘ └────────────────────┘ │ │
│  └────────────────────┬───────────────────────────────┘ │
│                       │                                  │
│  ┌────────────────────▼───────────────────────────────┐ │
│  │              Skill 注册表 (SkillRegistry)            │ │
│  │  发消息│加好友│建群│切模型│定时│搜索│分享│工作流... │ │
│  └────────────────────┬───────────────────────────────┘ │
│                       │                                  │
│  ┌────────────────────▼───────────────────────────────┐ │
│  │              统一身份层 (IdentityBridge + DID)        │ │
│  └────────────────────┬───────────────────────────────┘ │
│                       │                                  │
└───────────────────────┼──────────────────────────────────┘
                        │ HTTPS
┌───────────────────────▼──────────────────────────────────┐
│                    后端 (Cloudflare)                       │
│                                                          │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐ │
│  │ API Proxy    │ │ Cron Worker  │ │ Auth Worker      │ │
│  │ (AI/技能/配置)│ │ (定时任务)    │ │ (登录/注册)      │ │
│  └──────┬───────┘ └──────┬───────┘ └────────┬─────────┘ │
│         │                │                   │           │
│  ┌──────▼────────────────▼───────────────────▼─────────┐ │
│  │         Cloudflare KV / R2 / D1                     │ │
│  │  (模型配置/Skill定义/定时任务/文件/推送)              │ │
│  └────────────────────┬────────────────────────────────┘ │
│                       │                                   │
└───────────────────────┼───────────────────────────────────┘
                        │
┌───────────────────────▼───────────────────────────────────┐
│                   数据层                                   │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐  │
│  │ Supabase     │ │ Matrix       │ │ Cloudflare R2    │  │
│  │ (Auth/DB)    │ │ Synapse      │ │ (文件存储)        │  │
│  └──────────────┘ └──────────────┘ └──────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

---

## 四、技术栈规范

### 4.1 客户端

| 类别 | 技术选型 | 说明 |
|------|---------|------|
| 框架 | Flutter 3.x | 跨平台 |
| 状态管理 | flutter_bloc Cubit/Bloc | **唯一**状态管理方案，ChangeNotifier 已完全消除 | ✅ 已完成 |
| 依赖注入 | GetIt (单一实例) | 合并现有 `locator` 和 `sl` |
| 路由 | go_router | 声明式路由 |
| 本地存储 | flutter_secure_storage + sqflite（目标）+ Hive（当前） | 敏感数据用 secure storage，大量数据用 sqflite（新功能）/ Hive（旧功能）。迁移策略详见第三十四章 |
| 网络请求 | http (通过 ApiProxyService) | 所有请求走代理 |
| 聊天 | matrix SDK | 降级为聊天管道，不是身份中心 |
| AI 交互 | 后端 Agent API | 客户端不直接调 AI |
| 数据模型 | freezed + json_serializable | **强制使用**，禁止手写 fromJson/toJson |
| Lint 规则 | very_good_analysis | 替代 flutter_lints，更严格 |

### 4.2 后端

| 类别 | 技术选型 | 说明 |
|------|---------|------|
| API 网关 | Cloudflare Workers | 现有，扩展 |
| 认证 | Supabase Auth | Google/Apple/邮箱 |
| 数据库 | Supabase PostgreSQL | 用户数据、会话、记忆、模型配置、Skill 定义 |
| 聊天服务 | Matrix Synapse | 自托管，仅作消息管道 |
| 缓存/配置 | Cloudflare KV | 远程配置、限流、临时数据 |
| 定时任务 | Cloudflare Cron Triggers + Durable Objects | 定时/周期任务调度 |
| 文件存储 | Cloudflare R2 | 图片、视频、文件 |
| 推送 | FCM (Android) + APNs (iOS) | 推送通知 |

### 4.3 禁止事项

- ❌ 禁止在客户端直接调用 AI API（必须走后端代理）
- ❌ 禁止使用 ChangeNotifier 管理业务状态（用 Bloc）
- ❌ 禁止新建单例 Service（用 DI 容器注册）
- ❌ 禁止在 Widget 中直接调 Matrix SDK（通过 Skill/Repository）
- ❌ 禁止硬编码模型列表、Skill 列表（从后端下发）
- ❌ 禁止手写 fromJson/toJson（用 freezed + json_serializable）
- ❌ 禁止使用裸 `dynamic` 类型（用具体类型或泛型）
- ❌ 禁止使用裸 `List`、`Map`（必须指定泛型参数）

---

## 五、目录结构规范

```
lib/
├── app/                        # APP 级配置
│   ├── app.dart                # MaterialApp
│   ├── router.dart             # go_router 路由定义
│   └── di.dart                 # 唯一 DI 容器
│
├── core/                       # 纯工具层（不依赖任何 feature）
│   ├── network/                # HTTP 客户端、拦截器
│   │   ├── api_client.dart
│   │   └── api_interceptor.dart
│   ├── storage/                # 本地存储封装
│   │   ├── secure_storage.dart
│   │   └── database_service.dart
│   ├── identity/               # 统一身份
│   │   ├── identity_bridge.dart
│   │   ├── auth_service.dart
│   │   └── sovereign_identity.dart
│   ├── agent/                  # Agent 核心
│   │   ├── agent_orchestrator.dart
│   │   ├── agent_state_machine.dart
│   │   ├── skill_registry.dart
│   │   └── conversation_manager.dart
│   ├── skills/                 # Skill 定义
│   │   ├── skill.dart
│   │   ├── send_message_skill.dart
│   │   ├── add_friend_skill.dart
│   │   ├── set_reminder_skill.dart
│   │   └── ...
│   ├── notification/           # 推送通知
│   ├── utils/                  # 通用工具
│   └── logger/                 # 日志
│
├── features/                   # 每个 feature 自包含
│   ├── auth/                   # 认证
│   │   ├── data/
│   │   │   ├── models/         # freezed 生成的数据模型
│   │   │   ├── repositories/auth_repository_impl.dart
│   │   │   └── datasources/
│   │   ├── domain/
│   │   │   ├── entities/       # freezed 生成的领域实体
│   │   │   ├── repositories/auth_repository.dart
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── bloc/auth_bloc.dart
│   │       ├── pages/login_page.dart
│   │       └── widgets/
│   │
│   ├── chat/                   # 聊天（AI + 好友统一）
│   │   ├── data/
│   │   │   ├── models/         # UnifiedMessage 等数据模型
│   │   │   ├── repositories/chat_repository_impl.dart
│   │   │   └── datasources/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/chat_repository.dart
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── bloc/chat_bloc.dart
│   │       ├── pages/
│   │       └── widgets/
│   │           ├── message_list.dart
│   │           ├── chat_input.dart
│   │           ├── message_bubble.dart
│   │           ├── thought_chain.dart
│   │           ├── skill_confirm_dialog.dart
│   │           └── share_to_friend_sheet.dart
│   │
│   ├── contacts/               # 联系人
│   ├── moments/                # 动态/短视频（后续）
│   ├── settings/               # 设置
│   └── tasks/                  # 定时任务
│
└── shared/                     # 跨 feature 共享
    ├── widgets/                # 通用组件
    ├── theme/                  # 主题
    └── l10n/                   # 国际化
```

---

## 六、统一身份系统规范

### 6.1 登录流程

```
用户打开 APP
    ↓
检查 Supabase Auth 本地 session
    ↓
有 session？──是──→ 检查 Matrix 账号是否关联
    │                    │
    │               已关联 → 直接进主界面
    │               未关联 → 后端自动创建 Matrix 账号 → 进主界面
    │
    否
    ↓
显示登录页
    ↓
用户选择: Google / Apple / 邮箱注册
    ↓
Supabase Auth 处理登录
    ↓
登录成功 → 后端自动创建 Matrix 账号（对用户透明）
    ↓
IdentityBridge 绑定 DID
    ↓
进主界面
```

### 6.2 认证架构

```dart
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String email,
    String? displayName,
    String? avatarUrl,
    String? matrixUserId,
    String? did,
    @Default('basic') String trustLevel,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}

class AuthRepository {
  Future<UserModel> loginWithGoogle();
  Future<UserModel> loginWithApple();
  Future<UserModel> loginWithEmail(String email, String password);
  Future<UserModel> registerWithEmail(String email, String password);
  Future<void> _ensureMatrixAccount(String userId);
  Future<bool> restoreSession();
  Future<void> logout();
}
```

### 6.3 Token 刷新机制

- Supabase Auth **自动管理** access_token 和 refresh_token
- 客户端监听 `Supabase.instance.client.auth.onAuthStateChange`
- Token 过期时 Supabase SDK 自动刷新，用户无感
- Matrix token 在 Supabase 登录成功后由后端自动创建/恢复
- 只有 Supabase refresh_token 彻底过期才需要重新登录

### 6.4 Matrix 定位

- Matrix 是**聊天管道**，不是身份中心
- 用户不需要知道 Matrix 的存在
- Matrix 账号由后端自动创建，密码由后端管理
- 聊天消息通过 Matrix SDK 收发
- AI 发消息也通过 Matrix（Agent → Skill → MatrixService）

---

## 七、聊天系统统一方案（v2.0 新增）

### 7.1 核心原则：一套系统，一个入口

**删除 FriendChatPanel 的直接 Matrix 调用，统一走 ChatBloc + ChatRepositoryImpl。**

现状问题：
- FriendChatPanel（2500行）直接调 Matrix SDK
- ChatBloc 走 Repository 层但功能残缺
- 两套互不通信

目标架构：
```
UI 层：ChatPage（统一聊天页面）
  ↓
状态层：ChatBloc（统一状态管理）
  ↓
数据层：ChatRepositoryImpl（统一数据源）
  ├── AI 消息 → 后端 Agent API
  └── 好友消息 → Matrix SDK
  ↓
统一模型：UnifiedMessage
```

### 7.2 ChatRepositoryImpl 统一实现

```dart
class ChatRepositoryImpl implements IChatRepository {
  final MatrixService _matrix;
  final ApiProxyService _api;

  // AI 聊天：走后端 Agent API
  Stream<UnifiedMessage> sendAiMessage(String content, String modelId) { ... }

  // 好友聊天：走 Matrix SDK
  Future<UnifiedMessage> sendFriendMessage(String roomId, String content) async {
    final room = _matrix.client?.getRoomById(roomId);
    if (room == null) throw Exception('Room not found');
    final eventId = await room.sendTextEvent(content);
    return UnifiedMessage(
      id: eventId,  // 修复：使用真实 eventId
      senderId: _matrix.userId!,
      content: content,
      type: MessageType.friendChat,
      format: MessageFormat.text,
      timestamp: DateTime.now(),
    );
  }

  // 文件发送：实现 _readFile
  Future<UnifiedMessage> sendFileMessage(String roomId, String filePath, MessageFormat format) async {
    final bytes = await File(filePath).readAsBytes();
    final matrixFile = MatrixFile(bytes: bytes, name: path.basename(filePath));
    final eventId = await room.sendFileEvent(matrixFile);
    ...
  }

  // 打字指示器：实现 onTyping 流
  Stream<String> get onTyping => _matrix.onTypingStream;
}
```

### 7.3 FriendChatPanel 拆分方案

| 新组件 | 职责 | 预计行数 |
|--------|------|---------|
| ChatPage | 统一聊天页面容器 | ~150 |
| MessageList | 消息列表（AI + 好友通用） | ~200 |
| MessageBubble | 单条消息气泡 | ~150 |
| ChatInput | 输入区域（文本/语音/图片） | ~200 |
| ThoughtChain | AI 思维链展示 | ~100 |
| ChatAppBar | 顶部栏（好友信息/AI模型） | ~100 |
| ReplyPreview | 回复预览条 | ~50 |
| ForwardSheet | 转发选择面板 | ~150 |
| ShareToFriendSheet | 分享给好友面板 | ~100 |
| SkillConfirmDialog | Skill 执行确认弹窗 | ~80 |

### 7.4 AppProvider 迁移方案（v2.1 新增）

> 这是最关键的迁移步骤。AppProvider 是整个 APP 的"上帝对象"，管理 12 个子 Provider。
> 不能一次性删掉，必须逐步迁移。

**AppProvider 当前管理的子 Provider：**

| 子 Provider | 类型 | 迁移目标 | 迁移方式 | 状态 |
|-------------|------|---------|---------|------|
| MatrixProvider | ~~ChangeNotifier~~ | 降级为纯数据层 | 已迁移为 MatrixCubit | ✅ 已完成 |
| AgentOrchestrator | ~~ChangeNotifier~~ | Cubit | 已迁移为 Cubit<OrchestratorState> | ✅ 已完成 |
| ModelProvider | ~~ChangeNotifier~~ | Cubit | 已迁移为 ModelCubit | ✅ 已完成 |
| NavigationProvider | ~~ChangeNotifier~~ | Cubit | 已迁移为 NavigationCubit（go_router 待引入） | ✅ 已完成 |
| NotificationProvider | ~~ChangeNotifier~~ | Cubit | 已迁移为 NotificationCubit | ✅ 已完成 |
| QuickCommandProvider | ~~ChangeNotifier~~ | Cubit | 已迁移为 QuickCommandCubit | ✅ 已完成 |
| NoteProvider | ~~ChangeNotifier~~ | Cubit | 已迁移为 NoteCubit | ✅ 已完成 |
| ThemeProvider | ~~ChangeNotifier~~ | Cubit | 已迁移为 ThemeCubit | ✅ 已完成 |
| LocaleProvider | ~~ChangeNotifier~~ | Cubit | 已迁移为 LocaleCubit | ✅ 已完成 |
| SessionManager | ~~ChangeNotifier~~ | Cubit | 已合并到 SessionCubit | ✅ 已完成 |
| OmniviumSDK | 独立类 | 保留，被 Agent 使用 | 不变 | - |
| IdentityBridge | 独立类 | 保留，绑定到 AuthBloc | 不变 | - |

**迁移步骤（每个 Phase 对应）：**

```
Phase 0: AppProvider 不动，只清理 lint 问题

Phase 1: AppProvider 不动，只改数据模型

Phase 2: AppProvider.matrix → AuthBloc 接管登录
         AppProvider.matrix.isLoggedIn → AuthBloc.state
         AppProvider 内部 MatrixProvider 降级为数据层

Phase 3: AppProvider.matrix → ChatBloc 接管聊天
         FriendChatPanel 中 provider.matrix.xxx → ChatBloc ✅ 已完成
         AppProvider 内部 MatrixProvider 只保留连接管理 ✅ 已完成
         AiChatBloc → ChatBloc 统一 ✅ 已完成（@deprecated）
         presentation 层 matrix import: 7→1（仅 friend_chat_panel 保留 Timeline/Event）

Phase 4: AppProvider.orchestrator → Skill 通过 ChatBloc 调用
         AppProvider 内部 AgentOrchestrator 降级为 ChatBloc 的依赖

Phase 5-7: AppProvider 逐步瘦身
           最终 AppProvider 只保留 ThemeProvider + LocaleProvider
           或者完全删除，Theme/Locale 用全局 Bloc
```

**关键原则：每个 Phase 完成后，APP 必须能正常运行。不允许出现"改了一半跑不起来"的情况。**

### 7.5 Runtime/Plugin 系统处理（v2.1 新增）

项目中有 OmniviumSDK、Plugin 系统、沙箱（WASM/CivilizationKernel）等代码。
这些代码设计超前但大部分是空壳。

**处理方案：**

| 组件 | 状态 | 处理 |
|------|------|------|
| OmniviumSDK | 部分实现 | 保留，作为 Agent 的 Runtime 层 |
| Plugin 系统 | 框架在，Handler 空实现 | 保留框架，Skill 注册为 Plugin |
| WASM 沙箱 | 空壳 | 暂不迁移，后续按需实现 |
| CivilizationKernel | 空壳 | 暂不迁移，后续按需实现 |
| 分布式层（HLC/节点发现） | 空壳 | 暂不迁移，后续按需实现 |
| CapabilityRouter | 部分实现 | 保留，Skill 通过它路由 |

**原则：空壳代码不删，但也不花时间迁移。只确保它们不阻塞编译。**

---

## 八、Agent 能力规范

### 8.1 Skill 分类

| 分类 | Skill | 权限 | 优先级 |
|------|-------|------|--------|
| 聊天 | SendMessageSkill | confirm | P0 |
| 聊天 | ReadMessageSkill | auto | P0 |
| 聊天 | CreateGroupSkill | confirm | P1 |
| 聊天 | AddFriendSkill | confirm | P1 |
| 聊天 | AutoReplySkill | confirm | P2 |
| 聊天 | StartCallSkill | confirm | P2 |
| 聊天 | ReactionSkill | auto | P2 |
| AI | SwitchModelSkill | auto | P0 |
| AI | GenerateImageSkill | auto | P1 |
| AI | AnalyzeConversationSkill | auto | P1 |
| 系统 | SetReminderSkill | auto | P0 |
| 系统 | CancelReminderSkill | auto | P0 |
| 系统 | SwitchThemeSkill | auto | P1 |
| 系统 | ShareToFriendSkill | confirm | P1 |
| 系统 | ShareToAISkill | auto | P1 |
| 系统 | WebSearchSkill | auto | P0 |
| 后续 | CreatePostSkill | confirm | P2 |
| 后续 | CreateWorkflowSkill | confirm | P2 |

### 8.2 Skill 接口规范

```dart
enum PermissionLevel { auto, confirm }
enum IntentChannel { fast, slow }

@freezed
class SkillResult with _$SkillResult {
  const factory SkillResult.success({required Map<String, dynamic> data}) = SkillSuccess;
  const factory SkillResult.failure({required String error, int? code}) = SkillFailure;
}

abstract class Skill {
  String get id;
  String get name;
  String get description;
  IntentChannel get channel;
  PermissionLevel get permission;
  int get timeoutMs;
  bool get isDestructive;
  String get version;

  Future<SkillResult> execute(Map<String, dynamic> params);
  Map<String, dynamic> get paramSchema;
}
```

> **类型说明**：
> - `PermissionLevel`：`auto` = AI 自动执行，`confirm` = 需用户确认
> - `IntentChannel`：`fast` = 实时交互（如切换主题），`slow` = 耗时操作（如生成图片）
> - `SkillResult`：Skill 执行结果，成功返回 data，失败返回 error + code
> - `version`：语义化版本号字符串（如 "1.0.0"）

### 8.3 Agent 工作流

```
用户输入
    ↓
1. 意图理解（后端 AI 分类）
    ↓
2. 是否需要调 Skill？
    ├── 否 → 直接 AI 回复
    └── 是 → 3. 任务规划（后端 AI 规划步骤）
              ↓
         4. 逐步执行 Skill
              ├── auto 权限 → 直接执行
              └── confirm 权限 → 弹窗让用户确认
              ↓
         5. 汇总结果，AI 生成回复
```

### 8.4 后端 Skill 注入

后端通过 API 下发 Skill 定义，客户端动态注册：

```json
// GET /api/skills
{
  "skills": [
    {
      "id": "send_message",
      "name": "发送消息",
      "description": "给好友或群组发送文本消息",
      "channel": "slow",
      "permission": "confirm",
      "paramSchema": {
        "recipient_id": "string",
        "message": "string"
      },
      "endpoint": "/api/skills/send_message",
      "version": "1.0.0"
    }
  ]
}
```

---

## 九、定时任务规范

### 9.1 任务类型

| 类型 | 执行方 | 示例 |
|------|--------|------|
| 即时（< 1分钟） | 客户端 Timer | "5秒后提醒我" |
| 短期（1分钟 ~ 1小时） | 客户端 + 本地通知保底 | "10分钟后叫我起床" |
| 中期（1小时 ~ 1天） | 后端 Cron + 推送 | "今天下午3点开会" |
| 长期（> 1天） | 后端数据库 + Cron 扫描 | "一周后提醒我交报告" |
| 超长期（> 1月） | 后端数据库 + Cron 扫描 | "一年后续费" |
| 周期性 | 后端 Cron + 推送 | "每天早上9点提醒我"、"每周一开会" |

> 周期性任务通过 scheduled_tasks 表的 `recurrence_interval_ms` 字段实现，Cron Worker 每次执行后自动计算下次触发时间。

### 9.2 自然语言时间解析

后端 AI 解析自然语言为精确时间：

```
"5秒后"        → +5s
"10分钟后"     → +10min
"明天9点"      → 次日 09:00
"下周一下午3点" → 下周一 15:00
"一个月后"     → +30d
```

### 9.3 任务执行

定时任务触发时，不只是发通知，可以执行动作：

```json
{
  "id": "task_123",
  "trigger_at": "2026-05-30T09:00:00Z",
  "action": {
    "type": "notify_and_execute",
    "notify": { "title": "起床时间", "body": "该起床了！" },
    "execute": {
      "skill_id": "send_message",
      "params": { "recipient_id": "self", "message": "早上好！现在是9点，该起床了。" }
    }
  }
}
```

---

## 十、统一消息规范

### 10.1 消息模型

```dart
@freezed
class UnifiedMessage with _$UnifiedMessage {
  const factory UnifiedMessage({
    required String id,
    required String senderId,
    required String content,
    required MessageType type,
    required MessageFormat format,
    required DateTime timestamp,
    String? replyToId,
    String? sourceContext,
    @Default({}) Map<String, dynamic> metadata,
  }) = _UnifiedMessage;

  factory UnifiedMessage.fromJson(Map<String, dynamic> json) =>
      _$UnifiedMessageFromJson(json);
}

enum MessageType { aiChat, friendChat, groupChat, post, system }
enum MessageFormat { text, image, video, audio, file, card }
```

### 10.2 互通机制

```
AI 聊天 → 分享给好友：
  1. 用户长按 AI 消息 → 选"分享给好友"
  2. 弹出好友选择面板 (ShareToFriendSheet)
  3. 选好友 → ShareToFriendSkill.execute()
  4. 内部：复制消息内容 → 通过 Matrix 发给好友

好友消息 → 发给 AI：
  1. 用户长按好友消息 → 选"让 AI 分析"
  2. ShareToAISkill.execute()
  3. 内部：复制消息内容 → 插入 AI 对话上下文 → AI 分析
```

---

## 十一、UI 交互规范（v2.0 新增）

### 11.1 UI 布局原则

**核心布局框架保持不变。** 不做好友聊天和群组聊天的 UI 重构，只做底层架构和逻辑重构。AI 聊天区域允许采用新交互模式（详见第三十五章）。

现有布局（Telegram 风格）：
- 聊天列表页 = 联系人列表 = 历史聊天记录
- AI 聊天和好友聊天在同一列表中
- 点击进入聊天详情

重构只改底层：
- 状态管理从 ChangeNotifier → Bloc（UI 不变）
- 数据源从直接 Matrix SDK → ChatRepository（UI 不变）
- 消息模型统一为 UnifiedMessage（UI 不变）
- 新增互通功能（分享/AI分析）以菜单项形式加入现有长按菜单

### 11.2 新增交互（在现有 UI 上叠加）

| 操作 | 触发方式 | UI 响应 |
|------|---------|---------|
| AI 消息 → 好友 | 长按 AI 消息 → "分享给好友" | 弹出好友选择 Sheet，选好友后发送 |
| 好友消息 → AI | 长按好友消息 → "让 AI 分析" | 自动切换到 AI 对话，插入引用 |
| AI 消息 → 群组 | 长按 AI 消息 → "分享到群组" | 弹出群组选择 Sheet |
| 聊天记录 → AI | 聊天菜单 → "AI 总结" | AI 生成聊天摘要 |
| @AI | 在任何聊天输入 @AI | 触发 AI 回复 |

### 11.3 Skill 确认交互

```
Agent 需要执行 confirm 权限的 Skill 时：

┌─────────────────────────────┐
│  ⚠️ AI 请求执行操作          │
│                             │
│  发送消息给：张三            │
│  内容：明天下午3点开会        │
│                             │
│  ┌─────────┐  ┌──────────┐ │
│  │  拒绝   │  │  确认执行 │ │
│  └─────────┘  └──────────┘ │
└─────────────────────────────┘
```

### 11.4 定时任务交互

```
用户说："10分钟后叫我起床"

AI 回复：
┌─────────────────────────────────────┐
│  好的，我会在 10 分钟后提醒你起床。   │
│                                     │
│  ⏰ 10:10 起床提醒                   │
│  [取消] [修改时间]                   │
└─────────────────────────────────────┘
```

---

## 十二、瘦客户端规范

### 12.1 后端下发内容

| 内容 | API | 存储位置 | 更新频率 |
|------|-----|---------|---------|
| AI 模型列表 | GET /models | Supabase DB（非硬编码） | 新增模型时 |
| Skill 定义 | GET /api/skills | Supabase DB | 新增/修改 Skill 时 |
| 远程配置 | GET /config | Cloudflare KV | 实时 |
| UI Schema | GET /ui/schemas | Cloudflare KV | 版本更新时 |
| 权限策略 | GET /api/permissions | Cloudflare KV | 策略变更时 |
| 系统提示词 | 远程配置中 | Cloudflare KV | 运营调整时 |
| SSL Pin | GET /config/ssl-pins | Cloudflare KV | 证书更新时 |

### 12.2 模型列表改造方案（v2.0 新增）

**现状**：worker.js 中 `handleModels` 硬编码模型列表，根据环境变量过滤。

**目标**：模型配置存 Supabase DB，后端从数据库读取。

```sql
-- 新增模型配置表
CREATE TABLE model_configs (
  id TEXT PRIMARY KEY,           -- 'deepseek-v4-flash'
  name TEXT NOT NULL,            -- 'DeepSeek V4 Flash'
  provider TEXT NOT NULL,        -- 'deepseek'
  tier TEXT NOT NULL DEFAULT 'smart',  -- 'fast' / 'smart'
  enabled BOOLEAN DEFAULT true,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

```javascript
// worker.js 改造
async function handleModels(env) {
  const { data, error } = await supabase
    .from('model_configs')
    .select('*')
    .eq('enabled', true)
    .order('sort_order');
  return jsonResponse({ models: data || [] });
}
```

### 12.3 客户端不包含

- ❌ AI API Key
- ❌ 硬编码模型列表
- ❌ 硬编码 Skill 列表
- ❌ 业务逻辑判断（由后端 Agent 处理）
- ❌ 加密密钥

---

## 十三、类型安全规范（v2.0 新增）

### 13.1 freezed + json_serializable 强制使用

所有数据模型必须使用 `@freezed` + `@JsonSerializable`：

```dart
// ✅ 正确
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String email,
    String? displayName,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}

// ❌ 禁止
class UserModel {
  final String id;
  final String email;
  UserModel({required this.id, required this.email});
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(id: json['id'], email: json['email']); // 手写，容易出错
  }
}
```

### 13.2 消除 dynamic 的规则

| 场景 | 禁止 | 替代方案 |
|------|------|---------|
| 函数参数 | `dynamic value` | `T value`（泛型）或具体类型 |
| 变量声明 | `dynamic data` | 具体类型或 `Object?` |
| 集合 | `List<dynamic>` | `List<具体类型>` |
| 返回值 | `Future<dynamic>` | `Future<具体类型>` |
| Map | `Map<String, dynamic>` | 仅在 JSON 反序列化边界允许，立即转为 freezed 模型 |

### 13.3 analysis_options.yaml 完整配置

```yaml
include: package:very_good_analysis/analysis_options.yaml

analyzer:
  exclude:
    - build/**
    - '**/*.g.dart'
    - '**/*.freezed.dart'
  errors:
    avoid_dynamic_calls: error
    strict_raw_types: error
    invalid_annotation_target: ignore
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true

linter:
  rules:
    avoid_dynamic_calls: true
    strict_raw_types: true
    prefer_single_quotes: true
    always_declare_return_types: true
    avoid_unused_constructor_parameters: true
    cancel_subscriptions: true
    close_sinks: true
    prefer_const_constructors: true
    prefer_const_declarations: true
    prefer_final_fields: true
    prefer_final_locals: true
    require_trailing_commas: true
    use_key_in_widget_constructors: true
    avoid_print: true
    avoid_empty_else: true
    empty_catches: true
    unnecessary_import: true
    unused_import: true
    unused_local_variable: true
    unused_field: true
```

### 13.4 迁移优先级

| 优先级 | 模型 | 文件 |
|--------|------|------|
| P0 | UserModel | features/auth/data/models/ |
| P0 | SessionModel | features/auth/data/models/ |
| P0 | UnifiedMessage | features/chat/data/models/ |
| P0 | ChatRoom | features/chat/domain/entities/ |
| P1 | AgentModel | features/agent/domain/entities/ |
| P1 | Contact | features/contacts/domain/entities/ |
| P1 | ScheduledTask | features/tasks/data/models/ |
| P2 | QuickCommand | core/quick_command_service.dart |
| P2 | SessionMessage | core/session_provider.dart |
| P2 | ConversationMessage | core/agent/conversation_manager.dart |

---

## 十四、代码规范

### 14.1 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 文件名 | snake_case | `auth_bloc.dart` |
| 类名 | PascalCase | `AuthBloc` |
| 变量/函数 | camelCase | `currentUser` |
| 常量 | camelCase | `defaultTimeout` |
| 私有成员 | _前缀 | `_authRepository` |
| Bloc 事件 | PascalCase + 描述 | `AuthLoginRequested` |
| Bloc 状态 | PascalCase + 描述 | `AuthAuthenticated` |

### 14.2 文件大小限制

- 单个文件不超过 **500 行**
- Widget 文件不超过 **300 行**（超过就拆组件）
- Bloc 文件不超过 **400 行**（超过就拆事件/状态到单独文件）

### 14.3 CI 检查

```bash
flutter analyze --fatal-warnings --fatal-infos
flutter test
dart run build_runner build --delete-conflicting-outputs
```

---

## 十五、施工路线图

### Phase 0: 清理（预计 1-2 天）

| 序号 | 任务 | 验收标准 |
|------|------|---------|
| 0.1 | 修复 139 个 lint 问题 | `flutter analyze` 零错误零警告 |
| 0.2 | 删除未使用的 LoginPage（features/auth 版） | 编译通过 |
| 0.3 | 删除未使用的导入、变量、字段 | 无 unused 警告 |
| 0.4 | 合并 service_locator.dart 和 injection.dart 为 app/di.dart | 单一 DI 容器 |
| 0.5 | 更新 analysis_options.yaml 为 very_good_analysis | CI 可用 |
| 0.6 | 添加 very_good_analysis 依赖 | pubspec.yaml 更新 |

### Phase 1: 类型安全（预计 2-3 天）

| 序号 | 任务 | 验收标准 |
|------|------|---------|
| 1.1 | 为 P0 模型添加 @freezed + @JsonSerializable | build_runner 生成成功 |
| 1.2 | 迁移 UserModel、SessionModel | 旧手写代码删除 |
| 1.3 | 迁移 UnifiedMessage、ChatRoom | 统一消息模型可用 |
| 1.4 | 消除裸 dynamic（P0 文件） | 无 avoid_dynamic_calls 警告 |
| 1.5 | 修复 chat_repository_impl.dart 已知 Bug | 消息 ID 不为空、_readFile 实现 |

### Phase 2: 统一身份（预计 3-5 天）

| 序号 | 任务 | 验收标准 |
|------|------|---------|
| 2.1 | 后端：Supabase Auth Google/Apple/邮箱登录 | 可通过 API 注册/登录 |
| 2.2 | 后端：登录成功后自动创建 Matrix 账号 | 用户无感 |
| 2.3 | 后端：模型配置迁移到 Supabase DB | GET /models 从数据库读取 |
| 2.4 | 客户端：新登录页（Google/Apple/邮箱） | UI 完成 |
| 2.5 | 客户端：AuthBloc 对接 Supabase Auth | 登录/注册/恢复可用 |
| 2.6 | 客户端：Token 自动刷新 | 杀 APP 重开不失效 |
| 2.7 | 客户端：IdentityBridge 绑定到登录流程 | DID 随登录生成 |
| 2.8 | 删除旧 AuthRemoteDataSource 空壳 | 无残留 |

### Phase 3: 聊天系统统一（预计 5-7 天）

| 序号 | 任务 | 验收标准 |
|------|------|---------|
| 3.1 | 拆分 FriendChatPanel 为 10 个组件 | 每个文件 < 300 行 |
| 3.2 | ChatRepositoryImpl 统一 AI + 好友消息 | 单一数据源 |
| 3.3 | 修复发送消息返回空 ID Bug | eventId 正确返回 |
| 3.4 | 实现 _readFile（图片/文件/语音发送） | 文件消息可发送 |
| 3.5 | 实现 onTyping 流 | 打字指示器可用 |
| 3.6 | 统一 ChatBloc（AI + 好友） | 单一状态管理，UI 不变 |
| 3.7 | AppProvider 中聊天相关调用迁移到 ChatBloc | provider.matrix.xxx → ChatBloc |

### Phase 4: Skill 扩展（预计 5-7 天）

| 序号 | 任务 | 验收标准 |
|------|------|---------|
| 4.1 | 后端：Skill 定义下发 API | GET /api/skills 返回列表 |
| 4.2 | 后端：Skill 执行 API | POST /api/skills/:id/execute |
| 4.3 | 客户端：SendMessageSkill | AI 可发消息给好友 |
| 4.4 | 客户端：AddFriendSkill | AI 可加好友 |
| 4.5 | 客户端：SetReminderSkill | AI 可设定时任务 |
| 4.6 | 客户端：SwitchModelSkill | AI 可切模型 |
| 4.7 | 客户端：ShareToFriendSkill | AI 聊天可分享给好友（AI 指令触发，UI 入口在 Phase 6 补充） |
| 4.8 | 客户端：ShareToAISkill | 好友消息可发给 AI（AI 指令触发，UI 入口在 Phase 6 补充） |
| 4.9 | 客户端：SkillConfirmDialog | confirm 权限弹窗 |
| 4.10 | 客户端：RemoteSkill 动态注册 | 后端新增 Skill 客户端自动可用 |

### Phase 5: 定时任务升级（预计 3-5 天）

| 序号 | 任务 | 验收标准 |
|------|------|---------|
| 5.1 | 后端：Cron Worker 基础框架 | 可定时触发 |
| 5.2 | 后端：任务注册 API | 客户端可注册定时任务 |
| 5.3 | 后端：自然语言时间解析 | "明天9点" → 精确时间 |
| 5.4 | 后端：任务触发 + 推送 | 到时间推送通知 |
| 5.5 | 后端：任务触发 + 执行 Skill | 到时间执行动作 |
| 5.6 | 客户端：定时任务管理页 | 查看/取消/暂停任务 |

### Phase 6: 互通性完善（预计 3-5 天）

| 序号 | 任务 | 验收标准 |
|------|------|---------|
| 6.1 | AI 消息 → 好友聊天分享 | ShareToFriendSheet 可用 |
| 6.2 | 好友消息 → AI 分析 | 长按菜单有"让 AI 分析" |
| 6.3 | 聊天记录 → AI 总结 | 聊天菜单有"AI 总结" |
| 6.4 | AI 可在任何聊天被 @提及 | @AI 触发 AI 回复 |

### Phase 7: 瘦客户端深化（持续）

| 序号 | 任务 | 验收标准 |
|------|------|---------|
| 7.1 | 后端：Skill 动态注入 | 新增 Skill 不需发版 |
| 7.2 | 后端：模型列表动态下发 | 新增模型不需发版 |
| 7.3 | 后端：权限策略下发 | 权限变更不需发版 |
| 7.4 | RemoteUIEngine 扩展 | 支持更多组件类型 |

---

## 十六、后端 API 规范

### 16.1 认证 API

```
POST /v1/auth/register          # 邮箱注册
POST /v1/auth/login             # 邮箱登录
POST /v1/auth/login/google      # Google 登录
POST /v1/auth/login/apple       # Apple 登录
POST /v1/auth/logout            # 登出
POST /v1/auth/refresh           # 刷新 Token
GET  /v1/auth/me                # 当前用户信息
```

### 16.2 Skill API

```
GET  /api/skills             # 获取 Skill 列表
POST /api/skills/:id/execute # 执行 Skill
```

### 16.3 定时任务 API

```
POST /api/tasks              # 创建定时任务
GET  /api/tasks              # 获取任务列表
PUT  /api/tasks/:id          # 更新任务
DELETE /api/tasks/:id        # 删除任务
POST /api/tasks/parse-time   # 自然语言时间解析
```

### 16.4 现有 API（保留）

```
POST /ai/chat                # AI 聊天（Agent 模式）
POST /ai/classify            # 意图分类
POST /ai/plan                # 多步规划
POST /ai/reflect             # 反思
POST /ai/search              # 网页搜索
POST /ai/embed               # Embedding
POST /ai/transcribe          # 语音转文字
POST /ai/tts                 # 文字转语音
GET  /ai/memory              # 获取记忆
POST /ai/memory/store        # 存储记忆
GET  /models                 # 模型列表（改为从 DB 读取）
GET  /config                 # 远程配置
GET  /ui/schemas             # UI Schema
GET  /status                 # APP 状态
```

---

## 十七、数据库规范 (Supabase)

### 17.1 新增表

```sql
-- 用户表（id 引用 Supabase Auth 的 auth.users.id）
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  email TEXT UNIQUE,
  display_name TEXT,
  avatar_url TEXT,
  matrix_user_id TEXT,
  did TEXT,
  trust_level TEXT DEFAULT 'basic',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 模型配置表
CREATE TABLE model_configs (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  provider TEXT NOT NULL,
  tier TEXT NOT NULL DEFAULT 'smart',
  enabled BOOLEAN DEFAULT true,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 定时任务表
CREATE TABLE scheduled_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  title TEXT NOT NULL,
  description TEXT,
  trigger_at TIMESTAMPTZ NOT NULL,
  action JSONB NOT NULL,
  status TEXT DEFAULT 'active',
  recurrence_interval_ms BIGINT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Skill 定义表
CREATE TABLE skill_definitions (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  channel TEXT NOT NULL DEFAULT 'slow',
  permission TEXT NOT NULL DEFAULT 'confirm',
  param_schema JSONB NOT NULL DEFAULT '{}',
  endpoint TEXT NOT NULL,
  version TEXT NOT NULL DEFAULT '1.0.0',
  enabled BOOLEAN DEFAULT true,
  category TEXT NOT NULL DEFAULT 'system',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Skill 执行日志
CREATE TABLE skill_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  skill_id TEXT NOT NULL,
  params JSONB,
  result JSONB,
  success BOOLEAN,
  execution_time_ms INT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- AI 聊天消息表
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
  content TEXT NOT NULL,
  model_id TEXT,
  skill_executions JSONB,
  thinking_chain TEXT,
  parent_id UUID REFERENCES messages(id),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 用户设置表
CREATE TABLE user_settings (
  user_id UUID PRIMARY KEY REFERENCES users(id),
  theme TEXT NOT NULL DEFAULT 'system',
  language TEXT NOT NULL DEFAULT 'zh',
  default_model_id TEXT,
  ai_chat_mode TEXT NOT NULL DEFAULT 'pair',
  notifications_enabled BOOLEAN DEFAULT true,
  biometric_lock BOOLEAN DEFAULT false,
  auto_play_media BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

### 17.2 现有表（保留）

sessions, notes, memories, quick_commands — 保持不变，RLS 策略更新为使用 `auth.uid()` 而非 `matrix_user_id`。

---

## 十八、关键决策记录

| 决策 | 选择 | 理由 |
|------|------|------|
| Matrix 定位 | 降级为聊天管道 | 保留 E2E 加密聊天能力，但不再是身份中心 |
| 主认证 | Supabase Auth | 支持 Google/Apple/邮箱，自动 Token 刷新 |
| 状态管理 | flutter_bloc | 统一方案，可测试，可追踪 |
| DI 容器 | GetIt 单一实例 | 合并现有两个容器 |
| Skill 执行 | 客户端执行 + 后端定义 | 安全且灵活 |
| 定时任务 | 后端调度 + 推送 | APP 被杀也能执行 |
| 文件存储 | Cloudflare R2 | 与 Workers 同生态，低延迟 |
| 数据模型 | freezed + json_serializable | 编译期类型保障，消除手写序列化错误 |
| Lint 规则 | very_good_analysis | 比 flutter_lints 严格，含 avoid_dynamic_calls |
| 聊天系统 | 统一 ChatBloc + ChatRepositoryImpl | 消除两套并行系统 |
| 模型列表 | 存 Supabase DB | 新增模型不需改代码重新部署 |

## 十九、错误处理规范（v2.1 新增）

### 19.1 统一错误码

后端所有 API 返回统一错误格式：

```json
{
  "error": {
    "code": "AUTH_TOKEN_EXPIRED",
    "message": "登录已过期，请重新登录",
    "details": {}
  }
}
```

错误码分类：

| 前缀 | 范围 | 说明 |
|------|------|------|
| AUTH_xxx | 1000-1999 | 认证相关 |
| CHAT_xxx | 2000-2999 | 聊天相关 |
| SKILL_xxx | 3000-3999 | Skill 执行相关 |
| TASK_xxx | 4000-4999 | 定时任务相关 |
| SYSTEM_xxx | 5000-5999 | 系统级错误 |

关键错误码：

| 错误码 | HTTP 状态码 | 客户端行为 |
|--------|------------|-----------|
| AUTH_TOKEN_EXPIRED | 401 | 自动刷新 Token，重试请求 |
| AUTH_SESSION_INVALID | 401 | 跳转登录页 |
| AUTH_RATE_LIMITED | 429 | 显示"操作太频繁，请稍后再试" |
| CHAT_ROOM_NOT_FOUND | 404 | 显示"聊天不存在" |
| CHAT_MESSAGE_TOO_LONG | 400 | 显示"消息太长" |
| SKILL_PERMISSION_DENIED | 403 | 显示"无权限执行此操作" |
| SKILL_EXECUTION_FAILED | 500 | 显示"操作失败，请重试" |
| SKILL_TIMEOUT | 504 | 显示"操作超时" |
| TASK_INVALID_TIME | 400 | 显示"时间格式不正确" |
| SYSTEM_MAINTENANCE | 503 | 显示"系统维护中" |
| SYSTEM_FORCE_UPDATE | 426 | 弹出强制更新弹窗 |

### 19.2 客户端错误处理策略

```dart
class AppErrorHandler {
  static Failure handleHttpError(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final error = body['error'] as Map<String, dynamic>?;
    final code = error?['code'] as String? ?? 'UNKNOWN';
    final message = error?['message'] as String? ?? '未知错误';
    switch (code) {
      case 'AUTH_TOKEN_EXPIRED':
        return AuthFailure(code: code, message: message);
      case 'AUTH_SESSION_INVALID':
        return AuthFailure(code: code, message: message);
      default:
        return ServerFailure(code: code, message: message);
    }
  }

  static Failure handleException(Object error) {
    if (error is http.ClientException) {
      return NetworkFailure(message: '网络连接失败');
    }
    if (error is TimeoutException) {
      return NetworkFailure(message: '请求超时');
    }
    return UnknownFailure(message: error.toString());
  }
}
```

### 19.3 用户提示规范

| 错误类型 | 提示方式 | 示例 |
|---------|---------|------|
| 网络断开 | SnackBar + 重试按钮 | "网络连接失败 [重试]" |
| 认证过期 | 静默刷新 | 用户无感 |
| 业务错误 | SnackBar | "消息发送失败" |
| 系统维护 | 全屏遮罩 | "系统维护中，预计 10:00 恢复" |
| 强制更新 | 全屏弹窗 | "发现新版本，请更新" |
| Skill 确认 | 确认弹窗 | "AI 请求发送消息给张三" |

---

## 二十、离线支持规范（v2.1 新增）

### 20.1 离线优先策略

```
用户操作
    ↓
写入本地数据库（sqflite）
    ↓
网络可用？──是──→ 同步到服务器
    │
    否
    ↓
标记为 pending，等网络恢复后同步
```

### 20.2 离线可用功能

| 功能 | 离线可用 | 说明 |
|------|---------|------|
| 查看聊天历史 | ✅ | 本地数据库缓存 |
| 查看联系人 | ✅ | 本地缓存 |
| 发送文本消息 | ✅ | 存入 outbox，上线后发送 |
| AI 聊天 | ❌ | 需要网络 |
| 搜索 | ❌ | 需要网络 |
| 设置 | ✅ | 本地操作 |
| 定时任务查看 | ✅ | 本地缓存 |

### 20.3 数据同步

```dart
class SyncService {
  // 网络恢复时自动同步
  void onNetworkRestored() {
    _flushOutbox();       // 发送离线消息
    _syncChatHistory();   // 同步聊天历史
    _syncContacts();      // 同步联系人
    _syncScheduledTasks(); // 同步定时任务
  }
}
```

### 20.4 冲突解决

| 冲突类型 | 策略 | 说明 |
|---------|------|------|
| 消息冲突 | 服务器优先 | 以服务器时间戳为准 |
| 联系人冲突 | 最后写入胜 | 以最新修改为准 |
| 设置冲突 | 服务器优先 | 远程配置覆盖本地 |

---

## 二十一、安全规范（v2.1 新增）

### 21.1 传输安全

- 所有 API 通信强制 HTTPS
- SSL Pinning：关键域名配置证书指纹（已实现）
- WebSocket 使用 WSS

### 21.2 存储安全

| 数据类型 | 存储方式 | 说明 |
|---------|---------|------|
| Token | flutter_secure_storage | 硬件级加密 |
| DID 密钥对 | flutter_secure_storage | 硬件级加密 |
| 聊天缓存 | sqflite | 当前不加密，后续可升级为 sqflite_sqlcipher |
| 用户设置 | SharedPreferences | 非敏感数据 |
| 文件缓存 | 临时目录 | 自动清理 |

### 21.3 API 安全

- 所有 API 请求携带 JWT Token（Supabase Auth 自动管理）
- Matrix API 请求携带 Matrix Access Token
- 后端验证 Token：聊天相关 API 验证 Supabase JWT + Matrix Token；其他 API 仅验证 Supabase JWT
- 请求签名：关键操作（转账/删除）需要额外签名

### 21.4 内容安全

- AI 输出内容过滤（后端处理）
- 用户举报机制（后续）
- 敏感内容检测（后续）

### 21.5 防护措施

| 攻击类型 | 防护 | 说明 |
|---------|------|------|
| 重放攻击 | 请求时间戳 + Nonce | 后端验证 |
| 中间人攻击 | SSL Pinning | 已实现 |
| 暴力破解 | 限流（已有） | Cloudflare Workers 限流 |
| Token 泄露 | 短有效期 + 自动刷新 | Supabase Auth 管理 |
| 数据篡改 | JWT 签名验证 | 后端验证 |

---

## 二十二、数据迁移方案（v2.1 新增）

### 22.1 迁移范围

| 数据 | 当前存储 | 迁移目标 | 方式 |
|------|---------|---------|------|
| 用户身份 | Matrix Synapse | Supabase Auth | 后端自动迁移 |
| 聊天消息 | Matrix Synapse | 不变 | 无需迁移 |
| 会话数据 | Supabase (matrix_user_id) | Supabase (auth.uid) | RLS 策略更新 |
| 记忆 | Supabase (matrix_user_id) | Supabase (auth.uid) | RLS 策略更新 |
| 快捷命令 | Supabase (matrix_user_id) | Supabase (auth.uid) | RLS 策略更新 |

### 22.2 迁移步骤

```
1. 开启 Supabase Auth
2. 创建 users 表，关联 matrix_user_id 和 auth.uid
3. 现有用户首次登录时：
   a. Supabase Auth 创建账号（邮箱 = Matrix 绑定邮箱）
   b. 后端查找 matrix_user_id → 写入 users 表
   c. 更新 sessions/notes/memories 的 RLS 策略
4. 新用户：直接走 Supabase Auth 注册 → 自动创建 Matrix 账号
```

### 22.3 回滚方案

- 保留 Matrix 登录入口 30 天
- 如果 Supabase Auth 出问题，可切回 Matrix 登录
- 30 天后移除 Matrix 登录入口

---

## 二十三、测试策略（v2.1 新增）

### 23.1 测试层级

| 层级 | 工具 | 覆盖率目标 | 说明 |
|------|------|-----------|------|
| 单元测试 | flutter_test + mocktail | ≥ 70% | Bloc、Repository、UseCase、Skill |
| Widget 测试 | flutter_test | ≥ 50% | 关键页面和组件 |
| 集成测试 | integration_test | 核心流程 | 登录、发消息、AI 聊天 |
| 后端测试 | Vitest | ≥ 60% | API 端点、Skill 执行 |

### 23.2 必须有测试的模块

| 模块 | 测试类型 | 说明 |
|------|---------|------|
| AuthBloc | 单元测试 | 登录/注册/恢复/登出 |
| ChatBloc | 单元测试 | 发消息/收消息/切换会话 |
| Skill 执行 | 单元测试 | 每个 Skill 的 execute |
| ChatRepositoryImpl | 单元测试 | AI 消息 + 好友消息 |
| 登录流程 | 集成测试 | 完整登录流程 |
| 发消息 | 集成测试 | 文本/图片/文件 |

### 23.3 CI 流水线

```bash
# 每次 PR 必须通过
flutter analyze --fatal-warnings --fatal-infos
flutter test --coverage
dart run build_runner build --delete-conflicting-outputs

# 合并到 main 分支
flutter test --coverage
# 覆盖率 < 70% 则失败
```

---

## 二十四、监控与可观测性（v2.1 新增）

### 24.1 客户端监控

| 指标 | 采集方式 | 说明 |
|------|---------|------|
| 崩溃率 | Firebase Crashlytics（需添加依赖） | < 0.1% 目标 |
| ANR 率 | Firebase Performance（需添加依赖） | < 0.5% 目标 |
| API 延迟 | 客户端打点 | P99 < 3s |
| 登录成功率 | 客户端打点 | > 99% |
| 消息发送成功率 | 客户端打点 | > 99.9% |

### 24.2 后端监控

| 指标 | 采集方式 | 说明 |
|------|---------|------|
| API 响应时间 | Cloudflare Analytics | P99 < 2s |
| 错误率 | Cloudflare Analytics | < 0.1% |
| AI 调用延迟 | Worker 日志 | P99 < 5s |
| Skill 执行成功率 | Supabase skill_logs | > 99% |
| 定时任务执行率 | Cron Worker 日志 | > 99.9% |

### 24.3 告警

| 告警 | 阈值 | 通知方式 |
|------|------|---------|
| API 错误率 > 1% | 触发 | 邮件 + 推送 |
| 登录成功率 < 95% | 触发 | 邮件 + 推送 |
| AI 调用延迟 P99 > 10s | 触发 | 邮件 |
| 崩溃率 > 0.5% | 触发 | 邮件 + 推送 |

---

## 二十五、版本兼容性规范（v2.1 新增）

### 25.1 API 版本管理

- 新增 API 使用版本号前缀：`/v1/auth/login`
- 现有 API 暂不加前缀，保持 `/ai/chat`、`/models` 等路径不变
- 后续重构时逐步迁移现有 API 到 `/v1/` 前缀
- 客户端请求头携带版本号：`X-App-Version: 2.0.0`

### 25.2 客户端强制更新

```json
// GET /config 返回
{
  "minimum_version": "1.5.0",
  "latest_version": "2.0.0",
  "force_update": false
}
```

- 客户端启动时检查版本
- 当前版本 < minimum_version → 强制更新弹窗，不可关闭
- 当前版本 < latest_version → 可选更新提示

### 25.3 数据库迁移

- Supabase 使用 migration 脚本管理 schema 变更
- 客户端 sqflite 使用版本号管理本地 schema
- 每次升级必须提供回滚脚本

---

## 二十六、文档体系治理（v3.0 新增）

### 26.1 文档层级

| 层级 | 文档 | 权威性 | 说明 |
|------|------|--------|------|
| **L0 唯一权威** | SPEC.md（本文档） | 最高 | 重构的唯一参考，与其他文档冲突时以本文档为准 |
| **L1 架构参考** | RUNTIME_ARCHITECTURE.md | 高 | Runtime 微内核设计，Vocabulary 和铁律已 FROZEN，不可违反 |
| **L2 进度追踪** | AUDIT.md | 中 | 项目进度追踪，数据必须与 SPEC.md 对齐 |
| **L3 外部参考** | TELEGRAM_AUDIT.md / REFERENCE.md / OMNIVIUM_AUDIT.md | 低 | 纯参考，不影响项目架构 |

### 26.2 已废弃文档

| 文档 | 处理 | 理由 |
|------|------|------|
| ISSUES.md | 🗑️ 废弃 | 所有问题已在 SPEC.md 覆盖 |
| DEPLOY_CHECKLIST.md | 🔄 合并到本文档第二十七节 | 避免独立文档过时 |
| PROJECT_PLAN.md | 🔄 仅保留页面清单，架构部分废弃 | 与 SPEC.md 架构冲突 |

### 26.3 AUDIT.md 数据校准

AUDIT.md 声称 `flutter analyze = 0 Error / 0 Warning / 0 Info`，但实际运行结果为 **67 error / 45 warning / 27 info = 139 issues**。AUDIT.md 的数据需要以实际 `flutter analyze` 输出为准重新校准。

### 26.4 RUNTIME_ARCHITECTURE.md 与 SPEC.md 的关系

- SPEC.md 是**实现层**唯一权威；RUNTIME_ARCHITECTURE.md 的铁律和 Vocabulary 是**不可违反的底层约束**
- 当 SPEC.md 的实现细节与 RUNTIME_ARCHITECTURE.md 的铁律冲突时，以铁律为准；其他冲突以 SPEC.md 为准
- SPEC.md 的 Skill 系统是 RUNTIME_ARCHITECTURE.md Capability 系统的应用层封装（详见第二十八节）
- RUNTIME_ARCHITECTURE.md 的 Plugin Contract 是底层协议，SPEC.md 的 Bloc/Repository 是上层实现
- "文明内核"（ConstitutionalGuard/CivilizationKernel）当前为空壳，暂不纳入重构范围

---

## 二十七、部署检查清单（v3.0 新增，合并自 DEPLOY_CHECKLIST.md）

### 27.1 上架前必须完成

| 序号 | 任务 | 状态 | 说明 |
|------|------|------|------|
| 1 | 生成签名密钥库 | ❌ | `keytool -genkey -v -keystore upload-keystore.jks` |
| 2 | 填写 key.properties | ❌ | storePassword/keyPassword/storeFile/keyAlias |
| 3 | 下载 Firebase 配置文件 | ❌ | google-services.json + GoogleService-Info.plist |
| 4 | 放入应用图标源文件 | ❌ | 1024×1024 主图标 + 前景 |
| 5 | 注册开发者账号 | ❌ | Google Play ($25) + Apple Developer ($99/年) |
| 6 | 部署隐私政策和服务条款 | ❌ | https://omnivium.app/privacy + /terms |
| 7 | 配置自定义 API 域名 | ❌ | workers.dev → api.omnivium.app |
| 8 | 预置 SSL Pinning 证书哈希 | ❌ | 获取 api.omnivium.app 的 SHA-256 指纹 |
| 9 | 执行 supabase-schema.sql | ❌ | 创建所有数据库表 |
| 10 | 部署 LiveKit SFU 服务器 | ❌ | 群组通话功能依赖（Phase 5+） |

### 27.2 安全加固检查

| 检查项 | 状态 |
|--------|------|
| SSL Pinning 框架就绪 | ✅ |
| API Key 已迁移到服务端代理 | ✅ |
| Root/越狱检测已启用 | ✅ |
| 代码混淆构建已验证 | ✅ |
| ProGuard 规则已测试 | ✅ |
| 敏感字符串已加密 | ✅ |
| 网络请求全部 HTTPS | ✅ |
| 本地敏感数据使用 flutter_secure_storage | ✅ |
| 应用层加密 AES-256-GCM | ✅ |
| HMAC 请求签名 + 时间戳防重放 | ✅ |
| Matrix Token 服务端验证 | ✅ |
| 两步验证 TOTP | ✅ |
| 推送载荷加密 | ✅ |
| 应用锁 PIN + 生物识别 | ✅ |
| 加密文件存储 AES-256 | ✅ |
| SRP 安全远程密码 | ✅ |
| 截屏/录屏保护框架 | ✅ |
| SSL Pinning 真实证书 hash | ❌ 待配置 |

---

## 二十八、Skill 与 Capability 对齐方案（v3.0 新增）

### 28.1 映射关系

SPEC.md 的 Skill 是应用层概念，RUNTIME_ARCHITECTURE.md 的 Capability 是 Runtime 层概念。

| Skill（应用层） | Capability（Runtime 层） | 说明 |
|-----------------|-------------------------|------|
| SendMessageSkill | message.send | 发送消息 |
| ReadMessageSkill | message.receive | 读取消息 |
| AddFriendSkill | auth.verify + message.send | 添加好友 = 验证身份 + 发送邀请 |
| CreateGroupSkill | message.send (group) | 创建群聊 |
| AutoReplySkill | message.send (auto) | 自动回复 |
| SwitchModelSkill | agent.execute | 切换 AI 模型 |
| GenerateImageSkill | media.image | 生成图片 |
| AnalyzeConversationSkill | memory.search + memory.read | 分析对话 |
| SetReminderSkill | notification.push + config.set | 设定提醒 |
| CancelReminderSkill | config.set | 取消提醒 |
| SwitchThemeSkill | config.set | 切换主题 |
| ShareToFriendSkill | message.send | 分享给好友 |
| ShareToAISkill | memory.write + agent.chat | 分享给 AI |
| WebSearchSkill | search.web | 网页搜索 |
| CreatePostSkill | media.image + message.send | 发布动态 |
| CreateWorkflowSkill | workflow.create | 创建工作流 |
| StartCallSkill | message.call | 发起语音/视频通话 |
| ReactionSkill | message.react | 添加消息反应 |

### 28.2 Skill 调用链

```
用户输入 → AgentOrchestrator
  → SkillRegistry.lookup(skillId)
  → Skill.execute(params)
    → CapabilityRouter.route(capabilityId)
      → PluginHandler.invokeCapability()
        → 具体 Service 调用（MatrixService / ApiProxyService / ...）
```

### 28.3 Skill 是 Capability 的应用层封装

- Skill 知道"用户想做什么"（发消息给张三）
- Capability 知道"系统怎么执行"（message.send to roomId:xxx）
- Skill 负责参数转换（用户名 → roomId）、权限检查（confirm/auto）、结果格式化
- Capability 负责路由、隔离、超时、重试

---

## 二十九、E2EE 加密流程规范（v3.0 新增）

### 29.1 当前加密架构

Matrix 默认启用 Megolm + Vodozemac 端到端加密。所有私聊和群聊消息在传输前加密，只有参与者能解密。

### 29.2 Supabase Auth 迁移后的加密兼容

**关键问题**：Supabase Auth 登录后自动创建 Matrix 账号，但 Matrix 的加密密钥绑定在 Matrix 设备上。

**解决方案**：

```
Supabase Auth 登录成功
  ↓
后端用共享密钥调用 Synapse Admin API 创建 Matrix 账号
  ↓
客户端用 Matrix SDK 登录（后端返回 Matrix 凭据）
  ↓
Matrix SDK 自动处理 Megolm 密钥交换
  ↓
E2EE 正常工作
```

**关键约束**：
- Matrix 用户 ID（如 `@user:server`）必须与 Supabase 用户 ID 关联（存储在 users 表的 matrix_user_id 字段）
- Matrix 设备 ID 由客户端生成，用于 E2EE 密钥管理，一个用户可有多个设备
- 加密密钥备份使用 Matrix 的密钥备份机制（不是 Supabase）
- AI 无法读取 E2EE 加密消息（这是设计决策，不是 Bug）
- AI 只能读取用户主动分享给 AI 的消息（通过 ShareToAISkill，此时消息已解密）

### 29.3 AI 与 E2EE 的边界

| 场景 | AI 可读 | 说明 |
|------|---------|------|
| AI 聊天消息 | ✅ | 不走 Matrix E2EE，走后端 Agent API |
| 好友聊天消息（未分享） | ❌ | E2EE 加密，AI 无法读取 |
| 好友聊天消息（用户主动分享） | ✅ | 用户通过 ShareToAISkill 解密后分享 |
| 群聊消息 | ❌ | 同私聊，E2EE 加密 |
| 定时任务执行结果 | ✅ | 由后端执行，不涉及 E2EE |

---

## 三十、完整服务迁移映射（v3.0 新增）

### 30.1 现有 60+ 服务文件迁移方案

| 现有服务 | 迁移目标 | 迁移方式 | Phase |
|---------|---------|---------|-------|
| AppProvider | 拆分为多个 Bloc | 逐步迁移（见 7.4） | 0-7 |
| MatrixProvider | 降级为数据层 | 去掉 notifyListeners | 2-3 |
| MatrixService | 保留，被 ChatRepository 封装 | 不变 | 3 |
| AgentOrchestrator | 保留，被 AI ChatBloc 使用 | 去掉 notifyListeners | 4 |
| ModelProvider | 保留，被 AgentBloc 使用 | 去掉 notifyListeners | 4 |
| SessionProvider | 保留，被 SessionManager 代理 | 不变 | 2 |
| AuthService | 重写，对接 Supabase Auth | 新建 AuthRepositoryImpl | 2 |
| ApiProxyService | 保留 | 不变 | - |
| CallService | 统一为现有 CallBloc，删除 CallService + CallScreen | 重构 | 3 |
| VoiceService | 保留 | 不变 | - |
| EncryptionService | 保留 | 不变 | - |
| PushNotificationService | 保留，新建 NotificationBloc | 新建 Bloc | 4 |
| DatabaseService | 保留（Hive），新增 sqflite 层 | 渐进迁移 | 5 |
| SecureStorageService | 保留 | 不变 | - |
| NetworkSecurityService | 保留 | 不变 | - |
| AppLockService | 保留 | 不变 | - |
| BiometricService | 保留 | 不变 | - |
| DeepLinkService | 保留，对接 go_router | 修改路由 | 2 |
| LinkPreviewService | 保留 | 不变 | - |
| RemoteConfigService | 保留 | 不变 | - |
| FileDownloadService | 保留 | 不变 | - |
| NoteService | 保留，新建 NoteBloc | 新建 Bloc | 5 |
| QuickCommandService | 保留，新建 QuickCommandBloc | 新建 Bloc | 5 |
| LiteMode | 保留 | 不变 | - |
| LruCache | 保留 | 不变 | - |
| NavigationProvider | 删除，用 go_router 替代 | 新建 router.dart | 2 |
| NotificationCenter | 保留，跨 Bloc 通信用 | 不变 | - |
| ServiceLocator | 合并到 app/di.dart | 合并 | 0 |
| IdentityBridge | 保留，绑定到 AuthBloc | 不变 | 2 |
| OmniviumSDK | 保留，作为 Agent Runtime 层 | 不变 | - |
| CapabilityRouter | 保留，Skill 通过它路由 | 不变 | - |
| AnalyticsService | 保留 | 不变 | - |
| AuditLogService | 保留 | 不变 | - |
| HapticService | 保留 | 不变 | - |
| PermissionService | 保留 | 不变 | - |
| PrivacyConsentService | 保留 | 不变 | - |
| TotpService | 保留 | 不变 | - |
| PasswordKeyService | 保留 | 不变 | - |
| SupabaseSyncService | 保留，RLS 策略更新 | 更新 RLS | 2 |
| SessionManager | 保留 | 不变 | - |
| RemoteUIEngine | 保留 | 不变 | 7 |
| AppNavigator | 删除，用 go_router 替代 | 新建 router.dart | 2 |
| FileLog | 保留 | 不变 | - |
| AppLogger | 保留 | 不变 | - |
| ConnectivityService | 保留 | 不变 | - |
| SecurityCheckService | 保留 | 不变 | - |
| SecureFlagService | 保留 | 不变 | - |
| EncryptedFileStorage | 保留 | 不变 | - |

### 30.2 Runtime 子系统处理

| 组件 | 处理 | 说明 |
|------|------|------|
| RuntimeKernel | 保留框架 | 作为 Agent 的 Runtime 层 |
| PluginRegistry | 保留框架 | Skill 注册为 Plugin |
| CapabilityRouter | 保留 | Skill 通过它路由 |
| EventBus | 保留 | 跨 Bloc 通信 |
| Scheduler | 保留 | 定时任务调度 |
| Governance | 保留框架 | 暂不迁移 |
| Distributed | 保留框架 | 暂不迁移 |
| Sandbox (WASM) | 保留框架 | 暂不迁移 |
| Observability | 保留 | 与 Firebase 互补 |
| CivilizationKernel | 保留框架 | 暂不迁移 |

---

## 三十一、风险评估与应对（v3.0 新增）

### 31.1 高风险项

| 风险 | 影响 | 概率 | 应对方案 |
|------|------|------|---------|
| Supabase Auth + Matrix 账号关联失败 | 用户无法聊天 | 中 | 保留 Matrix 登录入口 30 天作为回滚 |
| FriendChatPanel 拆分导致功能回归 | 聊天功能不可用 | 高 | 每个 Phase 完成后必须全量回归测试 |
| AppProvider 迁移导致全局状态丢失 | APP 崩溃 | 高 | 逐步迁移，每步可回滚 |
| freezed 迁移导致 JSON 反序列化失败 | 数据丢失 | 中 | 先加测试再迁移 |
| Matrix SDK 版本不兼容 | 编译失败 | 低 | 锁定 matrix: ^7.1.2 |

### 31.2 回滚策略

| Phase | 回滚点 | 方式 |
|-------|--------|------|
| Phase 0 | lint 清理前 | git revert |
| Phase 1 | freezed 迁移前 | 保留旧手写 model，新 model 并行 |
| Phase 2 | Supabase Auth 上线前 | 保留 Matrix 登录入口 |
| Phase 3 | FriendChatPanel 拆分前 | 保留旧 Panel，新组件并行 |
| Phase 4 | Skill 上线前 | Skill 可独立禁用 |
| Phase 5-7 | 各功能独立 | 功能开关控制 |

### 31.3 每个 Phase 的验收标准（具体化）

| Phase | 验收命令 | 预期输出 |
|-------|---------|---------|
| 0 | `flutter analyze` | 0 error, 0 warning |
| 0 | `flutter test` | 全部通过 |
| 1 | `dart run build_runner build` | 生成 .freezed.dart 和 .g.dart 无报错 |
| 1 | `grep -r "dynamic" lib/ --include="*.dart" \| wc -l` | < 50（从 559 降低） |
| 2 | 手动测试：Google 登录 → 进主界面 → 发消息 | 全流程通过 |
| 2 | 杀 APP 重开 → 自动恢复登录 | 不需要重新登录 |
| 3 | 好友聊天发文本/图片/语音 | 全部正常 |
| 3 | AI 聊天 → 好友聊天切换 | 无崩溃 |
| 4 | AI 说"给张三发消息" → 弹确认框 → 发送成功 | 全流程通过 |
| 5 | AI 说"10分钟后提醒我" → 10分钟后收到通知 | 全流程通过 |

---

## 三十二、Phase 时间修正（v3.0 新增）

> 原 v2.1 的时间估算过于乐观，以下为修正后的现实估算。

| Phase | 原估算 | 修正估算 | 修正理由 |
|-------|--------|---------|---------|
| Phase 0: 清理 | 1-2 天 | 3-5 天 | 139 个 lint 问题 + 合并 DI + 更新 analysis_options |
| Phase 1: 类型安全 | 2-3 天 | 5-7 天 | 10 个模型迁移 + 消除 559 个 dynamic + 修复已知 Bug |
| Phase 2: 统一身份 | 3-5 天 | 7-10 天 | 后端 Supabase Auth + Matrix 关联 + 客户端登录页 + Token 刷新 |
| Phase 3: 聊天统一 | 5-7 天 | 10-14 天 | FriendChatPanel 2600行拆分 + ChatRepository 统一 + 修复 Bug |
| Phase 4: Skill 扩展 | 5-7 天 | 10-14 天 | 后端 Skill API + 10 个 Skill 实现 + 确认弹窗 |
| Phase 5: 定时任务 | 3-5 天 | 7-10 天 | 后端 Cron + 自然语言解析 + 推送 + 客户端管理页 |
| Phase 6: 互通性 | 3-5 天 | 5-7 天 | 分享/分析/总结/@AI |
| Phase 7: 瘦客户端 | 持续 | 持续 | 渐进式 |

**总估算**：原 22-39 天 → 修正 47-67 天（约 2-3 个月）

---

## 三十三、跨 Bloc 通信规范（v3.0 新增）

### 33.1 通信方式

| 场景 | 方式 | 说明 |
|------|------|------|
| Bloc → Bloc（父子） | 通过 Widget 层传递 Event | 父 Bloc 监听子 Bloc 的 Stream |
| Bloc → Bloc（兄弟） | 通过 NotificationCenter 中转 | 现有 45 种事件，逐步迁移为 Bloc Event |
| Bloc → Service | 直接调用 Service 方法 | Service 是无状态的 |
| Service → Bloc | 通过 NotificationCenter 发事件 | Bloc 监听事件转为 State |

### 33.2 NotificationCenter 迁移计划

NotificationCenter 当前有 45 种事件，不是全部都需要迁移为 Bloc Event。

| 事件类型 | 迁移方案 | 说明 |
|---------|---------|------|
| 认证相关（loginSuccess/logout） | 迁移为 AuthBloc Event | Phase 2 |
| 聊天相关（newMessage/typing） | 迁移为 ChatBloc Event | Phase 3 |
| 通知相关（pushReceived） | 迁移为 NotificationBloc Event | Phase 4 |
| 系统相关（networkChange） | 保留 NotificationCenter | 全局事件，不适合单个 Bloc |

---

## 三十四、Hive → sqflite 迁移策略（v3.0 新增）

### 34.1 现状

- 当前本地数据库使用 Hive（键值存储，AES-CBC 加密）
- SPEC.md 规范要求使用 sqflite（关系型数据库）
- 两者不兼容，需要渐进迁移

### 34.2 迁移方案

| 阶段 | 操作 | 说明 |
|------|------|------|
| Phase 0-2 | 保留 Hive，不迁移 | 稳定优先 |
| Phase 3 | 新增 sqflite，用于聊天消息缓存 | Hive 保留用于设置/快捷命令 |
| Phase 5 | sqflite 扩展：定时任务、联系人缓存 | Hive 保留 |
| Phase 7 | 评估是否完全迁移到 sqflite | 按需决定 |

**原则**：不强制一次性替换 Hive，新功能用 sqflite，旧功能保持不变。

---

## 三十五、AI 聊天 UI 规范（v3.1 新增）

### 35.1 "最新消息对"显示模式

AI 聊天采用**单轮对话聚焦模式**，与传统的全量消息列表不同：

| 特性 | 传统模式（好友聊天） | AI 聊天模式 |
|------|---------------------|------------|
| 显示范围 | 全部消息 | 仅最新一轮（用户消息 + AI 回复） |
| 滚动行为 | 自由上下滚动 | 默认显示最新，上滑查看历史 |
| 消息对 | 每条消息独立 | 用户消息 + AI 回复为一组 |
| 长消息 | 正常展开 | 正常展开，可上下滚动 |
| 历史消息 | 始终可见 | 上滑渐入，松手回弹 |

### 35.2 交互细节

```
┌─────────────────────────┐
│  [上滑查看历史消息...]     │  ← 半透明提示，上滑展开
├─────────────────────────┤
│                         │
│  👤 用户：帮我分析一下...  │  ← 用户消息
│                         │
│  🤖 AI：好的，我来分析...  │  ← AI 回复（可长可短）
│  [思考链] [操作栏]        │  ← AI 专属组件
│                         │
├─────────────────────────┤
│  [输入框] [发送]          │
└─────────────────────────┘
```

- 用户发送新消息时，上一轮对话自动收起到历史
- 上滑时历史对话以半透明遮罩渐入，松手回弹到最新轮
- AI 回复如果是长消息，在消息对内部正常滚动
- 消息对之间有明确的时间分隔线
- 流式生成时，AI 回复实时追加，光标闪烁

### 35.3 数据模型

AiConversationTurn 是 **UI 展示模型**，由两条 UnifiedMessage（一条 type=aiChat 的用户消息 + 一条 AI 回复消息）聚合而成。存储层始终使用 UnifiedMessage。

```dart
@freezed
class AiConversationTurn with _$AiConversationTurn {
  const factory AiConversationTurn({
    required String id,
    required String userMessage,
    required String aiMessage,
    required DateTime timestamp,
    String? thinkingChain,
    List<SkillExecution>? skillExecutions,
    String? modelUsed,
  }) = _AiConversationTurn;

  factory AiConversationTurn.fromJson(Map<String, dynamic> json) =>
      _$AiConversationTurnFromJson(json);
}
```

### 35.4 实现优先级

此 UI 模式复杂度高，建议在 Phase 4（Skill 扩展）之后单独实现。当前阶段先保持传统消息列表模式。

---

## 三十六、用户登录→聊天全流程规范（v3.1 新增）

### 36.1 Google 登录流程

```
用户点击 "Google 登录"
  ↓
Supabase Auth signInWithProvider(google)
  ↓
后端触发 onUserCreated 钩子
  ↓
  ├→ 创建 users 表记录（id, email, display_name, avatar_url, matrix_user_id）
  ├→ 调用 Synapse Admin API 注册 Matrix 账号（用户名 = supabase_id 前8位）
  ├→ 将 matrix_user_id 写入 users 表
  └→ 创建默认 AI 聊天室（1:1 with AI Agent）
  ↓
客户端收到 Supabase session + Matrix 凭据
  ↓
Matrix SDK 登录（自动）
  ↓
进入主界面（聊天列表页）
```

### 36.2 邮箱注册/登录流程

```
用户输入邮箱 + 密码
  ↓
Supabase Auth signUp / signInWithPassword
  ↓
（注册时）发送验证邮件 → 用户点击链接 → 邮箱验证完成
  ↓
同上后端钩子流程
```

### 36.3 登录后立即可用

用户登录成功后，**无需额外操作**即可：

| 功能 | 可用性 | 说明 |
|------|--------|------|
| AI 聊天 | ✅ 立即可用 | 自动创建 AI 聊天室 |
| 搜索用户 | ✅ 立即可用 | Matrix 用户目录搜索 |
| 发送好友请求 | ✅ 立即可用 | 搜索后点击添加 |
| 创建群组 | ✅ 立即可用 | 选择好友创建 |
| 加入群组 | ✅ 立即可用 | 通过邀请链接 |
| 浏览广场 | ✅ 立即可用 | 公开内容无需好友 |

### 36.4 好友添加流程

| 方式 | 操作 | 实现 |
|------|------|------|
| 搜索添加 | 搜索用户名/ID → 点击添加 → 对方收到请求 | ✅ 已实现 |
| 链接添加 | 分享 omnivium://user/xxx 链接 → 打开 → 添加 | ✅ 已实现 |
| QR 码添加 | 扫描二维码 → 添加 | ⏳ 待实现 |
| 通讯录匹配 | 上传通讯录 → 匹配已注册用户 | ⏳ 待实现 |

### 36.5 群组创建与加入

| 操作 | 流程 | 权限 |
|------|------|------|
| 创建群组 | 点击 + → 创建群组 → 选成员 → 设群名/描述/头像 → 创建 | 任何用户 |
| 邀请链接加入 | 点击链接 → 查看群信息 → 加入 | 任何用户（链接有效期内） |
| 好友邀请加入 | 群内成员 → 邀请 → 对方收到邀请 | 群成员（受群权限控制） |
| QR 码加入 | 扫描群二维码 → 加入 | 任何用户 |

---

## 三十七、群组高级功能规范（v3.1 新增）

> 参考 Telegram 群组功能设计，结合 AI 原生特性。

### 37.1 角色权限体系

| 角色 | 权限 |
|------|------|
| **Owner** | 全部权限 + 转让群主 + 解散群组 + 设置管理员 |
| **Admin** | 由 Owner 授权：禁言/踢人/置顶/编辑群信息/邀请/管理通话/添加管理员 |
| **Member** | 发消息/发媒体/邀请好友（受群默认权限限制） |

**权限位定义**（参考 Telegram ChatObject.ACTION_*）：

```dart
@freezed
class GroupPermissions with _$GroupPermissions {
  const factory GroupPermissions({
    @Default(true) bool canSendMessage,
    @Default(true) bool canSendMedia,
    @Default(true) bool canSendStickers,
    @Default(true) bool canSendPolls,
    @Default(false) bool canPinMessages,
    @Default(false) bool canChangeInfo,
    @Default(false) bool canInviteUsers,
    @Default(false) bool canBlockUsers,
    @Default(false) bool canAddAdmins,
    @Default(false) bool canManageCalls,
    @Default(false) bool canEditMessages,
    @Default(false) bool canDeleteMessages,
  }) = _GroupPermissions;
}
```

### 37.2 禁言/踢人

| 操作 | 说明 | 权限 |
|------|------|------|
| 禁言 | 设置时长：1小时/1天/1周/永久 | Admin+ |
| 踢出 | 从群组移除，可重新加入 | Admin+ |
| 全群禁言 | 只允许管理员发言 | Owner |
| 媒体禁言 | 只允许发文字，不能发图片/视频/语音 | Admin+ |

### 37.3 邀请链接

| 功能 | 说明 |
|------|------|
| 创建链接 | 生成 omnivium://group/xxx?invite=yyy 链接 |
| 设置过期 | 1小时/1天/7天/永不过期 |
| 使用次数限制 | 1次/10次/100次/无限 |
| 需审批模式 | 加入需管理员审批 |
| 撤销链接 | 立即失效 |
| 查看使用记录 | 谁通过此链接加入 |

### 37.4 慢速模式

- 管理员设置发送间隔：10秒/30秒/1分钟/5分钟/10分钟/15分钟
- 普通成员在间隔内无法发送新消息，发送按钮显示倒计时
- 管理员和 Owner 不受限制
- AI Agent 不受限制（通过 Skill 发送的消息绕过慢速模式）

### 37.5 群组通话

| 功能 | 说明 | 优先级 |
|------|------|--------|
| 语音群呼 | 最多 30 人同时发言 | Phase 5+ |
| 视频群呼 | 最多 6 人视频，其余语音 | Phase 6+ |
| 屏幕共享 | 通话中共享屏幕 | Phase 6+ |
| 通话录制 | 录制为音频/视频文件 | Phase 7+ |

**技术方案**：使用 LiveKit（开源 SFU）替代自建 WebRTC SFU，降低复杂度。

### 37.6 消息反应（Reactions）

- 长按消息弹出反应选择面板（6 个预设 emoji）
- 双击消息快速发送默认反应（❤️）
- 反应显示在消息气泡底部
- 管理员可配置群组可用反应列表
- AI 可通过 ReactionSkill 添加反应

### 37.7 消息置顶

- 管理员可置顶最多 5 条消息
- 置顶消息在聊天顶部显示横幅，点击跳转
- 新成员入群时显示置顶消息预览

### 37.8 自动删除

- 管理员设置自动删除时间：1天/7天/1个月/自定义
- 新消息在设定时间后自动删除
- 不影响已置顶消息

---

## 三十八、短视频/广场/动态交互规范（v3.1 新增）

### 38.1 功能定位

"广场"是 Omnivium 的内容发现层，类似 Telegram Stories + 抖音短视频的结合体。

### 38.2 内容类型

| 类型 | 说明 | 交互 |
|------|------|------|
| 图文动态 | 图片 + 文字 | 垂直滑动卡片 |
| 短视频 | 15秒-3分钟视频 | 全屏垂直滑动 |
| AI 生成内容 | AI 生成的图片/视频/文章 | 带生成标记 |
| 频道推送 | 订阅频道的内容更新 | 卡片流 |

### 38.3 与其他功能的深度交互

```
                    ┌─────────────┐
                    │   广场/动态   │
                    └──────┬──────┘
                           │
        ┌──────────┬───────┼────────┬──────────┐
        ↓          ↓       ↓        ↓          ↓
   ┌────────┐ ┌────────┐ ┌────┐ ┌────────┐ ┌──────┐
   │分享给好友│ │分享给AI │ │评论 │ │AI分析  │ │创建者 │
   └────┬───┘ └────┬───┘ └─┬──┘ └────┬───┘ └──┬───┘
        │          │       │        │        │
        ↓          ↓       ↓        ↓        ↓
   好友聊天    AI聊天   群组讨论   AI总结   个人主页
```

| 交互路径 | 操作 | 效果 |
|---------|------|------|
| 广场 → 好友 | 长按/菜单 → 分享给好友 | 好友收到卡片消息 |
| 广场 → AI | 长按/菜单 → 让 AI 分析 | AI 聊天中显示分析结果 |
| 广场 → 群组 | 长按/菜单 → 转发到群 | 群聊中显示卡片消息 |
| 好友 → 广场 | 聊天中长按消息 → 发布到广场 | 成为动态（需确认） |
| AI → 广场 | AI 生成内容 → 自动/手动发布 | 带AI生成标记 |
| 广场 → 好友关系 | 点击创作者头像 → 查看主页 → 添加好友 | 建立社交关系 |
| 广场 → 群组 | 动态评论区 → 创建讨论群 | 从讨论衍生群组 |

### 38.4 AI 与广场的交互

| AI 能力 | 说明 |
|---------|------|
| 内容分析 | 用户看到动态，让 AI 总结/翻译/分析 |
| 自动发布 | 用户让 AI 生成图片/视频 → 发布到广场 |
| 智能推荐 | 后端根据用户兴趣推荐内容（瘦客户端） |
| 评论辅助 | AI 帮用户写评论/回复 |
| 创作辅助 | AI 帮用户编辑图片/视频后发布 |

### 38.5 发布动态流程

```
用户点击 "+" → 选择"发布动态"
  ↓
选择内容类型：
  ├→ 拍照/录像 → 编辑（滤镜/裁剪/贴纸/文字）→ 发布
  ├→ 从相册选择 → 编辑 → 发布
  ├→ AI 生成 → 输入描述 → AI 生成图片/视频 → 编辑 → 发布
  └→ 纯文字 → 输入内容 → 发布
  ↓
设置隐私：
  ├→ 所有人可见
  ├→ 仅好友可见
  └→ 仅自己可见
  ↓
发布成功 → 出现在广场 + 个人主页
```

### 38.6 技术实现

| 组件 | 技术方案 | 说明 |
|------|---------|------|
| 视频播放 | media_kit（已集成） | 全屏垂直滑动 |
| 视频录制 | camera + ffmpeg | 15秒-3分钟 |
| 图片编辑 | 自建（裁剪/滤镜/文字） | Phase 6+ |
| 内容推荐 | 后端 API（瘦客户端） | 基于兴趣的推荐 |
| 内容存储 | Supabase Storage（广场内容）+ Cloudflare R2（聊天文件） | 广场图片/视频用 Supabase Storage CDN，聊天媒体文件用 R2 |
| 内容审核 | 后端 AI 审核 | 敏感内容过滤 |

---

## 三十九、功能深度交互矩阵（v3.1 新增）

### 39.1 四大模块交互全图

| 来源 ↓ / 目标 → | AI 聊天 | 好友聊天 | 群组聊天 | 广场/动态 |
|-----------------|---------|---------|---------|----------|
| **AI 聊天** | — | 分享 AI 回复给好友 | 分享 AI 回复到群 | 发布 AI 生成内容 |
| **好友聊天** | 分享聊天给 AI 分析 | — | 邀请好友入群 | 从聊天发布动态 |
| **群组聊天** | 分享群消息给 AI | 群内 @好友 | — | 从群公告发布动态 |
| **广场/动态** | 让 AI 分析动态 | 分享动态给好友 | 分享动态到群 | — |

### 39.2 统一分享机制

> 第八章 8.1 定义的 `ShareToFriendSkill` 和 `ShareToAISkill` 是两个独立 Skill。本节定义的 `ShareTarget` 是它们共享的参数类型，用于统一分享目标的表达。两个 Skill 内部使用 `ShareTarget` 区分目标类型。

所有跨模块分享统一使用 `ShareSkill`：

```dart
@freezed
class ShareTarget with _$ShareTarget {
  const factory ShareTarget.aiChat() = ShareToAI;
  const factory ShareTarget.friend(String userId) = ShareToFriend;
  const factory ShareTarget.group(String roomId) = ShareToGroup;
  const factory ShareTarget.plaza() = ShareToPlaza;
}

abstract class ShareableContent {
  String get displayTitle;
  String get displaySubtitle;
  String? get imageUrl;
  Map<String, dynamic> get payload;
}
```

### 39.3 AI 控制全功能的方式

| AI 操作 | Skill | 确认级别 | 说明 |
|---------|-------|---------|------|
| 发消息给好友 | SendMessageSkill | confirm | 弹窗确认后发送 |
| 加好友 | AddFriendSkill | confirm | 弹窗确认后发送请求 |
| 创建群组 | CreateGroupSkill | confirm | 弹窗确认后创建 |
| 发动态 | CreatePostSkill | confirm | 弹窗预览后发布 |
| 切换模型 | SwitchModelSkill | auto | 自动执行 |
| 设提醒 | SetReminderSkill | auto | 自动执行 |
| 分享内容 | ShareToFriendSkill / ShareToAISkill | confirm | 弹窗确认 |
| 搜索内容 | WebSearchSkill | auto | 自动执行 |
| 生成图片 | GenerateImageSkill | confirm | 预览后确认 |
| 分析对话 | AnalyzeConversationSkill | auto | 自动执行 |
| 切换主题 | SwitchThemeSkill | auto | 自动执行 |
| 打语音/视频 | StartCallSkill | confirm | 弹窗确认后拨出 |

### 39.4 新功能扩展机制

当需要新增 AI 可调用的功能时，按以下步骤操作：

**Step 1：定义 Skill**

```dart
class NewFeatureSkill extends Skill {
  @override
  String get id => 'new_feature';
  
  @override
  String get name => '新功能名称';
  
  @override
  String get description => '功能描述（给 LLM 看的）';
  
  @override
  PermissionLevel get permission => PermissionLevel.confirm;
  
  @override
  IntentChannel get channel => IntentChannel.slow;
  
  @override
  int get timeoutMs => 30000;
  
  @override
  bool get isDestructive => false;
  
  @override
  String get version => '1.0.0';
  
  @override
  Future<SkillResult> execute(Map<String, dynamic> params) async {
    final typedParams = NewFeatureParams.fromJson(params);
    // 实现逻辑
  }
  
  @override
  Map<String, dynamic> get paramSchema => {
    'type': 'object',
    'properties': { ... },
  };
}
```

**Step 2：注册 Skill 实现类**

在 `app/di.dart` 中注册 Skill 实现类（客户端代码）：

```dart
getIt<SkillRegistry>().register(NewFeatureSkill());
```

> **注意**：客户端注册的是 Skill 的**实现类**（代码逻辑）。后端控制的是 Skill 的**可用性和描述**（哪些 Skill 对当前用户可见）。两者职责不同：客户端提供能力，后端控制可见性。

**Step 3：后端推送 Skill 描述**

后端在模型配置中推送可用 Skill 列表，AI 自动知道新功能的存在：

```json
{
  "available_skills": [
    {
      "id": "new_feature",
      "name": "新功能名称",
      "description": "功能描述",
      "params_schema": { ... },
      "confirm_level": "confirm"
    }
  ]
}
```

**Step 4：瘦客户端渲染**

如果新功能需要 UI，通过 RemoteUIEngine 从后端推送 UI Schema：

```json
{
  "type": "page",
  "id": "new_feature_page",
  "components": [ ... ]
}
```

**关键原则**：
- 新功能 = 新 Skill，不需要改 AI 核心代码
- Skill 描述由后端推送，AI 自动适配
- UI 由后端 Schema 驱动，客户端只负责渲染
- 权限检查在 Skill.execute() 内完成

---

## 四十、持久性与登录态保证规范（v3.1 新增）

### 40.1 目标

像微信/Telegram 一样，用户登录后**几个月不用也无需重新登录**，打开即用。

### 40.2 Token 刷新机制

| Token 类型 | 有效期 | 刷新策略 |
|-----------|--------|---------|
| Supabase Access Token | 1 小时 | Supabase SDK 监听 onAuthStateChange 自动刷新 |
| Supabase Refresh Token | 长期有效 | 默认不设过期时间，仅在用户主动登出或管理员撤销时失效 |
| Matrix Access Token | 无限期 | 不过期，除非用户主动登出 |
| Matrix Device ID | 永久 | 绑定设备，不更换 |

### 40.3 会话恢复流程

```
APP 启动
  ↓
检查 SecureStorage 中是否有 Supabase session
  ├→ 有 → 调用 supabase.auth.refreshSession()
  │   ├→ 成功 → 检查 Matrix 凭据
  │   │   ├→ 有 → 调用 matrix.tryRestoreSession()
  │   │   │   ├→ 成功 → 进入主界面
  │   │   │   └→ 失败 → 用 Supabase 凭据重新关联 Matrix
  │   │   └→ 无 → 用 Supabase 凭据关联 Matrix
  │   └→ 失败 → 清除本地 session → 跳转登录页
  └→ 无 → 跳转登录页
```

### 40.4 离线消息保证

| 场景 | 处理方式 |
|------|---------|
| 离线期间收到消息 | Matrix SDK 自动同步（catchup 模式），上线后拉取所有未读消息 |
| 离线期间发送消息 | 存入 outbox，上线后自动发送 |
| 离线期间被邀请入群 | 上线后收到邀请通知 |
| 离线期间群设置变更 | 上线后同步最新群状态 |
| 长时间离线（>7天） | Matrix 支持拉取历史消息，但可能需要重新解密 |

### 40.5 APP 更新后保证

| 场景 | 处理方式 |
|------|---------|
| 热更新（RemoteUI） | 无需重启，实时生效 |
| 应用商店更新 | 本地 session 不受影响，启动时自动恢复 |
| 数据库 schema 变更 | sqflite/Hive 版本号迁移，自动升级 |
| 模型列表变更 | 后端推送，客户端自动更新 |

### 40.6 数据不丢失保证

| 数据类型 | 存储位置 | 持久化策略 |
|---------|---------|-----------|
| 登录凭证 | SecureStorage（主）+ SharedPreferences（仅存 isLoggedIn 标志位） | SecureStorage 存 Token，SharedPreferences 仅存非敏感标志 |
| 聊天消息 | Matrix 服务器 + 本地 sqflite 缓存 | 服务器为主，本地为缓存 |
| AI 聊天记录 | Supabase messages 表 + 本地 sqflite | 双写 |
| 联系人列表 | Matrix 服务器 + 本地缓存 | 服务器为主 |
| 用户设置 | Supabase user_settings 表 + 本地 Hive | 双写，云端优先 |
| 定时任务 | Supabase scheduled_tasks 表 | 服务器存储 |
| 草稿 | 本地 Hive | 仅本地 |

---

## 四十一、语音/视频通话规范（v3.1 新增）

### 41.1 当前实现状态

| 功能 | 状态 | 说明 |
|------|------|------|
| 1:1 语音通话 | ✅ 已实现 | WebRTC + Matrix 信令 |
| 1:1 视频通话 | ✅ 已实现 | 前后摄像头切换 |
| 通话 UI | ✅ 已实现 | 静音/扬声器/摄像头/计时 |
| 来电界面 | ✅ 已实现 | 脉冲动画 + 接听/拒绝 |
| 群组通话 | ❌ 未实现 | 需要 SFU（LiveKit） |
| 屏幕共享 | ❌ 未实现 | 需要 MediaProjection API |
| 通话录制 | ❌ 未实现 | 需要 MediaRecorder |
| 画中画 | ❌ 未实现 | 需要 PiP API |

### 41.2 重构注意事项

- 当前存在两套通话实现（CallService + CallScreen 和 CallBloc + CallPage），需统一为 Bloc 版本
- CallRepositoryImpl 的 toggleSpeaker/toggleCamera 为空实现，需补全
- 通话信令通过 Matrix 的 m.call.invite/candidates/answer/hangup 事件，保持不变

### 41.3 语音消息

| 功能 | 状态 | 说明 |
|------|------|------|
| 长按录音 | ✅ 已实现 | AAC-LC 编码 |
| 发送语音 | ✅ 已实现 | Matrix 文件事件 |
| 播放语音 | ✅ 已实现 | 进度条 + 时长 |
| 波形显示 | ❌ 未实现 | 参考 Telegram SeekBarWaveform |
| 语音转文字 | ❌ 未实现 | 需要 STT 服务 |
| 降噪 | ❌ 未实现 | 需要 rnnoise（Telegram 使用） |

### 41.4 语音转文字（STT）

- 现有 VoiceService 已集成 speech_to_text 包
- 好友聊天中的语音消息转文字：后端 STT API（Whisper）
- AI 聊天中的语音输入：本地 speech_to_text
- 群组聊天中的语音转文字：同好友聊天

---

## 四十二、消息卡片与富媒体展示规范（v3.1 新增）

### 42.1 卡片类型

| 卡片类型 | 触发条件 | 展示内容 |
|---------|---------|---------|
| 链接预览 | 消息含 URL | 标题/描述/图片/站点名 |
| AI 生成图片 | AI 回复含图片 | 图片 + 生成参数 |
| 好友名片 | 分享联系人 | 头像/昵称/状态/添加按钮 |
| 群组名片 | 分享群组 | 群名/成员数/加入按钮 |
| 动态卡片 | 分享广场内容 | 封面/标题/作者/互动数 |
| 位置卡片 | 分享位置 | 地图缩略图/地址 |
| 文件卡片 | 发送文件 | 文件名/大小/类型图标 |
| 通话记录 | 通话结束 | 通话类型/时长/回拨按钮 |

### 42.2 卡片运行时（CardRuntime）

现有 CardRuntime 已实现：
- 7 种生命周期状态（created/rendering/streaming/interactive/fullscreen/expired/dismissed）
- TTL 过期机制（默认 24 小时，5 分钟定时清理）
- 卡片状态管理（id/type/lifecycle/data/ttl）

### 42.3 远程 UI 引擎（RemoteUIEngine）

现有 RemoteUIEngine 已实现：
- 14 种组件类型（text/image/button/list/card/grid/tabs/separator/input/progress/badge/chart/form/container）
- 安全限制（最大深度 10、最大子项 50、URL 白名单）
- 服务端驱动 UI 渲染

---

## 四十三、模型管理规范（v3.1 新增）

### 43.1 模型获取方式

```
APP 启动
  ↓
调用后端 GET /v1/models
  ↓
后端返回可用模型列表（含 id/name/provider/tier/capabilities/pricing）
  ↓
客户端缓存到 SecureStorage（加密）
  ↓
用户在 AI 聊天中切换模型
```

### 43.2 模型增减

| 操作 | 流程 | 客户端感知 |
|------|------|-----------|
| 新增模型 | 后端添加模型配置 → 推送到模型列表 | 下次刷新自动出现 |
| 下线模型 | 后端标记为 deprecated → 30天后移除 | 显示"即将下线"标记 |
| 模型升级 | 后端更新模型配置（如 GPT-4 → GPT-4o） | 自动切换，用户无感知 |
| 模型降级 | 后端标记为 degraded → 降级到备选模型 | 显示降级提示 |

### 43.3 AI 自动选择模型

AI Agent 根据任务类型自动选择最合适的模型：

| 任务类型 | 模型选择 | 说明 |
|---------|---------|------|
| 简单对话 | 轻量模型（GPT-4o-mini） | 低成本，快速响应 |
| 复杂推理 | 强力模型（GPT-4o/Claude-3.5） | 高质量输出 |
| 图片生成 | 专用模型（DALL-E/SD） | 图片生成模型 |
| 代码生成 | 代码模型（Claude-3.5/GPT-4o） | 代码优化 |
| 语音合成 | TTS 模型 | 语音输出 |
| 长文档分析 | 长上下文模型 | 大 token 窗口 |

模型选择逻辑由后端控制（瘦客户端），客户端只执行后端返回的模型 ID。

---

## 四十四、搜索规范（v3.1 新增）

### 44.1 搜索层级

| 搜索类型 | 范围 | 实现 |
|---------|------|------|
| 全局搜索 | 聊天/联系人/群组/广场/消息 | 后端 API |
| 聊天内搜索 | 当前聊天的消息 | Matrix / Supabase |
| 广场搜索 | 动态/创作者/话题 | 后端 API |
| 用户搜索 | 搜索用户 → 添加好友 | Matrix 用户目录 |

### 44.2 聊天内搜索

- 支持按类型过滤：文本/图片/视频/文件/链接/语音
- 搜索结果高亮关键词
- 上下箭头跳转，显示 "3/15" 计数
- 支持按日期筛选

---

## 四十五、功能优先级与实现路线（v3.1 新增）

### 45.1 功能分级

| 级别 | 功能 | Phase |
|------|------|-------|
| **P0 核心** | AI 聊天、好友聊天、群组聊天、登录 | Phase 0-3 |
| **P1 重要** | Skill 扩展、定时任务、互通性 | Phase 4-6 |
| **P2 增强** | 群组权限、邀请链接、慢速模式、消息反应 | Phase 5-6 |
| **P3 社交** | 广场/动态、短视频、频道 | Phase 6-7 |
| **P4 高级** | 群组通话、屏幕共享、通话录制、语音转文字 | Phase 7+ |
| **P5 未来** | 声纹登录、AR 特效、实时翻译 | 远期 |

### 45.2 每个功能模块的完成度

| 模块 | 当前完成度 | 重构目标 | 缺失功能 |
|------|-----------|---------|---------|
| AI 聊天 | 90% | 100% | 最新消息对 UI、Skill 集成 |
| 好友聊天 | 85% | 100% | QR 码添加、消息反应、语音转文字 |
| 群组聊天 | 70% | 95% | 权限体系、禁言/踢人、邀请链接、慢速模式、群通话 |
| 广场/动态 | 40% | 80% | 短视频录制/上传、动态发布、AI 交互 |
| 语音/视频通话 | 85% | 95% | 统一两套实现、补全空方法 |
| 模型管理 | 95% | 100% | 后端推送增减模型 |
| 搜索 | 60% | 90% | 全局搜索、聊天内搜索、类型过滤 |
| 持久性 | 98% | 100% | 离线消息解密恢复 |

---

> 本文档随项目演进持续更新。任何架构变更必须先更新本文档，再动手写代码。
>
> **文档冲突解决原则**：当本文档与其他文档（AUDIT.md / PROJECT_PLAN.md / RUNTIME_ARCHITECTURE.md 等）内容冲突时，以本文档为准。RUNTIME_ARCHITECTURE.md 的 6 条铁律和 Vocabulary v4 除外，它们是 FROZEN 的不可违反的约束。
