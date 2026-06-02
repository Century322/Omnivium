import 'package:equatable/equatable.dart';
import '../../domain/entities/agent_entities.dart';

abstract class AgentState extends Equatable {
  const AgentState();
  @override
  List<Object?> get props => [];
}

class AgentInitial extends AgentState {
  const AgentInitial();
}

class AgentModelsLoading extends AgentState {
  const AgentModelsLoading();
}

class AgentModelsLoaded extends AgentState {
  final List<AgentModel> models;
  final AgentModel? activeModel;
  const AgentModelsLoaded({required this.models, this.activeModel});
  @override
  List<Object?> get props => [models, activeModel];
}

class AgentSkillsLoaded extends AgentState {
  final List<AgentModel> models;
  final AgentModel? activeModel;
  final List<AgentSkill> skills;
  const AgentSkillsLoaded({required this.models, this.activeModel, required this.skills});
  @override
  List<Object?> get props => [models, activeModel, skills];
}

class AgentError extends AgentState {
  final String message;
  const AgentError(this.message);
  @override
  List<Object?> get props => [message];
}
