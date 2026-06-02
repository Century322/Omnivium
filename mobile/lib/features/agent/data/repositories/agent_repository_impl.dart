import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/agent_entities.dart';
import '../../domain/repositories/i_agent_repository.dart';
import '../../../../core/model_cubit.dart';

class AgentRepositoryImpl implements IAgentRepository {
  final ModelCubit _ModelCubit;

  AgentRepositoryImpl(this._ModelCubit);

  @override
  Future<Either<Failure, List<AgentModel>>> getModels() async {
    try {
      if (_ModelCubit.models.isEmpty) {
        await _ModelCubit.loadModels();
      }
      final models = _ModelCubit.models;
      return Right(models.map((m) => AgentModel(
        id: m.id,
        name: m.name,
        provider: m.provider,
        tier: m.tier,
        isActive: m.id == _ModelCubit.activeModel?.id)).toList());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AgentModel>> getActiveModel() async {
    try {
      final active = _ModelCubit.activeModel;
      if (active == null) {
        return const Left(ServerFailure(message: 'No active model'));
      }
      return Right(AgentModel(
        id: active.id,
        name: active.name,
        provider: active.provider,
        tier: active.tier,
        isActive: true));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setActiveModel(String modelId) async {
    try {
      _ModelCubit.switchModel(modelId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AgentSkill>>> getSkills() async {
    try {
      return const Right([]);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> toggleSkill(String skillId, bool enabled) async {
    try {
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
