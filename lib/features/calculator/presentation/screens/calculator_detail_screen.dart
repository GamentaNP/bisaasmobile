import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/calculator.dart';
import '../controllers/calculator_controller.dart';
import '../widgets/calculator_input_field.dart';
import '../widgets/formula_display.dart';
import '../widgets/status_badge.dart';
import '../widgets/step_by_step_solution.dart';

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

  Future<void> _calculate(CalculatorConfig? config) async {
    if (!_formKey.currentState!.validate()) return;
    final inputs = _useSchema && config != null
        ? _collectSchemaInputs(config)
        : _collectLegacyInputs();
    if (inputs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one input')),
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
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: calcState.loading ? null : () => _calculate(config),
              icon: calcState.loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.calculate_rounded),
              label: Text(calcState.loading ? 'Calculating…' : 'Calculate (server)'),
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
                onPressed: () => context.push(Uri(
                  path: '/search',
                  queryParameters: {
                    'query': widget.slug.replaceAll('-', ' '),
                  },
                ).toString()),
                icon: const Icon(Icons.school_rounded, size: 18),
                label: const Text('Practice related questions'),
              ),
            ],
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => context.push('/calculators/${widget.domain}/${widget.slug}/history'),
              icon: const Icon(Icons.history_rounded),
              label: const Text('View history'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _renderSchemaForm(ThemeData theme, CalculatorConfig config, CalcState calcState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Inputs · ${config.label}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Inputs (legacy)', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'Server did not return a field schema. Falling back to generic key/value editor.',
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
                      labelText: 'key',
                      hintText: 'e.g. length',
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
          label: const Text('Add field'),
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
