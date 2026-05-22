enum DistributedInvariantId {
  msgOrdering,
  deliverySemantics,
  sessionOwnership,
  capabilityConsistency,
  timeAuthority,
  failureDomain,
  networkHostile,
}

enum MessageOrderingModel { strongOrdering, perSessionOrdering, bestEffort }

enum DeliveryGuarantee { atMostOnce, atLeastOnce, exactlyOnce }

enum CapabilityConsistencyModel { stronglyConsistent, eventuallyConsistent }

enum TimeAuthorityModel { wallClock, lamportClock, hybridLogicalClock }

class DistributedInvariant {
  final DistributedInvariantId id;
  final String name;
  final String description;
  final String decision;
  final String rationale;

  const DistributedInvariant({
    required this.id,
    required this.name,
    required this.description,
    required this.decision,
    required this.rationale,
  });
}

class DistributedInvariants {
  static const MessageOrderingModel messageOrdering =
      MessageOrderingModel.perSessionOrdering;

  static const DeliveryGuarantee capabilityInvokeDelivery =
      DeliveryGuarantee.atMostOnce;
  static const DeliveryGuarantee eventPropagationDelivery =
      DeliveryGuarantee.atLeastOnce;
  static const DeliveryGuarantee journalDelivery =
      DeliveryGuarantee.exactlyOnce;

  static const bool sessionSingleWriter = true;

  static const CapabilityConsistencyModel capabilityConsistency =
      CapabilityConsistencyModel.eventuallyConsistent;

  static const TimeAuthorityModel timeAuthority =
      TimeAuthorityModel.hybridLogicalClock;

  static const bool nodeFailureIsolated = true;

  static const bool networkIsHostile = true;

  static List<DistributedInvariant> all() => [
    const DistributedInvariant(
      id: DistributedInvariantId.msgOrdering,
      name: 'Message Ordering',
      description:
          'Messages within the same session are delivered in order. '
          'Cross-session ordering is not guaranteed.',
      decision: 'Per-Session Ordering',
      rationale:
          'AI Runtime does not require global strong consistency. '
          'Per-session ordering is sufficient and much cheaper.',
    ),
    const DistributedInvariant(
      id: DistributedInvariantId.deliverySemantics,
      name: 'Delivery Semantics',
      description:
          'Capability Invoke: At Most Once. '
          'Event Propagation: At Least Once. '
          'Timeline/Journal: Exactly Once (logical layer).',
      decision: 'Different guarantees per object type',
      rationale:
          'Capability invocations must not duplicate side effects. '
          'Events can be deduplicated by consumers. '
          'Journal entries must be exactly-once for replay correctness.',
    ),
    const DistributedInvariant(
      id: DistributedInvariantId.sessionOwnership,
      name: 'Session Ownership',
      description:
          'A session can only have one writer node at any given time. '
          'Session migration transfers ownership atomically.',
      decision: 'Single Writer Principle',
      rationale:
          'Concurrent writes to the same session create merge conflicts. '
          'Single writer eliminates an entire class of consistency bugs.',
    ),
    const DistributedInvariant(
      id: DistributedInvariantId.capabilityConsistency,
      name: 'Capability Consistency',
      description:
          'Capability discovery is eventually consistent across nodes. '
          'A node may see stale capability registrations for a bounded period.',
      decision: 'Eventually Consistent',
      rationale:
          'Global synchronous capability registry is too expensive. '
          'Gossip-based propagation converges within seconds, which is acceptable.',
    ),
    const DistributedInvariant(
      id: DistributedInvariantId.timeAuthority,
      name: 'Time Authority',
      description:
          'Hybrid Logical Clock (HLC) provides causally-ordered timestamps. '
          'Wall clock is used only for display. HLC is used for ordering, '
          'journal, trace, and replay.',
      decision: 'Hybrid Logical Clock',
      rationale:
          'Physical clocks drift across nodes. '
          'HLC captures causality while staying close to physical time. '
          'Essential for correct distributed replay and trace correlation.',
    ),
    const DistributedInvariant(
      id: DistributedInvariantId.failureDomain,
      name: 'Failure Domain',
      description:
          'Node failure does not equal runtime failure. '
          'A node crash is isolated to its local sessions and capabilities. '
          'Other nodes continue operating. Orphaned sessions are reclaimed '
          'after lease expiry.',
      decision: 'Node Isolation',
      rationale:
          'Cascading failures are the #1 killer of distributed systems. '
          'Isolation boundaries prevent a single node from taking down the cluster.',
    ),
    const DistributedInvariant(
      id: DistributedInvariantId.networkHostile,
      name: 'Network Is Hostile',
      description:
          'The runtime assumes network is always unreliable. '
          'Latency, packet loss, duplication, reconnection, half-open connections, '
          'partitions, and node drift are permanent conditions, not exceptions.',
      decision: 'Design for hostility',
      rationale:
          'Any system that assumes reliable network will fail in production. '
          'All distributed operations must have timeouts, retries, idempotency, '
          'and partition recovery.',
    ),
  ];
}
