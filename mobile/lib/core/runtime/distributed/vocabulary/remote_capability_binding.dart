enum BindingState {
  available,
  unreachable,
  deprecated,
}

class RemoteCapabilityBinding {
  final String capabilityId;
  final String providerNodeId;
  final String providerPluginId;
  final BindingState state;
  final int discoveredAt;
  final int lastVerifiedAt;
  final int version;
  final Map<String, String> metadata;

  const RemoteCapabilityBinding({
    required this.capabilityId,
    required this.providerNodeId,
    required this.providerPluginId,
    this.state = BindingState.available,
    required this.discoveredAt,
    required this.lastVerifiedAt,
    this.version = 1,
    this.metadata = const {},
  });

  RemoteCapabilityBinding copyWith({
    String? capabilityId,
    String? providerNodeId,
    String? providerPluginId,
    BindingState? state,
    int? discoveredAt,
    int? lastVerifiedAt,
    int? version,
    Map<String, String>? metadata,
  }) =>
      RemoteCapabilityBinding(
        capabilityId: capabilityId ?? this.capabilityId,
        providerNodeId: providerNodeId ?? this.providerNodeId,
        providerPluginId: providerPluginId ?? this.providerPluginId,
        state: state ?? this.state,
        discoveredAt: discoveredAt ?? this.discoveredAt,
        lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
        version: version ?? this.version,
        metadata: metadata ?? this.metadata,
      );

  bool get isAvailable => state == BindingState.available;

  String get bindingKey => '$providerNodeId:$providerPluginId:$capabilityId';

  Map<String, dynamic> toJson() => {
        'capabilityId': capabilityId,
        'providerNodeId': providerNodeId,
        'providerPluginId': providerPluginId,
        'state': state.name,
        'discoveredAt': discoveredAt,
        'lastVerifiedAt': lastVerifiedAt,
        'version': version,
        'metadata': metadata,
      };

  factory RemoteCapabilityBinding.fromJson(Map<String, dynamic> json) =>
      RemoteCapabilityBinding(
        capabilityId: json['capabilityId'] as String,
        providerNodeId: json['providerNodeId'] as String,
        providerPluginId: json['providerPluginId'] as String,
        state: BindingState.values.firstWhere(
          (s) => s.name == json['state'],
          orElse: () => BindingState.unreachable,
        ),
        discoveredAt: json['discoveredAt'] as int,
        lastVerifiedAt: json['lastVerifiedAt'] as int,
        version: json['version'] as int? ?? 1,
        metadata: (json['metadata'] as Map<String, dynamic>?)?.cast<String, String>() ?? {},
      );
}
