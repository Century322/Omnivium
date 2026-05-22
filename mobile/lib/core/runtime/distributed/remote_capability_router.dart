import 'vocabulary/remote_capability_binding.dart';
import 'hybrid_logical_clock.dart';
import 'transport/runtime_transport.dart';

class CapabilityAdvertisement {
  final String nodeId;
  final List<String> capabilityIds;
  final String pluginId;
  final int version;
  final int timestamp;

  const CapabilityAdvertisement({
    required this.nodeId,
    required this.capabilityIds,
    required this.pluginId,
    this.version = 1,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'nodeId': nodeId,
    'capabilityIds': capabilityIds,
    'pluginId': pluginId,
    'version': version,
    'timestamp': timestamp,
  };

  factory CapabilityAdvertisement.fromJson(Map<String, dynamic> json) =>
      CapabilityAdvertisement(
        nodeId: json['nodeId'] as String,
        capabilityIds: (json['capabilityIds'] as List).cast<String>(),
        pluginId: json['pluginId'] as String,
        version: json['version'] as int? ?? 1,
        timestamp: json['timestamp'] as int,
      );
}

enum RouteDecision { local, remote, fallback, unavailable }

class RouteResult {
  final RouteDecision decision;
  final String? targetNodeId;
  final String? capabilityId;
  final String? pluginId;
  final String reason;

  const RouteResult({
    required this.decision,
    this.targetNodeId,
    this.capabilityId,
    this.pluginId,
    this.reason = '',
  });

  bool get isLocal => decision == RouteDecision.local;
  bool get isRemote => decision == RouteDecision.remote;
  bool get isAvailable => decision != RouteDecision.unavailable;
}

class RemoteCapabilityRouter {
  final String _localNodeId;
  final Set<String> _localCapabilities = {};
  final Map<String, RemoteCapabilityBinding> _remoteCapabilities = {};
  final Map<String, CapabilityAdvertisement> _advertisements = {};
  final HybridLogicalClock _clock;
  // ignore: unused_field
  RuntimeTransport? _transport;

  RemoteCapabilityRouter({
    required String localNodeId,
    required HybridLogicalClock clock,
  }) : _localNodeId = localNodeId,
       _clock = clock;

  String get localNodeId => _localNodeId;
  int get localCapabilityCount => _localCapabilities.length;
  int get remoteCapabilityCount => _remoteCapabilities.length;
  List<RemoteCapabilityBinding> get remoteBindings =>
      _remoteCapabilities.values.toList();

  void setTransport(RuntimeTransport transport) {
    _transport = transport;
  }

  void registerLocalCapability(String capabilityId) {
    _localCapabilities.add(capabilityId);
  }

  void unregisterLocalCapability(String capabilityId) {
    _localCapabilities.remove(capabilityId);
  }

  void registerLocalCapabilities(List<String> capabilityIds) {
    _localCapabilities.addAll(capabilityIds);
  }

  void receiveAdvertisement(CapabilityAdvertisement ad) {
    if (ad.nodeId == _localNodeId) return;

    _advertisements[ad.nodeId] = ad;

    final now = _clock.tick();
    for (final capId in ad.capabilityIds) {
      final existing = _remoteCapabilities[capId];
      if (existing == null || existing.version < ad.version) {
        _remoteCapabilities[capId] = RemoteCapabilityBinding(
          capabilityId: capId,
          providerNodeId: ad.nodeId,
          providerPluginId: ad.pluginId,
          discoveredAt: existing?.discoveredAt ?? now.physicalTime,
          lastVerifiedAt: now.physicalTime,
          version: ad.version,
        );
      }
    }
  }

  void withdrawNodeCapabilities(String nodeId) {
    _advertisements.remove(nodeId);
    _remoteCapabilities.removeWhere(
      (_, binding) => binding.providerNodeId == nodeId,
    );
  }

  void markCapabilityUnreachable(String capabilityId) {
    final binding = _remoteCapabilities[capabilityId];
    if (binding == null) return;

    _remoteCapabilities[capabilityId] = binding.copyWith(
      state: BindingState.unreachable,
    );
  }

  RouteResult route(String capabilityId) {
    if (_localCapabilities.contains(capabilityId)) {
      return RouteResult(
        decision: RouteDecision.local,
        capabilityId: capabilityId,
        reason: 'Available locally',
      );
    }

    final remote = _remoteCapabilities[capabilityId];
    if (remote != null && remote.isAvailable) {
      return RouteResult(
        decision: RouteDecision.remote,
        targetNodeId: remote.providerNodeId,
        capabilityId: capabilityId,
        pluginId: remote.providerPluginId,
        reason: 'Available on node ${remote.providerNodeId}',
      );
    }

    return RouteResult(
      decision: RouteDecision.unavailable,
      capabilityId: capabilityId,
      reason: 'No provider found for $capabilityId',
    );
  }

  RouteResult routeWithFallback(
    String capabilityId,
    List<String> fallbackCapabilityIds,
  ) {
    final primary = route(capabilityId);
    if (primary.isAvailable) return primary;

    for (final fallbackId in fallbackCapabilityIds) {
      final fallback = route(fallbackId);
      if (fallback.isAvailable) {
        return RouteResult(
          decision: RouteDecision.fallback,
          targetNodeId: fallback.targetNodeId,
          capabilityId: fallbackId,
          pluginId: fallback.pluginId,
          reason: 'Fallback from $capabilityId to $fallbackId',
        );
      }
    }

    return primary;
  }

  CapabilityAdvertisement createAdvertisement(
    String pluginId,
    List<String> capabilityIds,
  ) {
    final now = _clock.tick();
    return CapabilityAdvertisement(
      nodeId: _localNodeId,
      capabilityIds: capabilityIds,
      pluginId: pluginId,
      timestamp: now.physicalTime,
    );
  }

  void clear() {
    _localCapabilities.clear();
    _remoteCapabilities.clear();
    _advertisements.clear();
  }
}
