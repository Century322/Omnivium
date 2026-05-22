import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../theme/locale_provider.dart';
import '../../core/app_provider.dart';
import '../../core/totp_service.dart';
import '../../core/srp_service.dart';

class MatrixLoginView extends StatefulWidget {
  final AppProvider provider;
  final VoidCallback? onLoginSuccess;
  const MatrixLoginView({
    super.key,
    required this.provider,
    this.onLoginSuccess,
  });

  @override
  State<MatrixLoginView> createState() => _MatrixLoginViewState();
}

class _MatrixLoginViewState extends State<MatrixLoginView> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _homeserverCtrl = TextEditingController(
    text: 'https://matrix.omnivium.app',
  );
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _homeserverFocus = FocusNode();
  bool _isRegister = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _showAdvanced = false;
  bool _showTotp = false;
  final _totpCtrl = TextEditingController();
  final _totpFocus = FocusNode();
  String? _error;
  static const _defaultHomeserver = 'https://matrix.omnivium.app';

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _homeserverCtrl.dispose();
    _totpCtrl.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _homeserverFocus.dispose();
    _totpFocus.dispose();
    super.dispose();
  }

  Future<String> _getHomeserver() async {
    if (_showAdvanced && _homeserverCtrl.text.trim().isNotEmpty)
      return _homeserverCtrl.text.trim();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('omnivium_matrix_homeserver') ?? _defaultHomeserver;
  }

  Future<void> _submit() async {
    final t = localeProvider.t;
    if (_showTotp) {
      final code = _totpCtrl.text.trim();
      if (code.length != 6) {
        setState(() => _error = t('invalid_code'));
        return;
      }
      if (!TotpService.instance.verify(code)) {
        setState(() => _error = t('invalid_code'));
        return;
      }
      widget.onLoginSuccess?.call();
      return;
    }
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = t('fill_all_fields'));
      return;
    }
    if (password.length < 8) {
      setState(() => _error = localeProvider.t('password_min_length'));
      return;
    }
    if (username.length > 255 || password.length > 1024) {
      setState(() => _error = localeProvider.t('input_too_long'));
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final homeserver = await _getHomeserver();
      final srp = SrpService.instance;

      if (!_isRegister && srp.hasVerifier && srp.username == username) {
        final srpResult = await srp.srpLogin(username, password);
        if (srpResult != null && srpResult['access_token'] != null) {
          await widget.provider.matrix.loginWithToken(
            srpResult['access_token'],
            srpResult['homeserver'] ?? homeserver,
          );
          if (mounted && widget.provider.matrix.isLoggedIn) {
            if (TotpService.instance.isEnabled) {
              setState(() {
                _showTotp = true;
                _isLoading = false;
              });
              Future.delayed(
                const Duration(milliseconds: 100),
                () => _totpFocus.requestFocus(),
              );
            } else {
              widget.onLoginSuccess?.call();
            }
            return;
          }
        }
      }

      if (_isRegister) {
        await widget.provider.matrix.register(username, password, homeserver);
        await srp.createVerifier(username, password);
      } else {
        await widget.provider.matrix.login(username, password, homeserver);
        await srp.createVerifier(username, password);
      }
      if (mounted && widget.provider.matrix.isLoggedIn) {
        if (TotpService.instance.isEnabled) {
          setState(() {
            _showTotp = true;
            _isLoading = false;
          });
          Future.delayed(
            const Duration(milliseconds: 100),
            () => _totpFocus.requestFocus(),
          );
        } else {
          widget.onLoginSuccess?.call();
        }
      } else if (mounted && widget.provider.matrix.error != null) {
        setState(() => _error = widget.provider.matrix.error);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = localeProvider.t;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accent, AppColors.accentPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      LucideIcons.messageCircle,
                      size: 40,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Omnivium',
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    t('e2e_encrypted'),
                    style: TextStyle(
                      color: AppColors.textHint(context),
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.sf(context),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _usernameCtrl,
                        focusNode: _usernameFocus,
                        style: TextStyle(
                          color: AppColors.textPrimary(context),
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          labelText: t('username'),
                          hintText: t('username'),
                          hintStyle: TextStyle(
                            color: AppColors.iconGray(context),
                            fontSize: 16,
                          ),
                          prefixIcon: Icon(
                            LucideIcons.user,
                            color: AppColors.iconGray(context),
                            size: 20,
                          ),
                          filled: true,
                          fillColor: AppColors.sf(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                      Divider(height: 1, color: AppColors.divider(context)),
                      TextField(
                        controller: _passwordCtrl,
                        focusNode: _passwordFocus,
                        obscureText: _obscurePassword,
                        style: TextStyle(
                          color: AppColors.textPrimary(context),
                          fontSize: 16,
                        ),
                        onSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: t('password'),
                          hintText: t('password'),
                          hintStyle: TextStyle(
                            color: AppColors.iconGray(context),
                            fontSize: 16,
                          ),
                          prefixIcon: Icon(
                            LucideIcons.lock,
                            color: AppColors.iconGray(context),
                            size: 20,
                          ),
                          suffixIcon: Semantics(
                            label: localeProvider.t('toggle_password'),
                            child: GestureDetector(
                              onTap: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              child: Icon(
                                _obscurePassword
                                    ? LucideIcons.eye
                                    : LucideIcons.eyeOff,
                                color: AppColors.iconGray(context),
                                size: 20,
                              ),
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.sf(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_showTotp) ...[
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.sf(context),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _totpCtrl,
                      focusNode: _totpFocus,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      style: TextStyle(
                        color: AppColors.textPrimary(context),
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 8,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        counterText: '',
                        labelText: t('verification_code'),
                        hintStyle: TextStyle(
                          color: AppColors.iconGray(context),
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: AppColors.sf(context),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                ],
                if (_showAdvanced && !_showTotp) ...[
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.sf(context),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _homeserverCtrl,
                      focusNode: _homeserverFocus,
                      style: TextStyle(
                        color: AppColors.textPrimary(context),
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        labelText: t('server_address'),
                        hintText: t('server_address'),
                        hintStyle: TextStyle(
                          color: AppColors.iconGray(context),
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          LucideIcons.server,
                          color: AppColors.iconGray(context),
                          size: 18,
                        ),
                        filled: true,
                        fillColor: AppColors.sf(context),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Semantics(
                  label: localeProvider.t('advanced_options'),
                  child: GestureDetector(
                    onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        _showAdvanced
                            ? t('hide_advanced')
                            : t('advanced_options'),
                        style: TextStyle(
                          color: AppColors.textTertiary(context),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.dng(context).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: AppColors.dng(context),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.textPrimary(context),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textPrimary(context),
                          ),
                        )
                      : Text(
                          _isRegister ? t('create_account') : t('login'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Semantics(
                    label: localeProvider.t('switch_to_register'),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _isRegister = !_isRegister;
                        _error = null;
                      }),
                      child: Text(
                        _isRegister
                            ? t('have_account_login')
                            : t('no_account_create'),
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
