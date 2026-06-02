import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/contact.dart';

abstract class IContactsRepository {
  Future<Either<Failure, List<Contact>>> getContacts();
  Future<Either<Failure, List<Contact>>> searchUsers(String query);
  Future<Either<Failure, void>> sendFriendRequest(String userId);
  Future<Either<Failure, void>> acceptFriendRequest(String userId);
  Future<Either<Failure, void>> declineFriendRequest(String userId);
  Future<Either<Failure, void>> removeContact(String userId);
  Future<Either<Failure, void>> blockUser(String userId);
  Future<Either<Failure, void>> unblockUser(String userId);
  Future<Either<Failure, Contact>> getUserProfile(String userId);
  Future<Either<Failure, List<Contact>>> getPendingRequests();
}
