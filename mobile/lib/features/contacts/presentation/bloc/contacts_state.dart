import 'package:equatable/equatable.dart';
import '../../domain/entities/contact.dart';

abstract class ContactsState extends Equatable {
  const ContactsState();
  @override
  List<Object?> get props => [];
}

class ContactsInitial extends ContactsState {
  const ContactsInitial();
}

class ContactsLoading extends ContactsState {
  const ContactsLoading();
}

class ContactsLoaded extends ContactsState {
  final List<Contact> contacts;
  const ContactsLoaded(this.contacts);
  @override
  List<Object?> get props => [contacts];
}

class ContactsSearchResult extends ContactsState {
  final List<Contact> contacts;
  final List<Contact> searchResults;
  const ContactsSearchResult({required this.contacts, required this.searchResults});
  @override
  List<Object?> get props => [contacts, searchResults];
}

class ContactsPendingLoaded extends ContactsState {
  final List<Contact> contacts;
  final List<Contact> pendingRequests;
  const ContactsPendingLoaded({required this.contacts, required this.pendingRequests});
  @override
  List<Object?> get props => [contacts, pendingRequests];
}

class ContactsError extends ContactsState {
  final String message;
  const ContactsError(this.message);
  @override
  List<Object?> get props => [message];
}
