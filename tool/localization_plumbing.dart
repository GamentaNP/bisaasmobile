// Finds the places that need the `l10n` local.
//
// `tool/apply_localization.py` replaces the hardcoded literals with
// `l10n.<key>` references. Each reference then needs two things: the import
// of the generated localisations, and a `l10n` binding in scope.
//
// This tool reports, for every file that uses `l10n`, which declaration each
// reference sits inside, where that declaration's body starts, and whether a
// `BuildContext` is in scope there:
//
//   * a `BuildContext context` parameter, or
//   * the enclosing class is a `State` (whose `context` getter is in scope).
//
// Declarations without a context — services, controllers, data sources — are
// reported separately, because those need the context-free lookup instead.

import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

class _Use {
  const _Use(
    this.file,
    this.kind,
    this.name,
    this.insertOffset,
    this.hasContext, [
    this.bodyKind = 'block',
  ]);
  final String file;
  final String kind;
  final String name;
  final int insertOffset;
  final bool hasContext;

  /// `block` or `expression` — an expression body has nowhere to prepend a
  /// local to, so it has to be converted first.
  final String bodyKind;
}

class _Finder extends RecursiveAstVisitor<void> {
  _Finder(this.file, this.uses);

  final String file;
  final List<_Use> uses;

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _check(node, node.name.lexeme, node.body, node.parameters, node.returnType);
    super.visitMethodDeclaration(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _check(node, node.name.lexeme, node.functionExpression.body, node.functionExpression.parameters, null);
    super.visitFunctionDeclaration(node);
  }

  void _check(
    AstNode node,
    String name,
    FunctionBody? body,
    FormalParameterList? parameters,
    TypeAnnotation? returnType,
  ) {
    if (body == null) return;
    final finder = _L10nFinder();
    body.accept(finder);
    if (!finder.found) return;

    final hasContextParam = parameters?.parameters
            .where((p) => p.name?.lexeme == 'context')
            .isNotEmpty ??
        false;
    final isState = _enclosingClassIsState(node);

    int insertOffset;
    String? bodyKind;
    if (body is BlockFunctionBody) {
      // `Token.end` is the offset of the token itself in analyzer 7+, so the
      // insertion point is one past the opening brace.
      insertOffset = body.block.leftBracket.offset + 1;
      bodyKind = 'block';
    } else if (body is ExpressionFunctionBody) {
      // `=> expression` — there is no block to prepend to, so the caller has
      // to convert it or fall back to an inline lookup.
      insertOffset = body.expression.offset;
      bodyKind = 'expression';
    } else {
      return;
    }

    uses.add(
      _Use(
        file,
        node is MethodDeclaration ? 'method' : 'function',
        name,
        insertOffset,
        hasContextParam || isState,
        bodyKind,
      ),
    );
  }

  bool _enclosingClassIsState(AstNode node) {
    AstNode? current = node;
    while (current != null) {
      if (current is ClassDeclaration) {
        final superclass = current.extendsClause?.superclass;
        return superclass != null && superclass.name.lexeme.endsWith('State');
      }
      current = current.parent;
    }
    return false;
  }
}

class _L10nFinder extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == 'l10n') found = true;
    super.visitSimpleIdentifier(node);
  }
}

Future<void> main(List<String> args) async {
  final separator = Platform.pathSeparator;
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.contains('${separator}l10n$separator'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final uses = <_Use>[];
  for (final file in files) {
    final source = file.readAsStringSync();
    if (!source.contains('l10n.')) continue;
    final result = parseString(
      content: source,
      path: file.path,
      throwIfDiagnostics: false,
    );
    final finder = _Finder(file.path.replaceAll('\\', '/'), uses);
    result.unit.accept(finder);
  }

  final byFile = <String, List<_Use>>{};
  for (final use in uses) {
    byFile.putIfAbsent(use.file, () => <_Use>[]).add(use);
  }

  for (final entry in byFile.entries) {
    stdout.writeln(entry.key);
    for (final use in entry.value) {
      stdout.writeln(
        '    ${use.kind} ${use.name}  context=${use.hasContext}  '
        'at=${use.insertOffset}  body=${use.bodyKind}',
      );

    }
  }
  stdout.writeln('--- ${byFile.length} files, ${uses.length} declarations ---');
}
