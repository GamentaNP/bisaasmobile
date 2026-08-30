import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/calculator.dart';

/// Dispatches to the correct input widget based on [CalculatorField.type].
///
/// - `number`  → [TextFormField] with numeric keyboard, unit suffix,
///              min/max/precision validation.
/// - `select`  → [DropdownButtonFormField] from [CalculatorField.options].
/// - `boolean` → [SwitchListTile].
/// - `text`    → plain [TextFormField].
class CalculatorInputField extends StatelessWidget {
  const CalculatorInputField({
    required this.field,
    required this.controller,
    required this.onChanged,
    this.errorText,
    this.initialBool,
    super.key,
  });

  final CalculatorField field;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? errorText;

  /// Only used for `type == 'boolean'`; the text controller is ignored.
  final bool? initialBool;

  @override
  Widget build(BuildContext context) {
    switch (field.type) {
      case 'select':
        return _SelectField(field: field, controller: controller, onChanged: onChanged, errorText: errorText);
      case 'boolean':
        return _BooleanField(field: field, initialValue: initialBool ?? false, onChanged: onChanged);
      case 'text':
        return _TextField(field: field, controller: controller, onChanged: onChanged, errorText: errorText);
      case 'number':
      default:
        return _NumberField(field: field, controller: controller, onChanged: onChanged, errorText: errorText);
    }
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.field, required this.controller, required this.onChanged, this.errorText});
  final CalculatorField field;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d.\-eE]')),
        ],
        textInputAction: TextInputAction.next,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: field.label + (field.required ? ' *' : ''),
          hintText: field.helpText,
          suffixText: field.unit,
          errorText: errorText,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        validator: (v) {
          if (field.required && (v == null || v.trim().isEmpty)) {
            return '${field.label} is required';
          }
          if (v == null || v.trim().isEmpty) return null;
          final n = num.tryParse(v.trim());
          if (n == null) return 'Must be a number';
          if (field.min != null && n < field.min!) return 'Min ${field.min}';
          if (field.max != null && n > field.max!) return 'Max ${field.max}';
          return null;
        },
      ),
    );
  }
}

class _SelectField extends StatelessWidget {
  const _SelectField({required this.field, required this.controller, required this.onChanged, this.errorText});
  final CalculatorField field;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: controller.text.isNotEmpty ? controller.text : null,
        decoration: InputDecoration(
          labelText: field.label + (field.required ? ' *' : ''),
          hintText: field.helpText,
          errorText: errorText,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        items: field.options
            .map((o) => DropdownMenuItem<String>(value: o.value, child: Text(o.label)))
            .toList(),
        onChanged: (v) {
          if (v == null) return;
          controller.text = v;
          onChanged(v);
        },
        validator: (v) {
          if (field.required && (v == null || v.isEmpty)) {
            return 'Select ${field.label}';
          }
          return null;
        },
      ),
    );
  }
}

class _BooleanField extends StatelessWidget {
  const _BooleanField({required this.field, required this.initialValue, required this.onChanged});
  final CalculatorField field;
  final bool initialValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile.adaptive(
        value: initialValue,
        onChanged: (v) => onChanged(v ? 'true' : 'false'),
        title: Text(field.label + (field.required ? ' *' : '')),
        subtitle: field.helpText != null ? Text(field.helpText!) : null,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({required this.field, required this.controller, required this.onChanged, this.errorText});
  final CalculatorField field;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        textInputAction: TextInputAction.next,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: field.label + (field.required ? ' *' : ''),
          hintText: field.helpText,
          errorText: errorText,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        validator: (v) {
          if (field.required && (v == null || v.trim().isEmpty)) {
            return '${field.label} is required';
          }
          return null;
        },
      ),
    );
  }
}
