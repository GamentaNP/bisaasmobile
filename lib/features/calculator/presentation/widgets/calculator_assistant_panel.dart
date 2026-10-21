import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/errors/error_handler.dart';
import '../../domain/entities/calculator_assistant.dart';
import '../controllers/calculator_controller.dart';
import '../../../../l10n/app_localizations.dart';

/// The calculator assistant panel.
///
/// `POST /api/v1/ai/calculator-assist` — the non-streaming endpoint the
/// mobile client is supposed to use (`MOBILE_API_INTEGRATION_GUIDE.md` §6).
///
/// The assistant is **advisory**. It proposes values for the calculator's
/// fields and the user applies them; the client never fills a field on the
/// assistant's word, and it never computes anything.
class CalculatorAssistantPanel extends ConsumerStatefulWidget {
  const CalculatorAssistantPanel({
    super.key,
    required this.domain,
    required this.slug,
    required this.name,
    required this.fields,
    required this.currentInputs,
    this.onApplyValue,
  });

  final String domain;
  final String slug;
  final String name;

  /// The calculator's own field descriptors, so the server knows what the
  /// form looks like.
  final List<Map<String, dynamic>> fields;

  /// What the user has typed so far.
  final Map<String, dynamic> currentInputs;

  /// Called when the user accepts a proposed value.
  final void Function(String field, String value)? onApplyValue;

  @override
  ConsumerState<CalculatorAssistantPanel> createState() =>
      _CalculatorAssistantPanelState();
}

class _CalculatorAssistantPanelState
    extends ConsumerState<CalculatorAssistantPanel> {
  final _controller = TextEditingController();
  bool _open = false;
  bool _loading = false;
  String? _error;
  CalculatorAssistant? _assistant;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    final message = _controller.text.trim();
    if (message.length < 3) {
      setState(() => _error = 'Describe what you want to calculate.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final assistant = await ref.read(calculatorRepositoryProvider).assist(
            message: message,
            domain: widget.domain,
            slug: widget.slug,
            name: widget.name,
            fields: widget.fields,
            currentInputs: widget.currentInputs,
          );
      if (mounted) setState(() => _assistant = assistant);
    } on Object catch (e) {
      if (mounted) {
        setState(() => _error = ErrorHandler.handle(e).message);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final assistant = _assistant;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _open = !_open),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      size: 18, color: AppColors.brand),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.calcAssistantTitle,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Icon(
                    _open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    size: 18,
                  ),
                ],
              ),
            ),
            if (_open) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _controller,
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(
                  hintText:
                      l10n.calcAssistantExample,
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: _loading ? null : _ask,
                    icon: _loading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded, size: 16),
                    label: Text(l10n.calcAsk),
                  ),
                  const Spacer(),
                  if (assistant != null)
                    Text(
                      assistant.model == null
                          ? ''
                          : l10n.calcVia(assistant.model!),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.wrongRedBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.wrongRed.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(fontSize: 11, color: AppColors.wrongRed),
                  ),
                ),
              ],
              if (assistant != null) ...[
                const SizedBox(height: 12),
                if (assistant.intent.isNotEmpty)
                  Text(
                    assistant.intent,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (assistant.explanation.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    assistant.explanation,
                    style: const TextStyle(fontSize: 12, height: 1.4),
                  ),
                ],
                if (assistant.hasFieldMappings) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.calcAssistantSuggested,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  ...assistant.fieldMappings
                      .where((m) => m.hasValue)
                      .map(
                        (m) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      m.field,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (m.sourceText != null)
                                      Text(
                                        m.sourceText!,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                m.displayValue +
                                    (m.unit == null ? '' : ' ${m.unit}'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.brand,
                                ),
                              ),
                              const SizedBox(width: 6),
                              TextButton(
                                onPressed: widget.onApplyValue == null
                                    ? null
                                    : () => widget.onApplyValue!(
                                          m.field,
                                          m.displayValue,
                                        ),
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(0, 30),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                ),
                                child: Text(l10n.calcApply,
                                    style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
                if (assistant.followUpQuestions.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    l10n.calcAssistantAlso,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  ...assistant.followUpQuestions.map(
                    (q) => TextButton(
                      onPressed: () {
                        _controller.text = q;
                        _ask();
                      },
                      style: TextButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        q,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 6),
              Text(
                l10n.calcAssistantDisclaimer,
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
