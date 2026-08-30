import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/calculator.dart';
import '../controllers/calculator_controller.dart';

/// Dynamic calculator form — server-authoritative.
///
/// Contract: `POST /{domain}/{slug}/calculate` validates inputs server-side.
/// Client renders generic key → value inputs and surfaces 422 `errors` inline.
/// Offline preview is not rendered locally — server reconciles on sync
/// per AGENTS.md. Result `data` is pretty-printed; no local math duplicated.
class CalculatorDetailScreen extends ConsumerStatefulWidget {
  const CalculatorDetailScreen({
    required this.domain,
    required this.slug,
    super.key,
  });

  final String domain;
  final String slug;

  @override
  ConsumerState<CalculatorDetailScreen> createState() => _CalculatorDetailScreenState();
}

class _CalculatorDetailScreenState extends ConsumerState<CalculatorDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fields = <_FieldEntry>[ _FieldEntry(key: '', value: '') ];
  bool _showJson = false;

  @override
  void dispose() {
    for (final f in _fields) { f.keyCtrl.dispose(); f.valCtrl.dispose(); }
    super.dispose();
  }

  Map<String, dynamic> _collectInputs() {
    final map = <String, dynamic>{};
    for (final f in _fields) {
      final k = f.keyCtrl.text.trim();
      final vRaw = f.valCtrl.text.trim();
      if (k.isEmpty || vRaw.isEmpty) continue;
      // Try to preserve numbers — backend validates as numeric.
      final numV = num.tryParse(vRaw);
      map[k] = numV ?? vRaw;
    }
    return map;
  }

  void _addField() => setState(() => _fields.add(_FieldEntry(key: '', value: '')));
  void _removeField(int i) => setState(() {
        _fields[i].keyCtrl.dispose();
        _fields[i].valCtrl.dispose();
        _fields.removeAt(i);
        if (_fields.isEmpty) _fields.add(_FieldEntry(key: '', value: ''));
      });

  Future<void> _calculate() async {
    if (!_formKey.currentState!.validate()) return;
    final inputs = _collectInputs();
    if (inputs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one input (key + value)')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    await ref.read(calculatorControllerProvider.notifier).calculate(widget.domain, widget.slug, inputs);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final configAsync = ref.watch(calculatorConfigProvider((domain: widget.domain, slug: widget.slug)));
    final calcState = ref.watch(calculatorControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(configAsync.when(
              data: (c) => c.label,
              loading: () => widget.slug.replaceAll('-', ' '),
              error: (_, __) => widget.slug.replaceAll('-', ' '),
            )),
            configAsync.maybeWhen(
              data: (c) => Text('${c.domainLabel} • ${widget.domain}/${widget.slug}',
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Config header
            configAsync.when(
              data: (c) => _HeaderCard(config: c),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => _ErrorCard(message: e.toString(), onRetry: () => ref.invalidate(calculatorConfigProvider((domain: widget.domain, slug: widget.slug)))),
            ),
            const SizedBox(height: 16),

            // Input builder — 80/20 generic (server validates shape)
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text('Inputs', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _addField,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add field'),
                      ),
                      IconButton(
                        tooltip: _showJson ? 'Form view' : 'JSON view',
                        icon: Icon(_showJson ? Icons.view_list_rounded : Icons.data_object_rounded),
                        onPressed: () => setState(() => _showJson = !_showJson),
                      ),
                    ],
                  ),
                  const Text(
                    'Server-authoritative — enter keys exactly as the API expects. '
                    'Empty keys/values are ignored. Server returns 422 with field errors if required inputs are missing.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  if (_showJson)
                    _JsonPreview(fields: _fields)
                  else
                    ...List.generate(_fields.length, (i) {
                      final f = _fields[i];
                      final fieldErr = calcState.fieldErrors?[f.keyCtrl.text.trim()];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: f.keyCtrl,
                                decoration: InputDecoration(
                                  labelText: 'key',
                                  hintText: 'e.g. length',
                                  errorText: fieldErr is List ? fieldErr.join(', ') : null,
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                                validator: (v) => v != null && v.trim().isNotEmpty && v.contains(' ') ? 'no spaces' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: f.valCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'value',
                                  hintText: 'e.g. 12.5',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline_rounded),
                              onPressed: () => _removeField(i),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: calcState.loading ? null : _calculate,
                    icon: calcState.loading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.calculate_rounded),
                    label: Text(calcState.loading ? 'Calculating…' : 'Calculate (server)'),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      ref.read(calculatorControllerProvider.notifier).clear();
                      for (final f in _fields) { f.keyCtrl.clear(); f.valCtrl.clear(); }
                      setState(() {});
                    },
                    child: const Text('Clear inputs & result'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Error / field errors
            if (calcState.error != null)
              _ErrorCard(
                message: calcState.error!,
                fieldErrors: calcState.fieldErrors,
                onRetry: _calculate,
              ),

            // Result — pretty-printed data (never computed locally)
            if (calcState.result != null) _ResultCard(result: calcState.result!),

            const SizedBox(height: 24),

            // History link
            OutlinedButton.icon(
              onPressed: () => context.push('/calculators/${widget.domain}/${widget.slug}/history'),
              icon: const Icon(Icons.history_rounded),
              label: const Text('View history (server, paginated)'),
            ),
            const SizedBox(height: 8),
            const Text(
              'History and analytics are server-cached (ApiCacheHeaders) and require auth. '
              'Snapshots sync at POST /v1/calculation-snapshots/sync when offline.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldEntry {
  _FieldEntry({required String key, required String value})
      : keyCtrl = TextEditingController(text: key),
        valCtrl = TextEditingController(text: value);
  final TextEditingController keyCtrl;
  final TextEditingController valCtrl;
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.config});
  final CalculatorConfig config;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(config.domainLabel.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.brand, letterSpacing: 0.6)),
          ),
          const SizedBox(height: 8),
          Text(config.label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(config.calculateEndpoint, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, this.fieldErrors, this.onRetry});
  final String message;
  final Map<String, dynamic>? fieldErrors;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.wrongRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.wrongRed.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.wrongRed, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(message, style: const TextStyle(color: AppColors.wrongRed, fontWeight: FontWeight.w600))),
            ],
          ),
          if (fieldErrors != null && fieldErrors!.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...fieldErrors!.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• ${e.key}: ${e.value is List ? (e.value as List).join(", ") : e.value}',
                      style: const TextStyle(fontSize: 12, color: AppColors.wrongRed)),
                )),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: 10),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});
  final CalculationResult result;

  @override
  Widget build(BuildContext context) {
    final pretty = const JsonEncoder.withIndent('  ').convert(result.data);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.correctGreen.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.correctGreen.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.correctGreen, size: 18),
              const SizedBox(width: 8),
              Text(result.message ?? 'Calculated (server)', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.correctGreen)),
              const Spacer(),
              Text('inputs: ${result.inputs.length}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2)),
            ),
            child: SelectableText(pretty, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _JsonPreview extends StatelessWidget {
  const _JsonPreview({required this.fields});
  final List<_FieldEntry> fields;

  @override
  Widget build(BuildContext context) {
    final map = <String, dynamic>{};
    for (final f in fields) {
      final k = f.keyCtrl.text.trim();
      final v = f.valCtrl.text.trim();
      if (k.isEmpty) continue;
      map[k] = num.tryParse(v) ?? v;
    }
    final json = const JsonEncoder.withIndent('  ').convert(map);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: SelectableText(json, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
    );
  }
}
