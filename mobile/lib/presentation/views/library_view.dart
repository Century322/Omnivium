import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/locale_provider.dart';
import '../../core/app_provider.dart';
import '../../core/navigation_provider.dart';

class LibraryView extends StatelessWidget {
  final AppProvider provider;
  const LibraryView({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Semantics(label: localeProvider.t('go_back'), child: GestureDetector(
                    onTap: () => provider.navigation.setCurrentView(ViewState.home),
                    child: Icon(LucideIcons.arrowLeft, color: AppColors.textSecondary(context)),
                  )),
                  const SizedBox(width: 16),
                  Text(localeProvider.t('library'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.sfAlt(context),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Icon(LucideIcons.clock, color: AppColors.textHint(context), size: 28),
                    ),
                    const SizedBox(height: 16),
                    Text(localeProvider.t('library'), style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.textHint(context))),
                    const SizedBox(height: 4),
                    Text(localeProvider.t('library_empty_desc'), style: TextStyle(fontSize: 12, color: AppColors.textDisabled(context))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
