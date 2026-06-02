import 'package:equatable/equatable.dart';

abstract class AgentEvent extends Equatable {
  const AgentEvent();
  @override
  List<Object?> get props => [];
}

class AgentModelsLoadRequested extends AgentEvent {
  const AgentModelsLoadRequested();
}

class AgentModelSelected extends AgentEvent {
  final String modelId;
  const AgentModelSelected(this.modelId);
  @override
  List<Object?> get props => [modelId];
}

class AgentSkillsLoadRequested extends AgentEvent {
  const AgentSkillsLoadRequested();
}

class AgentSkillToggled extends AgentEvent {
  final String skillId;
  final bool enabled;
  const AgentSkillToggled({required this.skillId, required this.enabled});
  @override
  List<Object?> get props => [skillId, enabled];
}
