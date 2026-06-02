# Omni Agent Cognitive Architecture Design V2

## 1. 核心理念

**Importance Memory（重要性记忆）**，不是 Conversation Memory（对话记忆）。
第一层是**重要性判断**，不是短期/长期分类。
记忆是**事件**，不是文本。
存"重要信息"，不存"对话"。
**记忆有领域（Domain）**，不是全局混存。
**重要性 ≠ 持久性**，用户名字永远重要，昨天午饭明天就忘。
**实体为中心（Entity-Centric）**，不是事件为中心。事件只是"实体发生了什么"。

## 2. Entity Layer（实体层）— 架构中心

实体是整个认知架构的中心。事件、记忆、知识图谱都围绕实体组织。

### 2.1 Entity（实体）

```dart
class MemoryEntity {
  final String id;
  final String name;               // "Omni" / "Flutter" / "张三"
  final EntityType type;           // person / project / tech / concept / organization / document / task / goal
  final MemoryDomain domain;       // project / personal / friend / business / research / entertainment
  final String? workspaceId;       // 所属工作空间
  final EntityLifecycle lifecycle; // active / warm / frozen
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastAccessedAt;
  final Map<String, dynamic> properties;
}
```

### 2.2 EntityType（实体类型）

```dart
enum EntityType {
  person,        // 人：用户、好友、同事
  project,       // 项目：Omni、CloudHub
  tech,          // 技术：Flutter、MCP、Matrix
  concept,       // 概念：Agent Memory、知识图谱
  organization,  // 组织：公司、团队
  document,      // 文档：PDF、代码文件
  task,          // 任务：发布APP、实现记忆系统
  goal,          // 目标：6月上线、Agent系统
}
```

### 2.3 Entity Relation（实体关系）

```dart
class EntityRelation {
  final String id;
  final String fromEntityId;
  final String toEntityId;
  final RelationType type;    // owns / uses / depends_on / part_of / knows / prefers / blocks / supports
  final double strength;      // 0-1
  final DateTime since;
  final String? sourceEventId; // 由哪个事件产生的关系
  final Map<String, dynamic> metadata;
}

enum RelationType {
  owns,         // User owns Omni
  uses,         // Omni uses Flutter
  dependsOn,    // Omni dependsOn Matrix
  partOf,       // MemorySystem partOf Agent
  knows,        // User knows 张三
  prefers,      // User prefers Flutter
  blocks,       // Bug blocks Release
  supports,     // MCP supports Agent
  created,      // User created Omni
  decided,      // User decided Flutter
}
```

### 2.4 为什么 Entity 中心？

```
错误：Event List
  [event1, event2, event3, ...]
  → 查询"Omni用了什么技术？"需要遍历所有事件

正确：Entity Graph
  Omni ─uses→ Flutter
  Omni ─uses→ Matrix
  Omni ─uses→ MCP
  → 查询"Omni用了什么技术？"直接遍历 Omni 的关系
```

## 3. 记忆数据模型

### 3.1 MemoryEvent（记忆事件）— 轻量化

事件只存结构化数据，不存上下文。上下文单独存储。

```dart
class MemoryEvent {
  final String id;
  final DateTime timestamp;

  // 事件核心
  final String eventType;           // project_created / tech_selected / preference_set
  final String summary;             // AI生成的自然语言摘要（<100字）
  final String? entityId;           // 关联实体ID

  // 评估维度（三维度分离）
  final int importance;             // 0-100
  final MemoryPersistence persistence; // permanent / longTerm / shortTerm / ephemeral
  final double confidence;          // 0-100

  // 分类维度
  final MemoryType memoryType;      // fact / decision / goal / preference / rule / relationship / experience
  final IntentType intent;          // 语言意图 + 行动意图
  final MemoryDomain domain;        // project / personal / friend / business / research / entertainment

  // 上下文（仅存ID引用，不存内容）
  final String? workspaceId;
  final String? speakerId;
  final String source;              // conversation / document / skill / reflection
  final String? snapshotId;         // 关联的快照ID（按需加载）

  // 生命周期
  final MemoryLifecycle lifecycle;  // active / warm / frozen
  final String? reason;

  final Map<String, dynamic> properties; // 事件特有属性
}
```

### 3.2 MemorySnapshot（记忆快照）— 按需加载

快照单独存储，只在需要上下文时加载。

