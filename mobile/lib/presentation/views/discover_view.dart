import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/locale_provider.dart';
import '../../core/app_provider.dart';
import '../../core/navigation_provider.dart';
import '../../core/api_proxy_service.dart';
import '../../core/app_logger.dart';
import '../../core/remote_config_service.dart';
import '../../core/lite_mode.dart';
import '../widgets/skeleton_loader.dart';
import '../utils/responsive.dart';

class DiscoverView extends StatefulWidget {
  final AppProvider provider;
  const DiscoverView({super.key, required this.provider});

  @override
  State<DiscoverView> createState() => _DiscoverViewState();
}

class _DiscoverViewState extends State<DiscoverView> {
  List<_Item> _items = [];
  bool _isLoading = true;

  static const _fallbackItems = [
    {'title': 'Welcome to Omnivium', 'desc': 'Discover curated content powered by AI. Stay tuned for the latest updates.', 'author': 'Omnivium', 'img': '', 'bg': '#1a1a2e', 'avatar': '#4a4a6a'},
  ];

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      final proxy = ApiProxyService.instance;
      if (proxy.isConfigured) {
        final uri = Uri.parse('${proxy.backendUrl}/content/discover');
        final response = await proxy.secureClient.get(uri, headers: {
          ...proxy.buildAuthHeaders(),
          ...proxy.buildDeviceHeaders(),
        }).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          final articles = body['articles'] as List<dynamic>?;
          if (articles != null && articles.isNotEmpty) {
            if (mounted) {
              setState(() {
                _items = articles.map((a) {
                  final m = a as Map<String, dynamic>;
                  return _Item(
                    title: m['title'] as String? ?? '',
                    desc: m['description'] as String? ?? '',
                    author: m['author'] as String? ?? '',
                    imgSrc: m['image'] as String? ?? '',
                    avatarColor: _parseColor(m['avatar_color'] as String?) ?? AppColors.accent,
                    bgColor: _parseColor(m['bg_color'] as String?) ?? AppColors.sf(context),
                  );
                }).toList();
                _isLoading = false;
              });
            }
            return;
          }
        }
      }
    } catch (e, stackTrace) {
      AppLogger.instance.warning('Discover content fetch failed, using fallback', error: e, stackTrace: stackTrace);
    }

    final schema = RemoteConfigService.instance.getUISchema('discover');
    if (schema != null && schema['items'] != null) {
      final items = schema['items'] as List<dynamic>;
      if (items.isNotEmpty && mounted) {
        setState(() {
          _items = items.map((a) {
            final m = a as Map<String, dynamic>;
            return _Item(
              title: m['title'] as String? ?? '',
              desc: m['description'] as String? ?? '',
              author: m['author'] as String? ?? '',
              imgSrc: m['image'] as String? ?? '',
              avatarColor: _parseColor(m['avatar_color'] as String?) ?? AppColors.accent,
              bgColor: _parseColor(m['bg_color'] as String?) ?? AppColors.sf(context),
            );
          }).toList();
          _isLoading = false;
        });
        return;
      }
    }

    if (mounted) {
      setState(() {
        _items = _fallbackItems.map((m) => _Item(
          title: m['title']!,
          desc: m['desc']!,
          author: m['author']!,
          imgSrc: m['img']!,
          avatarColor: _parseColor(m['avatar']) ?? AppColors.accent,
          bgColor: _parseColor(m['bg']) ?? AppColors.sf(context),
        )).toList();
        _isLoading = false;
      });
    }
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final code = hex.replaceFirst('#', '');
    if (code.length == 6) {
      return Color(int.parse('FF$code', radix: 16));
    }
    if (code.length == 8) {
      return Color(int.parse(code, radix: 16));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final contentWidth = Responsive.contentMaxWidth(context);

    return Scaffold(
      body: Semantics(label: localeProvider.t('go_back'), child: GestureDetector(

      behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: (d) {
          if (d.primaryVelocity != null && d.primaryVelocity! > 500) {
            widget.provider.navigation.setCurrentView(ViewState.home);
          }
        },
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: _isLoading
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: List.generate(2, (_) => const CardSkeleton())))
                    : PageView.builder(
                        scrollDirection: Axis.vertical,
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          return _buildCard(context, _items[index]);
                        },
                      ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRect(
                child: LiteMode.instance.blurEffectsEnabled
                    ? BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
                          child: SafeArea(
                            bottom: false,
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                                  child: Row(
                                    children: [
                                      Semantics(label: localeProvider.t('go_back'), child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () => widget.provider.navigation.setCurrentView(ViewState.home),
                                        child: Icon(LucideIcons.arrowLeft, color: AppColors.textSecondary(context)),
                                      )),
                                      const SizedBox(width: 16),
                                      Text(localeProvider.t('discover'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
                                      const Spacer(),
                                      Stack(
                                        children: [
                                          Icon(LucideIcons.heart, color: AppColors.textSecondary(context), size: 24),
                                          Positioned(
                                            top: 2,
                                            right: -2,
                                            child: Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: AppColors.textPrimary(context),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                                              ),
                                              child: Center(
                                                child: Text('+', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context))),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: 40,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    children: [
                                      _tab(context, localeProvider.t('for_you'), active: true),
                                      _tab(context, localeProvider.t('headline_news')),
                                      _tab(context, localeProvider.t('science_tech')),
                                      _tab(context, localeProvider.t('business')),
                                      _tab(context, localeProvider.t('art_culture')),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
                        child: SafeArea(
                          bottom: false,
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                                child: Row(
                                  children: [
                                    Semantics(label: localeProvider.t('go_back'), child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => widget.provider.navigation.setCurrentView(ViewState.home),
                                      child: Icon(LucideIcons.arrowLeft, color: AppColors.textSecondary(context)),
                                    )),
                                    const SizedBox(width: 16),
                                    Text(localeProvider.t('discover'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
                                    const Spacer(),
                                    Stack(
                                      children: [
                                        Icon(LucideIcons.heart, color: AppColors.textSecondary(context), size: 24),
                                        Positioned(
                                          top: 2,
                                          right: -2,
                                          child: Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: AppColors.textPrimary(context),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                                            ),
                                            child: Center(
                                              child: Text('+', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context))),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 40,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  children: [
                                    _tab(context, localeProvider.t('for_you'), active: true),
                                    _tab(context, localeProvider.t('headline_news')),
                                    _tab(context, localeProvider.t('science_tech')),
                                    _tab(context, localeProvider.t('business')),
                                    _tab(context, localeProvider.t('art_culture')),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildCard(BuildContext context, _Item item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: item.bgColor,
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (item.imgSrc.isNotEmpty)
              Expanded(
                flex: 55,
                child: CachedNetworkImage(
                  imageUrl: item.imgSrc,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(color: AppColors.sf(context), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent)))),
                  errorWidget: (_, _, _) => Container(
                    color: AppColors.sf(context),
                    child: Icon(LucideIcons.image, color: AppColors.textDisabled(context), size: 48),
                  ),
                ),
              )
            else
              Expanded(
                flex: 55,
                child: Container(
                  color: AppColors.sfAlt(context),
                  child: Center(child: Icon(LucideIcons.sparkles, color: AppColors.accent, size: 48)),
                ),
              ),
            Expanded(
              flex: 45,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context), height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Text(
                        item.desc,
                        style: TextStyle(fontSize: 14.5, color: AppColors.textSecondary(context), height: 1.5),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: item.avatarColor,
                          child: ClipOval(
                            child: item.imgSrc.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: 'https://picsum.photos/seed/${item.author}/100/100',
                                    width: 24,
                                    height: 24,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, _, _) => const SizedBox(),
                                  )
                                : Icon(LucideIcons.user, size: 14, color: AppColors.textPrimary(context)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(item.author, style: TextStyle(fontSize: 13, color: AppColors.textTertiary(context))),
                        const Spacer(),
                        Icon(LucideIcons.bookmark, color: AppColors.textTertiary(context), size: 20),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, String label, {bool active = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AppColors.accBg(context) : AppColors.sf(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.accentLight : AppColors.sec(context),
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _Item {
  final String title;
  final String desc;
  final String author;
  final String imgSrc;
  final Color avatarColor;
  final Color bgColor;

  const _Item({required this.title, required this.desc, required this.author, required this.imgSrc, required this.avatarColor, required this.bgColor});
}
