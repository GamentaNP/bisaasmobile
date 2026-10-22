import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/consent/consent_controller.dart';
import '../../../core/consent/consent_state.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../data/datasources/privacy_remote_data_source.dart';
import '../domain/entities/visitor_data.dart';
import '../../../l10n/app_localizations.dart';

final privacyRemoteDataSourceProvider = Provider<PrivacyRemoteDataSource>(
  (ref) => PrivacyRemoteDataSource(DioClient.instance.dio),
);

final visitorDataProvider = FutureProvider<VisitorData?>(
  (ref) => ref.watch(privacyRemoteDataSourceProvider).getVisitorData(),
);

/// What the server holds about this anonymous visitor, and the Art. 15/17
/// self-service controls.
///
/// Two states are kept deliberately distinct because they are different claims:
/// "the request failed" and "the server holds nothing".
class PrivacyDataScreen extends ConsumerWidget {
  const PrivacyDataScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final data = ref.watch(visitorDataProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyTitle)),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(visitorDataProvider),
        child: data.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _List(
            children: [
              _Note(
                l10n.privacyUnreachable,
              ),
              const SizedBox(height: 12),
              Center(
                child: FilledButton.tonal(
                  onPressed: () => ref.invalidate(visitorDataProvider),
                  child: Text(l10n.retry),
                ),
              ),
            ],
          ),
          // Null means the response had no visitor id: not understood, which is
          // not the same as "nothing stored".
          data: (visitor) => visitor == null
              ? _List(
                  children: [
                    _Note(
                      l10n.privacyUnreadable,
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: FilledButton.tonal(
                        onPressed: () => ref.invalidate(visitorDataProvider),
                        child: Text(l10n.retry),
                      ),
                    ),
                  ],
                )
              : _List(
                  children: [
                    Text(l10n.privacyAnonymousProfile, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      l10n.privacyReference(visitor.visitorId),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    _Row(
                      'Stored intent events',
                      '${visitor.eventCount}',
                    ),
                    _Row(
                      'Analytics consent',
                      visitor.consentMode.grantsAnalytics ? 'Granted' : 'Not granted',
                    ),
                    if (visitor.stitched)
                      _Row(l10n.privacyLinkedToAccount, 'Yes'),
                    const SizedBox(height: 16),
                    if (visitor.canEraseHere)
                      OutlinedButton.icon(
                        onPressed: () => _confirmErase(context, ref),
                        icon: const Icon(Icons.delete_outline),
                        label: Text(l10n.privacyEraseData),
                      )
                    else
                      _Note(
                        l10n.privacyEraseViaAccount,
                      ),
                    const SizedBox(height: 16),
                    Text(l10n.privacyLocalChoices, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _Note(
                      l10n.privacyLocalConsentNote,
                    ),
                    const SizedBox(height: 8),
                    const _LocalConsentSummary(),
                    const SizedBox(height: 24),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _confirmErase(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.privacyEraseTitle),
        content: Text(
          l10n.privacyEraseBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.privacyEraseConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(privacyRemoteDataSourceProvider).eraseVisitorData();
      ref.invalidate(visitorDataProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.privacyErased)),
        );
      }
    } on ApiException catch (e) {
      // The server refuses an anonymous erasure for a stitched profile. That is
      // a different instruction to the user, not a generic failure.
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == ApiErrorCode.erasureRequiresAccount
                ? l10n.privacyLinkedToAccount
                : e.message,
          ),
        ),
      );
    } catch (e) {
      AppLogger.w('erase visitor data failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.privacyEraseFailed)),
        );
      }
    }
  }
}

class _LocalConsentSummary extends ConsumerWidget {
  const _LocalConsentSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final consent = ref.watch(consentProvider).value ?? const ConsentState.unknown();
    if (!consent.decided) {
      return _Note(l10n.privacyNoChoiceYet);
    }
    return Column(
      children: [
        _Row('Functional', consent.functional ? 'Allowed' : 'Blocked'),
        _Row('Analytics', consent.analytics ? 'Allowed' : 'Blocked'),
        _Row('Marketing', consent.marketing ? 'Allowed' : 'Blocked'),
      ],
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: children,
      );
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}
