import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/errors/error_handler.dart';
import '../../data/datasources/social_sign_in_gateway.dart';
import '../controllers/auth_controller.dart';

/// Google / Apple sign-in buttons.
///
/// The platform SDK produces an **id_token**; the server verifies it and
/// mints the bearer PAT. The client never exchanges credentials itself and
/// never sees a provider access token.
///
/// A provider whose client id was not compiled into this build is not
/// rendered at all — offering a button that is guaranteed to fail is worse
/// than not offering it.
class SocialSignInButtons extends ConsumerWidget {
  const SocialSignInButtons({super.key, required this.onSignedIn});

  /// Called with the provider after a successful sign-in.
  final Future<void> Function(SocialProvider provider) onSignedIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availability = ref.watch(socialProvidersAvailableProvider);
    final theme = Theme.of(context);

    return availability.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (available) {
        if (available.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
              ],
            ),
            const SizedBox(height: 16),
            // Each provider is rendered only when it is actually usable.
            if (available.contains(SocialProvider.google)) ...[
              const _GoogleButton(),
              if (available.contains(SocialProvider.apple))
                const SizedBox(height: 10),
            ],
            if (available.contains(SocialProvider.apple)) const _AppleButton(),
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }
}

/// Google sign-in.
///
/// The SDK is asked for an id_token; without a server client id it will not
/// issue one, so the gateway raises a clear error rather than the client
/// silently posting an empty credential.
class _GoogleButton extends ConsumerStatefulWidget {
  const _GoogleButton();

  @override
  ConsumerState<_GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends ConsumerState<_GoogleButton> {
  bool _busy = false;

  Future<void> _signIn() async {
    setState(() => _busy = true);
    try {
      final gateway = ref.read(socialSignInGatewayProvider);
      final credential = await gateway.signIn(SocialProvider.google);
      if (credential == null) return; // dismissed
      await ref
          .read(authControllerProvider.notifier)
          .loginWithSocial(SocialProvider.google, credential: credential);
    } on SocialSignInException catch (e) {
      if (mounted && !e.isCancelled) _showError(e.message);
    } on Object catch (e) {
      if (mounted) _showError(ErrorHandler.handle(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.wrongRed),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      key: const Key('social_google'),
      onPressed: _busy ? null : _signIn,
      icon: _busy
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.g_mobiledata_rounded, size: 22),
      label: const Text('Continue with Google'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

/// Apple's own button widget.
///
/// `sign_in_with_apple` requires the platform's own button on Android and
/// web. Its `onPressed` starts the native flow; the credential comes back
/// through [SignInWithApple.getAppleIDCredential], which the gateway calls.
class _AppleButton extends ConsumerStatefulWidget {
  const _AppleButton();

  @override
  ConsumerState<_AppleButton> createState() => _AppleButtonState();
}

class _AppleButtonState extends ConsumerState<_AppleButton> {
  bool _busy = false;

  Future<void> _signIn() async {
    setState(() => _busy = true);
    try {
      final gateway = ref.read(socialSignInGatewayProvider);
      final credential = await gateway.signIn(SocialProvider.apple);
      if (credential == null) return; // dismissed
      await ref
          .read(authControllerProvider.notifier)
          .loginWithSocial(SocialProvider.apple, credential: credential);
    } on SocialSignInException catch (e) {
      if (mounted && !e.isCancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.wrongRed),
        );
      }
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.handle(e).message),
            backgroundColor: AppColors.wrongRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: SignInWithAppleButton(
        key: const Key('social_apple'),
        onPressed: _busy ? null : _signIn,
        text: 'Continue with Apple',
        height: 50,
        borderRadius: BorderRadius.circular(12),
        style: SignInWithAppleButtonStyle.black,
      ),
    );
  }
}
