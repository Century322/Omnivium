# Omnivium Runtime Architecture

> 版本：1.0.0 | 状态：**FROZEN** | 冻结日期：2026-05-20
>
> 本文档是 Omnivium Runtime 的最高架构权威。任何代码实现必须遵守本文档定义的铁律和契约。
> 修改本文档需要与修改操作系统内核 ABI 同等的审慎。

---

## 零、Runtime 定位

Omnivium Runtime 不是"APP 架构"。

它是 **AI Runtime Kernel ABI** — 与以下系统同层：

| 对标系统 | 层级 |
|----------|------|
| VSCode Extension Host | 编辑器运行时 |
| Chrome Extension Runtime | 浏览器运行时 |
| Kubernetes Control Plane | 容器编排运行时 |
| Erlang OTP | 分布式运行时 |
| Ray Runtime | AI 计算运行时 |
| Temporal Workflow Engine | 工作流运行时 |

**Omnivium Runtime 的独特性**：它是第一个以 AI Agent 为一等公民的超级平台运行时。

**设计原则**：Distributed Ready, Single Node Implementation
- 协议先分布式
- 实现先本地
- 后面扩展成本最低

---

## 一、Runtime 铁律（Iron Laws）

> 这 6 条铁律比代码重要。违反任何一条，Runtime 终将变成屎山。

### 铁律 1：Core Never Knows Implementation

**核心永远不允许知道实现。**

Core 只能依赖：
- Contract（契约）
- Descriptor（描述符）
- Protocol（协议）
- Capability（能力）

永远禁止：
```
import OpenAIService
import MatrixService
import SupabaseService
```
进入 Runtime Core。

**理由**：Core 一旦依赖具体实现，替换成本 = 重写。Runtime 的价值在于"不动核心换插件"。

### 铁律 2：Everything Is Message

**一切皆消息。**

不允许以下方式跨 Runtime Boundary 通信：
- 静态单例
- 全局状态
- 直接函数调用

Runtime Boundary 上的所有通信必须统一协议。

**理由**：消息是唯一能跨进程、跨节点、跨语言、跨沙箱的通信方式。一旦允许直接调用，分布式就是空话。

### 铁律 3：Capability Over Plugin

**永远依赖 Capability，不要依赖 Plugin。**

- Plugin 可以替换
- Capability 必须稳定

代码应该写：
```
// 正确：依赖 Capability
runtime.invokeCapability('chat.send', params)

// 错误：依赖 Plugin
matrixPlugin.sendMessage(params)
```

**理由**：Capability 是"做什么"，Plugin 是"谁来做"。系统应该只关心"做什么"。

### 铁律 4：Failure Is Normal

**失败不是异常。失败是 Runtime 的正常状态。**

所有 Capability、Stream、Event、Task 都必须默认可失败。

任何调用都必须提供：
- 超时策略
- 重试策略
- 降级策略

**理由**：在分布式系统中，失败是常态不是异常。如果只有 happy path，系统一上生产就会崩。

### 铁律 5：Distributed First

**即使现在单机，也必须协议先分布式，实现先本地。**

所有 Runtime Protocol 消息必须包含：
- 消息版本号
- 传播范围
- 路由信息
- 发送方身份

**理由**：协议是"语言"，实现是"方言"。语言一旦定死，方言可以随时换。但语言一旦改了，所有方言都得改。

### 铁律 6：Runtime Owns Time

**Runtime 必须控制所有时间相关行为。**

Runtime 控制的维度：
- timeout（超时）
- retry（重试）
- cancellation（取消）
- scheduling（调度）
- priority（优先级）
- budget（预算）

不能：某个插件自己无限 await。

**理由**：这是很多系统最后崩掉的根源。一个插件无限 await → 整个 Runtime 失控 → 级联故障。Runtime 必须是时间的唯一权威。

---

## 二、Runtime Vocabulary v4（FROZEN）

> 本节已冻结。不再修改。
> 继续抽象会进入"架构快感循环"，这是很多高级工程团队会死掉的地方。

### 2.1 Vocabulary 总览

Vocabulary 分为 5 个域：

| 域 | 原语 | 职责 |
|----|------|------|
| Runtime Primitive | Message, Event, Stream, Task, Route | 运行时通信与调度 |
| Runtime Identity | identity, instance, node | 身份与寻址 |
| Runtime Security | Permission, CapabilityContext, IsolationLevel | 安全与隔离 |
| Runtime Execution | Session, Scheduler, Budget, FailurePolicy | 执行与资源 |
| Runtime Distribution | PropagationScope, Route, CapabilityDiscovery | 分布式就绪 |

### 2.2 Runtime Primitive

#### RuntimeMessage

```typescript
interface RuntimeMessage {
  id: string
  version: number
  type: string
  source: RuntimeRoute
  target: RuntimeRoute
  payload: unknown
  metadata: RuntimeMetadata
  timestamp: number
}
```

#### RuntimeEvent

```typescript
interface RuntimeEvent {
  id: string
  version: number
  type: string
  source: RuntimeRoute
  phase: EventPhase
  payload: unknown
  metadata: RuntimeMetadata
  permission: EventPermission
  scope: PropagationScope
  timestamp: number
}

enum EventPhase {
  before = 'before'
  during = 'during'
  after = 'after'
}

enum EventPermission {
  observe = 'observe'
  intercept = 'intercept'
  mutate = 'mutate'
}

enum PropagationScope {
  local = 'local'
  session = 'session'
  node = 'node'
  cluster = 'cluster'
}
```

#### RuntimeStream

```typescript
interface RuntimeStream {
  id: string
  type: string
  source: RuntimeRoute
  chunks: AsyncIterable<StreamChunk>
  backpressure: BackpressureStrategy
  onCancel: () => void
}

interface StreamChunk {
  index: number
  data: unknown
  metadata: RuntimeMetadata
  isFinal: boolean
}

enum BackpressureStrategy {
  buffer = 'buffer'
  drop_oldest = 'drop_oldest'
  drop_newest = 'drop_newest'
  pause = 'pause'
}
```

