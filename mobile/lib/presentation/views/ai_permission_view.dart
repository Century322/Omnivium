import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/runtime/sdk/omnivium_sdk.dart';
import '../../core/runtime/capability_router.dart';
import '../../core/runtime/governance/policy_engine.dart';
import '../theme/app_colors.dart';
import '../theme/locale_provider.dart';

class AiPermissionView extends StatefulWidget {
  const AiPermissionView({super.key});

  @override
  State<AiPermissionView> createState() => _AiPermissionViewState();
}

class _AiPermissionViewState extends State<AiPermissionView> {
  String _globalMode = 'confirm';
  Map<String, String> _capabilityOverrides = {};
  List<CapabilityBinding> _bindings = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _loadGlobalMode();
    _loadBindings();
    _loadOverrides();
  }

  void _loadGlobalMode() {
    SharedPreferences.getInstance().then((prefs) {
      if (!mounted) return;
      final mode = prefs.getString('omnivium_agent_permission') ?? 'confirm';
      _syncGlobalModeToPolicyEngine(mode);
      setState(() {
        _globalMode = mode;
      });
    });
  }

  void _loadBindings() {
    final sdk = OmniviumSDK.instance;
    if (!sdk.isInitialized) return;
    setState(() {
      _bindings = sdk.container.capabilityRouter.allBindings;
    });
  }

  void _loadOverrides() {
    SharedPreferences.getInstance().then((prefs) {
      if (!mounted) return;
      final keys = prefs.getKeys().where((k) => k.startsWith('omnivium_perm_'));
      final overrides = <String, String>{};
      for (final key in keys) {
        final capId = key.replaceFirst('omnivium_perm_', '');
        final mode = prefs.getString(key) ?? 'confirm';
        overrides[capId] = mode;
        _syncCapabilityOverrideToPolicyEngine(capId, mode);
      }
      setState(() {
        _capabilityOverrides = overrides;
      });
    });
  }

  String _getEffectivePermission(CapabilityBinding binding) {
    final override = _capabilityOverrides[binding.capabilityId];
    if (override != null) return override;
    return _globalMode;
  }

  Future<void> _setGlobalMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('omnivium_agent_permission', mode);
    _syncGlobalModeToPolicyEngine(mode);
    if (!mounted) return;
    setState(() => _globalMode = mode);
  }

  Future<void> _setCapabilityPermission(String capId, String mode) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'omnivium_perm_$capId';
    if (mode == _globalMode) {
      await prefs.remove(key);
      _capabilityOverrides.remove(capId);
    } else {
      await prefs.setString(key, mode);
      _capabilityOverrides[capId] = mode;
    }
    _syncCapabilityOverrideToPolicyEngine(capId, mode);
    if (!mounted) return;
    setState(() {});
  }

  void _syncGlobalModeToPolicyEngine(String mode) {
    final sdk = OmniviumSDK.instance;
    if (!sdk.isInitialized) return;
    final engine = sdk.container.policyEngine;
    engine.removeRule('user-global-permission');
    if (mode == 'deny') {
      engine.addRule(
        PolicyRule(
          id: 'user-global-permission',
          description: 'User denied all capability invocations',
          effect: PolicyEffect.deny,
          callerPattern: 'agent.*',
          targetPattern: '*',
          priority: 300,
        ),
      );
    } else if (mode == 'auto') {
      engine.addRule(
        PolicyRule(
          id: 'user-global-permission',
          description: 'User allowed all capability invocations',
          effect: PolicyEffect.allow,
          callerPattern: 'agent.*',
          targetPattern: '*',
          priority: 300,
        ),
      );
    }
  }

  void _syncCapabilityOverrideToPolicyEngine(String capId, String mode) {
    final sdk = OmniviumSDK.instance;
    if (!sdk.isInitialized) return;
    final engine = sdk.container.policyEngine;
    final ruleId = 'user-perm-$capId';
    engine.removeRule(ruleId);
    if (mode == 'deny') {
      engine.addRule(
        PolicyRule(
          id: ruleId,
          description: 'User denied: $capId',
          effect: PolicyEffect.deny,
          callerPattern: 'agent.*',
          targetPattern: capId,
          priority: 350,
        ),
      );
    } else if (mode == 'auto') {
      engine.addRule(
        PolicyRule(
          id: ruleId,
          description: 'User auto-allowed: $capId',
          effect: PolicyEffect.allow,
          callerPattern: 'agent.*',
          targetPattern: capId,
          priority: 350,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = localeProvider.t;
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: t('back'),
          icon: Icon(
            LucideIcons.chevronLeft,
            color: AppColors.textPrimary(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t('ai_permission_management'),
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildGlobalModeSection(context),
          const SizedBox(height: 16),
          if (_bindings.isNotEmpty) _buildCapabilityList(context),
        ],
      ),
    );
  }

  Widget _buildGlobalModeSection(BuildContext context) {
    final t = localeProvider.t;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.shield, size: 18, color: AppColors.acc(context)),
              const SizedBox(width: 8),
              Text(
                t('global_permission_mode'),
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            t('global_permission_desc'),
            style: TextStyle(
              color: AppColors.textTertiary(context),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildModeChip(
                  context,
                  'auto',
                  LucideIcons.zap,
                  AppColors.ok(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildModeChip(
                  context,
                  'confirm',
                  LucideIcons.shieldQuestion,
                  AppColors.warn(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildModeChip(
                  context,
                  'deny',
                  LucideIcons.shieldOff,
                  AppColors.dng(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(
    BuildContext context,
    String mode,
    IconData icon,
    Color color,
  ) {
    final selected = _globalMode == mode;
    final t = localeProvider.t;
    return GestureDetector(
      onTap: () => _setGlobalMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.12)
              : AppColors.sfAlt(context),
          borderRadius: BorderRadius.circular(10),
          border: selected
              ? Border.all(color: color.withValues(alpha: 0.4))
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? color : AppColors.iconGray(context),
            ),
            const SizedBox(height: 4),
            Text(
              t('permission_$mode'),
              style: TextStyle(
                color: selected ? color : AppColors.textSecondary(context),
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapabilityList(BuildContext context) {
    final t = localeProvider.t;
    final autoCaps = _bindings
        .where((b) => _getEffectivePermission(b) == 'auto')
        .toList();
    final confirmCaps = _bindings
        .where((b) => _getEffectivePermission(b) == 'confirm')
        .toList();
    final denyCaps = _bindings
        .where((b) => _getEffectivePermission(b) == 'deny')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (autoCaps.isNotEmpty) ...[
          _buildSectionHeader(
            context,
            LucideIcons.zap,
            t('auto_execute'),
            AppColors.ok(context),
            autoCaps.length,
          ),
          ...autoCaps.map((b) => _buildCapabilityTile(context, b)),
        ],
        if (confirmCaps.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildSectionHeader(
            context,
            LucideIcons.shieldQuestion,
            t('need_confirm'),
            AppColors.warn(context),
            confirmCaps.length,
          ),
          ...confirmCaps.map((b) => _buildCapabilityTile(context, b)),
        ],
        if (denyCaps.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildSectionHeader(
            context,
            LucideIcons.shieldOff,
            t('always_deny'),
            AppColors.dng(context),
            denyCaps.length,
          ),
          ...denyCaps.map((b) => _buildCapabilityTile(context, b)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    int count,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilityTile(BuildContext context, CapabilityBinding binding) {
    final isOverridden = _capabilityOverrides.containsKey(binding.capabilityId);
    final dec = binding.declaration;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(10),
        border: isOverridden
            ? Border.all(color: AppColors.acc(context).withValues(alpha: 0.3))
            : null,
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Icon(
          dec.isDestructive ? LucideIcons.alertTriangle : LucideIcons.puzzle,
          size: 18,
          color: dec.isDestructive
              ? AppColors.dng(context)
              : AppColors.iconGray(context),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                dec.name.isNotEmpty ? dec.name : binding.capabilityId,
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isOverridden)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.acc(context).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  localeProvider.t('custom'),
                  style: TextStyle(
                    color: AppColors.acc(context),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          binding.pluginId,
          style: TextStyle(
            color: AppColors.textTertiary(context),
            fontSize: 11,
          ),
        ),
        trailing: _buildPermissionToggle(context, binding),
      ),
    );
  }

  Widget _buildPermissionToggle(
    BuildContext context,
    CapabilityBinding binding,
  ) {
    // ignore: unused_local_variable
    final effective = _getEffectivePermission(binding);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.sfAlt(context),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleBtn(context, binding, 'auto', effective == 'auto'),
          _buildToggleBtn(context, binding, 'confirm', effective == 'confirm'),
          _buildToggleBtn(context, binding, 'deny', effective == 'deny'),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(
    BuildContext context,
    CapabilityBinding binding,
    String mode,
    bool active,
  ) {
    Color color;
    IconData icon;
    switch (mode) {
      case 'auto':
        color = AppColors.ok(context);
        icon = LucideIcons.check;
        break;
      case 'deny':
        color = AppColors.dng(context);
        icon = LucideIcons.x;
        break;
      default:
        color = AppColors.warn(context);
        icon = LucideIcons.helpCircle;
    }

    return GestureDetector(
      onTap: () => _setCapabilityPermission(binding.capabilityId, mode),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 12,
          color: active ? color : AppColors.textDisabled(context),
        ),
      ),
    );
  }
}
