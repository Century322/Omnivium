import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/contact.dart';
import '../repositories/i_contacts_repository.dart';

class GetContactsUseCase extends UseCase<List<Contact>, NoParams> {
  final IContactsRepository _repository;
  GetContactsUseCase(this._repository);
  @override
  Future<Either<Failure, List<Contact>>> call(NoParams params) => _repository.getContacts();
}

class SearchUsersUseCase extends UseCase<List<Contact>, String> {
  final IContactsRepository _repository;
  SearchUsersUseCase(this._repository);
  @override
  Future<Either<Failure, List<Contact>>> call(String query) => _repository.searchUsers(query);
}

class SendFriendRequestUseCase extends UseCase<void, String> {
  final IContactsRepository _repository;
  SendFriendRequestUseCase(this._repository);
  @override
  Future<Either<Failure, void>> call(String userId) => _repository.sendFriendRequest(userId);
}

class AcceptFriendRequestUseCase extends UseCase<void, String> {
  final IContactsRepository _repository;
  AcceptFriendRequestUseCase(this._repository);
  @override
  Future<Either<Failure, void>> call(String userId) => _repository.acceptFriendRequest(userId);
}

class GetPendingRequestsUseCase extends UseCase<List<Contact>, NoParams> {
  final IContactsRepository _repository;
  GetPendingRequestsUseCase(this._repository);
  @override
  Future<Either<Failure, List<Contact>>> call(NoParams params) => _repository.getPendingRequests();
}