```dart
class MemorySnapshot {
  final String id;
  final String eventId;             // 关联的事件ID
  final String rawMessage;          // 原始消息
  final List<String> contextBefore; // 前文（最多3条）
  final List<String> contextAfter;  // 后文（最多3条）
  final DateTime createdAt;
  final MemorySnapshotLifecycle lifecycle; // active / archived / deleted
}
```

### 3.3 为什么 Event/Snapshot 分离？

```
用户一天500条消息，一年18万条

不分离：
  18万 × (rawMessage + contextBefore + contextAfter) = 数据库爆炸

分离后：
  18万事件（轻量，只有结构化数据）
  + 仅重要事件的快照（可能只有几千条）
  → 存储量降低 90%+
```

## 4. 三维度分离

**Importance（重要性）**：这条信息有多重要？
**Persistence（持久性）**：这条信息应该存多久？
**Confidence（置信度）**：我有多确定这是真的？

| 组合 | 例子 |
|------|------|
| importance=95, persistence=permanent | 用户名字 |
| importance=95, persistence=longTerm | Omni项目 |
| importance=50, persistence=ephemeral | 昨天午饭吃拉面 |
| importance=80, persistence=longTerm | 决定用Flutter |
| importance=30, persistence=shortTerm | 今天心情不好 |

```dart
enum MemoryPersistence {
  permanent,   // 永久：用户名字、核心身份
  longTerm,    // 长期：项目、决策、偏好
  shortTerm,   // 短期：当前对话上下文
  ephemeral,   // 瞬时：闲聊、天气
}
```

### 4.1 衰减按 Persistence 而非统一时间

```
persistence=permanent → 永不衰减
persistence=longTerm → 缓慢衰减（2年半衰期）
persistence=shortTerm → 中等衰减（30天半衰期）
persistence=ephemeral → 快速衰减（1天半衰期）
```

## 5. Memory Type + Intent（双维度分类）

### 5.1 Memory Type（记忆类型）

```dart
enum MemoryType {
  fact,         // 事实：用户叫张三
  decision,     // 决策：决定用Flutter
  goal,         // 目标：要开发Omni
  preference,   // 偏好：喜欢深色模式
  rule,         // 规则：不要在周末打扰我
  relationship, // 关系：李四是大学同学
  experience,   // 经验：上次用X框架出了问题
  procedure,    // 程序：搜索范围太窄时要扩大（Procedural Memory）
}
```

### 5.2 Intent Layer（意图层）— 语言意图 + 行动意图

```dart
enum IntentType {
  // 语言意图
  fact,       // 事实陈述
  opinion,    // 观点
  emotion,    // 情绪
  joke,       // 玩笑
  sarcasm,    // 讽刺
  complaint,  // 抱怨
  guess,      // 猜测
  question,   // 提问
  promise,    // 承诺

  // 行动意图
  goal,       // 目标意图：我要做世界第一平台
  task,       // 任务意图：帮我做一个APP
  research,   // 研究意图：调查一下Flutter性能
  decision,   // 决策意图：我决定用Flutter
  discussion, // 讨论意图：我们来聊聊架构
  command,    // 命令意图：删除这个文件
  plan,       // 计划意图：下周开始做Agent
}
```

### 5.3 Domain Layer（领域层）

```dart
enum MemoryDomain {
  project,       // 项目
  personal,      // 个人
  friend,        // 好友
  business,      // 商业
  research,      // 研究
  entertainment, // 娱乐
}
```

## 6. Workspace 三级结构

### 6.1 Workspace → Subspace → Topic

```dart
class MemoryWorkspace {
  final String id;
  final String name;               // "Omni" / "CloudHub"
  final MemoryDomain domain;
  final MemoryLifecycle lifecycle;  // active / warm / frozen
  final DateTime lastActiveAt;
  final List<MemorySubspace> subspaces;
}

class MemorySubspace {
  final String id;
  final String workspaceId;
  final String name;               // "Agent" / "UI" / "Backend" / "MCP"
  final DateTime lastActiveAt;
  final List<MemoryTopic> topics;
}

class MemoryTopic {
  final String id;
  final String subspaceId;
  final String name;               // "Memory System" / "Chat Panel" / "Encryption"
  final DateTime lastActiveAt;
}
```

### 6.2 示例

