import '../../core/app_logger.dart';
import '../../core/app_navigator.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../theme/locale_provider.dart';
import '../../main.dart';
import '../../core/app_provider.dart';
import '../../core/remote_ui_engine.dart';
import '../../core/auth_service.dart';
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
  String _agentPermission = 'confirm';
  String _assistantLang = 'auto';
  String _imageModel = 'Default';
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
    setState(() {
      _notifications = prefs.getBool('omnivium_notifications') ?? true;
      _dataRetention = prefs.getBool('omnivium_data_retention') ?? true;
      _agentEnabled = prefs.getBool('omnivium_agent_enabled') ?? true;
      _lockEnabled = prefs.getBool('lock_enabled') ?? false;
      _agentPermission =
          prefs.getString('omnivium_agent_permission') ?? 'confirm';
      _assistantLang = prefs.getString('omnivium_assistant_lang') ?? 'auto';
      _imageModel = prefs.getString('omnivium_image_model') ?? 'Default';
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
              if (details.primaryVelocity != null &&
                  details.primaryVelocity! > 500) {
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
                            enabled: _notifications,
                            onChanged: (v) {
                              setState(() => _notifications = v);
                              _savePref('omnivium_notifications', v);
                              try {
                                PushNotificationService.instance
                                    .requestPermissions();
                              } catch (_) {}
                            },
                          ),
                        ),
                        SettingItem(
                          title: t('data_retention'),
                          subtitle: t('data_retention_desc'),
                          rightContent: AnimatedToggle(
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
                          subtitle: _imageModel,
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
                      ? AppColors.accent
                      : AppColors.textPrimary(context),
                  fontSize: 14,
                ),
              ),
              trailing: _assistantLang == value
                  ? Icon(LucideIcons.check, color: AppColors.accent, size: 18)
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
                      ? AppColors.accent
                      : AppColors.textPrimary(context),
                  fontSize: 14,
                ),
              ),
              trailing: currentKey == key
                  ? Icon(LucideIcons.check, color: AppColors.accent, size: 18)
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
                  'Operation failed',
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
                  onChanged: (v) {
                    setDialogState(() {
                      _lockEnabled = v;
                    });
                    _savePref('lock_enabled', v);
                  },
                  title: Text(
                    t('enable_lock'),
                    style: TextStyle(color: AppColors.textPrimary(context)),
                  ),
                  activeThumbColor: AppColors.accent,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                t('cancel'),
                style: TextStyle(color: AppColors.sec(context)),
              ),
            ),
            if (isSetting)
              TextButton(
                onPressed: () async {
                  if (pinCtrl.text.length < 4) return;
                  final salt = DateTime.now().millisecondsSinceEpoch.toString();
                  final pinHash = sha256
                      .convert(utf8.encode('$salt${pinCtrl.text}'))
                      .toString();
                  await _secure.write('omnivium_lock_pin_hash', pinHash);
                  await _secure.write('omnivium_lock_pin_salt', salt);
                  await _secure.delete('omnivium_lock_pin');
                  if (!mounted) return;
                  setState(() {
                    _lockEnabled = true;
                  });
                  _savePref('lock_enabled', true);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text(
                  t('confirm'),
                  style: TextStyle(color: AppColors.accent),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showImageModelDialog() {
    final models = ['Default', 'DALL-E 3', 'Stable Diffusion XL', 'Midjourney'];
    _showChoiceDialog(
      t('image_model'),
      models,
      _imageModel,
      (v) => setState(() => _imageModel = v),
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
                      ? AppColors.accent
                      : AppColors.textPrimary(context),
                  fontSize: 14,
                ),
              ),
              trailing: _sttEngine == key
                  ? Icon(LucideIcons.check, color: AppColors.accent, size: 18)
                  : null,
              onTap: () {
                setState(() => _sttEngine = key);
                _savePref('omnivium_stt_engine', key);
                try {
                  VoiceService.instance.setSttEngine(key);
                } catch (_) {}
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
      } catch (_) {}
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
                      ? AppColors.accent
                      : AppColors.textPrimary(context),
                  fontSize: 14,
                ),
              ),
              trailing: _voiceMode == key
                  ? Icon(LucideIcons.check, color: AppColors.accent, size: 18)
                  : null,
              onTap: () {
                setState(() => _voiceMode = key);
                _savePref('omnivium_voice_mode', key);
                try {
                  VoiceService.instance.setVoiceModeByName(key);
                } catch (_) {}
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
                          ? AppColors.accent
                          : AppColors.textPrimary(context),
                      fontSize: 14,
                    ),
                  ),
                  trailing: current == opt
                      ? Icon(
                          LucideIcons.check,
                          color: AppColors.accent,
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
                      ? AppColors.accent
                      : AppColors.textPrimary(context),
                  fontSize: 14,
                ),
              ),
              trailing: localeProvider.locale.languageCode == code
                  ? Icon(LucideIcons.check, color: AppColors.accent, size: 18)
                  : null,
              onTap: () {
                localeProvider.setLocaleFromLabel(code);
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
