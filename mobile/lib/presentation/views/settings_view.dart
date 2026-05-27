import '../../core/app_logger.dart';
import '../../core/app_navigator.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:io' if (dart.library.html) '';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../theme/wallpaper_presets.dart';
import '../theme/locale_provider.dart';
import '../../main.dart';
import '../../core/app_provider.dart';
import '../../core/analytics_service.dart';
import '../../core/remote_ui_engine.dart';
import '../../core/remote_config_service.dart';
import '../../core/database_service.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/auth_service.dart';
import '../../core/app_lock_service.dart';
import '../widgets/section_header.dart';
import '../widgets/setting_item.dart';
import '../widgets/animated_toggle.dart';
import 'matrix_login_view.dart';
import 'faq_view.dart';
import 'privacy_policy_view.dart';
import 'terms_of_service_view.dart';
import '../../core/secure_storage_service.dart';
import '../../core/voice_service.dart';
import '../../core/push_notification_service.dart';

class SettingsView extends StatefulWidget {
  final AppProvider provider;
  const SettingsView({super.key, required this.provider});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView>
    with SingleTickerProviderStateMixin {
  static String _appVersion = '';
  String t(String key) => localeProvider.t(key);
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool _notifications = true;
  bool _dataRetention = true;
  bool _agentEnabled = true;
  bool _lockEnabled = false;
  String _assistantLang = 'auto';
  String _imageModel = 'default_model';
  String _sttEngine = 'system';
  String _ttsVoice = 'Kyrin';
  String _voiceMode = 'hands_free';
  final _secure = SecureStorageService.instance;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _loadAppVersion();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
    _slideController.forward();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final lockEnabled = prefs.getBool('lock_enabled') ?? false;
    final hasPinHash = await _secure.read('omnivium_lock_pin_hash');
    if (lockEnabled && (hasPinHash == null || hasPinHash.isEmpty)) {
      await prefs.setBool('lock_enabled', false);
    }
    if (!mounted) return;
    setState(() {
      _notifications = prefs.getBool('omnivium_notifications') ?? true;
      _dataRetention = prefs.getBool('omnivium_data_retention') ?? true;
      _agentEnabled = prefs.getBool('omnivium_agent_enabled') ?? true;
      _lockEnabled = lockEnabled && hasPinHash != null && hasPinHash.isNotEmpty;
      _assistantLang = prefs.getString('omnivium_assistant_lang') ?? 'auto';
      _imageModel = prefs.getString('omnivium_image_model') ?? 'default_model';
      _sttEngine = prefs.getString('omnivium_stt_engine') ?? 'system';
      _ttsVoice = prefs.getString('omnivium_tts_voice') ?? 'Kyrin';
      _voiceMode = prefs.getString('omnivium_voice_mode') ?? 'hands_free';
    });
  }

