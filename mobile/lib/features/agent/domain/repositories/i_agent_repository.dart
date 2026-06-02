import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/agent_entities.dart';

abstract class IAgentRepository {
  Future<Either<Failure, List<AgentModel>>> getModels();
  Future<Either<Failure, AgentModel>> getActiveModel();
  Future<Either<Failure, void>> setActiveModel(String modelId);
  Future<Either<Failure, List<AgentSkill>>> getSkills();
  Future<Either<Failure, void>> toggleSkill(String skillId, bool enabled);
}
