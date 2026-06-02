enum RfcStatus { draft, proposed, accepted, frozen, superseded, rejected }

enum RfcCategory {
  core,
  protocol,
  governance,
  distributed,
  security,
  sdk,
  deprecation,
}

class RuntimeRfc {
  final String id;
  final String title;
  final RfcStatus status;
  final RfcCategory category;
  final String author;
  final int createdAt;
  final int? frozenAt;
  final String summary;
  final String motivation;
  final String specification;
  final String? breakingChanges;
  final String? migrationGuide;
  final String? supersededBy;

  const RuntimeRfc({
    required this.id,
    required this.title,
    required this.status,
    required this.category,
    required this.author,
    required this.createdAt,
    this.frozenAt,
    required this.summary,
    required this.motivation,
    required this.specification,
    this.breakingChanges,
    this.migrationGuide,
    this.supersededBy,
  });
}

class RuntimeSpecRegistry {
  final Map<String, RuntimeRfc> _rfcs = {};

  RuntimeSpecRegistry() {
    _registerFrozenRfcs();
  }

  List<RuntimeRfc> get rfcs => _rfcs.values.toList();
  List<RuntimeRfc> get frozenRfcs =>
      _rfcs.values.where((r) => r.status == RfcStatus.frozen).toList();
  List<RuntimeRfc> get activeRfcs => _rfcs.values
      .where(
        (r) => r.status == RfcStatus.accepted || r.status == RfcStatus.frozen)
      .toList();

  RuntimeRfc? getRfc(String id) => _rfcs[id];

  void register(RuntimeRfc rfc) {
    _rfcs[rfc.id] = rfc;
  }

