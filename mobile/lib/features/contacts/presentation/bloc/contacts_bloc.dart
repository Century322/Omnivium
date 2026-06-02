import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/contact.dart';
import '../../domain/usecases/contacts_usecases.dart';
import 'contacts_event.dart';
import 'contacts_state.dart';

class ContactsBloc extends Bloc<ContactsEvent, ContactsState> {
  final GetContactsUseCase _getContacts;
  final SearchUsersUseCase _searchUsers;
  final SendFriendRequestUseCase _sendFriendRequest;
  final AcceptFriendRequestUseCase _acceptFriendRequest;
  final GetPendingRequestsUseCase _getPendingRequests;

  ContactsBloc(
    this._getContacts,
    this._searchUsers,
    this._sendFriendRequest,
    this._acceptFriendRequest,
    this._getPendingRequests) : super(const ContactsInitial()) {
    on<ContactsLoadRequested>(_onLoadContacts);
    on<ContactsSearched>(_onSearch);
    on<FriendRequestSent>(_onSendRequest);
    on<FriendRequestAccepted>(_onAcceptRequest);
    on<FriendRequestDeclined>(_onDeclineRequest);
    on<ContactRemoved>(_onRemoveContact);
    on<PendingRequestsLoaded>(_onLoadPending);
  }

  Future<void> _onLoadContacts(ContactsLoadRequested event, Emitter<ContactsState> emit) async {
    emit(const ContactsLoading());
    final result = await _getContacts(const NoParams());
    result.fold(
      (failure) => emit(ContactsError(failure.message)),
      (contacts) => emit(ContactsLoaded(contacts)));
  }

  Future<void> _onSearch(ContactsSearched event, Emitter<ContactsState> emit) async {
    final result = await _searchUsers(event.query);
    final currentContacts = state is ContactsLoaded
        ? (state as ContactsLoaded).contacts
        : <Contact>[];
    result.fold(
      (failure) => emit(ContactsError(failure.message)),
      (results) => emit(ContactsSearchResult(contacts: currentContacts, searchResults: results)));
  }

  Future<void> _onSendRequest(FriendRequestSent event, Emitter<ContactsState> emit) async {
    await _sendFriendRequest(event.userId);
  }

  Future<void> _onAcceptRequest(FriendRequestAccepted event, Emitter<ContactsState> emit) async {
    await _acceptFriendRequest(event.userId);
    add(const ContactsLoadRequested());
  }

  Future<void> _onDeclineRequest(FriendRequestDeclined event, Emitter<ContactsState> emit) async {
  }

  Future<void> _onRemoveContact(ContactRemoved event, Emitter<ContactsState> emit) async {
    add(const ContactsLoadRequested());
  }

  Future<void> _onLoadPending(PendingRequestsLoaded event, Emitter<ContactsState> emit) async {
    final contactsResult = await _getContacts(const NoParams());
    final pendingResult = await _getPendingRequests(const NoParams());
    final contacts = contactsResult.getOrElse(() => []);
    pendingResult.fold(
      (failure) => emit(ContactsError(failure.message)),
      (pending) => emit(ContactsPendingLoaded(contacts: contacts, pendingRequests: pending)));
  }
}
