import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../domain/password_policy.dart';
import '../controllers/auth_controller.dart';

/// Completes a password reset from the emailed link.
///
/// This screen exists because the reset link used to dead-end: the deep-link
/// handler carried `?token=…&email=…` to `ForgotPasswordScreen`, which accepts
/// only an email and therefore dropped the token on the floor and re-sent a new
/// reset email instead. A user who tapped the link could never set a password
/// in the app. `POST /auth/reset-password` has always existed and accepts the
/// token, so the missing piece was only this screen.
///
/// On success the server revokes **every** token and session
/// (`MobilePasswordController::resetPassword`), so the user must sign in again —
/// hence the hand-off to `/login` rather than back into the app.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.token, this.email});

  /// One-time token from the reset link.
  final String? token;

  /// Address the token was issued for. Needed by the server alongside the token.
  final String? email;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _confirmFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscure = true;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    _confirmFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final token = widget.token;
    final email = widget.email;
    if (token == null || token.isEmpty || email == null || email.isEmpty) {
      setState(() => _errorMessage = 'This reset link is incomplete. Request a new one.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authControllerProvider.notifier).resetPassword(
            token: token,
            email: email,
            password: _password.text,
            passwordConfirmation: _confirm.text,
          );
      if (!mounted) return;
      // Every session was revoked server-side; sign in again with the new one.
      // The token is a one-time secret, so it is deliberately not carried
      // through into the URL of the next screen.
      context.go('/login?reset=1');
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = ErrorHandler.handle(e).message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasCredentials = (widget.token?.isNotEmpty ?? false) &&
        (widget.email?.isNotEmpty ?? false);

    return Scaffold(
      appBar: AppBar(title: const Text('Set a new password')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(Icons.lock_reset_rounded, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Choose a new password',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You will be signed out everywhere, including this device.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  if (!hasCredentials)
                    _Notice(
                      icon: Icons.link_off_rounded,
                      text: 'This link is missing its reset token. Open the link from '
                          'your email, or request a new one.',
                      color: AppColors.wrongRed,
                      action: FilledButton.tonal(
                        onPressed: () => context.go('/forgot-password'),
                        child: const Text('Request a new link'),
                      ),
                    )
                  else ...[
                    TextFormField(
                      controller: _password,
                      focusNode: _passwordFocus,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.newPassword],
                      // The confirmation field sits under the keyboard on a
                      // small screen, so the keyboard's own "next" must move
                      // focus there. Without this the user has to reach past the
                      // keyboard to tap a field they cannot see.
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
                      decoration: InputDecoration(
                        labelText: 'New password',
                        helperText: 'At least ${PasswordPolicy.minLength} characters',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => PasswordPolicy.validate(v ?? ''),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirm,
                      focusNode: _confirmFocus,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        labelText: 'Confirm new password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_reset_rounded),
                      ),
                      validator: (v) => PasswordPolicy.validateConfirmation(
                        _password.text,
                        v ?? '',
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.wrongRed, fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 24),
                    GradientButton(
                      label: _loading ? 'Updating…' : 'Update password',
                      onPressed: _loading ? null : _submit,
                      loading: _loading,
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _loading ? null : () => context.go('/forgot-password'),
                      child: const Text('Request a new link instead'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text, required this.color, this.action});

  final IconData icon;
  final String text;
  final Color color;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
          if (action != null) ...[const SizedBox(height: 14), action!],
        ],
      ),
    );
  }
}
