import 'runtime/plugin/plugin_descriptor.dart';
import 'runtime/plugin/plugin_handler.dart';
import 'runtime/vocabulary/runtime_message.dart';
import 'runtime/vocabulary/runtime_event.dart';
import 'runtime/vocabulary/capability_context.dart';

enum OmniObjectType {
  message,
  chatRoom,
  contact,
  agent,
  agentGroup,
  file,
  note,
  task,
  project,
  product,
  post,
}

class OmniAction {
  final String id;
  final String name;
  final String description;
  final String objectTypeId;
  final String capabilityId;
  final Map<String, dynamic> paramSchema;
  final bool isDestructive;
  final String permission;

  const OmniAction({
    required this.id,
    required this.name,
    required this.description,
    required this.objectTypeId,
    required this.capabilityId,
    this.paramSchema = const {},
    this.isDestructive = false,
    this.permission = 'confirm',
  });
}

abstract class OmniObject {
  String get id;
  OmniObjectType get objectType;
  String get displayName;
  Map<String, dynamic> get state;
  List<OmniAction> get availableActions;
  Map<String, dynamic> toJson();
}

class OmniObjectRegistry {
  final Map<String, OmniObject> _objects = {};
  final Map<OmniObjectType, List<OmniAction>> _actionsByType = {};

  static final OmniObjectRegistry _instance = OmniObjectRegistry._();
  static OmniObjectRegistry get instance => _instance;
  OmniObjectRegistry._();

  void registerObject(OmniObject obj) {
    _objects[obj.id] = obj;
  }

  void unregisterObject(String id) {
    _objects.remove(id);
  }

  OmniObject? getObject(String id) => _objects[id];

  List<OmniObject> getObjectsByType(OmniObjectType type) =>
      _objects.values.where((o) => o.objectType == type).toList();

  void registerAction(OmniObjectType objectType, OmniAction action) {
    _actionsByType.putIfAbsent(objectType, () => []).add(action);
  }

  List<OmniAction> getActionsForType(OmniObjectType type) =>
      _actionsByType[type] ?? [];

  List<OmniAction> getActionsForObject(OmniObject obj) {
    final typeActions = getActionsForType(obj.objectType);
    final instanceActions = obj.availableActions;
    return {...typeActions, ...instanceActions}.toList();
  }

  OmniObject? findObject(String query) {
    if (_objects.containsKey(query)) return _objects[query];
    final lower = query.toLowerCase();
    for (final obj in _objects.values) {
      if (obj.displayName.toLowerCase().contains(lower)) return obj;
    }
    return null;
  }

  void clear() {
    _objects.clear();
    _actionsByType.clear();
  }
}

class CognitivePluginHandler implements PluginHandler {
  final Map<String, Future<CapabilityResult> Function(Object?, CapabilityContext)> _handlers = {};

  void registerCapability(
    String capabilityId,
    Future<CapabilityResult> Function(Object?, CapabilityContext) handler,
  ) {
    _handlers[capabilityId] = handler;
  }

  @override
  Future<HandlerResult> handleMessage(
    RuntimeMessage message,
    CapabilityContext context,
  ) async {
    return HandlerResult.ok({'processed': true});
  }

  @override
  Future<HandlerResult> handleEvent(
    RuntimeEvent event,
    CapabilityContext context,
  ) async {
    return HandlerResult.ok({'processed': true});
  }

  @override
  Future<CapabilityResult> invokeCapability(
    String capabilityId,
    Object? params,
    CapabilityContext context,
  ) async {
    final handler = _handlers[capabilityId];
    if (handler == null) {
      return CapabilityResult.fail(
        RuntimeError.notFound(message: 'Cognitive capability not found: $capabilityId'),
      );
    }
    return handler(params, context);
  }
}
