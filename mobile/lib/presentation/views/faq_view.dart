import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/locale_provider.dart';

class FaqView extends StatefulWidget {
  const FaqView({super.key});

  @override
  State<FaqView> createState() => _FaqViewState();
}

class _FaqViewState extends State<FaqView> {
  int? _expandedIndex;

  List<(String, String)> get _faqs => [
    (localeProvider.t('faq_q1'), localeProvider.t('faq_a1')),
    (localeProvider.t('faq_q2'), localeProvider.t('faq_a2')),
    (localeProvider.t('faq_q3'), localeProvider.t('faq_a3')),
    (localeProvider.t('faq_q4'), localeProvider.t('faq_a4')),
    (localeProvider.t('faq_q5'), localeProvider.t('faq_a5')),
    (localeProvider.t('faq_q6'), localeProvider.t('faq_a6')),
    (localeProvider.t('faq_q7'), localeProvider.t('faq_a7')),
    (localeProvider.t('faq_q8'), localeProvider.t('faq_a8')),
    (localeProvider.t('faq_q9'), localeProvider.t('faq_a9')),
    (localeProvider.t('faq_q10'), localeProvider.t('faq_a10')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          tooltip: localeProvider.t('back'),
          icon: Icon(LucideIcons.arrowLeft, color: AppColors.sec(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          localeProvider.t('help_faq'),
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: _faqs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 6),
        itemBuilder: (_, i) {
          final (question, answer) = _faqs[i];
          final isExpanded = _expandedIndex == i;
          return Container(
            decoration: BoxDecoration(
              color: AppColors.sf(context),
              borderRadius: BorderRadius.circular(14),
              border: isExpanded
                  ? Border.all(
                      color: AppColors.acc(context).withValues(alpha: 0.2),
                    )
                  : null,
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerTheme: const DividerThemeData(color: Colors.transparent),
              ),
              child: ExpansionTile(
                initiallyExpanded: isExpanded,
                onExpansionChanged: (expanded) =>
                    setState(() => _expandedIndex = expanded ? i : null),
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                trailing: Icon(
                  isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 18,
                  color: AppColors.sec(context),
                ),
                title: Text(
                  question,
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Text(
                      answer,
                      style: TextStyle(
                        color: AppColors.textHint(context),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