#### RuntimeTask

```typescript
interface RuntimeTask {
  id: string
  type: string
  priority: TaskPriority
  budget: TaskBudget
  schedulerHint: SchedulerHint
  failurePolicy: FailurePolicy
}

enum TaskPriority {
  critical = 0
  high = 1
  normal = 2
  low = 3
  idle = 4
}

interface TaskBudget {
  maxDurationMs: number
  maxRetries: number
  maxMemoryMb: number
}

interface SchedulerHint {
  preferredNode?: string
  isolationLevel: IsolationLevel
  deadline?: number
}
```

#### RuntimeRoute

```typescript
interface RuntimeRoute {
  capability: string
  pluginId: string
  instanceId: string
  nodeId: string
}
```

### 2.3 Runtime Identity

```typescript
interface RuntimeIdentity {
  identity: string
  instance: string
  node: string
}
```

- **identity**：逻辑身份（如 pluginId）
- **instance**：实例标识（同一插件可多实例）
- **node**：节点地址（分布式部署时区分）

### 2.4 Runtime Security

#### Permission

```typescript
interface RuntimePermission {
  capabilities: string[]
  isolation: IsolationLevel
  maxBudget: TaskBudget
  network: NetworkPermission
  storage: StoragePermission
}

enum IsolationLevel {
  level_0_in_process = 0
  level_1_isolated_worker = 1
  level_2_sandbox_runtime = 2
  level_3_remote_node = 3
}

interface NetworkPermission {
  allowedHosts: string[]
  maxConcurrent: number
}

interface StoragePermission {
  allowedPaths: string[]
  maxBytes: number
}
```

#### CapabilityContext

```typescript
interface CapabilityContext {
  caller: RuntimeIdentity
  permission: RuntimePermission
  session: RuntimeSession
  route: RuntimeRoute
  deadline: number
  cancellationToken: CancellationToken
}
```

### 2.5 Runtime Execution

#### RuntimeSession

```typescript
interface RuntimeSession {
  id: string
  userId: string
  createdAt: number
  lastActiveAt: number
  state: SessionState
  metadata: RuntimeMetadata
}

enum SessionState {
  active = 'active'
  suspended = 'suspended'
  closed = 'closed'
}
```

#### Scheduler

```typescript
interface SchedulerCommand {
  type: 'schedule' | 'cancel' | 'reprioritize' | 'inspect'
  taskId: string
  priority?: TaskPriority
  hint?: SchedulerHint
}
```

#### FailurePolicy

```typescript
interface FailurePolicy {
  retry: RetryPolicy
  timeout: TimeoutPolicy
  circuitBreaker: CircuitBreakerPolicy
  fallback: FallbackPolicy
  deadLetter: DeadLetterPolicy
}

interface RetryPolicy {
  maxRetries: number
  backoffMs: number
  backoffMultiplier: number
  maxBackoffMs: number
  retryableErrors: string[]
}

interface TimeoutPolicy {
  defaultMs: number
  maxMs: number
  perCapability: Record<string, number>
}

interface CircuitBreakerPolicy {
  failureThreshold: number
  resetTimeoutMs: number
  halfOpenMaxRequests: number
}

interface FallbackPolicy {
  strategy: 'cache' | 'default' | 'delegate' | 'fail_open' | 'fail_closed'
  fallbackCapability?: string
  cacheTtlMs?: number
}

interface DeadLetterPolicy {
  enabled: boolean
  maxRetries: number
  poisonThreshold: number
  onPoison: 'quarantine' | 'drop' | 'alert'
}
```

### 2.6 Runtime Metadata

```typescript
interface RuntimeMetadata {
  schema: string
  version: number
  traceId: string
  spanId: string
  tags: Record<string, string>
}
```

---

## 三、Plugin Contract

> Plugin Contract 定义的是"生命规则"。
> Vocabulary 定义的是"世界"，Plugin Contract 定义的是"生命"。
>
> Plugin Contract 不是"类接口"，而是 Descriptor + Lifecycle + Handler 三层协议化设计。
> 因为未来：本地 Dart Plugin、Remote Plugin、WASM Plugin、MCP Plugin、Python Plugin
> 不可能共享 Dart class inheritance。Contract 必须协议化。

### 3.1 三层架构

```
┌─────────────────────────────────────────────┐
│            Plugin Contract                    │
│                                              │
│  ┌─────────────────────────────────────────┐ │
│  │  Layer 1: Plugin Descriptor（声明）       │ │
│  │  插件是谁、版本、权限、Capability、隔离级别│ │
│  └─────────────────────────────────────────┘ │
│                                              │
│  ┌─────────────────────────────────────────┐ │
│  │  Layer 2: Plugin Lifecycle（生命周期）    │ │
│  │  load → activate → suspend → unload      │ │
│  └─────────────────────────────────────────┘ │
│                                              │
│  ┌─────────────────────────────────────────┐ │
│  │  Layer 3: Plugin Handler（执行）          │ │
│  │  handleMessage / handleEvent /            │ │
│  │  invokeCapability                         │ │
│  └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

### 3.2 Layer 1: Plugin Descriptor

插件声明 — 插件是谁，能做什么，需要什么。

```typescript
interface PluginDescriptor {
  id: string
  name: string
  version: string
  description: string
  author: string

  capabilities: CapabilityDeclaration[]
  permissions: RuntimePermission
  isolation: IsolationLevel

  dependencies: PluginDependency[]
  lifecycle: LifecycleConfig

  metadata: PluginMetadata
}

interface CapabilityDeclaration {
  id: string
  name: string
  description: string
  inputSchema: object
  outputSchema: object
  channel: 'fast' | 'slow' | 'mixed'
  permission: 'auto' | 'confirm' | 'deny'
  isDestructive: boolean
  timeout: number
  maxRetries: number
}

