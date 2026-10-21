// Measures how much of the user-facing interface is actually translated.
//
// The language picker is a promise: a user who switches to Nepali must get a
// Nepali interface. The seeded registry and the ARB directory are checked by
// `test/app/language_honesty_test.dart`, but that only proves an ARB file
// *exists* — it says nothing about how much of the app it covers. An ARB with
// twenty keys and an interface with six hundred strings satisfies that test
// perfectly while still handing an English screen to a Nepali reader.
//
// This tool measures the real thing: it parses every file under `lib/` with the
// Dart analyzer, finds the string literals that reach the user, and reports
// which of them come from the ARB and which are hardcoded English.
//
//   dart run tool/localization_coverage.dart            # summary
//   dart run tool/localization_coverage.dart --verbose  # every hit, per file
//   dart run tool/localization_coverage.dart --keys     # the distinct literals
//
// The output is what `test/app/localization_coverage_test.dart` asserts
// against, so the budget cannot silently grow.

import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// Widgets whose first positional argument is the visible text.
const _positionalTextWidgets = <String>{
  'Text',
  'SelectableText',
  'SnackBar',
  'Tooltip',
};

/// Named parameters whose value is the visible text.
///
/// The exact list matters less than the shape: screens in this codebase pass
/// their copy to local helper widgets (`_Row(label: …)`, `_HubTile(title: …)`,
/// `_SettingTile(subtitle: …)`), so a fixed list of Material parameter names
/// misses most of the text. The pattern therefore also matches any parameter
/// whose name ends in a text-ish word, which catches the helpers.
final _namedTextParams = <String>{
  'label',
  'title',
  'subtitle',
  'hintText',
  'helperText',
  'tooltip',
  'semanticLabel',
  'errorText',
  'prefixText',
  'suffixText',
  'text',
  'message',
  'content',
  'placeholder',
  'cancelText',
  'okButtonLabel',
  'closeButtonLabel',
  'hint',
  'description',
  'actionLabel',
  'emptyText',
  'buttonLabel',
  'confirmLabel',
  'dismissLabel',
  'header',
  'caption',
  'body',
  'emptyLabel',
  'primaryLabel',
  'secondaryLabel',
  'actionText',
  'supporting',
};

final _textParamPattern = RegExp(
  '(label|title|subtitle|text|message|hint|description|tooltip|caption|header|'
  r'placeholder|empty)$',
  caseSensitive: false,
);

bool _isTextParam(String label) =>
    _namedTextParams.contains(label) || _textParamPattern.hasMatch(label);

/// A letter, in any of the scripts this app ships. A literal without one
/// cannot be translated: it is a number, a separator, a unit or a symbol
/// (`'12/20'`, `'•'`, `'+50 XP'` is not one of these but `'${n} / ${m}'` is).
/// Requiring a letter keeps the measurement honest — otherwise a screen full
/// of counters would look like untranslated copy.
final _hasLetter = RegExp(r'[A-Za-z\u0900-\u097F\u0600-\u06FF]');

class Hit {
  const Hit(
    this.file,
    this.line,
    this.offset,
    this.length,
    this.text,
    this.kind, {
    this.constOffsets = const <int>[],
    this.interpolations = const <String>[],
  });

  final String file;
  final int line;

  /// Byte offset of the string literal in the source file.
  final int offset;

  /// Length of the string literal in the source file.
  final int length;

  final String text;
  final String kind;

  /// Offsets of the `const` keywords of the const constructions the literal
  /// sits inside, innermost first. A literal that becomes `l10n.someKey` can
  /// no longer sit inside a const expression, so every keyword in the chain
  /// has to go with it.
  final List<int> constOffsets;

  /// The interpolated expressions of the literal, in order. A generated
  /// message with placeholders is a *method*, not a getter, so the rewritten
  /// call needs the arguments.
  final List<String> interpolations;

  @override
  String toString() => '$file:$line  [$kind]  $text';
}

/// The visible text of a string literal, with interpolations collapsed to
/// `{…}` so that two literals differing only in a variable read as one string.
String? visibleText(Expression expression) {
  if (expression is SimpleStringLiteral) return expression.stringValue;
  if (expression is StringInterpolation) {
    final buffer = StringBuffer();
    for (final element in expression.elements) {
      if (element is InterpolationString) {
        buffer.write(element.value);
      } else if (element is InterpolationExpression) {
        buffer.write('{…}');
      }
    }
    return buffer.toString();
  }
  if (expression is AdjacentStrings) {
    final buffer = StringBuffer();
    for (final string in expression.strings) {
      final value = visibleText(string);
      if (value == null) return null;
      buffer.write(value);
    }
    return buffer.toString();
  }
  return null;
}

class _Visitor extends RecursiveAstVisitor<void> {
  _Visitor(this.file, this.lineOf);

  final String file;
  final int Function(int offset) lineOf;
  final List<Hit> hits = [];

  /// The `const` keyword offsets of the const constructions currently being
  /// visited, innermost last. A literal inside them cannot stay const.
  final List<int> _constStack = <int>[];

  void _record(Expression expression, String kind) {
    final source = expression.toSource();
    // Anything that reads from the generated localisations is already
    // translated; anything else is English in the source.
    if (source.contains('l10n.') || source.contains('AppLocalizations')) return;
    final value = visibleText(expression);
    if (value == null || value.trim().isEmpty) return;
    if (!_hasLetter.hasMatch(value)) return;
    hits.add(
      Hit(
        file,
        lineOf(expression.offset),
        expression.offset,
        expression.length,
        value.trim(),
        kind,
        constOffsets: List<int>.of(_constStack).reversed.toList(),
        interpolations: interpolationSources(expression),
      ),
    );
  }

