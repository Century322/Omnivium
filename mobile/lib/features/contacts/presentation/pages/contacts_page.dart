import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../domain/entities/contact.dart';
import '../bloc/contacts_bloc.dart';
import '../bloc/contacts_event.dart';
import '../bloc/contacts_state.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/locale_cubit.dart';
import '../../../../core/di/app_di.dart';

class ContactsPage extends StatelessWidget {
  final VoidCallback? onOpenChat;
  final void Function(String userId, String displayName)? onOpenFriendChat;

  const ContactsPage({super.key, this.onOpenChat, this.onOpenFriendChat});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ContactsBloc>()..add(const ContactsLoadRequested()),
      child: _ContactsContent(
        onOpenChat: onOpenChat,
        onOpenFriendChat: onOpenFriendChat));
  }
}

class _ContactsContent extends StatefulWidget {
  final VoidCallback? onOpenChat;
  final void Function(String userId, String displayName)? onOpenFriendChat;

  const _ContactsContent({this.onOpenChat, this.onOpenFriendChat});

  @override
  State<_ContactsContent> createState() => _ContactsContentState();
}

class _ContactsContentState extends State<_ContactsContent> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _doSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    context.read<ContactsBloc>().add(ContactsSearched(query));
  }

  @override
  Widget build(BuildContext context) {
    final t = localeProvider.t;
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 56,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.divider(context)))),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      LucideIcons.arrowLeft,
                      color: AppColors.textPrimary(context),
                      size: 24)),
                  const SizedBox(width: 16),
                  Text(
                    t('contacts'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary(context))),
                  const Spacer(),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _showSearch = !_showSearch),
                    child: Icon(
                      LucideIcons.search,
                      color: AppColors.textSecondary(context),
                      size: 20)),
                ])),
            if (_showSearch) _buildSearchBar(),
            Expanded(child: _buildBody()),
          ])));
  }

  Widget _buildSearchBar() {
    return AnimatedBuilder(
      animation: Listenable.merge([_searchFocus]),
      builder: (context, _) {
        final isFocused = _searchFocus.hasFocus;
        return Container(
          margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.sf(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isFocused
                  ? AppColors.acc(context)
                  : AppColors.divider(context))),
          child: Row(
            children: [
              Icon(
                LucideIcons.search,
                size: 16,
                color: isFocused
                    ? AppColors.acc(context)
                    : AppColors.textHint(context)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  maxLength: 256,
                  autofocus: true,
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 14),
                  decoration: InputDecoration(
                    labelText: localeProvider.t('search_id'),
                    hintStyle: TextStyle(
                      color: AppColors.textTertiary(context),
                      fontSize: 14),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    isDense: true),
                  onSubmitted: (_) => _doSearch(),
                  onChanged: (_) => setState(() {}))),
              if (_searchController.text.isNotEmpty)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    _searchController.clear();
                    context.read<ContactsBloc>().add(const ContactsLoadRequested());
                    setState(() {});
                  },
                  child: Icon(
                    LucideIcons.x,
                    size: 14,
                    color: AppColors.textHint(context))),
            ]));
      });
  }

  Widget _buildBody() {
    return BlocConsumer<ContactsBloc, ContactsState>(
      listener: (context, state) {
        if (state is ContactsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.dng(context)));
        }
      },
      builder: (context, state) {
        if (state is ContactsLoading) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.acc(context)));
        }

        if (state is ContactsSearchResult) {
          return _buildSearchResults(state);
        }

        if (state is ContactsPendingLoaded) {
          return _buildPendingAndContacts(state);
        }

        if (state is ContactsLoaded) {
          return _buildContactsList(state.contacts);
        }

        return _buildEmptyState();
      });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.users,
            size: 48,
            color: AppColors.textDisabled(context)),
          const SizedBox(height: 16),
          Text(
            localeProvider.t('no_chats'),
            style: TextStyle(
              color: AppColors.textTertiary(context),
              fontSize: 15)),
        ]));
  }

  Widget _buildContactsList(List<Contact> contacts) {
    if (contacts.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      color: AppColors.acc(context),
      onRefresh: () async {
        context.read<ContactsBloc>().add(const ContactsLoadRequested());
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: contacts.length,
        itemBuilder: (_, i) => _buildContactItem(contacts[i])));
  }

  Widget _buildSearchResults(ContactsSearchResult state) {
    if (state.searchResults.isEmpty) {
      return Center(
        child: Text(
          localeProvider.t('no_match_chat'),
          style: TextStyle(
            color: AppColors.textTertiary(context),
            fontSize: 15)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: state.searchResults.length,
      itemBuilder: (_, i) => _buildContactItem(state.searchResults[i], isSearchResult: true));
  }

  Widget _buildPendingAndContacts(ContactsPendingLoaded state) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        if (state.pendingRequests.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              localeProvider.t('friend_requests'),
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 13,
                fontWeight: FontWeight.w600))),
          ...state.pendingRequests.map((c) => _buildPendingItem(c)),
          const SizedBox(height: 12),
        ],
        if (state.contacts.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              localeProvider.t('contacts'),
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 13,
                fontWeight: FontWeight.w600))),
          ...state.contacts.map((c) => _buildContactItem(c)),
        ],
      ]);
  }

  Widget _buildPendingItem(Contact contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          _buildAvatar(contact.displayName, contact.isOnline),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.displayName,
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
                Text(
                  contact.matrixId ?? contact.userId,
                  style: TextStyle(
                    color: AppColors.textTertiary(context),
                    fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              ])),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => context.read<ContactsBloc>().add(
                  FriendRequestAccepted(contact.userId)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.acc(context),
                    borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    localeProvider.t('accept'),
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)))),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.read<ContactsBloc>().add(
                  FriendRequestDeclined(contact.userId)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.dng(context).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    localeProvider.t('decline'),
                    style: TextStyle(
                      color: AppColors.dng(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)))),
            ]),
        ]));
  }

  Widget _buildContactItem(Contact contact, {bool isSearchResult = false}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onOpenFriendChat?.call(contact.userId, contact.displayName),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.sf(context),
          borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            _buildAvatar(contact.displayName, contact.isOnline),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.displayName,
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                  if (contact.matrixId != null)
                    Text(
                      contact.matrixId!,
                      style: TextStyle(
                        color: AppColors.textTertiary(context),
                        fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ])),
            if (isSearchResult)
              GestureDetector(
                onTap: () => context.read<ContactsBloc>().add(
                  FriendRequestSent(contact.userId)),
                child: Icon(
                  LucideIcons.userPlus,
                  size: 18,
                  color: AppColors.sec(context)))
            else
              Icon(
                LucideIcons.messageCircle,
                size: 18,
                color: AppColors.sec(context)),
          ])));
  }

  Widget _buildAvatar(String name, bool isOnline) {
    return Stack(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.acc(context).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20)),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                color: AppColors.acc(context),
                fontSize: 16,
                fontWeight: FontWeight.w600)))),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.ok(context),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.bg(context),
                  width: 2)))),
      ]);
  }
}
