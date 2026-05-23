import '../../core/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/skeleton_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../theme/locale_provider.dart';
import '../../core/app_provider.dart';
import '../../core/navigation_provider.dart';

class SearchView extends StatefulWidget {
  final AppProvider provider;
  const SearchView({super.key, required this.provider});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _isSearching = false;
  bool _searchError = false;
  List<_SearchResult> _results = [];
  List<String> _searchHistory = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('omnivium_search_history') ?? [];
    if (!mounted) return;
    setState(() => _searchHistory = history);
  }

  Future<void> _saveHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    _searchHistory = [
      query,
      ..._searchHistory.where((h) => h != query),
    ].take(10).toList();
    await prefs.setStringList('omnivium_search_history', _searchHistory);
  }

  Future<void> _doSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _query = query.trim();
      _isSearching = true;
      _searchError = false;
      _results.clear();
    });
    await _saveHistory(query.trim());

    final results = <_SearchResult>[];
    final matrix = widget.provider.matrix;
    bool messageSearchFailed = false;
    bool userSearchFailed = false;
    if (matrix.isLoggedIn && matrix.client != null) {
      try {
        for (final room in matrix.rooms) {
          final timeline = await room.getTimeline();
          var events = timeline.events;
          var count = 0;
          for (final event in events) {
            if (count >= 50) break;
            if (event.body.toLowerCase().contains(query.toLowerCase())) {
              results.add(
                _SearchResult(
                  type: _SearchResultType.message,
                  title: room.getLocalizedDisplayname(),
                  subtitle: event.body,
                  roomId: room.id,
                  eventId: event.eventId,
                ),
              );
              count++;
            }
          }
        }
      } catch (e, stackTrace) {
        messageSearchFailed = true;
        AppLogger.instance.error(
          'Operation failed',
          error: e,
          stackTrace: stackTrace,
        );
      }
      try {
        final users = await matrix.searchUsers(query);
        for (final user in users.take(5)) {
          results.add(
            _SearchResult(
              type: _SearchResultType.user,
              title:
                  user.displayName ??
                  user.userId.split(':').first.replaceFirst('@', ''),
              subtitle: user.userId,
              userId: user.userId,
            ),
          );
        }
      } catch (e, stackTrace) {
        userSearchFailed = true;
        AppLogger.instance.error(
          'Operation failed',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }

    for (final session in widget.provider.session.sessions.take(20)) {
      if (session.title.toLowerCase().contains(query.toLowerCase())) {
        results.add(
          _SearchResult(
            type: _SearchResultType.conversation,
            title: session.title,
            subtitle:
                '${session.messages.length} ${localeProvider.t('messages')}',
            sessionId: session.id,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _results = results;
        _isSearching = false;
        _searchError = messageSearchFailed && userSearchFailed && results.isEmpty;
      });
    }
  }

  void _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('omnivium_search_history');
    if (!mounted) return;
    setState(() => _searchHistory = []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(context),
            Expanded(
              child: _isSearching
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: List.generate(4, (_) => const CardSkeleton()),
                      ),
                    )
                  : _searchError
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.searchX, size: 48, color: AppColors.mut(context)),
                              const SizedBox(height: 12),
                              Text(
                                localeProvider.t('search_error'),
                                style: TextStyle(color: AppColors.textSecondary(context), fontSize: 15),
                              ),
                              const SizedBox(height: 16),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.acc(context),
                                  foregroundColor: AppColors.bg(context),
                                ),
                                onPressed: () => _doSearch(_query),
                                child: Text(localeProvider.t('retry')),
                              ),
                            ],
                          ),
                        )
                  : _query.isEmpty
                  ? _buildHistorySection(context)
                  : _buildResults(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          Semantics(
            label: localeProvider.t('go_back'),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  widget.provider.navigation.setCurrentView(ViewState.home),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  LucideIcons.arrowLeft,
                  color: AppColors.textTertiary(context),
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(22),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.search,
                    size: 18,
                    color: AppColors.textHint(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: TextStyle(
                        color: AppColors.textPrimary(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        labelText: localeProvider.t('search_posts'),
                        hintStyle: TextStyle(
                          color: AppColors.textDisabled(context),
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                      ),
                      onSubmitted: _doSearch,
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    Semantics(
                      label: localeProvider.t('clear_search'),
                      button: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          _searchController.clear();
                          setState(() {
                            _query = '';
                            _results.clear();
                          });
                        },
                        child: Icon(
                          LucideIcons.x,
                          size: 16,
                          color: AppColors.textHint(context),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context) {
    if (_searchHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.divider(context),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: AppColors.divider(context)),
              ),
              child: Icon(
                LucideIcons.search,
                color: AppColors.textDisabled(context),
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              localeProvider.t('no_search_history'),
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textHint(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              localeProvider.t('search_history_desc'),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textDisabled(context),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                localeProvider.t('search_history'),
                style: TextStyle(
                  color: AppColors.mut(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Semantics(
                label: localeProvider.t('clear_search_history'),
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _clearHistory,
                  child: Text(
                    localeProvider.t('clear'),
                    style: TextStyle(color: AppColors.acc(context), fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        ..._searchHistory.map(
          (h) => ListTile(
            leading: Icon(
              LucideIcons.clock,
              size: 18,
              color: AppColors.textDisabled(context),
            ),
            title: Text(
              h,
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 14,
              ),
            ),
            trailing: Icon(
              LucideIcons.arrowUpRight,
              size: 16,
              color: AppColors.textDisabled(context),
            ),
            onTap: () {
              _searchController.text = h;
              _doSearch(h);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResults(BuildContext context) {
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.searchX,
              size: 48,
              color: AppColors.textDisabled(context),
            ),
            const SizedBox(height: 12),
            Text(
              localeProvider.t('no_search_results'),
              style: TextStyle(
                color: AppColors.textHint(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final messages = _results
        .where((r) => r.type == _SearchResultType.message)
        .toList();
    final users = _results
        .where((r) => r.type == _SearchResultType.user)
        .toList();
    final conversations = _results
        .where((r) => r.type == _SearchResultType.conversation)
        .toList();

    final items = <dynamic>[
      if (conversations.isNotEmpty) ...['_header_conv', ...conversations],
      if (messages.isNotEmpty) ...['_header_msg', ...messages],
      if (users.isNotEmpty) ...['_header_user', ...users],
    ];
    if (items.isEmpty) {
      return Center(
        child: Text(
          localeProvider.t('no_results'),
          style: TextStyle(color: AppColors.textTertiary(context)),
        ),
      );
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item == '_header_conv') {
          return _buildSectionHeader(
            context,
            localeProvider.t('conversations'),
            conversations.length,
          );
        }
        if (item == '_header_msg') {
          return _buildSectionHeader(
            context,
            localeProvider.t('messages'),
            messages.length,
          );
        }
        if (item == '_header_user') {
          return _buildSectionHeader(
            context,
            localeProvider.t('contacts'),
            users.length,
          );
        }
        return _buildResultTile(context, item as _SearchResult);
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        '$title ($count)',
        style: TextStyle(
          color: AppColors.mut(context),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildResultTile(BuildContext context, _SearchResult result) {
    IconData icon;
    switch (result.type) {
      case _SearchResultType.message:
        icon = LucideIcons.messageSquare;
        break;
      case _SearchResultType.user:
        icon = LucideIcons.user;
        break;
      case _SearchResultType.conversation:
        icon = LucideIcons.bot;
        break;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.accBg(context),
        child: Icon(icon, size: 18, color: AppColors.acc(context)),
      ),
      title: Text(
        result.title,
        style: TextStyle(
          color: AppColors.textPrimary(context),
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        result.subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: AppColors.mut(context), fontSize: 12),
      ),
      onTap: () => _handleResultTap(result),
    );
  }

  void _handleResultTap(_SearchResult result) {
    switch (result.type) {
      case _SearchResultType.message:
        if (result.roomId != null) {
          widget.provider.matrix.setActiveRoom(result.roomId!);
          widget.provider.navigation.setCurrentView(ViewState.home);
        }
        break;
      case _SearchResultType.user:
        if (result.userId != null) {
          widget.provider.matrix.createDirectChat(result.userId!).then((
            roomId,
          ) {
            widget.provider.matrix.setActiveRoom(roomId);
            widget.provider.navigation.setCurrentView(ViewState.home);
          });
        }
        break;
      case _SearchResultType.conversation:
        if (result.sessionId != null) {
          widget.provider.session.switchSession(result.sessionId!);
          widget.provider.navigation.setCurrentView(ViewState.home);
        }
        break;
    }
  }
}

enum _SearchResultType { message, user, conversation }

class _SearchResult {
  final _SearchResultType type;
  final String title;
  final String subtitle;
  final String? roomId;
  final String? eventId;
  final String? userId;
  final String? sessionId;

  const _SearchResult({
    required this.type,
    required this.title,
    required this.subtitle,
    this.roomId,
    this.eventId,
    this.userId,
    this.sessionId,
  });
}