```
Omni（Workspace）
  ├─ Agent（Subspace）
  │   ├─ Memory System（Topic）
  │   ├─ Cognitive Architecture（Topic）
  │   └─ Skills（Topic）
  ├─ UI（Subspace）
  │   ├─ Chat Panel（Topic）
  │   └─ Settings（Topic）
  ├─ Backend（Subspace）
  │   ├─ Matrix Protocol（Topic）
  │   └─ MCP（Topic）
  └─ Product（Subspace）
      ├─ Release Plan（Topic）
      └─ User Feedback（Topic）

CloudHub（Workspace）
  ├─ Architecture（Subspace）
  └─ Deployment（Subspace）
```

## 7. Memory Lifecycle（记忆生命周期）

```dart
enum MemoryLifecycle {
  active,  // 活跃：最近使用，全量加载
  warm,    // 温暖：6个月没碰，摘要加载
  frozen,  // 冻结：2年没碰，按需解冻
}
```

### 7.1 状态转换

```
Active → 6个月无访问 → Warm → 2年无访问 → Frozen
  ↑                                            |
  └──────────── 被触发召回 ─────────────────────┘
```

## 8. Event Extraction（事件提取）

### 8.1 事件格式

```dart
class ExtractedEvent {
  final String eventType;     // project_created / tech_selected / preference_set
  final String entity;        // Omni / Flutter
  final Map<String, dynamic> properties;
  final DateTime timestamp;
  final String sourceMessageId;
}
```

### 8.2 事件 → 实体 + 关系

```
事件：{ eventType: "tech_selected", entity: "Flutter", properties: { project: "Omni" } }

产生：
  Entity: Flutter (type: tech)
  Entity: Omni (type: project)
  Relation: Omni ─uses→ Flutter
```

## 9. Episodic Memory（情景记忆）— Phase 2

人脑利用场景回忆，不只是关键词。

```dart
class EpisodicMemory {
  final String id;
  final String scene;           // "深夜讨论Omni架构"
  final List<String> participants; // ["user", "agent"]
  final String? emotion;        // "兴奋" / "沮丧" / "困惑"
  final DateTime timestamp;
  final String? workspaceId;
  final List<String> relatedEventIds;
  final String? location;       // "办公室" / "线上"
}
```

### 9.1 回忆示例

```
问：那个晚上讨论的Agent方案
  → EpisodicMemory: scene="深夜讨论Agent方案", emotion="兴奋"
  → 关联事件列表
  → 返回完整上下文
```

## 10. Procedural Memory（程序性记忆）— Phase 2

Agent 从失败中学习，改变行为。

```dart
class ProceduralMemory {
  final String id;
  final String lesson;          // "搜索范围太窄时要扩大"
  final String trigger;         // "连续搜索失败3次"
  final String action;          // "自动扩大搜索范围"
  final int failureCount;       // 触发次数
  final DateTime lastTriggered;
  final double confidence;      // 0-100
}
```

### 10.1 示例

```
Agent连续10次搜索失败
  → 自动产生 ProceduralMemory: lesson="搜索范围太窄"
  → 下次搜索时自动扩大范围
```

## 11. Goal System（目标系统）— Phase 1

目标树，支持分解和追踪。

```dart
class GoalNode {
  final String id;
  final String title;            // "发布APP" / "实现记忆系统"
  final GoalStatus status;       // planned / in_progress / completed / abandoned
  final String? parentGoalId;    // 父目标
  final String? workspaceId;
  final int priority;            // 0-100
  final DateTime createdAt;
  final DateTime? completedAt;
  final List<String> relatedEntityIds;
  final List<String> subGoalIds;
}

enum GoalStatus {
  planned,      // 计划中
  inProgress,   // 进行中
  completed,    // 已完成
  abandoned,    // 已放弃
  paused,       // 暂停
}
```

### 11.1 示例

```
Omni（Workspace）
  ├─ 发布APP（Goal）
  │   ├─ Agent系统（Goal）
  │   │   ├─ 记忆系统（Goal）
  │   │   ├─ 认知架构（Goal）
  │   │   └─ Skills系统（Goal）
  │   ├─ MCP生态（Goal）
  │   └─ UI优化（Goal）
  └─ 用户增长（Goal）
```

## 12. Speaker Graph（说话者图谱）

```dart
class SpeakerEntry {
  final String speakerId;    // user / friend_xxx / agent
  final String speakerType;  // user / friend / agent / model_gpt5 / model_claude
  final String? displayName;
  final DateTime timestamp;
  final String content;
  final String messageId;
}
```