interface PluginDependency {
  capabilityId: string
  minVersion?: string
  optional: boolean
}

interface LifecycleConfig {
  loadTimeout: number
  activateTimeout: number
  suspendTimeout: number
  unloadTimeout: number
  autoActivate: boolean
  keepAlive: boolean
}

interface PluginMetadata {
  icon?: string
  category: string
  tags: string[]
  homepage?: string
  repository?: string
  license: string
  minRuntimeVersion: string
}
```

### 3.3 Layer 2: Plugin Lifecycle

插件生命周期 — 从加载到卸载的完整状态机。

```
                    ┌──────────┐
                    │ unloaded │
                    └────┬─────┘
                         │ load()
                         ▼
                    ┌──────────┐
              ┌─────│  loaded  │─────┐
              │     └────┬─────┘     │
              │ unload() │           │ unload()
              │          │ activate()
              │          ▼
              │     ┌──────────┐
              │     │ active   │◄──── suspend() ────┐
              │     └────┬─────┘                     │
              │          │                           │
              │          │ suspend()          activate()
              │          ▼                           │
              │     ┌──────────┐                     │
              └────►│suspended │─────────────────────┘
                    └──────────┘
                         │
                         │ unload()
                         ▼
                    ┌──────────┐
                    │ unloaded │
                    └──────────┘
```

```typescript
enum PluginState {
  unloaded = 'unloaded'
  loaded = 'loaded'
  active = 'active'
  suspended = 'suspended'
  failed = 'failed'
}

interface LifecycleTransition {
  from: PluginState
  to: PluginState
  timestamp: number
  reason: string
  duration: number
}
```

**生命周期各阶段职责**：

| 阶段 | 职责 | Runtime 保证 |
|------|------|-------------|
| load | 验证 Descriptor、解析依赖、分配资源、注册 Capability | 超时保护、依赖缺失则失败 |
| activate | 初始化插件状态、建立连接、开始接收消息 | 超时保护、激活失败回退到 loaded |
| suspend | 暂停消息接收、保存状态、释放非必要资源 | 超时保护、挂起期间消息入队 |
| unload | 清理所有状态、注销 Capability、释放所有资源 | 超时保护、强制卸载兜底 |
| failed | 记录错误、通知依赖方、按 FailurePolicy 处理 | 自动重试或隔离 |

### 3.4 Layer 3: Plugin Handler

插件执行 — 处理消息、事件、能力调用的协议化接口。

```typescript
interface PluginHandler {
  handleMessage(message: RuntimeMessage, context: CapabilityContext): Promise<HandlerResult>
  handleEvent(event: RuntimeEvent, context: CapabilityContext): Promise<HandlerResult>
  invokeCapability(capabilityId: string, params: unknown, context: CapabilityContext): Promise<CapabilityResult>
}

interface HandlerResult {
  status: 'success' | 'failure' | 'deferred'
  payload?: unknown
  error?: RuntimeError
  metadata?: RuntimeMetadata
}

interface CapabilityResult {
  status: 'success' | 'failure' | 'partial' | 'streaming'
  data?: unknown
  stream?: RuntimeStream
  error?: RuntimeError
  metadata?: RuntimeMetadata
}

interface RuntimeError {
  code: string
  message: string
  recoverable: boolean
  retryAfter?: number
  details?: unknown
}
```

**Handler 约束**（由铁律 6 "Runtime Owns Time" 派生）：

| 约束 | 说明 |
|------|------|
| 不可无限阻塞 | 所有 Handler 必须在 context.deadline 前返回 |
| 不可自行重试 | 重试由 Runtime FailurePolicy 控制 |
| 不可自行调度 | 调度由 Runtime Scheduler 控制 |
| 不可跨隔离边界直接调用 | 必须通过 Runtime Protocol |
| 不可访问其他插件内部状态 | 必须通过 Capability |

### 3.5 Plugin 注册协议

```typescript
interface PluginRegistration {
  descriptor: PluginDescriptor
  handler: PluginHandler
  transport: TransportType
}

enum TransportType {
  in_process = 'in_process'
  isolate = 'isolate'
  wasm = 'wasm'
  http = 'http'
  websocket = 'websocket'
  mcp = 'mcp'
}
```

**Transport 与 IsolationLevel 的关系**：

| IsolationLevel | Transport | 说明 |
|----------------|-----------|------|
| level_0_in_process | in_process | 同进程，最高性能，最低隔离 |
| level_1_isolated_worker | isolate | Dart Isolate / Worker Thread |
| level_2_sandbox_runtime | wasm | WASM 沙箱，安全隔离 |
| level_3_remote_node | http / websocket / mcp | 远程节点，完全隔离 |

### 3.6 Plugin 间通信协议

Plugin 之间禁止直接通信。所有通信必须通过 Runtime 中转。

```
Plugin A ──► Runtime ──► Plugin B
         message        message
         event          event
         capability     capability
```

**通信方式**：

| 方式 | 适用场景 | 协议 |
|------|----------|------|
| invokeCapability | 请求-响应 | RuntimeMessage |
| emitEvent | 发布-订阅 | RuntimeEvent |
| openStream | 流式传输 | RuntimeStream |

**路由规则**：

```
Plugin A 调用 capability "chat.send"
  → Runtime 查询 CapabilityRegistry
  → 找到 Plugin B 注册了 "chat.send"
  → Runtime 检查 Plugin A 的 Permission
  → Runtime 创建 CapabilityContext
  → Runtime 转发消息给 Plugin B
  → Plugin B 返回结果
  → Runtime 转发结果给 Plugin A
