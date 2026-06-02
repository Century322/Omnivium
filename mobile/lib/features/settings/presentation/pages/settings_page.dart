import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/app_logger.dart';
import '../../../../core/app_navigator.dart';
import '../../../../core/analytics_service.dart';
import '../../../../core/auth_service.dart';
import '../../../../core/app_lock_service.dart';
import '../../../../core/voice_service.dart';
import '../../../../core/di/app_di.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../presentation/theme/theme_cubit.dart';
import '../../domain/settings_repository.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/locale_cubit.dart';
import '../../../../presentation/widgets/section_header.dart';
import '../../../../presentation/widgets/setting_item.dart';
import '../../../../presentation/widgets/animated_toggle.dart';

class SettingsPage extends StatelessWidget {
  final VoidCallback? onClose;

  const SettingsPage({super.key, this.onClose});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SettingsBloc>()..add(const SettingsLoadRequested()),
      child: _SettingsContent(onClose: onClose));
  }
}

class _SettingsContent extends StatefulWidget {
  final VoidCallback? onClose;

  const _SettingsContent({this.onClose});

  @override
  State<_SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<_SettingsContent>
    with SingleTickerProviderStateMixin {
  static String _appVersion = '';
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this);
    _slideAnimation = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _slideController.forward();
  }

  Future<void> _loadAppVersion() async {
    if (_appVersion.isNotEmpty) return;
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _appVersion = info.version);
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  String t(String key) => localeProvider.t(key);

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
                widget.onClose?.call();
              }
            },
            child: SafeArea(
              child: Column(
                children: [
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.divider(context)))),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Semantics(
                            label: localeProvider.t('go_back'),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => widget.onClose?.call(),
                              child: Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary(context), size: 24))),
                          const SizedBox(width: 16),
                          Text(t('settings'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                        ]))),
                  Expanded(
                    child: BlocBuilder<SettingsBloc, SettingsState>(
                      builder: (context, state) {
                        if (state is SettingsLoading) {
                          return Center(child: CircularProgressIndicator(color: AppColors.acc(context)));
                        }
                        if (state is SettingsError) {
                          return Center(
                            child: Text(state.message, style: TextStyle(color: AppColors.dng(context))));
                        }
                        final settings = state is SettingsLoaded ? state.settings : const AppSettings();
                        return _buildSettingsList(context, settings);
                      })),
                ]))))));
  }

  Widget _buildSettingsList(BuildContext context, AppSettings settings) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 48),
      children: [
        SectionHeader(title: t('account')),
        Builder(
          builder: (context) {
            final auth = getIt<AuthService>();
            if (auth.isAuthenticated) {
              return SettingItem(
                title: localeProvider.t('omnivium_cloud'),
                subtitle: '${auth.currentUser?.email ?? localeProvider.t('connected')} · ${localeProvider.t('synced')}');
            }
            return const SizedBox.shrink();
          }),
        SettingItem(
          title: t('notifications'),
          subtitle: t('notifications_desc'),
          rightContent: AnimatedToggle(
            semanticLabel: t('notifications'),
            enabled: settings.notificationsEnabled,
            onChanged: (v) => context.read<SettingsBloc>().add(SettingsNotificationsChanged(v)))),
        SettingItem(
          title: t('data_retention'),
          subtitle: t('data_retention_desc'),
          rightContent: AnimatedToggle(
            semanticLabel: t('data_retention'),
            enabled: settings.dataRetention,
            onChanged: (v) => context.read<SettingsBloc>().add(SettingsDataRetentionChanged(v)))),
        SectionHeader(title: t('security')),
        SettingItem(
          title: t('clear_history'),
          subtitle: t('clear_history_desc'),
          textColor: AppColors.dng(context),
          onTap: _showClearHistoryDialog),
        SectionHeader(title: t('assistant')),
        SettingItem(
          title: t('enable_assistant'),
          subtitle: t('enable_assistant_desc'),
          rightContent: AnimatedToggle(
            semanticLabel: t('enable_assistant'),
            enabled: settings.agentEnabled,
            onChanged: (v) => context.read<SettingsBloc>().add(SettingsAgentEnabledChanged(v)))),
        SettingItem(
          title: t('permissions'),
          subtitle: t('ai_permission_management_desc'),
          onTap: () => AppNavigator.go<void>(context, '/permissions')),
        SettingItem(
          title: t('assistant_language'),
          subtitle: _assistantLangLabel(settings.assistantLang),
          onTap: () => _showLanguageDialog(settings)),
        SettingItem(
          title: t('lock_screen'),
          subtitle: t('lock_screen_desc'),
          onTap: () => _showLockScreenDialog(settings)),
        SettingItem(
          title: t('quick_commands'),
          subtitle: t('quick_commands'),
          onTap: () => AppNavigator.go<void>(context, '/commands')),
        SettingItem(
          title: t('ai_workbench'),
          subtitle: t('ai_workbench_desc'),
          onTap: () => AppNavigator.go<void>(context, '/workbench')),
        SettingItem(
          title: t('productivity'),
          subtitle: t('productivity_desc'),
          onTap: () => AppNavigator.go<void>(context, '/productivity')),
        SettingItem(
          title: t('agent_replay'),
          subtitle: t('agent_replay_desc'),
          onTap: () => AppNavigator.go<void>(context, '/replay')),
        SettingItem(
          title: t('ai_operation_log'),
          subtitle: t('ai_operation_log_desc'),
          onTap: () => AppNavigator.go<void>(context, '/operation-log')),
        SectionHeader(title: t('profile')),
        SettingItem(
          title: t('image_model'),
          subtitle: settings.imageModel == 'default_model' ? t('default_model') : settings.imageModel,
          onTap: () => _showImageModelDialog(settings)),
        SectionHeader(title: t('personalization')),
        SettingItem(
          title: t('voice_recognition'),
          subtitle: _sttEngineLabel(settings.sttEngine),
          onTap: () => _showSttDialog(settings)),
        SettingItem(
          title: t('narration'),
          subtitle: settings.ttsVoice,
          onTap: () => _showTtsDialog(settings)),
        SettingItem(
          title: t('voice_mode'),
          subtitle: _voiceModeLabel(settings.voiceMode),
          onTap: () => _showVoiceModeDialog(settings)),
        SectionHeader(title: t('help_center')),
        SettingItem(
          title: t('help_faq'),
          onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const _FaqPlaceholder()))),
        SectionHeader(title: t('appearance')),
        SettingItem(
          title: t('language'),
          subtitle: localeProvider.currentLabel,
          onTap: _showLanguageSettingDialog),
        SettingItem(
          title: t('theme'),
          subtitle: getIt<ThemeCubit>().state.currentLabel,
          onTap: _showThemeDialog),
        SettingItem(
          title: t('accent_color'),
          onTap: _showAccentDialog),
        SectionHeader(title: t('more')),
        SettingItem(
          title: t('storage'),
          subtitle: t('storage_desc'),
          onTap: () => AppNavigator.go<void>(context, '/storage')),
        SettingItem(
          title: t('privacy_policy'),
          onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const _PrivacyPlaceholder()))),
        SettingItem(
          title: t('terms_of_service'),
          onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const _TermsPlaceholder()))),
        SettingItem(
          title: t('chat_wallpaper'),
          subtitle: t('chat_wallpaper_desc'),
          onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const _WallpaperPlaceholder()))),
        SettingItem(
          title: t('labs'),
          subtitle: t('labs_desc'),
          onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const _LabsPlaceholder()))),
        SettingItem(
          title: t('about'),
          subtitle: 'v$_appVersion',
          onTap: () => AppNavigator.go<void>(context, '/about')),
        SettingItem(
          title: t('delete_account'),
          subtitle: t('delete_account_desc'),
          textColor: AppColors.dng(context),
          onTap: _showDeleteAccountDialog),
      ]);
  }

  String _assistantLangLabel(String lang) {
    switch (lang) {
      case 'auto': return t('auto');
      case 'zh': return '中文';
      case 'en': return 'English';
      case 'ja': return '日本語';
      case 'ko': return '한국어';
      default: return t('auto');
    }
  }

  String _sttEngineLabel(String engine) {
    switch (engine) {
      case 'system': return t('system_default');
      case 'whisper': return 'OpenAI Whisper';
      case 'google': return 'Google Speech-to-Text';
      default: return t('system_default');
    }
  }

  String _voiceModeLabel(String mode) {
    switch (mode) {
      case 'hands_free': return t('hands_free');
      case 'push_to_talk': return t('push_to_talk');
      case 'off': return t('close');
      default: return t('hands_free');
    }
  }

  void _showClearHistoryDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(t('clear_history'), style: TextStyle(color: AppColors.textPrimary(context))),
        content: Text(t('clear_history_confirm'), style: TextStyle(color: AppColors.textSecondary(context), fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel'), style: TextStyle(color: AppColors.sec(context)))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(t('clear'), style: TextStyle(color: AppColors.dng(context)))),
        ]));
  }

  void _showLanguageDialog(AppSettings settings) {
    final langs = [('auto', t('auto')), ('zh', '中文'), ('en', 'English'), ('ja', '日本語'), ('ko', '한국어')];
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(t('assistant_language'), style: TextStyle(color: AppColors.textPrimary(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: langs.map((item) {
            final (value, label) = item;
            return ListTile(
              title: Text(label, style: TextStyle(
                color: settings.assistantLang == value ? AppColors.acc(context) : AppColors.textPrimary(context),
                fontSize: 14)),
              trailing: settings.assistantLang == value ? Icon(LucideIcons.check, color: AppColors.acc(context), size: 18) : null,
              onTap: () {
                context.read<SettingsBloc>().add(SettingsAssistantLangChanged(value));
                Navigator.pop(context);
              });
          }).toList())));
  }

  void _showLockScreenDialog(AppSettings settings) {
    final pinCtrl = TextEditingController();
    bool isSetting = !settings.lockEnabled;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.sf(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(t('lock_screen'), style: TextStyle(color: AppColors.textPrimary(context))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSetting) ...[
                Text(t('set_pin_desc'), style: TextStyle(color: AppColors.textSecondary(context), fontSize: 14)),
                const SizedBox(height: 12),
                TextField(
                  controller: pinCtrl,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: TextStyle(color: AppColors.textPrimary(context), fontSize: 18, letterSpacing: 8),
                  decoration: InputDecoration(
                    labelText: t('enter_pin'),
                    counterText: '',
                    filled: true,
                    fillColor: AppColors.sfAlt(context),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
              ] else ...[
                Text(t('lock_screen_desc'), style: TextStyle(color: AppColors.textSecondary(context), fontSize: 14)),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: settings.lockEnabled,
                  onChanged: (v) async {
                    if (!v) await getIt<AppLockService>().removePasscode();
                    context.read<SettingsBloc>().add(SettingsLockEnabledChanged(v));
                    setDialogState(() {});
                  },
                  title: Text(t('enable_lock'), style: TextStyle(color: AppColors.textPrimary(context))),
                  activeThumbColor: AppColors.acc(context)),
              ],
            ]),
          actions: [
            TextButton(
              onPressed: () { Navigator.pop(ctx); pinCtrl.dispose(); },
              child: Text(t('cancel'), style: TextStyle(color: AppColors.sec(context)))),
            if (isSetting)
              TextButton(
                onPressed: () async {
                  if (pinCtrl.text.length < 4) return;
                  await getIt<AppLockService>().setPasscode(pinCtrl.text, PasscodeType.pin);
                  if (!mounted) return;
                  context.read<SettingsBloc>().add(const SettingsLockEnabledChanged(true));
                  pinCtrl.dispose();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text(t('confirm'), style: TextStyle(color: AppColors.acc(context)))),
          ])));
  }

  void _showImageModelDialog(AppSettings settings) {
    final modelKeys = ['default_model', 'DALL-E 3', 'Stable Diffusion XL', 'Midjourney'];
    final modelLabels = modelKeys.map((k) => k == 'default_model' ? t('default_model') : k).toList();
    _showChoiceDialog(
      t('image_model'),
      modelLabels,
      settings.imageModel == 'default_model' ? t('default_model') : settings.imageModel,
      (v) {
        final key = modelKeys[modelLabels.indexOf(v)];
        context.read<SettingsBloc>().add(SettingsImageModelChanged(key));
      });
  }

  void _showSttDialog(AppSettings settings) {
    final engines = [('system', t('system_default')), ('whisper', 'OpenAI Whisper'), ('google', 'Google Speech-to-Text')];
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(t('voice_recognition'), style: TextStyle(color: AppColors.textPrimary(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: engines.map((item) {
            final (key, label) = item;
            return ListTile(
              title: Text(label, style: TextStyle(
                color: settings.sttEngine == key ? AppColors.acc(context) : AppColors.textPrimary(context), fontSize: 14)),
              trailing: settings.sttEngine == key ? Icon(LucideIcons.check, color: AppColors.acc(context), size: 18) : null,
              onTap: () {
                context.read<SettingsBloc>().add(SettingsSttEngineChanged(key));
                try { getIt<VoiceService>().setSttEngine(key); } catch (e) { AppLogger.instance.warning('Set STT engine failed', error: e); }
                Navigator.pop(context);
              });
          }).toList())));
  }

  void _showTtsDialog(AppSettings settings) {
    final voices = ['Kyrin', 'Alloy', 'Echo', 'Fable', 'Onyx', 'Nova', 'Shimmer'];
    _showChoiceDialog(t('narration'), voices, settings.ttsVoice, (v) {
      context.read<SettingsBloc>().add(SettingsTtsVoiceChanged(v));
      try {
        getIt<VoiceService>().setTTSVoice(TTSVoice.values.firstWhere((e) => e.name == v, orElse: () => TTSVoice.alloy));
      } catch (e) { AppLogger.instance.warning('Set TTS voice failed', error: e); }
    });
  }

  void _showVoiceModeDialog(AppSettings settings) {
    final modes = [('hands_free', t('hands_free')), ('push_to_talk', t('push_to_talk')), ('off', t('close'))];
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(t('voice_mode'), style: TextStyle(color: AppColors.textPrimary(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: modes.map((item) {
            final (key, label) = item;
            return ListTile(
              title: Text(label, style: TextStyle(
                color: settings.voiceMode == key ? AppColors.acc(context) : AppColors.textPrimary(context), fontSize: 14)),
              trailing: settings.voiceMode == key ? Icon(LucideIcons.check, color: AppColors.acc(context), size: 18) : null,
              onTap: () {
                context.read<SettingsBloc>().add(SettingsVoiceModeChanged(key));
                try { getIt<VoiceService>().setVoiceModeByName(key); } catch (e) { AppLogger.instance.warning('Set voice mode failed', error: e); }
                Navigator.pop(context);
              });
          }).toList())));
  }

  void _showChoiceDialog(String title, List<String> options, String current, ValueChanged<String> onSelect) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: TextStyle(color: AppColors.textPrimary(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) => ListTile(
            title: Text(opt, style: TextStyle(
              color: current == opt ? AppColors.acc(context) : AppColors.textPrimary(context), fontSize: 14)),
            trailing: current == opt ? Icon(LucideIcons.check, color: AppColors.acc(context), size: 18) : null,
            onTap: () { onSelect(opt); Navigator.pop(context); })).toList())));
  }

  void _showThemeDialog() {
    final themes = [('dark', t('dark')), ('light', t('light')), ('system', t('system'))];
    final currentKey = getIt<ThemeCubit>().state.mode == ThemeMode.dark ? 'dark' : getIt<ThemeCubit>().state.mode == ThemeMode.light ? 'light' : 'system';
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(t('theme'), style: TextStyle(color: AppColors.textPrimary(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: themes.map((item) {
            final (key, label) = item;
            return ListTile(
              title: Text(label, style: TextStyle(
                color: currentKey == key ? AppColors.acc(context) : AppColors.textPrimary(context), fontSize: 14)),
              trailing: currentKey == key ? Icon(LucideIcons.check, color: AppColors.acc(context), size: 18) : null,
              onTap: () {
                context.read<SettingsBloc>().add(SettingsThemeChanged(key));
                getIt<ThemeCubit>().setModeFromString(key);
                setState(() {});
                Navigator.pop(context);
              });
          }).toList())));
  }

  void _showAccentDialog() {
    final currentKey = getIt<ThemeCubit>().state.accentPreset.key;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(t('accent_color'), style: TextStyle(color: AppColors.textPrimary(context))),
        content: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: AccentPreset.presets.map((preset) {
            final isSelected = preset.key == currentKey;
            final color = AppColors.isLightMode(context) ? preset.lightAccent : preset.darkAccent;
            return GestureDetector(
              onTap: () {
                getIt<ThemeCubit>().setAccent(preset.key);
                setState(() {});
                Navigator.pop(context);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: AppColors.textPrimary(context), width: 3) : null),
                    child: isSelected ? Icon(Icons.check, color: AppColors.bg(context), size: 22) : null),
                  const SizedBox(height: 4),
                  Text(t('accent_${preset.key}'), style: TextStyle(
                    color: isSelected ? AppColors.acc(context) : AppColors.textSecondary(context), fontSize: 11)),
                ]));
          }).toList())));
  }

  void _showLanguageSettingDialog() {
    final langs = [('zh', '中文'), ('en', 'English'), ('ja', '日本語'), ('ko', '한국어')];
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(t('language'), style: TextStyle(color: AppColors.textPrimary(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: langs.map((item) {
            final (code, label) = item;
            return ListTile(
              title: Text(label, style: TextStyle(
                color: localeProvider.locale.languageCode == code ? AppColors.acc(context) : AppColors.textPrimary(context), fontSize: 14)),
              trailing: localeProvider.locale.languageCode == code ? Icon(LucideIcons.check, color: AppColors.acc(context), size: 18) : null,
              onTap: () {
                context.read<SettingsBloc>().add(SettingsLocaleChanged(code));
                localeProvider.setLocaleFromLabel(code);
                getIt<AnalyticsService>().logChangeLanguage(language: code);
                setState(() {});
                Navigator.pop(context);
              });
          }).toList())));
  }

  void _showDeleteAccountDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(t('delete_account'), style: TextStyle(color: AppColors.dng(context))),
        content: Text(t('confirm_delete_account'), style: TextStyle(color: AppColors.textSecondary(context), fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t('cancel'), style: TextStyle(color: AppColors.sec(context)))),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('permanent_delete'), style: TextStyle(color: AppColors.dng(context)))),
        ]));
  }
}

class _FaqPlaceholder extends StatelessWidget {
  const _FaqPlaceholder();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(localeProvider.t('help_faq'))),
    body: const Center(child: Text('FAQ')));
}

class _PrivacyPlaceholder extends StatelessWidget {
  const _PrivacyPlaceholder();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(localeProvider.t('privacy_policy'))),
    body: const Center(child: Text('Privacy Policy')));
}

class _TermsPlaceholder extends StatelessWidget {
  const _TermsPlaceholder();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(localeProvider.t('terms_of_service'))),
    body: const Center(child: Text('Terms of Service')));
}

class _WallpaperPlaceholder extends StatelessWidget {
  const _WallpaperPlaceholder();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(localeProvider.t('chat_wallpaper'))),
    body: const Center(child: Text('Wallpaper')));
}

class _LabsPlaceholder extends StatelessWidget {
  const _LabsPlaceholder();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(localeProvider.t('labs'))),
    body: const Center(child: Text('Labs')));
}
