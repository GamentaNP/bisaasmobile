import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/calculator.dart';
import '../controllers/calculator_controller.dart';
import '../widgets/calculator_assistant_panel.dart';
import '../widgets/calculator_input_field.dart';
import '../widgets/formula_display.dart';
import '../widgets/status_badge.dart';
import '../widgets/step_by_step_solution.dart';
import '../../../../l10n/app_localizations.dart';

/// Schema-driven calculator screen.
///
/// Renders inputs from [CalculatorConfig.fields] (server-supplied). When
/// `fields[]` is empty, falls back to the legacy generic key/value
/// editor so older endpoints still work. Server is the source of truth
/// for math — Flutter never duplicates calculations.
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

  /// key → controller for schema-driven fields.
  late final Map<String, TextEditingController> _textCtrls;

  /// key → bool for boolean fields.
  late final Map<String, bool> _boolValues;

  /// Legacy fallback rows.
  final _legacyFields = <_LegacyFieldEntry>[_LegacyFieldEntry()];

  bool _useSchema = false;

  /// Whether a share permalink is being minted.
  bool _sharing = false;

  /// Whether a session token exists.
  ///
  /// The calculator screens are guest-reachable, but the assistant endpoint
  /// is not, so the panel is only offered to a signed-in user.
  bool get _hasSession => ref.read(hasSessionProvider).value ?? false;

  @override
  void initState() {
    super.initState();
    _textCtrls = {};
    _boolValues = {};
  }

  @override
  void dispose() {
    for (final c in _textCtrls.values) {
      c.dispose();
    }
    for (final f in _legacyFields) {
      f.keyCtrl.dispose();
      f.valCtrl.dispose();
    }
    super.dispose();
  }

  void _initFromConfig(CalculatorConfig config) {
    for (final f in config.fields) {
      if (f.type == 'boolean') {
        _boolValues.putIfAbsent(f.name, () => false);
      } else {
        final defaultValue = config.defaults[f.name];
        _textCtrls.putIfAbsent(
          f.name,
          () => TextEditingController(text: defaultValue?.toString() ?? ''),
        );
      }
    }
    if (mounted) setState(() => _useSchema = config.fields.isNotEmpty);
  }

  Map<String, dynamic> _collectSchemaInputs(CalculatorConfig config) {
    final out = <String, dynamic>{};
    for (final f in config.fields) {
      if (f.type == 'boolean') {
        out[f.name] = _boolValues[f.name] ?? false;
      } else {
        final raw = _textCtrls[f.name]?.text.trim() ?? '';
        if (raw.isEmpty) continue;
        if (f.type == 'number') {
          final n = num.tryParse(raw);
          if (n != null) {
            out[f.name] = f.precision != null ? double.parse(n.toDouble().toStringAsFixed(f.precision!)) : n;
          } else {
            out[f.name] = raw;
          }
        } else {
          out[f.name] = raw;
        }
      }
    }
    return out;
  }

  Map<String, dynamic> _collectLegacyInputs() {
    final map = <String, dynamic>{};
    for (final f in _legacyFields) {
      final k = f.keyCtrl.text.trim();
      final vRaw = f.valCtrl.text.trim();
      if (k.isEmpty || vRaw.isEmpty) continue;
      final numV = num.tryParse(vRaw);
      map[k] = numV ?? vRaw;
    }
    return map;
  }

  /// Writes a value the assistant proposed into the matching input field.
  ///
  /// The assistant is advisory: the user taps "Apply" on a specific
  /// suggestion, and only then does anything change. The client never
  /// silently fills a field.
  /// Shares the result.
  ///
  /// The permalink is minted by the server from the **inline** payload —
  /// the domain, the calculator, the inputs the user typed and the result the
  /// server computed. The intent is `rehydrate`, so the recipient's calculator
  /// prefills the form and recomputes: the number they see is the server's,
  /// not one this device asserted.
  ///
  /// `POST /api/v1/share` is deliberately **not** used: it is snapshot-only
  /// and demands a `calculable_type` the client cannot mint.
  Future<void> _shareResult(
    CalculatorConfig config,
    CalcState calcState,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final result = calcState.result;
    if (result == null) return;

    setState(() => _sharing = true);
    try {
      final inputs = _useSchema
          ? _collectSchemaInputs(config)
          : _collectLegacyInputs();
      final permalink = await ref.read(calculatorRepositoryProvider).createPermalink(
            domain: widget.domain,
            calculatorSlug: widget.slug,
            inputs: inputs,
            results: result.data,
          );
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          text: '${config.label} — ${permalink.url}',
          subject: config.label,
        ),
      );
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.calcShareFailed(e))),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  void _applyAssistantValue(String field, String value) {
    final l10n = AppLocalizations.of(context)!;
    // A boolean field lives in the bool map, not the text map. The previous
    // version only looked at the text map, so applying a suggestion to a
    // boolean showed a misleading "no input named X" error.
    if (_boolValues.containsKey(field)) {
      setState(() => _boolValues[field] = value == 'true' || value == '1');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$field = $value')),
      );
      return;
    }

    final ctrl = _textCtrls[field];
    if (ctrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.calcNoInputNamed(field))),
      );
      return;
    }
    setState(() => ctrl.text = value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$field = $value')),
    );
  }

  Future<void> _calculate(CalculatorConfig? config) async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    final inputs = _useSchema && config != null
        ? _collectSchemaInputs(config)
        : _collectLegacyInputs();
    if (inputs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.calcAddInput)),
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
        title: Text(configAsync.when(
          data: (c) => c.label,
          loading: () => widget.slug.replaceAll('-', ' '),
          // The server has no label for us; showing the humanised slug is
          // honest about where the name came from rather than implying the
          // calculator loaded.
          error: (_, __) => widget.slug.replaceAll('-', ' '),
        )),
      ),
      body: configAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorCard(
          message: e.toString(),
          onRetry: () => ref.invalidate(calculatorConfigProvider((domain: widget.domain, slug: widget.slug))),
        ),
        data: (config) {
          // Lazily initialise controllers when config first arrives.
          if (_useSchema == false && config.fields.isNotEmpty) {
            _initFromConfig(config);
          }
          return _buildBody(context, theme, config, calcState);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, CalculatorConfig config, CalcState calcState) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeaderCard(config: config),
            if (config.formulaLatex != null && config.formulaLatex!.isNotEmpty) ...[
              const SizedBox(height: 12),
              FormulaDisplay(latex: config.formulaLatex!),
            ],
            const SizedBox(height: 16),
            if (_useSchema)
              _renderSchemaForm(theme, config, calcState)
            else
              _renderLegacyForm(theme, calcState),
            const SizedBox(height: 12),
            // The assistant endpoint lives inside the authenticated v1 group,
            // so a guest would get a 401 for every question. The panel is
            // hidden rather than offered as a control that cannot work.
            if (_hasSession)
              CalculatorAssistantPanel(
                domain: widget.domain,
                slug: widget.slug,
                name: config.label,
                fields: config.fields
                    .map((f) => <String, dynamic>{
                          'name': f.name,
                          'label': f.label,
                          if (f.unit != null) 'unit': f.unit,
                          'type': f.type,
                        })
                    .toList(),
                currentInputs: _useSchema
                    ? _collectSchemaInputs(config)
                    : _collectLegacyInputs(),
                onApplyValue: _applyAssistantValue,
              ),
            const SizedBox(height: 4),
            FilledButton.icon(
              onPressed: calcState.loading ? null : () => _calculate(config),
              icon: calcState.loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.calculate_rounded),
              label: Text(calcState.loading ? l10n.calcCalculating : l10n.calcCalculateServer),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
            const SizedBox(height: 8),
            if (calcState.error != null) _ErrorCard(message: calcState.error!, fieldErrors: calcState.fieldErrors, onRetry: () => _calculate(config)),
            if (calcState.result != null) ...[
              const SizedBox(height: 12),
              if (calcState.result!.status != null) StatusBadge(result: calcState.result!),
              if (calcState.result!.status != null) const SizedBox(height: 12),
              if (config.stepsInResponse) StepByStepSolution(steps: calcState.result!.steps),
              if (config.stepsInResponse) const SizedBox(height: 12),
              _ResultCard(result: calcState.result!),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _sharing
                    ? null
                    : () => _shareResult(config, calcState),
                icon: _sharing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.share_rounded, size: 18),
                label: Text(l10n.calcShareResult),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => context.go(Uri(
                  path: '/search',
                  queryParameters: {
                    'query': widget.slug.replaceAll('-', ' '),
                  },
                ).toString()),
                icon: const Icon(Icons.school_rounded, size: 18),
                label: Text(l10n.calcPracticeRelated),
              ),
            ],
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => context.go('/calculators/${widget.domain}/${widget.slug}/history'),
              icon: const Icon(Icons.history_rounded),
              label: Text(l10n.calcViewHistory),
            ),
          ],
        ),
      ),
    );
  }

  Widget _renderSchemaForm(ThemeData theme, CalculatorConfig config, CalcState calcState) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.calcInputsLabel(config.label), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...config.fields.map((f) {
          final fieldErr = calcState.fieldErrors?[f.name];
          final err = fieldErr is List
              ? fieldErr.join(', ')
              : fieldErr is String
                  ? fieldErr
                  : null;
          if (f.type == 'boolean') {
            return CalculatorInputField(
              field: f,
              controller: TextEditingController(),
              initialBool: _boolValues[f.name] ?? false,
              onChanged: (v) => setState(() => _boolValues[f.name] = v == 'true'),
            );
          }
          return CalculatorInputField(
            field: f,
            controller: _textCtrls[f.name]!,
            onChanged: (_) => setState(() {}),
            errorText: err,
          );
        }),
      ],
    );
  }

  Widget _renderLegacyForm(ThemeData theme, CalcState calcState) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.calcInputsLegacy, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          l10n.calcNoSchema,
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        ...List.generate(_legacyFields.length, (i) {
          final f = _legacyFields[i];
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
                      labelText: l10n.calcKeyLabel,
                      hintText: l10n.calcKeyExample,
                      errorText: fieldErr is List ? fieldErr.join(', ') : null,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: f.valCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.calcValueLabel,
                      hintText: l10n.calcValueExample,
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                  onPressed: () => setState(() {
                    f.keyCtrl.dispose();
                    f.valCtrl.dispose();
                    _legacyFields.removeAt(i);
                    if (_legacyFields.isEmpty) _legacyFields.add(_LegacyFieldEntry());
                  }),
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () => setState(() => _legacyFields.add(_LegacyFieldEntry())),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(l10n.calcAddField),
        ),
      ],
    );
  }
}

class _LegacyFieldEntry {
  _LegacyFieldEntry()
      : keyCtrl = TextEditingController(),
        valCtrl = TextEditingController();
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
            child: Text(config.domainLabel.toUpperCase(),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.brand, letterSpacing: 0.6)),
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
    final l10n = AppLocalizations.of(context)!;
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
            FilledButton(onPressed: onRetry, child: Text(l10n.retry)),
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
    final l10n = AppLocalizations.of(context)!;
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
              Text(l10n.calcInputsCount(result.inputs.length), style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
