import 'package:equatable/equatable.dart';

abstract class ContactsEvent extends Equatable {
  const ContactsEvent();
  @override
  List<Object?> get props => [];
}

class ContactsLoadRequested extends ContactsEvent {
  const ContactsLoadRequested();
}

class ContactsSearched extends ContactsEvent {
  final String query;
  const ContactsSearched(this.query);
  @override
  List<Object?> get props => [query];
}

class FriendRequestSent extends ContactsEvent {
  final String userId;
  const FriendRequestSent(this.userId);
  @override
  List<Object?> get props => [userId];
}

class FriendRequestAccepted extends ContactsEvent {
  final String userId;
  const FriendRequestAccepted(this.userId);
  @override
  List<Object?> get props => [userId];
}

class FriendRequestDeclined extends ContactsEvent {
  final String userId;
  const FriendRequestDeclined(this.userId);
  @override
  List<Object?> get props => [userId];
}

class ContactRemoved extends ContactsEvent {
  final String userId;
  const ContactRemoved(this.userId);
  @override
  List<Object?> get props => [userId];
}

class PendingRequestsLoaded extends ContactsEvent {
  const PendingRequestsLoaded();
}
