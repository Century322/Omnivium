import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/locale_provider.dart';
import '../widgets/home_components.dart';

class ChatSearchSheet extends StatelessWidget {
  final List<ChatMessageData> messages;
  String t(String key) => localeProvider.t(key);

  const ChatSearchSheet({super.key, required this.messages});

  void show(BuildContext context) {
    final searchCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final query = searchCtrl.text.toLowerCase();
            List<dynamic> results = [];
            if (query.isNotEmpty) {
              for (var i = 0; i < messages.length; i++) {
                if (messages[i].content.toLowerCase().contains(query)) {
                  results.add({
                    'index': i,
                    'content': messages[i].content,
                    'role': messages[i].role,
                  });
                }
              }
            }
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: searchCtrl,
                              autofocus: true,
                              style: TextStyle(
                                color: AppColors.textPrimary(context),
                                fontSize: 15,
                              ),
                              decoration: InputDecoration(
                                labelText: t('search_messages'),
                                hintStyle: TextStyle(
                                  color: AppColors.textDisabled(context),
                                ),
                                prefixIcon: Icon(
                                  LucideIcons.search,
                                  color: AppColors.textHint(context),
                                  size: 18,
                                ),
                                filled: true,
                                fillColor: AppColors.sf(context),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                              onChanged: (_) => setModalState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              t('cancel'),
                              style: TextStyle(color: AppColors.sec(context)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (query.isNotEmpty && results.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          t('no_match_msg'),
                          style: TextStyle(
                            color: AppColors.textDisabled(context),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    if (results.isNotEmpty)
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(ctx).size.height * 0.4,
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: results.length,
                          itemBuilder: (ctx, i) {
                            final r = results[i];
                            final content = r['content'] as String;
                            final highlightStart = content
                                .toLowerCase()
                                .indexOf(query);
                            return ListTile(
                              dense: true,
                              title: _buildHighlightedText(
                                context,
                                content,
                                highlightStart,
                                query.length,
                              ),
                              subtitle: Text(
                                r['role'] == 'user'
                                    ? localeProvider.t('me')
                                    : localeProvider.t('ai'),
                                style: TextStyle(
                                  color: AppColors.textDisabled(context),
                                  fontSize: 11,
                                ),
                              ),
                              onTap: () => Navigator.pop(ctx),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHighlightedText(
    BuildContext context,
    String text,
    int start,
    int length,
  ) {
    if (start < 0)
      return Text(
        text,
        style: TextStyle(color: AppColors.textSecondary(context), fontSize: 14),
      );
    final before = text.substring(0, start);
    final match = text.substring(start, start + length);
    final after = text.substring(start + length);
    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(color: AppColors.textSecondary(context), fontSize: 14),
        children: [
          TextSpan(text: before),
          TextSpan(
            text: match,
            style: TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
