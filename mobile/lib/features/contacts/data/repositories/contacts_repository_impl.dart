import 'package:dartz/dartz.dart';
import 'package:matrix/matrix.dart' as matrix;
import '../../../../core/errors/failures.dart';
import '../../../../core/matrix/matrix_service.dart';
import '../../../../core/app_logger.dart';
import '../../domain/entities/contact.dart';
import '../../domain/repositories/i_contacts_repository.dart';

class ContactsRepositoryImpl implements IContactsRepository {
  final MatrixService _matrix;

  ContactsRepositoryImpl(this._matrix);

  @override
  Future<Either<Failure, List<Contact>>> getContacts() async {
    try {
      if (!_matrix.isLoggedIn) return const Right([]);
      final rooms = _matrix.rooms;
      final contacts = <Contact>[];
      final seen = <String>{};
      for (final room in rooms) {
        if (!room.isDirectChat) continue;
        final members = room.getParticipants();
        for (final user in members) {
          if (user.id == _matrix.userId) continue;
          if (seen.contains(user.id)) continue;
          seen.add(user.id);
          contacts.add(Contact(
            userId: user.id,
            displayName: user.displayName ?? user.id.split(':').first.replaceFirst('@', ''),
            avatarUrl: user.avatarUrl?.toString(),
            matrixId: user.id,
            isOnline: user.presence?.presence == 'online',
            status: ContactStatus.accepted));
        }
      }
      return Right(contacts);
    } catch (e, st) {
      AppLogger.instance.error('getContacts failed', error: e, stackTrace: st);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Contact>>> searchUsers(String query) async {
    try {
      if (!_matrix.isLoggedIn || query.isEmpty) return const Right([]);
      final profiles = await _matrix.searchUsers(query);
      final contacts = profiles.map((p) => Contact(
        userId: p.userId,
        displayName: p.displayName ?? p.userId.split(':').first.replaceFirst('@', ''),
        avatarUrl: p.avatarUrl?.toString(),
        matrixId: p.userId,
        status: ContactStatus.none)).toList();
      return Right(contacts);
    } catch (e, st) {
      AppLogger.instance.error('searchUsers failed', error: e, stackTrace: st);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendFriendRequest(String userId) async {
    try {
      if (!_matrix.isLoggedIn) return const Left(ServerFailure(message: 'Not logged in'));
      await _matrix.createDirectChat(userId);
      return const Right(null);
    } catch (e, st) {
      AppLogger.instance.error('sendFriendRequest failed', error: e, stackTrace: st);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> acceptFriendRequest(String userId) async {
    try {
      if (!_matrix.isLoggedIn) return const Left(ServerFailure(message: 'Not logged in'));
      await _matrix.createDirectChat(userId);
      return const Right(null);
    } catch (e, st) {
      AppLogger.instance.error('acceptFriendRequest failed', error: e, stackTrace: st);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> declineFriendRequest(String userId) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> removeContact(String userId) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> blockUser(String userId) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> unblockUser(String userId) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, Contact>> getUserProfile(String userId) async {
    try {
      if (!_matrix.isLoggedIn) return const Left(ServerFailure(message: 'Not logged in'));
      final profile = await _matrix.searchUsers(userId);
      if (profile.isEmpty) return const Left(ServerFailure(message: 'User not found'));
      final p = profile.first;
      return Right(Contact(
        userId: p.userId,
        displayName: p.displayName ?? p.userId.split(':').first.replaceFirst('@', ''),
        avatarUrl: p.avatarUrl?.toString(),
        matrixId: p.userId,
        status: ContactStatus.none));
    } catch (e, st) {
      AppLogger.instance.error('getUserProfile failed', error: e, stackTrace: st);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Contact>>> getPendingRequests() async {
    return const Right([]);
  }
}
