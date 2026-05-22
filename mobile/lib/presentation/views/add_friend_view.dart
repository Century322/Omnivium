import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:matrix/matrix.dart';
import '../widgets/skeleton_loader.dart';
import '../theme/app_colors.dart';
import '../theme/locale_provider.dart';
import '../../core/app_provider.dart';

class AddFriendView extends StatefulWidget {
  final AppProvider provider;
  const AddFriendView({super.key, required this.provider});

  @override
  State<AddFriendView> createState() => _AddFriendViewState();
}

class _AddFriendViewState extends State<AddFriendView> {
  final _searchController = TextEditingController();
  final _idController = TextEditingController();
  final _idFocus = FocusNode();
  final _searchFocus = FocusNode();
  List<Profile> _searchResults = [];
  bool _isSearching = false;
  bool _isAdding = false;
  int _addingIndex = -1;

  @override
  void dispose() {
    _searchController.dispose();
    _idController.dispose();
    _idFocus.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _doSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() => _isSearching = true);
    final results = await widget.provider.matrix.searchUsers(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  Future<void> _startChatWith(String userId, int index) async {
    setState(() {
      _isAdding = true;
      _addingIndex = index;
    });
    try {
      final roomId = await widget.provider.matrix.createDirectChat(userId);
      if (mounted) {
        widget.provider.matrix.setActiveRoom(roomId);
        Navigator.pop(context, roomId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localeProvider.t('add_contact_failed')}: $e'),
            backgroundColor: AppColors.dng(context),
          ),
        );
      }
    }
    if (mounted) {
      setState(() {
        _isAdding = false;
        _addingIndex = -1;
      });
    }
  }

  Future<void> _addById() async {
    final userId = _idController.text.trim();
    if (userId.isEmpty) return;
    if (!userId.startsWith('@') || !userId.contains(':') || userId.length < 5 || userId.split(':').length != 2 || userId.split(':')[0].length < 2 || userId.split(':')[1].length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localeProvider.t('invalid_matrix_id')),
          backgroundColor: AppColors.warn(context),
        ),
      );
      return;
    }
    setState(() => _isAdding = true);
    try {
      final roomId = await widget.provider.matrix.createDirectChat(userId);
      if (mounted) {
        widget.provider.matrix.setActiveRoom(roomId);
        Navigator.pop(context, roomId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localeProvider.t('add_contact_failed')}: $e'),
            backgroundColor: AppColors.dng(context),
          ),
        );
      }
    }
    if (mounted) {
      setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.sf(context),
        elevation: 0,
        leading: IconButton(
          tooltip: localeProvider.t('back'),
          icon: Icon(LucideIcons.arrowLeft, color: AppColors.textSecondary(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(localeProvider.t('add_contact'), style: TextStyle(color: AppColors.textPrimary(context), fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAddByIdSection(context),
            const SizedBox(height: 24),
            _buildSearchSection(context),
            if (_isSearching)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(children: List.generate(3, (_) => const MessageSkeleton())),
              )
            else if (_searchResults.isNotEmpty)
              ..._buildSearchResults(context)
            else if (_searchController.text.isNotEmpty && !_isSearching)
              _buildEmptyResult(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAddByIdSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        border: Border(bottom: BorderSide(color: AppColors.divider(context))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(localeProvider.t('add_by_id'), style: TextStyle(color: AppColors.textPrimary(context), fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(localeProvider.t('add_by_id_desc'), style: TextStyle(color: AppColors.mut(context), fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_idFocus]),
                  builder: (context, _) {
                    final isFocused = _idFocus.hasFocus;
                    return Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.bg(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isFocused ? AppColors.accent : AppColors.divider(context)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        controller: _idController,
                        focusNode: _idFocus,
                        style: TextStyle(color: AppColors.textPrimary(context), fontSize: 14),
                        decoration: InputDecoration(
                          labelText:  '@user:server.com',
                          hintStyle: TextStyle(color: AppColors.textDisabled(context), fontSize: 14),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: FilledButton(
                  onPressed: _isAdding ? null : _addById,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.bg(context),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isAdding
                      ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bg(context)))
                      : Text(localeProvider.t('add'), style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        border: Border(bottom: BorderSide(color: AppColors.divider(context))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(localeProvider.t('search_users'), style: TextStyle(color: AppColors.textPrimary(context), fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: Listenable.merge([_searchFocus]),
            builder: (context, _) {
              final isFocused = _searchFocus.hasFocus;
              return Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.bg(context),
                  borderRadius: BorderRadius.circular(22),
                  border: isFocused ? Border.all(color: AppColors.accent) : null,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(LucideIcons.search, size: 18, color: isFocused ? AppColors.accent : AppColors.textHint(context)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocus,
                        style: TextStyle(color: AppColors.textPrimary(context), fontSize: 15),
                        decoration: InputDecoration(
                          labelText:  localeProvider.t('search_users_hint'),
                          hintStyle: TextStyle(color: AppColors.textDisabled(context)),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                        ),
                        onSubmitted: (_) => _doSearch(),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      Semantics(label: localeProvider.t('clear_search'), child: GestureDetector(

      behavior: HitTestBehavior.opaque,
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchResults = []);
                        },
                        child: Icon(LucideIcons.x, size: 16, color: AppColors.textHint(context)),
                      )),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton(
              onPressed: _doSearch,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.accent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(localeProvider.t('search'), style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSearchResults(BuildContext context) {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text('${localeProvider.t('search_results')} (${_searchResults.length})', style: TextStyle(color: AppColors.mut(context), fontSize: 12, fontWeight: FontWeight.w600)),
      ),
      ..._searchResults.asMap().entries.map((entry) {
        final index = entry.key;
        final profile = entry.value;
        final displayName = profile.displayName ?? profile.userId.split(':').first.replaceFirst('@', '');
        final isAddingThis = _isAdding && _addingIndex == index;
        return Container(
          decoration: BoxDecoration(
            color: AppColors.sf(context),
            border: Border(bottom: BorderSide(color: AppColors.divider(context))),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.accBg(context),
              child: Text(displayName[0].toUpperCase(), style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
            ),
            title: Text(displayName, style: TextStyle(color: AppColors.textPrimary(context), fontWeight: FontWeight.w500)),
            subtitle: Text(profile.userId, style: TextStyle(color: AppColors.mut(context), fontSize: 12)),
            trailing: isAddingThis
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))
                : Icon(LucideIcons.userPlus, color: AppColors.accent, size: 22),
            onTap: isAddingThis ? null : () => _startChatWith(profile.userId, index),
          ),
        );
      }),
    ];
  }

  Widget _buildEmptyResult(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(LucideIcons.userX, size: 40, color: AppColors.textDisabled(context)),
            const SizedBox(height: 12),
            Text(localeProvider.t('no_users_found'), style: TextStyle(color: AppColors.textHint(context), fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(localeProvider.t('try_different_search'), style: TextStyle(color: AppColors.textDisabled(context), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