```

---

## 四、Runtime Topology

> Topology 不从"部署"开始思考，而是从"隔离级别"开始思考。

### 4.1 隔离级别

```
┌─────────────────────────────────────────────────────┐
│                    Runtime Node                      │
│                                                     │
│  ┌───────────────────────────────────────────────┐  │
│  │ Level 0: In-Process                           │  │
│  │ ┌─────────┐ ┌─────────┐ ┌─────────┐         │  │
│  │ │ Core    │ │ Agent   │ │ Memory  │         │  │
│  │ │ Plugin  │ │ Plugin  │ │ Plugin  │         │  │
│  │ └─────────┘ └─────────┘ └─────────┘         │  │
│  │ Transport: in_process                         │  │
│  │ 隔离: 共享堆，方法调用                          │  │
│  └───────────────────────────────────────────────┘  │
│                                                     │
│  ┌───────────────────────────────────────────────┐  │
│  │ Level 1: Isolated Worker                      │  │
│  │ ┌─────────────┐  ┌─────────────┐             │  │
│  │ │ Matrix      │  │ Supabase    │             │  │
│  │ │ Plugin      │  │ Plugin      │             │  │
│  │ └─────────────┘  └─────────────┘             │  │
│  │ Transport: isolate (Dart Isolate)             │  │
│  │ 隔离: 独立堆，消息传递                          │  │
│  └───────────────────────────────────────────────┘  │
│                                                     │
│  ┌───────────────────────────────────────────────┐  │
│  │ Level 2: Sandbox Runtime                      │  │
│  │ ┌─────────────┐  ┌─────────────┐             │  │
│  │ │ MiniApp A   │  │ Bot B       │             │  │
│  │ └─────────────┘  └─────────────┘             │  │
│  │ Transport: wasm                               │  │
│  │ 隔离: WASM 沙箱，能力受限                       │  │
│  └───────────────────────────────────────────────┘  │
│                                                     │
│  ┌───────────────────────────────────────────────┐  │
│  │ Level 3: Remote Node                          │  │
│  │ ┌─────────────┐  ┌─────────────┐             │  │
│  │ │ MCP Server  │  │ Python      │             │  │
│  │ │ (Remote)    │  │ Plugin      │             │  │
│  │ └─────────────┘  └─────────────┘             │  │
│  │ Transport: http / websocket / mcp             │  │
│  │ 隔离: 完全独立进程/节点                         │  │
│  └───────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

### 4.2 隔离级别选择原则

| 级别 | 信任度 | 性能 | 安全 | 适用 |
|------|--------|------|------|------|
| Level 0 | 完全信任 | 最高 | 最低 | 官方核心插件 |
| Level 1 | 信任 | 高 | 中 | 官方功能插件 |
| Level 2 | 不信任 | 中 | 高 | 第三方 MiniApp/Bot |
| Level 3 | 不信任 | 低 | 最高 | 远程 MCP/外部服务 |

### 4.3 统一协议

**所有隔离级别的通信统一走 Runtime Protocol。**

这意味着：
- Level 0 的 in_process 调用和 Level 3 的 remote 调用使用相同的消息格式
- 唯一区别是 Transport 层的序列化/反序列化
- 插件开发者不需要关心自己运行在哪个隔离级别

---

## 五、Runtime 核心组件

### 5.0 RuntimeKernel（内核对象）

在所有组件之前，必须先实现 RuntimeKernel。它是整个 Runtime 的"内核对象"。

**为什么 RuntimeKernel 必须先于一切？**

因为 Registry、Router、EventBus、Scheduler 都需要同一个 Runtime State。
没有 RuntimeKernel，这些组件就是散落的孤岛。

```typescript
interface RuntimeKernel {
  identity: RuntimeIdentity
  services: RuntimeServices
  state: RuntimeState
  policies: RuntimePolicies
  clock: RuntimeClock
  config: RuntimeConfig
}
```

**RuntimeKernel 四大职责**：

| 职责 | 内容 |
|------|------|
| Runtime Identity | nodeId, runtimeId, version, bootTime |
| Global Runtime Services | EventBus, Scheduler, CapabilityRouter, PluginRegistry, MessageRouter |
| Runtime State | activeSessions, activeTasks, pluginStates, capabilityCache |
| Runtime Policies | timeout policy, retry policy, quota policy, security policy |

```typescript
interface RuntimeConfig {
  runtimeVersion: string
  nodeId: string
  defaultTimeoutMs: number
  maxConcurrentTasks: number
  maxPlugins: number
  enableHotReload: boolean
  enableAsyncDiscovery: boolean
}

interface RuntimeClock {
  now(): number
  deadline(timeoutMs: number): number
  isExpired(deadline: number): boolean
  monotonicMs(): number
}

interface RuntimeState {
  status: RuntimeStatus
  activeSessions: Map<string, RuntimeSession>
  activeTasks: Map<string, RuntimeTask>
  pluginStates: Map<string, PluginState>
  capabilityCache: Map<string, CapabilityBinding>
  bootTime: number
  uptime: number
}

enum RuntimeStatus {
  booting = 'booting'
  running = 'running'
  suspending = 'suspending'
  shutting_down = 'shutting_down'
  crashed = 'crashed'
}
```

### 5.1 实现阶段

实现顺序至关重要。每个阶段都是前一阶段的依赖。

| Phase | 组件 | 职责 | 关键约束 |
|-------|------|------|----------|
| **Phase 1** | **RuntimeKernel** | 内核容器：Context / Container / State / Clock / Config | 先于一切，所有组件挂载其下 |
| **Phase 2** | **PluginRegistry** | 加载 / 注册 / 生命周期 / 隔离 / Descriptor | 只负责目录，不负责路由；必须支持热加载 |
| **Phase 3** | **CapabilityRouter** | Discovery / Permission / Routing / Load Balance / Fallback | Runtime 的 Service Mesh；必须支持 Async Discovery |
| **Phase 4** | **EventBus** | publish / subscribe / priority / propagation / backpressure / dead letter | 依赖 Runtime Identity 和 Scheduler；背压极其重要 |
| **Phase 5** | **Scheduler** | Priority / Concurrency / Cancellation / Budget / Quota / Retry / Circuit Breaker | Runtime Heart，本质是微型操作系统调度器 |