## 13. Recall Engine（回忆引擎）

不是搜索，是回忆。

```
搜索：关键词 → 向量库 → 结果
回忆：线索 → 领域 → 项目 → 子空间 → 时间 → 实体 → 事件 → 情景
```

### 13.1 回忆流水线

```dart
class RecallQuery {
  final String clue;              // 线索（模糊描述）
  final MemoryDomain? domain;     // 领域过滤
  final String? workspaceId;      // 项目过滤
  final String? subspaceId;       // 子空间过滤
  final DateTime? timeRange;      // 时间范围
  final String? speakerId;        // 说话者过滤
  final String? entityId;         // 实体过滤
  final MemoryType? memoryType;   // 记忆类型过滤
  final IntentType? intent;       // 意图过滤
  final String? scene;            // 情景线索（"那个晚上"）
}

class RecallResult {
  final List<MemoryEvent> events;
  final List<MemoryEntity> relatedEntities;
  final List<EntityRelation> relations;
  final EpisodicMemory? episode;  // 情景记忆（如果有）
  final String? workspaceContext;
  final double relevanceScore;
}
```

## 14. 三层记忆架构

### Layer 1: 原始消息（Raw Messages）
- 保存30天
- 便宜存储
- 用于精确回溯

### Layer 2: 实体 + 事件（Entity + Events）
- 永久保存
- Entity Graph + Event List
- 按 Workspace/Subspace/Topic 分区
- Active/Warm/Frozen 生命周期
- Snapshot 按需加载

### Layer 3: 知识图谱 + 情景记忆（Knowledge Graph + Episodic）
- 实体关系推理
- 情景记忆关联
- 程序性记忆

## 15. 处理流水线

```
用户输入
    ↓
[Perception Engine] 感知
    ↓ 识别说话者、格式、媒体类型、所属领域、关联实体
[Understanding Engine] 理解
    ↓ 意图分类（语言+行动）+ 重要性评分 + 持久性评估 + 事件提取 + 实体识别
[Memory Engine] 记忆
    ↓ 实体更新 + 事件存储 + 关系建立 + Workspace分区 + 生命周期管理
[Reasoning Engine] 推理
    ↓ 基于实体图谱和记忆推理
[Planning Engine] 规划
    ↓ 制定行动计划（关联Goal）
[Execution Engine] 执行
    ↓ 调用工具/Skill
[Reflection Engine] 反思
    ↓ 评估结果 + 事件提取 + 实体更新 + 程序性记忆 + 记忆更新
[Value Engine] 价值判断
    ↓ 风险评估 + 优先级排序
```

## 16. 与现有代码的映射

| 新架构 | 现有代码 | 状态 |
|--------|---------|------|
| Entity Layer | `cognitive/entity_layer.dart` + `entity_store.dart` | � **已实现** |
| Memory Engine | `cognitive/cognitive_engine.dart` | 🟢 **已实现（Entity中心+三维度+Workspace+Lifecycle）** |
| Understanding Engine | `cognitive/understanding_engine.dart` | 🟢 **已实现（意图+重要性+持久性+事件+实体识别）** |
| Knowledge Graph | `entity_store.dart` (EntityRelation) | 🟢 **基础已实现** |
| Perception Engine | StreamEventHandler | 需扩展 |
| Reasoning Engine | 无 | 需新建 |
| Planning Engine | AgentOrchestrator._processInput | 🟡 **已接入CognitiveEngine** |
| Execution Engine | SkillRegistry + CapabilityRouter | 已有基础 |
| Reflection Engine | `cognitive_engine.reflect()` + `_cognitiveReflect()` | 🟢 **已实现（reflecting→memorizing循环闭合）** |
| Value Engine | 无 | 需新建 |
| Recall Engine | EmbeddingService.searchSimilar | 需重构 |
| Speaker Graph | 无 | 需新建 |
| Goal System | `cognitive/goal_runtime.dart` + `goal_store.dart` | � **已实现（含成功/失败条件/进度/依赖）** |
| Episodic Memory | 无 | Phase 2 |
| Procedural Memory | 无 | Phase 2 |
| Embedding | EmbeddingService | 需优化 |
| Memory Plugin | MemoryPlugin | 需统一 |
| AI Prompt 注入 | `_buildSystemPrompt()` + `buildMemoryContext()` | 🟢 **已实现** |
| 状态机认知循环 | `agent_state_machine.dart` | 🟢 **已实现（executing→reflecting→memorizing→completed→idle）** |

