import 'package:freezed_annotation/freezed_annotation.dart';

part 'agent_entities.freezed.dart';
part 'agent_entities.g.dart';

@freezed
sealed class AgentModel with _$AgentModel {
  const factory AgentModel({
    required String id,
    required String name,
    required String provider,
    required String tier,
    @Default(false) bool isActive,
  }) = _AgentModel;

  factory AgentModel.fromJson(Map<String, dynamic> json) =>
      _$AgentModelFromJson(json);
}

@freezed
sealed class AgentSkill with _$AgentSkill {
  const factory AgentSkill({
    required String id,
    required String name,
    required String description,
    @Default(true) bool enabled,
  }) = _AgentSkill;

  factory AgentSkill.fromJson(Map<String, dynamic> json) =>
      _$AgentSkillFromJson(json);
}
