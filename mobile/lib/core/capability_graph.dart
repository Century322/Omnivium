import 'dart:convert';
import 'app_logger.dart';
import 'database_service.dart';
import 'capability_system.dart';
import 'omni_model.dart';

class GraphNode {
  final String id;
  final String label;
  final String type;
  final Map<String, dynamic> metadata;

  const GraphNode({
    required this.id,
    required this.label,
    required this.type,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'type': type,
    'metadata': metadata,
  };

  factory GraphNode.fromJson(Map<String, dynamic> json) => GraphNode(
    id: json['id'] as String,
    label: json['label'] as String,
    type: json['type'] as String,
    metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
  );
}

class GraphEdge {
  final String sourceId;
  final String targetId;
  final String relation;
  final Map<String, dynamic> metadata;

  const GraphEdge({
    required this.sourceId,
    required this.targetId,
    required this.relation,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'sourceId': sourceId,
    'targetId': targetId,
    'relation': relation,
    'metadata': metadata,
  };

  factory GraphEdge.fromJson(Map<String, dynamic> json) => GraphEdge(
    sourceId: json['sourceId'] as String,
    targetId: json['targetId'] as String,
    relation: json['relation'] as String,
    metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
  );
}

class CapabilityGraph {
  final Map<String, GraphNode> _nodes = {};
  final List<GraphEdge> _edges = [];
  final DatabaseService _db;
  bool _isInitialized = false;

  static const _nodesKey = 'cap_graph_nodes';
  static const _edgesKey = 'cap_graph_edges';

  CapabilityGraph(this._db);

  bool get isInitialized => _isInitialized;
  int get nodeCount => _nodes.length;
  int get edgeCount => _edges.length;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final nodesJson = await _db.getCache(_nodesKey);
      if (nodesJson != null) {
        final map = jsonDecode(nodesJson) as Map<String, dynamic>;
        for (final entry in map.entries) {
          _nodes[entry.key] = GraphNode.fromJson(entry.value as Map<String, dynamic>);
        }
      }
      final edgesJson = await _db.getCache(_edgesKey);
      if (edgesJson != null) {
        final list = jsonDecode(edgesJson) as List<dynamic>;
        for (final e in list) {
          _edges.add(GraphEdge.fromJson(e as Map<String, dynamic>));
        }
      }
      _isInitialized = true;
      AppLogger.instance.info(
        'CapabilityGraph initialized: ${_nodes.length} nodes, ${_edges.length} edges',
      );
    } catch (e, st) {
      AppLogger.instance.error('CapabilityGraph init failed', error: e, stackTrace: st);
      _isInitialized = true;
    }
  }

  void addObjectNode(String objectTypeId, String label, {Map<String, dynamic>? metadata}) {
    _nodes['obj_$objectTypeId'] = GraphNode(
      id: 'obj_$objectTypeId',
      label: label,
      type: 'object',
      metadata: {'objectType': objectTypeId, ...?metadata},
    );
  }

  void addCapabilityNode(String capabilityId, String label, {Map<String, dynamic>? metadata}) {
    _nodes['cap_$capabilityId'] = GraphNode(
      id: 'cap_$capabilityId',
      label: label,
      type: 'capability',
      metadata: {'capabilityId': capabilityId, ...?metadata},
    );
  }

  void addActionNode(String actionId, String label, {Map<String, dynamic>? metadata}) {
    _nodes['act_$actionId'] = GraphNode(
      id: 'act_$actionId',
      label: label,
      type: 'action',
      metadata: {'actionId': actionId, ...?metadata},
    );
  }

  void linkObjectToCapability(String objectTypeId, String capabilityId) {
    _edges.add(GraphEdge(
      sourceId: 'obj_$objectTypeId',
      targetId: 'cap_$capabilityId',
      relation: 'hasCapability',
    ));
  }

  void linkCapabilityToAction(String capabilityId, String actionId, {String? providerName}) {
    _edges.add(GraphEdge(
      sourceId: 'cap_$capabilityId',
      targetId: 'act_$actionId',
      relation: 'implementedBy',
      metadata: {if (providerName != null) 'provider': providerName},
    ));
  }

  List<GraphNode> getCapabilitiesForObject(String objectTypeId) {
    final capNodeIds = _edges
        .where((e) => e.sourceId == 'obj_$objectTypeId' && e.relation == 'hasCapability')
        .map((e) => e.targetId)
        .toSet();
    return capNodeIds.map((id) => _nodes[id]).whereType<GraphNode>().toList();
  }

  List<GraphNode> getActionsForCapability(String capabilityId) {
    final actNodeIds = _edges
        .where((e) => e.sourceId == 'cap_$capabilityId' && e.relation == 'implementedBy')
        .map((e) => e.targetId)
        .toSet();
    return actNodeIds.map((id) => _nodes[id]).whereType<GraphNode>().toList();
  }