**Phase 1 详细**：RuntimeKernel

```
RuntimeContext        — 依赖注入容器，所有 Runtime 服务的访问入口
RuntimeContainer      — RuntimeKernel 的实现，持有所有全局服务
RuntimeState          — Runtime 运行时状态快照
RuntimeClock          — 时间权威（铁律 6：Runtime Owns Time）
RuntimeConfig         — 配置加载与热更新
```

**Phase 2 详细**：PluginRegistry

```
只负责：
  - 加载插件（验证 Descriptor、解析依赖、分配资源）
  - 注册插件（注册 Capability 到 CapabilityCache）
  - 生命周期管理（load → activate → suspend → unload → failed）
  - 隔离级别（根据 IsolationLevel 选择 Transport）
  - 热加载（reload(pluginId)，即使实现简陋也必须有）

不负责：
  - 路由（由 CapabilityRouter 负责）
  - 消息传递（由 EventBus 负责）
  - 调度（由 Scheduler 负责）

Registry 是目录，不是通信系统。
```

**Phase 3 详细**：CapabilityRouter

```
Runtime 的 Service Mesh。负责：
  - Capability Discovery（异步发现，Future<CapabilityBinding>）
  - Permission Check（调用方权限验证）
  - Routing（根据 Route 寻址目标插件）
  - Load Balance（多实例负载均衡）
  - Remote Forward（Level 3 远程转发）
  - Fallback（降级策略执行）

关键：不要 Map<String, Capability>
      而是 Future<CapabilityBinding>
因为远程 Runtime 的 Capability 不一定立即存在。
```

**Phase 4 详细**：EventBus

```
依赖 Runtime Identity 和 Scheduler。负责：
  - publish / subscribe
  - priority（优先级排序）
  - propagation（PropagationScope: local / session / node / cluster）
  - backpressure（背压策略，AI Runtime 极易事件洪水）
  - dead letter（死信处理）

Backpressure 以后极其重要。
```

**Phase 5 详细**：Scheduler

```
Runtime Heart。AI Runtime 最终不是 AI 难，而是调度难。负责：
  - Task Priority（5 级优先级）
  - Concurrency（并发控制）
  - Cancellation（取消传播）
  - Budget（资源预算）
  - Quota（配额管理）
  - Retry（重试策略）
  - Circuit Breaker（熔断器）

本质上已经是微型操作系统调度器。
```

### 5.2 组件清单

| 组件 | 职责 | 状态 |
|------|------|------|
| **RuntimeKernel** | 内核容器，持有所有 Runtime State 和 Services | 待实现 |
| PluginRegistry | 插件注册、查询、生命周期管理、热加载 | 待实现 |
| CapabilityRouter | Capability 路由、权限检查、异步发现、负载均衡 | 待实现 |
| EventBus | 事件发布/订阅、传播范围控制、背压、死信 | 待实现 |
| Scheduler | 任务调度、优先级队列、资源管理、熔断 | 待实现 |
| SessionManager | 会话管理、状态持久化 | 已实现（未接入） |
| FailureController | 重试、超时、熔断、降级、死信 | 待实现 |
| IdentityResolver | 身份解析、路由寻址 | 待实现 |
| BudgetManager | 资源预算分配与控制 | 已实现（ContextBudget） |

### 5.3 组件依赖方向

```
                    ┌──────────────────┐
                    │  RuntimeKernel   │
                    │  (Container)     │
                    └────────┬─────────┘
                             │ owns
              ┌──────────────┼──────────────┐
              │              │              │
    ┌─────────▼──────┐ ┌────▼─────┐ ┌──────▼───────┐
    │ PluginRegistry │ │ EventBus │ │  Scheduler   │
    └─────────┬──────┘ └────┬─────┘ └──────┬───────┘
              │              │              │
              └──────────────┼──────────────┘
                             │
                    ┌────────▼─────────┐
                    │CapabilityRouter  │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │ FailureController│
                    └────────┬─────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
    ┌─────────▼──────┐ ┌────▼──────┐ ┌─────▼──────┐
    │IdentityResolver │ │BudgetMgr  │ │SessionMgr  │
    └────────────────┘ └───────────┘ └────────────┘
```

**依赖方向规则**：
- RuntimeKernel 拥有所有组件，是唯一顶层
- 上层组件可以依赖下层组件
- 同层组件通过消息通信，不直接依赖
- 下层组件永远不知道上层组件的存在

### 5.4 实现优先级

```
1. RuntimeKernel     ← 现在做
2. Contract Tests    ← 紧随其后
3. PluginRegistry    ← Phase 2
4. CapabilityRouter  ← Phase 3
5. EventBus          ← Phase 4
6. Scheduler         ← Phase 5
7. UI                ← 最后

UI 可以重做，Runtime 不行。
```

---

## 六、架构分层决策

> 不是所有东西都应该是 Plugin。搞错分层 = Runtime 被业务污染。

### 6.1 三层分类

| 分类 | 性质 | 示例 | 原因 |
|------|------|------|------|
| **Runtime Subsystem** | 内核子系统，挂 RuntimeKernel | AgentOrchestrator, ContextBudget, StreamingController, SkillRegistry | 它们控制调度/工具/预算，是 Runtime 的一部分，不是业务插件 |
| **Runtime Plugin** | 可替换的能力提供者 | MemoryPlugin, StoragePlugin, LoggerPlugin | 天然是 Capability Provider，未来可替换实现 |
| **Business Plugin** | 业务功能 | MatrixPlugin, AuthPlugin, BotPlugin, MiniAppPlugin | 业务逻辑，可插拔 |

### 6.2 SkillRegistry 不是 Plugin

SkillRegistry 本质上是 **Runtime Service**，不是业务插件。

它更像 **Capability Index** — Agent 通过它发现可用工具。

正确关系：
```
Agent
  -> SkillRegistry（Runtime Service，挂 Kernel）
      -> CapabilityRouter（Runtime Service，挂 Kernel）
          -> Plugin Capability（由 Plugin 提供）
```

