import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/network/api_exception.dart';
import '../controllers/auth_controller.dart';
import '../../../../l10n/app_localizations.dart';

/// Offers to resend the account-verification email.
///
/// The server refuses protected endpoints for an unverified account with
/// `403 AUTH_EMAIL_UNVERIFIED`. Without this banner the user has no way out
/// of that state — the resend endpoint
/// (`POST /api/v1/auth/email/verification-notification`) exists precisely
/// for it.
///
/// The endpoint answers 200 whether or not the address still needs
/// verifying, so the UI never reveals whether an account exists.
class EmailVerificationBanner extends ConsumerStatefulWidget {
  const EmailVerificationBanner({super.key});

  @override
  ConsumerState<EmailVerificationBanner> createState() =>
      _EmailVerificationBannerState();
}

class _EmailVerificationBannerState extends ConsumerState<EmailVerificationBanner> {
  bool _sending = false;
  bool _sent = false;
  String? _error;

  Future<void> _resend() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).resendVerificationEmail();
      if (mounted) setState(() => _sent = true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on Object catch (e) {
      if (mounted) setState(() => _error = ErrorHandler.handle(e).message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final required = ref.watch(emailVerificationRequiredProvider);
    if (!required) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.warnAmberBg,
        borderRadius: BorderRadius.circular(12),
        border: const Border.fromBorderSide(
          BorderSide(color: Color(0x59F59E0B)),
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mark_email_unread_rounded,
                  size: 18, color: AppColors.warningShadow),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.authVerifyEmailBanner,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warningShadow,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Text(
            _sent
                ? l10n.authVerificationResentBody
                : l10n.authVerificationResentHint,
            style: const TextStyle(fontSize: 11, color: AppColors.warningShadow),
          ),
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(
              _error!,
              style: const TextStyle(fontSize: 11, color: AppColors.wrongRed),
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('resend_verification_email'),
              onPressed: _sending || _sent ? null : _resend,
              icon: _sending
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 16),
              label: Text(_sent ? l10n.authVerificationSent : l10n.authResendVerification),
              style: TextButton.styleFrom(foregroundColor: AppColors.warningShadow),
            ),
          ),
        ],
      ),
    );
  }
}