  void _scanArguments(ArgumentList arguments) {
    for (final argument in arguments.arguments) {
      if (argument is NamedArgument) {
        final label = argument.name.lexeme;
        if (!_isTextParam(label)) continue;
        if (argument.argumentExpression is StringLiteral) {
          _record(argument.argumentExpression, 'named:$label');
        } else {
          _recordConditional(argument.argumentExpression, 'named:$label');
        }
      }
    }
  }

  /// The two branches of a `cond ? 'a' : 'b'` are both user-facing.
  void _recordConditional(Object? argument, String kind) {
    if (argument is! ConditionalExpression) return;
    for (final branch in [argument.thenExpression, argument.elseExpression]) {
      if (branch is StringLiteral) {
        _record(branch, kind);
      }
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;
    if (_positionalTextWidgets.contains(name)) {
      for (final argument in node.argumentList.arguments) {
        if (argument is StringLiteral) {
          _record(argument, 'positional:$name');
        } else {
          _recordConditional(argument, 'positional:$name');
        }
      }
    }
    _scanArguments(node.argumentList);
    super.visitMethodInvocation(node);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    // `const [ … ]` — the list is a constant expression, so a getter call
    // inside it is not allowed.
    final constOffset = node.constKeyword?.offset;
    if (constOffset != null) _constStack.add(constOffset);
    super.visitListLiteral(node);
    if (constOffset != null) _constStack.removeLast();
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    final constOffset = node.constKeyword?.offset;
    if (constOffset != null) _constStack.add(constOffset);
    super.visitSetOrMapLiteral(node);
    if (constOffset != null) _constStack.removeLast();
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    // `const Text('…')` and friends. `NamedType.name` is a `Token` in analyzer
    // 7+, so the lexeme has to be taken off it.
    final typeName = node.constructorName.type.name.lexeme;
    final constOffset = node.keyword?.offset;
    if (constOffset != null) _constStack.add(constOffset);
    if (_positionalTextWidgets.contains(typeName)) {
      for (final argument in node.argumentList.arguments) {
        if (argument is StringLiteral) {
          _record(argument, 'positional:$typeName');
        }
      }
    }
    _scanArguments(node.argumentList);
    super.visitInstanceCreationExpression(node);
    if (constOffset != null) _constStack.removeLast();
  }
}

/// The interpolated expressions of a string literal, in order.
///
/// Adjacent string literals — `'${a} of ${b} ' 'drilled'` — are one string
/// in the source, so their interpolations have to be collected together.
List<String> interpolationSources(Expression expression) {
  if (expression is AdjacentStrings) {
    final sources = <String>[];
    for (final part in expression.strings) {
      sources.addAll(interpolationSources(part));
    }
    return sources;
  }
  if (expression is! StringInterpolation) return const <String>[];
  final sources = <String>[];
  for (final element in expression.elements) {
    if (element is InterpolationExpression) {
      sources.add(element.expression.toSource());
    }
  }
  return sources;
}

Future<List<Hit>> collectHits() async {
  final hits = <Hit>[];
  final separator = Platform.pathSeparator;
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      // The generated localisations are the translations themselves; counting
      // them would be counting the answer.
      .where((f) => !f.path.contains('${separator}l10n$separator'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final source = file.readAsStringSync();
    final result = parseString(
      content: source,
      path: file.path,
      throwIfDiagnostics: false,
    );
    final lineInfo = result.lineInfo;
    final visitor = _Visitor(
      file.path.replaceAll('\\', '/'),
      (offset) => lineInfo.getLocation(offset).lineNumber,
    );
    result.unit.accept(visitor);
    hits.addAll(visitor.hits);
  }
  return hits;
}

Future<void> main(List<String> args) async {
  final verbose = args.contains('--verbose');
  final keysOnly = args.contains('--keys');
  final asJson = args.contains('--json');

  // `--file <substring>` narrows the report to matching paths, so the strings
  // of one screen can be listed without the noise of the whole app.
  String? fileFilter;
  final fileIndex = args.indexOf('--file');
  if (fileIndex != -1 && fileIndex + 1 < args.length) {
    fileFilter = args[fileIndex + 1];
  }

  var hits = await collectHits();
  final filter = fileFilter;
  if (filter != null) {
    hits = hits.where((h) => h.file.contains(filter)).toList();
  }

  if (asJson) {
    final payload = [
      for (final hit in hits)
        {
          'file': hit.file,
          'line': hit.line,
          'offset': hit.offset,
          'length': hit.length,
          'text': hit.text,
          'kind': hit.kind,
          'constOffsets': hit.constOffsets,
          'interpolations': hit.interpolations,
        },
    ];
    stdout.write(const JsonEncoder.withIndent('  ').convert(payload));
    return;
  }

  if (keysOnly) {
    final unique = <String>{};
    for (final hit in hits) {
      unique.add(hit.text);
    }
    final sorted = unique.toList()..sort();
    sorted.forEach(stdout.writeln);
    stdout.writeln('--- ${sorted.length} distinct strings ---');
    return;
  }

  final byFile = <String, List<Hit>>{};
  for (final hit in hits) {
    byFile.putIfAbsent(hit.file, () => <Hit>[]).add(hit);
  }

  final rows = byFile.entries.toList()
    ..sort((a, b) => b.value.length.compareTo(a.value.length));

  stdout.writeln('Hardcoded user-facing strings: ${hits.length}');
  stdout.writeln('Files affected: ${rows.length}');
  stdout.writeln('');

  for (final row in rows) {
    stdout.writeln('${row.value.length.toString().padLeft(4)}  ${row.key}');
    if (verbose) {
      for (final hit in row.value) {
        stdout.writeln('        ${hit.line}: ${hit.text}');
      }
    }
  }
}
