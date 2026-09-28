import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/consent/consent_controller.dart';
import '../../../core/consent/consent_state.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../data/datasources/privacy_remote_data_source.dart';
import '../domain/entities/visitor_data.dart';

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
    final data = ref.watch(visitorDataProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Your data')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(visitorDataProvider),
        child: data.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _List(
            children: [
              const _Note(
                'We could not reach the server to show what is stored about this '
                'device.',
              ),
              const SizedBox(height: 12),
              Center(
                child: FilledButton.tonal(
                  onPressed: () => ref.invalidate(visitorDataProvider),
                  child: const Text('Retry'),
                ),
              ),
            ],
          ),
          // Null means the response had no visitor id: not understood, which is
          // not the same as "nothing stored".
          data: (visitor) => visitor == null
              ? _List(
                  children: [
                    const _Note(
                      'We could not read what is stored about this device. Your '
                      'local choices are unaffected.',
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: FilledButton.tonal(
                        onPressed: () => ref.invalidate(visitorDataProvider),
                        child: const Text('Retry'),
                      ),
                    ),
                  ],
                )
              : _List(
                  children: [
                    Text('Anonymous profile', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Reference ${visitor.visitorId}',
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
                      const _Row('Linked to an account', 'Yes'),
                    const SizedBox(height: 16),
                    if (visitor.canEraseHere)
                      OutlinedButton.icon(
                        onPressed: () => _confirmErase(context, ref),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Erase stored data'),
                      )
                    else
                      const _Note(
                        'This profile is linked to your account, so erasing it is '
                        'handled by the account deletion flow. Use Delete account '
                        'in Settings to remove everything.',
                      ),
                    const SizedBox(height: 16),
                    Text('Local choices', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    const _Note(
                      'Analytics, functional and marketing consent are stored on '
                      'this device and applied immediately, independently of the '
                      'anonymous profile above.',
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erase stored data?'),
        content: const Text(
          'This deletes the anonymous profile and every intent event stored for '
          'this device. It cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Erase'),
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
          const SnackBar(content: Text('Stored data erased')),
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
                ? 'This profile is linked to your account. Delete the account to '
                    'erase everything.'
                : e.message,
          ),
        ),
      );
    } catch (e) {
      AppLogger.w('erase visitor data failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not erase your data. Try again.')),
        );
      }
    }
  }
}

class _LocalConsentSummary extends ConsumerWidget {
  const _LocalConsentSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consent = ref.watch(consentProvider).value ?? const ConsentState.unknown();
    if (!consent.decided) {
      return const _Note('You have not made a choice yet.');
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