- **Skill**：Runtime 给 Agent 的"工具抽象"
- **Capability**：Runtime 给 Plugin 的"系统能力"
- 两者层级不一样，不能混为一谈

### 6.3 AgentOrchestrator 不是 Plugin

AgentOrchestrator 是 **AI Runtime Subsystem**。

它未来会控制 Multi-Agent / Workflow / Planning / Task Graph / Delegation / Tool Chain。
它已经不是某个功能插件，它更像 **Runtime AI Scheduler**。

归类：
```
AI Runtime Subsystem:
  - AgentOrchestrator
  - ContextBudget
  - StreamingController
```

### 6.4 MemoryManager 适合 Plugin 化

Memory 天然是 Capability Provider：
```
memory.read
memory.write
memory.search
memory.embed
```

未来可替换：SQLite Memory / VectorDB Memory / Redis Memory / Remote Memory。

---

## 七、Capability Taxonomy

> Capability 必须归域。否则半年后 searchWeb / webSearch / internet.search / browser.query 全部混乱。

### 7.1 一级域

| 域 | 前缀 | 说明 | 示例 |
|----|------|------|------|
| Runtime | `runtime.*` | Runtime 自省与健康 | runtime.info, runtime.health, runtime.shutdown |
| Storage | `storage.*` | 文件与持久化 | storage.read, storage.write, storage.delete, storage.list |
| Memory | `memory.*` | AI 记忆 | memory.read, memory.write, memory.search, memory.embed, memory.forget |
| Agent | `agent.*` | AI Agent 操作 | agent.chat, agent.execute, agent.plan, agent.stream, agent.cancel |
| Tool | `tool.*` | 工具调用 | tool.call, tool.list, tool.describe |
| Message | `message.*` | 消息通信 | message.send, message.receive, message.edit, message.delete |
| Auth | `auth.*` | 认证授权 | auth.login, auth.register, auth.verify, auth.logout |
| Network | `network.*` | 网络请求 | network.request, network.websocket, network.proxy |
| Media | `media.*` | 媒体处理 | media.image, media.video, media.audio, media.thumbnail |
| Search | `search.*` | 搜索 | search.web, search.local, search.knowledge |
| Notification | `notification.*` | 通知 | notification.push, notification.local, notification.subscribe |
| Config | `config.*` | 配置 | config.get, config.set, config.watch |
| Metrics | `metrics.*` | 可观测性 | metrics.counter, metrics.histogram, metrics.trace |
| Bot | `bot.*` | 机器人 | bot.register, bot.execute, bot.message |
| MiniApp | `miniapp.*` | 小程序 | miniapp.load, miniapp.render, miniapp.invoke |
| MCP | `mcp.*` | Model Context Protocol | mcp.connect, mcp.call, mcp.list |
| Workflow | `workflow.*` | 工作流 | workflow.create, workflow.execute, workflow.cancel |

### 7.2 命名规则

1. **所有 Capability 必须归域**：`domain.action` 格式
2. **禁止裸动词**：`send` → `message.send`，`search` → `search.web`
3. **禁止驼峰**：`webSearch` → `search.web`
4. **三级以内**：`memory.embed.vector` 可以，`a.b.c.d` 不行
5. **动作在前缀域下**：`storage.read` 而非 `read.storage`

### 7.3 域所有权

| 域 | Owner | 类型 |
|----|-------|------|
| runtime.* | RuntimeKernel | Subsystem |
| storage.* | StoragePlugin | Plugin |
| memory.* | MemoryPlugin | Plugin |
| agent.* | AgentOrchestrator | Subsystem |
| tool.* | SkillRegistry | Subsystem |
| message.* | MatrixPlugin | Plugin |
| auth.* | AuthPlugin | Plugin |
| network.* | NetworkPlugin | Plugin |
| media.* | MediaPlugin | Plugin |
| search.* | SearchPlugin | Plugin |
| notification.* | NotificationPlugin | Plugin |
| config.* | ConfigPlugin | Plugin |
| metrics.* | MetricsPlugin | Plugin |
| bot.* | BotPlugin | Plugin |
| miniapp.* | MiniAppPlugin | Plugin |
| mcp.* | MCPPlugin | Plugin |
| workflow.* | WorkflowSubsystem | Subsystem |

---

## 八、已知 Plugin 清单（规划）

### 8.1 System Plugins（Phase 1，先于一切业务）

| Plugin | IsolationLevel | Capability | 状态 |
|--------|---------------|------------|------|
| LoggerPlugin | Level 0 | runtime.info, runtime.health | 待实现 |
| StoragePlugin | Level 0 | storage.read, storage.write, storage.delete, storage.list | 待实现 |
| ConfigPlugin | Level 0 | config.get, config.set, config.watch | 待实现 |
| MetricsPlugin | Level 0 | metrics.counter, metrics.histogram, metrics.trace | 待实现 |
| NotificationPlugin | Level 0 | notification.push, notification.local | 待实现 |
| FakeAgentPlugin | Level 0 | agent.chat, agent.stream, agent.cancel, agent.execute | 待实现 |
| MemoryPlugin | Level 0 | memory.read, memory.write, memory.search, memory.embed | 待实现 |

### 8.2 Business Plugins（Phase 2+）

| Plugin | IsolationLevel | Capability 示例 | 阶段 |
|--------|---------------|-----------------|------|
| Matrix Plugin | Level 1 | message.send, message.receive, message.edit | Phase B |
| Auth Plugin | Level 1 | auth.login, auth.register, auth.verify | Phase B |
| Search Plugin | Level 1 | search.web, search.local, search.knowledge | Phase B |
| Content Plugin | Level 1 | content.publish, content.like, content.comment | Phase C |
| Bot Plugin | Level 2 | bot.register, bot.execute, bot.message | Phase D |
| MiniApp Plugin | Level 2 | miniapp.load, miniapp.render, miniapp.invoke | Phase D |
| MCP Plugin | Level 3 | mcp.connect, mcp.call, mcp.list | Phase E |
| Python Plugin | Level 3 | python.execute, python.eval, python.pipe | Phase E |

