import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/di/app_di.dart';
import '../../domain/entities/user.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../../presentation/theme/app_colors.dart';

class UnifiedLoginPage extends StatelessWidget {
  final VoidCallback? onLoginSuccess;

  const UnifiedLoginPage({super.key, this.onLoginSuccess});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthBloc>(),
      child: _UnifiedLoginView(onLoginSuccess: onLoginSuccess),
    );
  }
}

class _UnifiedLoginView extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const _UnifiedLoginView({this.onLoginSuccess});

  @override
  State<_UnifiedLoginView> createState() => _UnifiedLoginViewState();
}

class _UnifiedLoginViewState extends State<_UnifiedLoginView> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _isRegister = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _displayNameCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }
    if (_isRegister) {
      context.read<AuthBloc>().add(AuthRegisterRequested(
            email: email,
            password: password,
            displayName: _displayNameCtrl.text.trim().isNotEmpty
                ? _displayNameCtrl.text.trim()
                : null,
          ));
    } else {
      context.read<AuthBloc>().add(AuthEmailLoginRequested(
            email: email,
            password: password,
          ));
    }
  }

  void _googleLogin() {
    context.read<AuthBloc>().add(const AuthGoogleLoginRequested());
  }

  void _appleLogin() {
    context.read<AuthBloc>().add(const AuthAppleLoginRequested());
  }

  bool _showAppleSignIn() {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isMacOS;
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode? focusNode,
    required String labelText,
    required IconData prefixIcon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    void Function(String)? onSubmitted,
    int maxLength = 256,
  }) {
    return Container(
        decoration: BoxDecoration(
            color: AppColors.sf(context),
            borderRadius: BorderRadius.circular(16)),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLength: maxLength,
          autocorrect: false,
          style: TextStyle(
              color: AppColors.textPrimary(context), fontSize: 16),
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            labelText: labelText,
            labelStyle: TextStyle(color: AppColors.textHint(context)),
            prefixIcon: Icon(prefixIcon,
                color: AppColors.iconGray(context), size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.sf(context),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          widget.onLoginSuccess?.call();
        } else if (state is AuthError) {
          setState(() => _error = state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return Scaffold(
          backgroundColor: AppColors.bg(context),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.messagesSquare,
                        size: 64, color: AppColors.acc(context)),
                    const SizedBox(height: 16),
                    Text('Omnivium',
                        style: TextStyle(
                            color: AppColors.textPrimary(context),
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text('End-to-End Encrypted',
                        style: TextStyle(
                            color: AppColors.textHint(context),
                            fontSize: 14)),
                    const SizedBox(height: 48),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: AppColors.dng(context).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12)),
                          child: Row(children: [
                            Icon(LucideIcons.alertCircle,
                                size: 18,
                                color: AppColors.dng(context)),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(_error!,
                                    style: TextStyle(
                                        color: AppColors.dng(context),
                                        fontSize: 14))),
                          ]),
                        ),
                      ),
                    if (_isRegister) ...[
                      _buildTextField(
                        controller: _displayNameCtrl,
                        focusNode: null,
                        labelText: 'Display Name (optional)',
                        prefixIcon: LucideIcons.user,
                      ),
                      const SizedBox(height: 1),
                    ],
                    _buildTextField(
                      controller: _emailCtrl,
                      focusNode: _emailFocus,
                      labelText: 'Email',
                      prefixIcon: LucideIcons.mail,
                      keyboardType: TextInputType.emailAddress,
                      onSubmitted: (_) => _passwordFocus.requestFocus(),
                    ),
                    const SizedBox(height: 1),
                    _buildTextField(
                      controller: _passwordCtrl,
                      focusNode: _passwordFocus,
                      labelText: 'Password',
                      prefixIcon: LucideIcons.lock,
                      obscureText: _obscurePassword,
                      onSubmitted: (_) => _submit(),
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscurePassword
                                ? LucideIcons.eye
                                : LucideIcons.eyeOff,
                            color: AppColors.iconGray(context),
                            size: 20),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.acc(context),
                          foregroundColor: AppColors.textOnAccent(context),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: isLoading ? null : _submit,
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text(_isRegister ? 'Register' : 'Login',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () =>
                          setState(() => _isRegister = !_isRegister),
                      child: Text(
                          _isRegister
                              ? 'Already have an account? Login'
                              : "Don't have an account? Register",
                          style: TextStyle(
                              color: AppColors.acc(context), fontSize: 14)),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                            child: Divider(color: AppColors.divider(context))),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('or continue with',
                              style: TextStyle(
                                  color: AppColors.textHint(context),
                                  fontSize: 12)),
                        ),
                        Expanded(
                            child: Divider(color: AppColors.divider(context))),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SocialButton(
                          icon: LucideIcons.chrome,
                          label: 'Google',
                          onPressed: isLoading ? null : _googleLogin,
                        ),
                        if (_showAppleSignIn()) ...[
                          const SizedBox(width: 16),
                          _SocialButton(
                            icon: LucideIcons.apple,
                            label: 'Apple',
                            onPressed: isLoading ? null : _appleLogin,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _SocialButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: AppColors.textPrimary(context)),
      label: Text(label,
          style: TextStyle(
              color: AppColors.textPrimary(context), fontSize: 14)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        side: BorderSide(color: AppColors.divider(context)),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