## 17. V3 补充（ChatGPT 第三轮反馈）

### 17.1 Entity State System（实体状态演化）

实体不是静态的，有状态时间线。

```dart
class EntityState {
  final String id;
  final String entityId;
  final String state;           // "idea" / "developing" / "launched" / "commercialized"
  final DateTime since;
  final String? sourceEventId;  // 由哪个事件触发状态变更
  final Map<String, dynamic> context;
}

// Entity 新增字段
class MemoryEntity {
  // ... 原有字段 ...
  final String currentState;    // 当前状态
  final List<EntityState> stateHistory; // 状态时间线
}
```

### 17.2 Goal Runtime（目标运行时）

Goal 不是 Todo，需要有成功/失败条件、进度、依赖。

```dart
class GoalNode {
  // ... 原有字段 ...
  final List<String> successConditions;  // ["安卓上线", "iOS上线"]
  final List<String> failureConditions;  // ["超过deadline", "核心成员离开"]
  final DateTime? deadline;
  final int progress;            // 0-100
  final List<String> dependencies; // 依赖的其他Goal
  final List<String> blockers;     // 阻塞因素
}
```

### 17.3 Attention Engine + Working Memory（Phase 2）

决定当前关注什么，避免全局搜索爆炸。

```dart
class WorkingMemory {
  final List<String> activeEntityIds;   // 当前活跃实体
  final List<String> activeGoalIds;     // 当前活跃目标
  final String? currentWorkspaceId;     // 当前工作空间
  final List<String> recentEventIds;    // 最近事件
  final int maxItems;                   // 容量限制（~50条）
}

// 处理流水线增加
Recall Engine → Attention Engine → Working Memory → Reasoning
```

### 17.4 Reflection 增强

反思不只更新记忆，还要更新实体状态和目标进度。

```
Reflection
  ↓ 更新记忆
  ↓ 更新实体状态（Entity State）
  ↓ 更新目标进度（Goal Progress）
  ↓ 更新策略（Procedural Memory）
```

### 17.5 Prediction Engine（Phase 3）

基于记忆和实体状态推演未来。

```
Memory → Reasoning → Prediction → Planning
```

## 18. 分阶段实现计划（V3 最终版）

### Phase 1: 认知基础（9项）

| # | 任务 | 核心产出 | 优先级 |
|---|------|---------|--------|
| ① | **Entity Layer + State** | MemoryEntity + EntityState + EntityRelation + 存储 | 🔴 最高 |
| ② | **Goal Runtime** | GoalNode（含成功/失败条件/进度/依赖）+ 目标树 | 🔴 最高 |
| ③ | Intent Layer | IntentType分类（语言+行动） | 🔴 高 |
| ④ | Importance + Persistence | 三维度分离评分 | 🔴 高 |
| ⑤ | Memory Type + Event/Snapshot | 轻量事件 + 按需快照 | 🔴 高 |
| ⑥ | Reflecting Loop | 闭合循环 + 实体状态更新 + 目标进度更新 | 🔴 高 |
| ⑦ | Event Extraction + Entity Update | 对话→事件→实体+关系+状态 | 🔴 高 |
| ⑧ | Workspace 三级 | Workspace→Subspace→Topic | 🟡 中 |
| ⑨ | Active/Warm/Frozen | 生命周期管理 | 🟡 中 |

### Phase 2: 关联、回忆与注意力

| # | 任务 | 核心产出 |
|---|------|---------|
| ① | Knowledge Graph | 基于Entity Relation的图查询 |
| ② | Attention Engine | 决定当前关注什么 |
| ③ | Working Memory | 当前上下文窗口（~50条） |
| ④ | Recall Engine | 线索→领域→项目→实体→事件→情景 |
| ⑤ | Speaker Graph | 说话者识别+按人查询 |
| ⑥ | Episodic Memory | 情景记忆 |
| ⑦ | Procedural Memory | 经验记忆 |

### Phase 3: 高级认知

| # | 任务 | 核心产出 |
|---|------|---------|
| ① | Prediction Engine | 基于记忆和状态推演未来 |
| ② | Value Engine | 收益/风险/成本/一致性评估 |
| ③ | Self Evolution | Agent自我认知+模型切换感知 |
| ④ | Multi-Agent Society | 多智能体协作框架 |
