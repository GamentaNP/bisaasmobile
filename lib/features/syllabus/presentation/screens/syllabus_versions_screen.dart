import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/locale_controller.dart';
import '../../../../app/theme/script_fonts.dart';
import '../../domain/entities/syllabus.dart';
import '../controllers/syllabus_controller.dart';

/// Version picker — the entry point to the syllabus feature.
///
/// Public read: the catalog routes have `withoutMiddleware('auth:sanctum')`, so
/// this must work signed out. The learner's own plans are therefore fetched
/// separately and are allowed to fail without taking the screen down.
class SyllabusVersionsScreen extends ConsumerWidget {
  const SyllabusVersionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(syllabusVersionsControllerProvider);
    // Titles arrive in the syllabus's own language from the server. Resolving the
    // font from the text rather than the active locale is what lets a Nepali
    // title render inside an English interface.
    final preferNative = ref.watch(_preferNativeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Syllabus')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(syllabusVersionsControllerProvider.notifier).refresh(),
        child: _body(context, ref, state, preferNative),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    SyllabusVersionsState state,
    bool preferNative,
  ) {
    if (state.isLoading && state.versions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.versions.isEmpty) {
      return _ErrorView(
        message: state.error!,
        onRetry: () => ref.read(syllabusVersionsControllerProvider.notifier).load(force: true),
      );
    }

    if (state.isEmpty) {
      return const _EmptyView(
        icon: Icons.account_tree_outlined,
        message: 'No syllabus has been published yet.',
      );
    }

    final versions = state.effective;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: versions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _VersionCard(
        version: versions[i],
        preferNative: preferNative,
        onTap: () => context.push('/syllabus/${versions[i].publicId}'),
      ),
    );
  }
}

/// Whether to show the server's Nepali title when one exists.
///
/// Follows the active UI locale, so a Nepali reader sees Nepali titles and an
/// English reader sees English. The server ships both on the same row, so this
/// is a local choice between two provided strings — not a translation request.
final _preferNativeProvider = Provider<bool>((ref) {
  final code = ref.watch(localeProvider)?.languageCode;
  return code != null && code != 'en';
});

class _VersionCard extends StatelessWidget {
  const _VersionCard({required this.version, required this.onTap, required this.preferNative});

  final SyllabusVersion version;
  final VoidCallback onTap;
  final bool preferNative;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = version.titleFor(preferNative: preferNative);
    final base = theme.textTheme.titleMedium;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: ScriptFonts.forText(base ?? const TextStyle(), title)),
              if (version.exam != null) ...[
                const SizedBox(height: 4),
                Text(
                  version.exam!.name,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Chip(
                    label: version.versionCode,
                    icon: Icons.tag,
                  ),
                  if (version.nodeCount > 0)
                    _Chip(
                      label: '${version.nodeCount} topics',
                      icon: Icons.account_tree_outlined,
                    ),
                  if (version.examinableNodeCount > 0)
                    _Chip(
                      label: '${version.examinableNodeCount} examinable',
                      icon: Icons.verified_outlined,
                    ),
                  if (version.effectiveWindow != null)
                    _Chip(label: version.effectiveWindow!, icon: Icons.event_outlined),
                  if (!version.isEffectiveNow)
                    _Chip(label: 'Not current', icon: Icons.history, warn: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.icon, this.warn = false});

  final String label;
  final IconData icon;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = warn ? scheme.error : scheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        // Labels mix numerals and text from the server, so the font is resolved
        // from the string itself.
        Text(
          label,
          style: ScriptFonts.forText(
            Theme.of(context).textTheme.labelSmall ?? const TextStyle(),
            label,
          ).copyWith(color: color),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 48),
        Icon(Icons.cloud_off, size: 48, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Center(
          child: FilledButton.tonalIcon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 48),
        Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center),
      ],
    );
  }
}
