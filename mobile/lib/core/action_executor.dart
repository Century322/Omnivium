import 'omni_model.dart';
import 'state_service.dart';
import 'event_store.dart';
import 'di/app_di.dart';
import 'runtime/sdk/omnivium_sdk.dart';
import 'runtime/plugin/plugin_handler.dart';
import 'runtime/vocabulary/runtime_identity.dart';
import 'app_logger.dart';

class ActionExecutor {
  static final ActionExecutor _instance = ActionExecutor._();
  static ActionExecutor get instance => _instance;
  ActionExecutor._();

  final Map<String, Future<ActionResult> Function(OmniObject, Map<String, dynamic>)> _actionHandlers = {};

  void registerActionHandler(
    String actionId,
    Future<ActionResult> Function(OmniObject, Map<String, dynamic>) handler,
  ) {
    _actionHandlers[actionId] = handler;
  }

  Future<ActionResult> execute(
    OmniAction action,
    OmniObject target,
    Map<String, dynamic> params,
  ) async {
    final handler = _actionHandlers[action.id];
    if (handler != null) {
      try {
        final result = await handler(target, params);
        _recordStateChange(target, action, params, result.success);
        return result;
      } catch (e) {
        _recordStateChange(target, action, params, false, error: e.toString());
        return ActionResult.failure(action.id, target.id, e.toString());
      }
    }

    final sdk = OmniviumSDK.instance;
    if (sdk.isInitialized) {
      try {
        final capResult = await sdk.invokeCapability(
          action.capabilityId,
          params: {
            'objectId': target.id,
            'objectType': target.objectType.name,
            'objectState': target.state,
            'actionId': action.id,
            ...params,
          },
        );
        final success = capResult.status == CapabilityStatus.success;
        _recordStateChange(target, action, params, success);
        return ActionResult(
          actionId: action.id,
          objectId: target.id,
          success: success,
          data: capResult.data is Map<String, dynamic>
              ? capResult.data as Map<String, dynamic>
              : {'raw': capResult.data},
        );
      } catch (e) {
        _recordStateChange(target, action, params, false, error: e.toString());
        return ActionResult.failure(action.id, target.id, e.toString());
      }
    }

    _recordStateChange(target, action, params, false, error: 'No handler and SDK not available');
    return ActionResult.failure(action.id, target.id, 'No handler registered for action: ${action.id}');
  }

  Future<List<ActionResult>> executeBatch(
    List<(OmniAction, OmniObject, Map<String, dynamic>)> actions,
  ) async {
    final results = <ActionResult>[];
    for (final (action, target, params) in actions) {
      results.add(await execute(action, target, params));
    }
    return results;
  }

  void _recordStateChange(
    OmniObject target,
    OmniAction action,
    Map<String, dynamic> params,
    bool success, {
    String? error,
  }) {
    final sdk = OmniviumSDK.instance;
    if (sdk.isInitialized) {
      try {
        sdk.container.eventBus.publish(
          'state.${target.objectType.name}.${action.id}',
          {
            'objectId': target.id,
            'objectType': target.objectType.name,
            'actionId': action.id,
            'capabilityId': action.capabilityId,
            'success': success,
            if (error != null) 'error': error,
            'timestamp': DateTime.now().toIso8601String(),
          },
          source: RuntimeIdentity.forPlugin('action-executor'),
        );
      } catch (e) {
        AppLogger.instance.warning('Failed to record state change', error: e);
      }
    }

    _writeToStateService(target, action, params, success, error: error);
  }

  void _writeToStateService(
    OmniObject target,
    OmniAction action,
    Map<String, dynamic> params,
    bool success, {
    String? error,
  }) {
    try {
      final stateService = getIt<StateService>();
      if (stateService.isInitialized) {
        final result = success
            ? ActionResult.success(action.id, target.id, {
                'lastAction': action.id,
                'lastActionTime': DateTime.now().toIso8601String(),
              })
            : ActionResult.failure(action.id, target.id, error ?? 'unknown');

        stateService.recordActionExecution(
          result,
          target: target,
          action: action,
          params: params,
        );
      }
    } catch (e) {
      AppLogger.instance.warning('Failed to write to StateService', error: e);
    }

    try {
      final eventStore = getIt<EventStore>();
      if (eventStore.isInitialized) {
        final eventType = _mapActionToEventType(action.id, success);
        final event = eventStore.createEvent(
          type: eventType,
          aggregateId: target.id,
          aggregateType: target.objectType.name,
          payload: {
            'actionId': action.id,
            'success': success,
            if (error != null) 'error': error,
            ...params,
          },
        );
        eventStore.append(event);
      }
    } catch (e) {
      AppLogger.instance.warning('Failed to write to EventStore', error: e);
    }
  }

  DomainEventType _mapActionToEventType(String actionId, bool success) {
    if (!success) return DomainEventType.stateChanged;
    if (actionId.contains('create') || actionId.contains('Create')) {
      if (actionId.contains('agent')) return DomainEventType.agentCreated;
      if (actionId.contains('project')) return DomainEventType.projectCreated;
      if (actionId.contains('note')) return DomainEventType.noteCreated;
      if (actionId.contains('plan')) return DomainEventType.planCreated;
      if (actionId.contains('file')) return DomainEventType.fileUploaded;
      return DomainEventType.stateChanged;
    }
    if (actionId.contains('destroy') || actionId.contains('delete')) {
      if (actionId.contains('agent')) return DomainEventType.agentDestroyed;
      if (actionId.contains('file')) return DomainEventType.fileDeleted;
      return DomainEventType.stateChanged;
    }
    if (actionId.contains('assign')) return DomainEventType.taskAssigned;
    if (actionId.contains('complete') || actionId.contains('toggleDone')) return DomainEventType.taskCompleted;
    if (actionId.contains('edit')) return DomainEventType.noteEdited;
    if (actionId.contains('send')) return DomainEventType.messageSent;
    if (actionId.contains('forward')) return DomainEventType.messageForwarded;
    if (actionId.contains('share')) return DomainEventType.postShared;
    if (actionId.contains('archive')) return DomainEventType.projectArchived;
    return DomainEventType.stateChanged;
  }

  List<OmniAction> planActions(String userIntent, List<OmniObject> targets) {
    final actions = <OmniAction>[];
    for (final target in targets) {
      final available = OmniObjectRegistry.instance.getActionsForObject(target);
      for (final action in available) {
        if (_actionMatchesIntent(action, userIntent)) {
          actions.add(action);
        }
      }
    }
    return actions;
  }

  bool _actionMatchesIntent(OmniAction action, String intent) {
    final lower = intent.toLowerCase();
    if (action.name.toLowerCase().contains(lower)) return true;
    if (action.description.toLowerCase().contains(lower)) return true;
    if (action.capabilityId.toLowerCase().contains(lower)) return true;
    return false;
  }
}

class ActionResult {
  final String actionId;
  final String objectId;
  final bool success;
  final Map<String, dynamic>? data;
  final String? error;

  const ActionResult({
    required this.actionId,
    required this.objectId,
    required this.success,
    this.data,
    this.error,
  });

  factory ActionResult.failure(String actionId, String objectId, String error) =>
      ActionResult(actionId: actionId, objectId: objectId, success: false, error: error);

  factory ActionResult.success(String actionId, String objectId, [Map<String, dynamic>? data]) =>
      ActionResult(actionId: actionId, objectId: objectId, success: true, data: data);
}
