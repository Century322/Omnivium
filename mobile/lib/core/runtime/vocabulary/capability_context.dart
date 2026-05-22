import 'runtime_identity.dart';
import 'runtime_permission.dart';
import 'runtime_session.dart';
import 'runtime_route.dart';

class CancellationToken {
  final int _deadlineMs;
  bool _isCancelled = false;

  CancellationToken(this._deadlineMs);

  bool get isCancelled => _isCancelled;
  bool get isExpired => DateTime.now().millisecondsSinceEpoch > _deadlineMs;
  int get deadlineMs => _deadlineMs;

  void cancel() {
    _isCancelled = true;
  }

  bool get shouldAbort => _isCancelled || isExpired;
}

class CapabilityContext {
  final RuntimeIdentity caller;
  final RuntimePermission permission;
  final RuntimeSession session;
  final RuntimeRoute route;
  final int deadline;
  final CancellationToken cancellationToken;

  CapabilityContext({
    required this.caller,
    required this.permission,
    required this.session,
    required this.route,
    required this.deadline,
    required this.cancellationToken,
  });

  factory CapabilityContext.create({
    required RuntimeIdentity caller,
    required RuntimePermission permission,
    required RuntimeSession session,
    required RuntimeRoute route,
    required int timeoutMs,
  }) {
    final deadline = DateTime.now().millisecondsSinceEpoch + timeoutMs;
    return CapabilityContext(
      caller: caller,
      permission: permission,
      session: session,
      route: route,
      deadline: deadline,
      cancellationToken: CancellationToken(deadline),
    );
  }

  bool get shouldAbort => cancellationToken.shouldAbort;

  bool hasCapability(String capabilityId) => permission.hasCapability(capabilityId);
}