  Future<void> _loadAppVersion() async {
    if (_appVersion.isNotEmpty) return;
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = info.version;
      });
    }
  }

  Future<void> _savePref(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is String) await prefs.setString(key, value);
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Scaffold(
        body: Semantics(
          label: localeProvider.t('go_back'),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity;
              if (velocity != null && velocity > 500) {
                widget.provider.navigation.closeSettingsAndReturnToDrawer();
              }
            },
            child: SafeArea(
              child: Column(
                children: [
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.divider(context)),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Semantics(
                            label: localeProvider.t('go_back'),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => widget.provider.navigation
                                  .closeSettingsAndReturnToDrawer(),
                              child: Icon(
                                LucideIcons.arrowLeft,
                                color: AppColors.textPrimary(context),
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            t('settings'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 48),
                      children: [
                        SectionHeader(title: t('account')),
                        Builder(
                          builder: (context) {
                            final auth = AuthService.instance;
                            if (auth.isAuthenticated) {
                              return SettingItem(
                                title: localeProvider.t('omnivium_cloud'),
                                subtitle:
                                    '${auth.currentUser?.email ?? localeProvider.t('connected')} · ${localeProvider.t('synced')}',
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        ListenableBuilder(
                          listenable: widget.provider.matrix,
                          builder: (context, _) {
                            final matrix = widget.provider.matrix;
                            if (matrix.isLoggedIn) {
                              return Column(
                                children: [
                                  SettingItem(
                                    title: 'Matrix ${t('account')}',
                                    subtitle: matrix.userId ?? t('login'),
                                  ),
                                  SettingItem(
                                    title: t('logout'),
                                    subtitle: t('logout'),
                                    textColor: AppColors.dng(context),
                                    onTap: () => matrix.logout(),
                                  ),
                                ],
                              );
                            }
                            return SettingItem(
                              title: '${t('login')} Matrix',
                              subtitle: t('login_matrix_desc'),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MatrixLoginView(
                                      provider: widget.provider,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        ListenableBuilder(
                          listenable: widget.provider.navigation,
                          builder: (context, _) {
                            return SettingItem(
                              title: t('incognito'),
                              subtitle: t('incognito_desc'),
                              rightContent: AnimatedToggle(
                                semanticLabel: t('incognito'),
                                enabled: widget.provider.navigation.isIncognito,
                                onChanged:
                                    widget.provider.navigation.setIsIncognito,
                              ),
                            );
                          },
                        ),
                        SettingItem(
                          title: t('notifications'),
                          subtitle: t('notifications_desc'),
                          rightContent: AnimatedToggle(
                            semanticLabel: t('notifications'),
                            enabled: _notifications,
                            onChanged: (v) {
                              setState(() => _notifications = v);
                              _savePref('omnivium_notifications', v);
                              try {
                                PushNotificationService.instance
                                    .requestPermissions();
                              } catch (e) {
                                AppLogger.instance.warning(
                                  'Push permission failed',
                                  error: e,
                                );
                              }
                            },
                          ),
                        ),
                        SettingItem(
                          title: t('data_retention'),
                          subtitle: t('data_retention_desc'),
                          rightContent: AnimatedToggle(
                            semanticLabel: t('data_retention'),
                            enabled: _dataRetention,
                            onChanged: (v) {
                              setState(() => _dataRetention = v);
                              _savePref('omnivium_data_retention', v);
                            },
                          ),
                        ),
                        SectionHeader(title: t('security')),
                        SettingItem(
                          title: t('clear_history'),
                          subtitle: t('clear_history_desc'),
                          textColor: AppColors.dng(context),
                          onTap: _showClearHistoryDialog,
                        ),
                        SectionHeader(title: t('assistant')),
                        SettingItem(
                          title: t('enable_assistant'),
                          subtitle: t('enable_assistant_desc'),
                          rightContent: AnimatedToggle(
                            semanticLabel: t('enable_assistant'),
                            enabled: _agentEnabled,
                            onChanged: (v) {
                              setState(() => _agentEnabled = v);
                              _savePref('omnivium_agent_enabled', v);
                              widget.provider.orchestrator.setEnabled(v);
                            },
                          ),
                        ),
                        SettingItem(
                          title: t('permissions'),
                          subtitle: t('ai_permission_management_desc'),
                          onTap: () {
                            AppNavigator.go(context, '/permissions');
                          },
                        ),
                        SettingItem(
                          title: t('assistant_language'),
                          subtitle: _assistantLangLabel,
                          onTap: _showLanguageDialog,
                        ),
                        SettingItem(
                          title: t('lock_screen'),
                          subtitle: t('lock_screen_desc'),
                          onTap: _showLockScreenDialog,
                        ),
                        SettingItem(
                          title: t('quick_commands'),
                          subtitle:
                              '${widget.provider.quickCommands.commands.length} ${t('quick_commands')}',
                          onTap: () {
                            AppNavigator.go(context, '/commands');
                          },
                        ),
                        SettingItem(
                          title: t('ai_workbench'),
                          subtitle: t('ai_workbench_desc'),
                          onTap: () {
                            AppNavigator.go(context, '/workbench');
                          },
                        ),
                        SettingItem(
                          title: t('productivity'),
                          subtitle: t('productivity_desc'),
                          onTap: () {
                            AppNavigator.go(context, '/productivity');
                          },
                        ),
                        SettingItem(
                          title: t('agent_replay'),
                          subtitle: t('agent_replay_desc'),
                          onTap: () {
                            AppNavigator.go(context, '/replay');
                          },
                        ),
                        SettingItem(
                          title: t('ai_operation_log'),
                          subtitle: t('ai_operation_log_desc'),
                          onTap: () {
                            AppNavigator.go(context, '/operation-log');
                          },
                        ),
                        SectionHeader(title: t('profile')),
                        SettingItem(
                          title: t('image_model'),
                          subtitle: _imageModel == 'default_model'
                              ? t('default_model')
                              : _imageModel,
                          onTap: _showImageModelDialog,
                        ),
                        SectionHeader(title: t('personalization')),
                        SettingItem(
                          title: t('voice_recognition'),
                          subtitle: _sttEngineLabel,
                          onTap: _showSttDialog,
                        ),
                        SettingItem(
                          title: t('narration'),
                          subtitle: _ttsVoice,
                          onTap: _showTtsDialog,
                        ),
                        SettingItem(
                          title: t('voice_mode'),
                          subtitle: _voiceModeLabel,
                          onTap: _showVoiceModeDialog,
                        ),
                        SectionHeader(title: t('help_center')),
                        SettingItem(
                          title: t('help_faq'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const FaqView(),
                              ),
                            );
                          },
                        ),
                        SectionHeader(title: t('appearance')),
                        SettingItem(
                          title: t('language'),
                          subtitle: localeProvider.currentLabel,
                          onTap: _showLanguageSettingDialog,
                        ),
                        SettingItem(
                          title: t('theme'),
                          subtitle: themeProvider.currentLabel,
                          onTap: _showThemeDialog,
                        ),
                        SettingItem(
                          title: t('accent_color'),
                          onTap: _showAccentDialog,
                        ),
                        SectionHeader(title: t('more')),
                        SettingItem(
                          title: t('storage'),
                          subtitle: t('storage_desc'),
                          onTap: () {
                            AppNavigator.go(context, '/storage');
                          },
                        ),
                        SettingItem(
                          title: t('privacy_policy'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PrivacyPolicyView(),
                              ),
                            );
                          },
                        ),
                        SettingItem(
                          title: t('terms_of_service'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TermsOfServiceView(),
                              ),
                            );
                          },
                        ),
                        SettingItem(
                          title: t('chat_wallpaper'),
                          subtitle: t('chat_wallpaper_desc'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    _WallpaperView(provider: widget.provider),
                              ),
                            );
                          },
                        ),
                        SettingItem(
                          title: t('labs'),
                          subtitle: t('labs_desc'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    _LabsView(provider: widget.provider),
                              ),
                            );
                          },
                        ),
                        SettingItem(
                          title: t('about'),
                          subtitle: 'v${_SettingsViewState._appVersion}',
                          onTap: () {
                            AppNavigator.go(context, '/about');
                          },
                        ),
                        SettingItem(
                          title: t('delete_account'),
                          subtitle: t('delete_account_desc'),
                          textColor: AppColors.dng(context),
                          onTap: _showDeleteAccountDialog,
                        ),
                      ],
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      final schema = widget.provider.remoteConfig.getUISchema(
                        'settings',
                      );
                      if (schema == null) return const SizedBox.shrink();
                      return RemoteUIEngine.render(schema, context);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _assistantLangLabel {
    switch (_assistantLang) {
      case 'auto':
        return t('auto');
      case 'zh':
        return '中文';
      case 'en':
        return 'English';
      case 'ja':
        return '日本語';
      case 'ko':
        return '한국어';
      default:
        return t('auto');
    }
  }

  String get _sttEngineLabel {
    switch (_sttEngine) {
      case 'system':
        return t('system_default');
      case 'whisper':
        return 'OpenAI Whisper';
      case 'google':
        return 'Google Speech-to-Text';
      default:
        return t('system_default');
    }
  }

  String get _voiceModeLabel {
    switch (_voiceMode) {
      case 'hands_free':
        return t('hands_free');
      case 'push_to_talk':
        return t('push_to_talk');
      case 'off':
        return t('close');
      default:
        return t('hands_free');
    }
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t('clear_history'),
          style: TextStyle(color: AppColors.textPrimary(context)),
        ),
        content: Text(
          t('clear_history_confirm'),
          style: TextStyle(
            color: AppColors.textSecondary(context),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              t('cancel'),
              style: TextStyle(color: AppColors.sec(context)),
            ),
          ),
          TextButton(
            onPressed: () {
              widget.provider.session.clearAllSessions();
              Navigator.pop(context);
            },
            child: Text(
              t('clear'),
              style: TextStyle(color: AppColors.dng(context)),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    final langs = [
      ('auto', t('auto')),
      ('zh', '中文'),
      ('en', 'English'),
      ('ja', '日本語'),
      ('ko', '한국어'),
    ];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t('assistant_language'),
          style: TextStyle(color: AppColors.textPrimary(context)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: langs.map((item) {
            final (value, label) = item;
            return ListTile(
              title: Text(
                label,
                style: TextStyle(
                  color: _assistantLang == value
                      ? AppColors.acc(context)
                      : AppColors.textPrimary(context),
                  fontSize: 14,
                ),
              ),
              trailing: _assistantLang == value
                  ? Icon(
                      LucideIcons.check,
                      color: AppColors.acc(context),
                      size: 18,
                    )
                  : null,
              onTap: () {
                setState(() => _assistantLang = value);
                _savePref('omnivium_assistant_lang', value);
                widget.provider.orchestrator.setAgentLanguage(
                  value == 'auto' ? '' : value,
                );
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showThemeDialog() {
    final themes = [
      ('dark', t('dark')),
      ('light', t('light')),
      ('system', t('system')),
    ];
    final currentKey = themeProvider.mode == ThemeMode.dark
        ? 'dark'
        : themeProvider.mode == ThemeMode.light
        ? 'light'
        : 'system';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t('theme'),
          style: TextStyle(color: AppColors.textPrimary(context)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: themes.map((item) {
            final (key, label) = item;
            return ListTile(
              title: Text(
                label,
                style: TextStyle(
                  color: currentKey == key
                      ? AppColors.acc(context)
                      : AppColors.textPrimary(context),
                  fontSize: 14,
                ),
              ),
              trailing: currentKey == key
                  ? Icon(
                      LucideIcons.check,
                      color: AppColors.acc(context),
                      size: 18,
                    )
                  : null,
              onTap: () {
                themeProvider.setModeFromString(key);
                setState(() {});
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showAccentDialog() {
    final currentKey = themeProvider.accentPreset.key;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t('accent_color'),
          style: TextStyle(color: AppColors.textPrimary(context)),
        ),
        content: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: AccentPreset.presets.map((preset) {
            final isSelected = preset.key == currentKey;
            final color = AppColors.isLightMode(context)
                ? preset.lightAccent
                : preset.darkAccent;
            return GestureDetector(
              onTap: () {
                themeProvider.setAccent(preset.key);
                setState(() {});
                Navigator.pop(context);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: AppColors.textPrimary(context),
                              width: 3,
                            )
                          : null,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            color: AppColors.bg(context),
                            size: 22,
                          )
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t('accent_${preset.key}'),
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.acc(context)
                          : AppColors.textSecondary(context),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t('delete_account'),
          style: TextStyle(color: AppColors.dng(context)),
        ),
        content: Text(
          t('confirm_delete_account'),
          style: TextStyle(
            color: AppColors.textSecondary(context),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              t('cancel'),
              style: TextStyle(color: AppColors.sec(context)),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await widget.provider.matrix.client?.deactivateAccount();
                await widget.provider.matrix.logout();
              } catch (e, stackTrace) {
                AppLogger.instance.error(
                  'App error',
                  error: e,
                  stackTrace: stackTrace,
                );
              }
            },
            child: Text(
              t('permanent_delete'),
              style: TextStyle(color: AppColors.dng(context)),
            ),
          ),
        ],
      ),
    );
  }

  void _showLockScreenDialog() {
    final pinCtrl = TextEditingController();
    bool isSetting = !_lockEnabled;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.sf(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            t('lock_screen'),
            style: TextStyle(color: AppColors.textPrimary(context)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSetting) ...[
                Text(
                  t('set_pin_desc'),
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pinCtrl,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 18,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    labelText: t('enter_pin'),
                    hintStyle: TextStyle(
                      color: AppColors.textDisabled(context),
                    ),
                    counterText: '',
                    filled: true,
                    fillColor: AppColors.sfAlt(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  t('lock_screen_desc'),
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _lockEnabled,
                  onChanged: (v) async {
                    if (!v) {
                      await AppLockService.instance.removePasscode();
                    }
                    setDialogState(() {
                      _lockEnabled = v;
                    });
                    _savePref('lock_enabled', v);
                  },
                  title: Text(
                    t('enable_lock'),
                    style: TextStyle(color: AppColors.textPrimary(context)),
                  ),
                  activeThumbColor: AppColors.acc(context),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                pinCtrl.dispose();
              },
              child: Text(
                t('cancel'),
                style: TextStyle(color: AppColors.sec(context)),
              ),
            ),
            if (isSetting)
              TextButton(
                onPressed: () async {
                  if (pinCtrl.text.length < 4) return;
                  await AppLockService.instance.setPasscode(
                    pinCtrl.text,
                    PasscodeType.pin,
                  );
                  if (!mounted) return;
                  setState(() {
                    _lockEnabled = true;
                  });
                  _savePref('lock_enabled', true);
                  pinCtrl.dispose();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text(
                  t('confirm'),
                  style: TextStyle(color: AppColors.acc(context)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showImageModelDialog() {
    final modelKeys = [
      'default_model',
      'DALL-E 3',
      'Stable Diffusion XL',
      'Midjourney',
    ];
    final modelLabels = modelKeys
        .map((k) => k == 'default_model' ? t('default_model') : k)
        .toList();
    _showChoiceDialog(
      t('image_model'),
      modelLabels,
      _imageModel == 'default_model' ? t('default_model') : _imageModel,
      (v) {
        final key = modelKeys[modelLabels.indexOf(v)];
        setState(() => _imageModel = key);
        _savePref('omnivium_image_model', key);
      },
    );
  }

  void _showSttDialog() {
    final engines = [
      ('system', t('system_default')),
      ('whisper', 'OpenAI Whisper'),
      ('google', 'Google Speech-to-Text'),
    ];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t('voice_recognition'),
          style: TextStyle(color: AppColors.textPrimary(context)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: engines.map((item) {
            final (key, label) = item;
            return ListTile(
              title: Text(
                label,
                style: TextStyle(
                  color: _sttEngine == key
                      ? AppColors.acc(context)
                      : AppColors.textPrimary(context),
                  fontSize: 14,
                ),
              ),
              trailing: _sttEngine == key
                  ? Icon(
                      LucideIcons.check,
                      color: AppColors.acc(context),
                      size: 18,
                    )
                  : null,
              onTap: () {
                setState(() => _sttEngine = key);
                _savePref('omnivium_stt_engine', key);
                try {
                  VoiceService.instance.setSttEngine(key);
                } catch (e) {
                  AppLogger.instance.warning('Set STT engine failed', error: e);
                }
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showTtsDialog() {
    final voices = [
      'Kyrin',
      'Alloy',
      'Echo',
      'Fable',
      'Onyx',
      'Nova',
      'Shimmer',
    ];
    _showChoiceDialog(t('narration'), voices, _ttsVoice, (v) {
      setState(() => _ttsVoice = v);
      _savePref('omnivium_tts_voice', v);
      try {
        VoiceService.instance.setTTSVoice(
          TTSVoice.values.firstWhere(
            (e) => e.name == v,
            orElse: () => TTSVoice.alloy,
          ),
        );
      } catch (e) {
        AppLogger.instance.warning('Set TTS voice failed', error: e);
      }
    });
  }

  void _showVoiceModeDialog() {
    final modes = [
      ('hands_free', t('hands_free')),
      ('push_to_talk', t('push_to_talk')),
      ('off', t('close')),
    ];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t('voice_mode'),
          style: TextStyle(color: AppColors.textPrimary(context)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: modes.map((item) {
            final (key, label) = item;
            return ListTile(
              title: Text(
                label,
                style: TextStyle(
                  color: _voiceMode == key
                      ? AppColors.acc(context)
                      : AppColors.textPrimary(context),
                  fontSize: 14,
                ),
              ),
              trailing: _voiceMode == key
                  ? Icon(
                      LucideIcons.check,
                      color: AppColors.acc(context),
                      size: 18,
                    )
                  : null,
              onTap: () {
                setState(() => _voiceMode = key);
                _savePref('omnivium_voice_mode', key);
                try {
                  VoiceService.instance.setVoiceModeByName(key);
                } catch (e) {
                  AppLogger.instance.warning('Set voice mode failed', error: e);
                }
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showChoiceDialog(
    String title,
    List<String> options,
    String current,
    ValueChanged<String> onSelect,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: TextStyle(color: AppColors.textPrimary(context)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map(
                (opt) => ListTile(
                  title: Text(
                    opt,
                    style: TextStyle(
                      color: current == opt
                          ? AppColors.acc(context)
                          : AppColors.textPrimary(context),
                      fontSize: 14,
                    ),
                  ),
                  trailing: current == opt
                      ? Icon(
                          LucideIcons.check,
                          color: AppColors.acc(context),
                          size: 18,
                        )
                      : null,
                  onTap: () {
                    onSelect(opt);
                    Navigator.pop(context);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showLanguageSettingDialog() {
    final langs = [
      ('zh', '中文'),
      ('en', 'English'),
      ('ja', '日本語'),
      ('ko', '한국어'),
    ];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t('language'),
          style: TextStyle(color: AppColors.textPrimary(context)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: langs.map((item) {
            final (code, label) = item;
            return ListTile(
              title: Text(
                label,
                style: TextStyle(
                  color: localeProvider.locale.languageCode == code
                      ? AppColors.acc(context)
                      : AppColors.textPrimary(context),
                  fontSize: 14,
                ),
              ),
              trailing: localeProvider.locale.languageCode == code
                  ? Icon(
                      LucideIcons.check,
                      color: AppColors.acc(context),
                      size: 18,
                    )
                  : null,
              onTap: () {
                localeProvider.setLocaleFromLabel(code);
                AnalyticsService.instance.logChangeLanguage(language: code);
                setState(() {});
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _WallpaperView extends StatefulWidget {
  final AppProvider provider;
  const _WallpaperView({required this.provider});

  @override
  State<_WallpaperView> createState() => _WallpaperViewState();
}

class _WallpaperViewState extends State<_WallpaperView> {
  String? _currentWallpaper;
  final _presets = [
    'none',
    'gradient_sunset',
    'gradient_ocean',
    'gradient_forest',
    'gradient_night',
    'gradient_rose',
    'solid_dark',
    'solid_midnight',
  ];

  @override
  void initState() {
    super.initState();
    _loadWallpaper();
  }

  void _loadWallpaper() {
    final db = DatabaseService.instance;
    final data = db.getData('chat_wallpaper');
    if (data != null) {
      setState(() => _currentWallpaper = data['id'] as String?);
    }
  }

  void _setWallpaper(String id) {
    final db = DatabaseService.instance;
    if (id == 'none') {
      db.deleteData('chat_wallpaper');
      setState(() => _currentWallpaper = null);
    } else {
      db.putData('chat_wallpaper', {'id': id});
      setState(() => _currentWallpaper = id);
    }
  }

  Future<void> _pickCustomImage() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1920,
      imageQuality: 80,
    );
    if (xfile == null) return;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final wallpaperDir = Directory('${appDir.path}/wallpapers');
      if (!await wallpaperDir.exists()) {
        await wallpaperDir.create(recursive: true);
      }
      final ext = xfile.path.split('.').lastOrNull ?? 'jpg';
      final savedPath = '${wallpaperDir.path}/custom_wallpaper.$ext';
      await File(xfile.path).copy(savedPath);
      final db = DatabaseService.instance;
      db.putData('chat_wallpaper', {'id': 'custom', 'path': savedPath});
      if (!mounted) return;
      setState(() => _currentWallpaper = 'custom');
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        'Save wallpaper failed',
        error: e,
        stackTrace: stackTrace,
      );
      final db = DatabaseService.instance;
      db.putData('chat_wallpaper', {'id': 'custom', 'path': xfile.path});
      if (!mounted) return;
      setState(() => _currentWallpaper = 'custom');
    }
  }

  BoxDecoration _buildPresetDecoration(String id) {
    switch (id) {
      case 'gradient_sunset':
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: WallpaperPresets.warm,
          ),
        );
      case 'gradient_ocean':
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: WallpaperPresets.ocean,
          ),
        );
      case 'gradient_forest':
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: WallpaperPresets.forest,
          ),
        );
      case 'gradient_night':
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: WallpaperPresets.dark,
          ),
        );
      case 'gradient_rose':
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: WallpaperPresets.pink,
          ),
        );
      case 'solid_dark':
        return const BoxDecoration(color: WallpaperPresets.darkBg);
      case 'solid_midnight':
        return const BoxDecoration(color: WallpaperPresets.darkBlueBg);
      default:
        return const BoxDecoration(color: Colors.transparent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = localeProvider.t;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: AppColors.sec(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t('chat_wallpaper'),
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionHeader(title: t('preset_wallpapers')),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: _presets.map((id) {
              final isSelected =
                  _currentWallpaper == id ||
                  (id == 'none' && _currentWallpaper == null);
              return GestureDetector(
                onTap: () => _setWallpaper(id),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: AppColors.acc(context), width: 3)
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      decoration: id == 'none'
                          ? BoxDecoration(
                              color: AppColors.bg(context),
                              border: Border.all(
                                color: AppColors.divider(context),
                              ),
                            )
                          : _buildPresetDecoration(id),
                      child: id == 'none'
                          ? Center(
                              child: Icon(
                                LucideIcons.x,
                                size: 20,
                                color: AppColors.textDisabled(context),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SectionHeader(title: t('custom_wallpaper')),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickCustomImage,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.sf(context),
                borderRadius: BorderRadius.circular(12),
                border: _currentWallpaper == 'custom'
                    ? Border.all(color: AppColors.acc(context), width: 3)
                    : Border.all(color: AppColors.divider(context)),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.imagePlus,
                      size: 20,
                      color: AppColors.sec(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t('choose_from_gallery'),
                      style: TextStyle(
                        color: AppColors.sec(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _LabsView extends StatefulWidget {
  final AppProvider provider;
  const _LabsView({required this.provider});

  @override
  State<_LabsView> createState() => _LabsViewState();
}

class _LabsViewState extends State<_LabsView> {
  Map<String, dynamic> _config = {};
  Map<String, Map<String, dynamic>> _uiSchemas = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final svc = RemoteConfigService.instance;
    await svc.fetch();
    if (mounted) {
      setState(() {
        _config = svc.config;
        _uiSchemas = svc.uiSchemas;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = localeProvider.t;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: AppColors.sec(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t('labs'),
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.acc(context)),
            )
          : RefreshIndicator(
              onRefresh: _loadConfig,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SectionHeader(title: t('feature_flags')),
                  const SizedBox(height: 8),
                  ..._buildFeatureFlags(),
                  const SizedBox(height: 24),
                  SectionHeader(title: t('remote_config')),
                  const SizedBox(height: 8),
                  ..._buildConfigValues(),
                  if (_uiSchemas.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    SectionHeader(title: t('ui_schemas')),
                    const SizedBox(height: 8),
                    ..._buildUISchemas(),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildFeatureFlags() {
    final features = _config['features'] as Map<String, dynamic>? ?? {};
    if (features.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            localeProvider.t('no_feature_flags'),
            style: TextStyle(
              color: AppColors.textTertiary(context),
              fontSize: 14,
            ),
          ),
        ),
      ];
    }
    return features.entries.map((entry) {
      final enabled = entry.value as bool? ?? false;
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.sf(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                entry.key,
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: enabled
                    ? AppColors.ok(context).withValues(alpha: 0.15)
                    : AppColors.textDisabled(context).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                enabled
                    ? localeProvider.t('enabled')
                    : localeProvider.t('disabled'),
                style: TextStyle(
                  color: enabled
                      ? AppColors.ok(context)
                      : AppColors.textDisabled(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildConfigValues() {
    final displayConfig = Map<String, dynamic>.from(_config)
      ..remove('features');
    if (displayConfig.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            localeProvider.t('no_remote_config'),
            style: TextStyle(
              color: AppColors.textTertiary(context),
              fontSize: 14,
            ),
          ),
        ),
      ];
    }
    return displayConfig.entries.map((entry) {
      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.sf(context),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                entry.key,
                style: TextStyle(
                  color: AppColors.textSecondary(context),
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              '${entry.value}',
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildUISchemas() {
    return _uiSchemas.keys.map((screenId) {
      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.sf(context),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.layout, size: 16, color: AppColors.acc(context)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                screenId,
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _previewSchema(screenId),
              child: Icon(
                LucideIcons.eye,
                size: 16,
                color: AppColors.sec(context),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  void _previewSchema(String screenId) {
    final schema = _uiSchemas[screenId];
    if (schema == null) return;
    final widget = RemoteUIEngine.render(schema, context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          child: widget,
        ),
      ),
    );
  }
}