  List<GraphNode> getObjectsForCapability(String capabilityId) {
    final objNodeIds = _edges
        .where((e) => e.targetId == 'cap_$capabilityId' && e.relation == 'hasCapability')
        .map((e) => e.sourceId)
        .toSet();
    return objNodeIds.map((id) => _nodes[id]).whereType<GraphNode>().toList();
  }

  List<String> deduceActionsForObject(String objectTypeId) {
    final capabilities = getCapabilitiesForObject(objectTypeId);
    final actions = <String>{};
    for (final cap in capabilities) {
      final capId = cap.metadata['capabilityId'] as String?;
      if (capId != null) {
        final capActions = getActionsForCapability(capId);
        for (final act in capActions) {
          final actionId = act.metadata['actionId'] as String?;
          if (actionId != null) actions.add(actionId);
        }
      }
    }
    return actions.toList();
  }

  List<String> deduceCapabilitiesForObject(String objectTypeId) {
    return getCapabilitiesForObject(objectTypeId)
        .map((n) => n.metadata['capabilityId'] as String?)
        .whereType<String>()
        .toList();
  }

  String buildGraphContext({String? objectTypeId}) {
    final buffer = StringBuffer();
    buffer.writeln('[Capability Graph]');

    if (objectTypeId != null) {
      final capabilities = getCapabilitiesForObject(objectTypeId);
      if (capabilities.isEmpty) {
        buffer.writeln('No capabilities found for object type: $objectTypeId');
        return buffer.toString();
      }

      buffer.writeln('\n$objectTypeId can:');
      for (final cap in capabilities) {
        final capId = cap.metadata['capabilityId'] as String?;
        buffer.writeln('  ${cap.label}');
        if (capId != null) {
          final actions = getActionsForCapability(capId);
          for (final act in actions) {
            final provider = act.metadata['provider'] as String?;
            buffer.writeln('    → ${act.label}${provider != null ? ' ($provider)' : ''}');
          }
        }
      }
    } else {
      final objectNodes = _nodes.values.where((n) => n.type == 'object').toList();
      final capNodes = _nodes.values.where((n) => n.type == 'capability').toList();

      buffer.writeln('\nObjects (${objectNodes.length}):');
      for (final obj in objectNodes) {
        final caps = getCapabilitiesForObject(obj.metadata['objectType'] as String? ?? '');
        buffer.writeln('  ${obj.label}: ${caps.map((c) => c.label).join(', ')}');
      }

      buffer.writeln('\nCapabilities (${capNodes.length}):');
      for (final cap in capNodes) {
        final capId = cap.metadata['capabilityId'] as String?;
        if (capId != null) {
          final actions = getActionsForCapability(capId);
          final objects = getObjectsForCapability(capId);
          buffer.writeln('  ${cap.label}');
          buffer.writeln('    Applies to: ${objects.map((o) => o.label).join(', ')}');
          buffer.writeln('    Implemented by: ${actions.map((a) => a.label).join(', ')}');
        }
      }
    }

    return buffer.toString();
  }

  void buildFromRegistry(CapabilityRegistry registry) {
    _nodes.clear();
    _edges.clear();

    for (final type in OmniObjectType.values) {
      addObjectNode(type.name, _typeLabel(type.name));
    }

    for (final cap in registry.allCapabilities) {
      addCapabilityNode(cap.id, cap.name, metadata: {
        'category': cap.category.name,
        'isDestructive': cap.isDestructive,
      });

      for (final objectType in cap.applicableObjectTypes) {
        linkObjectToCapability(objectType, cap.id);
      }
    }

    for (final cap in registry.allCapabilities) {
      final bindings = registry.getBindings(cap.id);
      for (final binding in bindings) {
        addActionNode(binding.actionId, binding.providerName, metadata: {
          'provider': binding.providerName,
        });
        linkCapabilityToAction(cap.id, binding.actionId, providerName: binding.providerName);
      }
    }
  }

  String _typeLabel(String typeName) {
    const labels = {
      'message': 'Message',
      'chatRoom': 'Chat Room',
      'contact': 'Contact',
      'agent': 'Agent',
      'agentGroup': 'Agent Group',
      'file': 'File',
      'note': 'Note',
      'task': 'Task',
      'project': 'Project',
      'product': 'Product',
      'post': 'Post',
    };
    return labels[typeName] ?? typeName;
  }

  Future<void> persist() async {
    try {
      await _db.putCache(
        _nodesKey,
        jsonEncode(_nodes.map((k, v) => MapEntry(k, v.toJson()))),
      );
      await _db.putCache(
        _edgesKey,
        jsonEncode(_edges.map((e) => e.toJson()).toList()),
      );
    } catch (e, st) {
      AppLogger.instance.error('CapabilityGraph persist failed', error: e, stackTrace: st);
    }
  }

  Future<void> clear() async {
    _nodes.clear();
    _edges.clear();
    await persist();
  }
}