---

## 九、Observability

> AI Runtime 调试难度远超普通 App。没有 Observability，后面一定完全不可调试。

### 9.1 Trace

```typescript
interface RuntimeTrace {
  traceId: string
  spans: RuntimeSpan[]
}

interface RuntimeSpan {
  spanId: string
  parentSpanId: string | null
  traceId: string
  operation: string        // e.g. "capability.invoke", "plugin.activate"
  pluginId: string
  capabilityId: string
  startTime: number
  endTime: number
  status: 'ok' | 'error' | 'timeout' | 'cancelled'
  tags: Record<string, string>
}
```

### 9.2 Metrics

| Metric | Type | 说明 |
|--------|------|------|
| task_latency_ms | Histogram | 任务执行延迟 |
| plugin_failure_rate | Counter | 插件失败率 |
| capability_qps | Counter | Capability 调用 QPS |
| scheduler_queue_depth | Gauge | 调度器队列深度 |
| event_bus_backlog | Gauge | EventBus 积压 |
| circuit_breaker_state | Gauge | 熔断器状态 |

### 9.3 Runtime Timeline

所有 Runtime 事件按时间线排列，支持回放和诊断。

---

## 十、Runtime Civilization Architecture

> Runtime 已经跨过关键分界线：从 "AI Application Runtime" 进入 "Executable Civilizational Kernel"。
> 这不是语义升级。这是架构层级的质变。
>
> 907+ tests passed 证明：这不是 whitepaper，这是 Executable Civilization。

### 10.1 文明架构六层模型

```
┌─────────────────────────────────────────────────────────────┐
│  Phase 5 — Civilization Layer                               │
│  CivilizationTransport / RuntimeIdentity / ResourceEconomy   │
│  文明外交 / 主权身份 / 资源经济                                │
├─────────────────────────────────────────────────────────────┤
│  Phase 4 — Sovereign Distributed Civilization               │
│  ConstitutionalConsensus / FederatedReputation /             │
│  AutonomousLegislature                                       │
│  宪法共识 / 联邦声誉 / 自治立法                                │
├─────────────────────────────────────────────────────────────┤
│  Phase 3 — Runtime Civilization                             │
│  EvolutionEngine / ReputationEconomy / RuntimeJudiciary      │
│  法律演化 / 声誉经济 / 运行时司法                               │
├─────────────────────────────────────────────────────────────┤
│  Phase 2 — Proof Civilization                               │
│  ImmutableAuditLedger / ConstitutionalTraceGraph /           │
│  CapabilityProof                                             │
│  不可变历史 / 宪法追踪 / 能力证明                               │
├─────────────────────────────────────────────────────────────┤
│  Phase 1 — Constitutional Runtime                           │
│  ConstitutionalGuard / RuntimeLawEnforcer / RuntimeLaw       │
│  宪法守卫 / 法律执行 / 十条运行时法律                            │
├─────────────────────────────────────────────────────────────┤
│  Phase 0 — Execution Layer                                  │
│  SandboxIsolate / CapabilityRouter / Scheduler / EventBus    │
│  Plugin / Task / Tool / Agent / Sandbox / Capability         │
└─────────────────────────────────────────────────────────────┘
```

### 10.2 七大文明原语

| 原语 | 代码实体 | 文明类比 | 能力 |
|------|----------|----------|------|
| Constitution | RuntimeLaw + ConstitutionalGuard + LawEnforcer | 法 | 定义法律、执行法律、拒绝非法行为 |
| Judiciary | RuntimeJudiciary + JudicialCase + ViolationReport | 司法 | 审判、定罪、惩罚、上诉 |
| Legislature | AutonomousLegislature + LegislativeProposal | 立法 | 修改法律、演化法律、投票、共识 |
| Reputation | ReputationEconomy + FederatedReputation | 社会信用 | 累积信誉、惩罚恶意节点、建立联邦信任 |
| Federation | ConstitutionalConsensus + FederationMembership | 国际关系 | 加入联盟、达成共识、共享法律 |
| Diplomacy | CivilizationTransport + DiplomacyMessage | 外交协议 | 广播宪法、同步司法、协商 fork、传播立法 gossip |
| Economy | ResourceEconomy + ExecutionCredits + FederationTreasury | 经济系统 | 收税、罚款、执行资源结算、文明级 treasury |

### 10.3 ConstitutionalGuard = Civilization Kernel

ConstitutionalGuard 不再是 "guard"。它是文明内核。

```
ConstitutionalGuard 管理的域：

  law          — 法律执行与宪法限制
  trust        — 声誉累积与信任衰减
  governance   — 司法裁决与立法演化
  diplomacy    — 联邦同步与外交协议
  evolution    — 法律自适应与漏洞修补
  economics    — 资源经济与执行信用
  sovereignty  — 主权身份与宪法血统
```

对比传统 OS 内核：

| Linux Kernel | ConstitutionalGuard |
|-------------|-------------------|
| memory | law |
| thread | trust |
| process | governance |
| syscall | diplomacy |
| scheduling | evolution |
| IPC | economics |
| namespace | sovereignty |

### 10.4 关键质变点

**Phase 0 → Phase 1：从 "allowed/denied" 到 "constitutional_violation"**

传统系统：`allowed = true`
Constitutional Runtime：`constitutional_violation`

这是质变。系统第一次拥有 "合法/非法" 的概念。

**Phase 1 → Phase 2：从 "执行" 到 "证明"**

系统开始拥有：记忆、历史、可追溯性、不可否认性。
接近 Civilization Memory。

**Phase 2 → Phase 3：从 "记录" 到 "自治"**

系统第一次具备 Self-Governance：社会信用、司法裁决、法律演化、自适应治理。