  void _registerFrozenRfcs() {
    register(
      const RuntimeRfc(
        id: 'RFC-001',
        title: 'Runtime Lifecycle Semantics',
        status: RfcStatus.frozen,
        category: RfcCategory.core,
        author: 'runtime-team',
        createdAt: 0,
        frozenAt: 0,
        summary:
            'Defines the lifecycle of Runtime: boot → running → shutdown. '
            'All components must respect this lifecycle. No component may operate outside it.',
        motivation:
            'Without a defined lifecycle, components can initialize in arbitrary order, '
            'leading to dependency violations and race conditions.',
        specification:
            '1. RuntimeContainer.boot() transitions state: uninitialized → booting → running.\n'
            '2. RuntimeContainer.shutdown() transitions: running → shutting → stopped.\n'
            '3. No capability invocation is allowed before running state.\n'
            '4. All plugins must be unloaded before shutdown completes.\n'
            '5. Event journal records boot and shutdown as immutable entries.'));

    register(
      const RuntimeRfc(
        id: 'RFC-002',
        title: 'Capability Discovery and Invocation',
        status: RfcStatus.frozen,
        category: RfcCategory.core,
        author: 'runtime-team',
        createdAt: 0,
        frozenAt: 0,
        summary:
            'Capabilities are discovered through CapabilityRouter. '
            'Invocation goes through: discover → policy check → resource check → invoke.',
        motivation:
            'Direct plugin-to-plugin invocation creates hidden dependencies. '
            'Capability-based routing enables governance, policy enforcement, and remote invocation.',
        specification:
            '1. All capabilities must be declared in PluginDescriptor.\n'
            '2. CapabilityRouter.discover() returns a Route with pluginId and capability metadata.\n'
            '3. PolicyEngine.evaluate() must return ALLOW before invocation proceeds.\n'
            '4. ResourceController.tryAcquireTokens() must succeed before invocation.\n'
            '5. Capability invocation returns CapabilityResult with status: success/failure/unavailable.'));

    register(
      const RuntimeRfc(
        id: 'RFC-003',
        title: 'Wire Protocol',
        status: RfcStatus.frozen,
        category: RfcCategory.protocol,
        author: 'runtime-team',
        createdAt: 0,
        frozenAt: 0,
        summary:
            'Defines the frame format, handshake, ack, heartbeat, and chunking protocol '
            'for inter-node communication.',
        motivation:
            'Without a defined wire protocol, each transport implements its own framing, '
            'leading to incompatible message formats and unreliable delivery.',
        specification:
            '1. All communication uses WireFrame with: frameId, type, source, target, hlcTime.\n'
            '2. Connection starts with HandshakeFrame/HandshakeAckFrame negotiation.\n'
            '3. Data frames require AckFrame response within ackTimeout.\n'
            '4. HeartbeatFrame sent every heartbeatInterval.\n'
            '5. Large messages are chunked into WireEnvelope with correlationId.\n'
            '6. Protocol version negotiation happens during handshake.'));

    register(
      const RuntimeRfc(
        id: 'RFC-004',
        title: 'Lease Semantics',
        status: RfcStatus.frozen,
        category: RfcCategory.governance,
        author: 'runtime-team',
        createdAt: 0,
        frozenAt: 0,
        summary:
            'Unifies Session Lease, Resource Ownership, and Capability Lock '
            'into a single Lease Semantics with acquire/renew/release/revoke lifecycle.',
        motivation:
            'Three independent lease-like mechanisms (session lease, resource budget, '
            'capability binding) share the same semantics but were implemented separately. '
            'Unification reduces Primitive count and increases consistency.',
        specification:
            '1. UnifiedLease has type: session | resource | capability.\n'
            '2. Each lease type has its own TTL (session: 30s, resource: 60s, capability: 15s).\n'
            '3. Single Writer Principle: only the lease owner can write.\n'
            '4. Lease expiry is detected by tickExpiry().\n'
            '5. Expired leases are reclaimed after grace period.\n'
            '6. Remote lease state is synchronized via receiveLeaseState().'));

    register(
      const RuntimeRfc(
        id: 'RFC-005',
        title: 'Distributed Invariants',
        status: RfcStatus.frozen,
        category: RfcCategory.distributed,
        author: 'runtime-team',
        createdAt: 0,
        frozenAt: 0,
        summary:
            '7 frozen distributed invariants: Per-Session Ordering, Differentiated Delivery, '
            'Single Writer Session, Eventually Consistent Capabilities, HLC Time Authority, '
            'Node Isolation, Network Is Hostile.',
        motivation:
            'Distributed systems without explicit invariants inevitably develop inconsistencies. '
            'Defining invariants before implementation prevents semantic collapse.',
        specification:
            '1. Message Ordering: Per-Session Ordering. Cross-session not guaranteed.\n'
            '2. Delivery: Capability=AtMostOnce, Event=AtLeastOnce, Journal=ExactlyOnce.\n'
            '3. Session Ownership: Single Writer Principle. One node writes at a time.\n'
            '4. Capability Consistency: Eventually Consistent via Gossip.\n'
            '5. Time Authority: Hybrid Logical Clock for all ordering.\n'
            '6. Failure Domain: Node failure is isolated. No cascading.\n'
            '7. Network: Always hostile. Design for latency, loss, partition.'));

    register(
      const RuntimeRfc(
        id: 'RFC-006',
        title: 'Write-Ahead Log',
        status: RfcStatus.frozen,
        category: RfcCategory.core,
        author: 'runtime-team',
        createdAt: 0,
        frozenAt: 0,
        summary:
            'All state mutations are recorded in a WAL before execution. '
            'Supports transactions, checkpoint, compaction, and replay.',
        motivation:
            'Without a WAL, crash recovery is impossible. Event sourcing requires '
            'a durable, ordered log of all state changes.',
        specification:
            '1. Every state mutation appends a WalEntry with LSN, type, HLC time, data.\n'
            '2. Transactions: beginTransaction → append → commit/rollback.\n'
            '3. Checkpoint marks a known-good LSN for recovery.\n'
            '4. Compaction removes entries before last checkpoint.\n'
            '5. Replay from any LSN reconstructs state.\n'
            '6. Integrity validation via checksum on each entry.'));

    register(
      const RuntimeRfc(
        id: 'RFC-007',
        title: 'Security and Trust Model',
        status: RfcStatus.frozen,
        category: RfcCategory.security,
        author: 'runtime-team',
        createdAt: 0,
        frozenAt: 0,
        summary:
            'Defines trust levels, plugin signing, capability authorization, '
            'secret management, and audit logging.',
        motivation:
            'As Runtime opens to external plugins and remote nodes, '
            'a security model is essential to prevent unauthorized access and resource abuse.',
        specification:
            '1. Trust levels: system > signed > verified > untrusted > blocked.\n'
            '2. Plugin signing: plugins can be signed with Ed25519/RSA256.\n'
            '3. Capability auth: each capability defines required trust level and allowed callers.\n'
            '4. Secret store: secrets are scoped, time-limited, and access-logged.\n'
            '5. Trust boundaries: define capability/node/resource restrictions per boundary.\n'
            '6. Audit log: all capability invocations and policy decisions are recorded.'));

    register(
      const RuntimeRfc(
        id: 'RFC-008',
        title: 'Sandbox Runtime',
        status: RfcStatus.proposed,
        category: RfcCategory.core,
        author: 'runtime-team',
        createdAt: 0,
        summary:
            'Defines Sandbox as a governed resource universe. '
            'Sandbox is not just code isolation—it is a complete execution context '
            'with time, resources, permissions, budget, lifecycle, identity, '
            'causality, and distributed consistency enforcement.',
        motivation:
            'AI Runtime will execute untrusted code: third-party plugins, '
            'agent-generated code, remote tools, MCP servers, MiniApps. '
            'Without Sandbox, any execution unit can bypass Runtime governance, '
            'pollute semantics, and collapse the entire system. '
            'Sandbox is the second constitution of Omnivium.',
        specification:
            '1. SandboxIsolate: every execution unit runs inside an isolate with its own resource universe.\n'
            '2. ResourceUniverse: each sandbox has its own time (HLC), budget, lease, capability set, and trace context.\n'
            '3. ExecutionGovernor: enforces budget limits, capability restrictions, and lifecycle rules.\n'
            '4. No bypass: all communication goes through CapabilityRouter. No side channels. No global state sharing.\n'
            '5. Runtime Law: Sandbox enforcement is mandatory. Business logic cannot override Runtime governance.\n'
            '6. Lifecycle: sandbox transitions through created → running → suspended → terminated.\n'
            '7. Audit: all sandbox operations are traced, journaled, and auditable.',
        breakingChanges:
            'None. Sandbox is additive. Existing plugins continue to work in the default trust boundary.',
        migrationGuide:
            'Existing plugins automatically run in the "default" trust boundary with verified trust level. '
            'No migration needed. New untrusted plugins opt into sandbox isolation.'));
  }
}
