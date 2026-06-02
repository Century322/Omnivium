import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/agent_entities.dart';
import '../../domain/repositories/i_agent_repository.dart';
import 'agent_event.dart';
import 'agent_state.dart';

class AgentBloc extends Bloc<AgentEvent, AgentState> {
  final IAgentRepository _repository;

  AgentBloc(this._repository) : super(const AgentInitial()) {
    on<AgentModelsLoadRequested>(_onLoadModels);
    on<AgentModelSelected>(_onSelectModel);
    on<AgentSkillsLoadRequested>(_onLoadSkills);
    on<AgentSkillToggled>(_onToggleSkill);
  }

  Future<void> _onLoadModels(AgentModelsLoadRequested event, Emitter<AgentState> emit) async {
    emit(const AgentModelsLoading());
    final modelsResult = await _repository.getModels();
    final activeResult = await _repository.getActiveModel();

    if (modelsResult.isLeft()) {
      final failure = modelsResult.swap().getOrElse(() => ServerFailure(message: 'Unknown error'));
      emit(AgentError(failure.message));
      return;
    }

    final models = modelsResult.getOrElse(() => <AgentModel>[]);
    AgentModel active;
    if (activeResult.isRight()) {
      active = activeResult.getOrElse(() => AgentModel(id: '', name: '', provider: '', tier: ''));
    } else if (models.isNotEmpty) {
      active = models.first;
    } else {
      active = AgentModel(id: '', name: '', provider: '', tier: '');
    }
    emit(AgentModelsLoaded(models: models, activeModel: active));
  }

  Future<void> _onSelectModel(AgentModelSelected event, Emitter<AgentState> emit) async {
    await _repository.setActiveModel(event.modelId);
    add(const AgentModelsLoadRequested());
  }

  Future<void> _onLoadSkills(AgentSkillsLoadRequested event, Emitter<AgentState> emit) async {
    final currentState = state;
    final skillsResult = await _repository.getSkills();

    if (skillsResult.isLeft()) {
      final failure = skillsResult.swap().getOrElse(() => ServerFailure(message: 'Unknown error'));
      emit(AgentError(failure.message));
      return;
    }

    final skills = skillsResult.getOrElse(() => <AgentSkill>[]);
    List<AgentModel> models = [];
    AgentModel? active;
    if (currentState is AgentModelsLoaded) {
      models = currentState.models;
      active = currentState.activeModel;
    }
    emit(AgentSkillsLoaded(models: models, activeModel: active, skills: skills));
  }

  Future<void> _onToggleSkill(AgentSkillToggled event, Emitter<AgentState> emit) async {
    await _repository.toggleSkill(event.skillId, event.enabled);
    add(const AgentSkillsLoadRequested());
  }
}