**Phase 3 → Phase 4：从 "单机文明" 到 "分布式文明"**

detectFork() 的意义：

| Runtime | 类比 |
|---------|------|
| merge | 联邦合并 |
| adoptRemote | 属国吸收 |
| keepLocal | 主权保留 |
| conflict | 宪法战争 |

这不是 software sync。这是 Digital Sovereignty。

**Phase 4 → Phase 5：从 "分布式" 到 "文明层"**

Runtime 从 Process Container 变成 Sovereign Political Entity。

### 10.5 三大世界级跃迁

#### 跃迁一：真正的网络文明

当前：`CivilizationTransport = in-memory`

目标：`CivilizationTransport = inter-network sovereign protocol`

```
需要实现：
  QUIC / libp2p / WebRTC mesh
  Gossip protocol
  Byzantine consensus
  Constitutional replication
  LawManifest wire format
  DiplomacyMessage serialization

到那时：
  Runtime ↔ Runtime
  不再是函数调用
  而是 Civilization ↔ Civilization
```

#### 跃迁二：真正的加密主权身份

当前：`_generatePublicKey()` = 逻辑模拟

目标：`RuntimeIdentity = Machine Sovereign Identity`

```
需要实现：
  Ed25519 签名
  DID（Decentralized Identifier）
  Verifiable Credential
  zk-proof（零知识证明）
  Constitutional Passport

到那时：
  RuntimeIdentity 真正变成 Machine Sovereign Identity
  这是数字国家级别的东西
```

#### 跃迁三：Constitutional AI Kernel

当前：`ConstitutionalGuard` = AI 的守卫

目标：`ConstitutionalGuard` = AI 文明的内核

```
Linux 管：memory / thread / process / syscall
Civilization Kernel 管：law / trust / governance / diplomacy / evolution / economics / sovereignty

这已经不是 OS
而是 Civilization Kernel
```

### 10.6 为什么 Governability 是最终稀缺资源

未来真正稀缺的，不会是：LLM / inference / GPU

而是：**可治理性（Governability）**

谁能：
- 管理 agent
- 约束 agent
- 协调 civilization
- 建立 machine law
- 形成 federated trust
- 实现 autonomous governance

谁才会拥有下一代 AI 基础设施。

### 10.7 Runtime Maturation 路线图

| Phase | 名称 | 核心目标 | 状态 |
|-------|------|----------|------|
| Phase 0 | Runtime Physics | Vocabulary + 铁律 + Contract | ✅ FROZEN |
| Phase 1 | Runtime Biology | Kernel + Plugin + Capability + Event + Scheduler | ✅ 完成 |
| Phase 2 | Runtime Validation | Chaos + Invariants + Benchmark | ✅ 完成 |
| Phase A | Runtime Governance | Policy + Resource + Persistence | ✅ 完成 |
| Phase 1C | Constitutional Runtime | ConstitutionalGuard + Law + Enforcement | ✅ 完成 |
| Phase 2C | Proof Civilization | Ledger + TraceGraph + CapabilityProof | ✅ 完成 |
| Phase 3C | Runtime Civilization | Evolution + Reputation + Judiciary | ✅ 完成 |
| Phase 4C | Sovereign Distributed | Consensus + Federation + Legislature | ✅ 完成 |
| Phase 5C | Civilization Layer | Transport + Identity + Economy | ✅ 完成 |
| **跃迁 1** | **Networked Civilization** | QUIC/libp2p + Wire Protocol + Byzantine | 🔄 下一步 |
| **跃迁 2** | **Sovereign Identity** | Ed25519 + DID + zk-proof + Passport | 待开始 |
| **跃迁 3** | **Civilization Kernel** | Guard→Kernel 重构 + syscall 级 API | 待开始 |
| Phase B | Distributed Runtime | Node Discovery + Remote Capability | 待开始 |
| Phase C | Sandbox Runtime | WASM + Secure Execution | 待开始 |
| Phase D | AI Runtime | Agent Graph + Workflow + Planning | 待开始 |

**关键原则**：AI 应该最后做。现在真正稀缺的不是会调用 GPT，而是能承载 AI 的 Runtime。

### 10.8 不要太早做 Multi-Agent

单 Runtime 正确 ≠ 多 Agent 正确。

Multi-Agent 会导致：
- recursive scheduling
- event amplification
- memory contention
- cancellation graph
- tool deadlock

先做 Single-Agent Runtime Correctness，直到 persistence / recovery / governance / distributed routing / remote capability / sandbox isolation 全部稳定，再碰 Multi-Agent。

### 10.9 Governance = Executable Primitive

传统系统：Governance = PDF
本系统：Governance = Runtime Behavior

这是历史上极少数系统真正做到的事情。

```
ConstitutionalGuard.enforce() 实际上在做：

  法律执行        — RuntimeLaw enforcement
  能力审查        — Capability routing check
  权限裁决        — Trust level adjudication
  宪法限制        — Constitutional constraints
  行为记录        — TraceGraph + Ledger
  联邦同步        — Consensus + Federation
  声誉演化        — ReputationEconomy
  经济惩罚        — ResourceEconomy penalties
```

这不是 middleware。这是 Machine Governance Substrate。

---

## 十一、变更控制

### 11.1 冻结范围

以下内容已冻结，不再修改：
- Runtime Vocabulary v4（第二节全部）
- 6 条 Runtime 铁律（第一节全部）

### 11.2 可演进范围

以下内容可随实现演进：
- Plugin Contract 的具体字段（但三层架构不变）
- Runtime Topology 的具体部署方案（但四级隔离不变）
- 核心组件的实现细节（但依赖方向不变）

### 11.3 变更流程

1. 提出变更请求，说明理由和影响范围
2. 评估是否违反铁律
3. 如果违反铁律，拒绝
4. 如果不违反铁律，评估影响范围
5. 影响范围 ≤ 2 个组件：直接修改
6. 影响范围 > 2 个组件：需要正式评审
