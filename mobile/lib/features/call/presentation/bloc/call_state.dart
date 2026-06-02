import 'package:equatable/equatable.dart';
import '../../domain/entities/call_entities.dart';

abstract class CallBlocState extends Equatable {
  const CallBlocState();
  @override
  List<Object?> get props => [];
}

class CallIdle extends CallBlocState {
  const CallIdle();
}

class CallRinging extends CallBlocState {
  final CallState call;
  const CallRinging(this.call);
  @override
  List<Object?> get props => [call];
}

class CallConnecting extends CallBlocState {
  final CallState call;
  const CallConnecting(this.call);
  @override
  List<Object?> get props => [call];
}

class CallConnected extends CallBlocState {
  final CallState call;
  const CallConnected(this.call);
  @override
  List<Object?> get props => [call];
}

class CallEnded extends CallBlocState {
  final CallState? lastCall;
  const CallEnded(this.lastCall);
  @override
  List<Object?> get props => [lastCall];
}
