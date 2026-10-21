import '../../../../l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../domain/entities/ai_settings.dart';
import '../controllers/ai_settings_controller.dart';

/// Bring-your-own-key management.
///
/// `GET /ai-keys`, `POST /ai-keys`, `DELETE /ai-keys/{key}`.
///
/// The secret is **write-only**: it is sent once over TLS and the server
/// never returns it — every row shows a masked `••••last4` preview. The
/// client therefore never reads a secret back and never stores one.
class AiKeysScreen extends ConsumerStatefulWidget {
  const AiKeysScreen({super.key});

  @override
  ConsumerState<AiKeysScreen> createState() => _AiKeysScreenState();
}

class _AiKeysScreenState extends ConsumerState<AiKeysScreen> {
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiSettingsControllerProvider.notifier).fetchKeys();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(aiSettingsControllerProvider);
    final notifier = ref.read(aiSettingsControllerProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aiKeysTitle)),
      body: RefreshIndicator(
        onRefresh: notifier.fetchKeys,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.brand.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.brand),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.aiKeysExplain,
                      style: TextStyle(fontSize: 11, color: AppColors.brandDark, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (state.saveKeyMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.correctGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.correctGreen), const SizedBox(width: 8), Expanded(child: Text(state.saveKeyMessage!, style: const TextStyle(fontSize: 12, color: AppColors.correctGreen)))]),
              ),
              const SizedBox(height: 10),
            ],
            if (state.saveKeyError != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.wrongRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.wrongRed), const SizedBox(width: 8), Expanded(child: Text(state.saveKeyError!, style: const TextStyle(fontSize: 12, color: AppColors.wrongRed)))]),
              ),
              const SizedBox(height: 10),
            ],
            if (_adding) ...[
              const _AddKeyForm(),
              const SizedBox(height: 14),
            ],
            FilledButton.icon(
              onPressed: () => setState(() => _adding = !_adding),
              icon: Icon(_adding ? Icons.close_rounded : Icons.add_rounded, size: 18),
              label: Text(_adding ? l10n.commonCancel : l10n.aiKeysAddTitle),
            ),
            const SizedBox(height: 16),
            if (state.isKeysLoading && state.keys.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator())),
            if (state.keysError != null && state.keys.isEmpty)
              ErrorView(
                message: state.keysError!,
                onRetry: notifier.fetchKeys,
              )

            else if (!state.isKeysLoading && state.keys.isEmpty && state.keysError == null)
              EmptyState(
                title: l10n.aiKeysNoneYet,
                subtitle:
                    l10n.aiKeysNoneExplain,
                icon: Icons.key_rounded,
              )
            else ...[
              Text(l10n.aiKeysStored, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...state.keys.map(
                (k) => _KeyCard(credential: k, onRevoke: () => notifier.revokeKey(k.id)),
              ),
              if (state.keysHasMore)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: OutlinedButton.icon(
                    onPressed: state.isKeysLoading
                        ? null
                        : () => notifier.fetchKeys(cursor: state.keysCursor, append: true),
                    icon: const Icon(Icons.expand_more_rounded),
                    label: Text(l10n.commonLoadMore),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _KeyCard extends StatelessWidget {
  const _KeyCard({required this.credential, required this.onRevoke});
  final AiKey credential;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final key = credential;
    final health = key.healthStatus?.toLowerCase();
    final healthColor = health == 'healthy' || health == 'ok'
        ? AppColors.correctGreen
        : (health == null ? Colors.grey : AppColors.warnAmber);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    key.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: healthColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    key.healthStatus ?? 'unknown',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: healthColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  key.provider.label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                Text(
                  key.maskedPreview ?? '••••',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            if (key.dailyTokenLimit > 0) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (key.tokensConsumedToday / key.dailyTokenLimit)
                      .clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.aiKeysTokensUsed(key.tokensConsumedToday, key.dailyTokenLimit),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
            if (key.healthDetail != null) ...[
              const SizedBox(height: 6),
              Text(
                key.healthDetail!,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRevoke,
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: Text(l10n.aiKeysRevoke, style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: AppColors.wrongRed),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddKeyForm extends ConsumerStatefulWidget {
  const _AddKeyForm();

  @override
  ConsumerState<_AddKeyForm> createState() => _AddKeyFormState();
}

class _AddKeyFormState extends ConsumerState<_AddKeyForm> {
  final _secret = TextEditingController();
  final _label = TextEditingController();
  AiProvider _provider = AiProvider.openai;

  @override
  void dispose() {
    _secret.dispose();
    _label.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final secret = _secret.text.trim();
    if (secret.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aiKeysTooShort)),
      );
      return;
    }
    final ok = await ref.read(aiSettingsControllerProvider.notifier).storeKey(
          provider: _provider,
          secret: secret,
          label: _label.text.trim().isEmpty ? null : _label.text.trim(),
        );
    if (!ok || !mounted) return;
    // The secret is never read back — drop it from memory immediately.
    _secret.clear();
    _label.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(aiSettingsControllerProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.aiKeysAddProvider,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AiProvider>(
              initialValue: _provider,
              decoration: InputDecoration(
                labelText: l10n.aiKeysProvider,
                isDense: true,
              ),
              items: [
                for (final p in AiProvider.values)
                  DropdownMenuItem<AiProvider>(
                    value: p,
                    child: Text(p.label),
                  ),
              ],
              onChanged: (v) => setState(() => _provider = v ?? _provider),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _secret,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: l10n.aiKeysApiKey,
                helperText: l10n.aiKeysSentOnce,
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _label,
              decoration: InputDecoration(
                labelText: l10n.aiKeysLabelOptional,
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: state.isSavingKey ? null : _save,
              child: state.isSavingKey
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.aiKeysSaveKey),
            ),
          ],
        ),
      ),
    );
  }
}
