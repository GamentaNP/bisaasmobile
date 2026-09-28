import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/locale_controller.dart';
import '../../../../app/theme/script_fonts.dart';
import '../../domain/entities/syllabus.dart';
import '../controllers/syllabus_controller.dart';

/// The syllabus tree for one version.
///
/// The server returns the whole nested graph in one call, cached for 24h keyed
/// on `structure_hash`, so expansion is pure local state — no request per tap.
class SyllabusTreeScreen extends ConsumerStatefulWidget {
  const SyllabusTreeScreen({required this.versionPublicId, super.key});

  /// The version's `public_id`. The route binds on this, not on `version_code`.
  final String versionPublicId;

  @override
  ConsumerState<SyllabusTreeScreen> createState() => _SyllabusTreeScreenState();
}

class _SyllabusTreeScreenState extends ConsumerState<SyllabusTreeScreen> {
  /// Node ids the user has opened, so expansion survives a rebuild and a
  /// refresh. Keyed on id because two versions may share a code.
  final Set<int> _expanded = <int>{};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(syllabusTreeControllerProvider(widget.versionPublicId));
    final notifier = ref.read(syllabusTreeControllerProvider(widget.versionPublicId).notifier);
    final preferNative = _preferNative(ref);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Syllabus'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: notifier.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: state.isLoading && state.tree == null
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.tree == null
              ? _ErrorView(message: state.error!, onRetry: () => notifier.load(widget.versionPublicId, force: true))
              : _body(context, state, preferNative),
      bottomNavigationBar: _SearchBar(
        onChanged: (v) => setState(() => _query = v),
      ),
    );
  }

  bool _preferNative(WidgetRef ref) {
    final code = ref.watch(localeProvider)?.languageCode;
    return code != null && code != 'en';
  }

  Widget _body(BuildContext context, SyllabusTreeState state, bool preferNative) {
    final tree = state.tree;
    if (tree == null || tree.isEmpty) {
      return const _EmptyView(message: 'This syllabus has no published nodes yet.');
    }

    final matches = _query.trim().isEmpty ? null : tree.search(_query);

    if (matches != null) {
      if (matches.isEmpty) {
        return _EmptyView(message: 'No topic matches "$_query".');
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: matches.length,
        itemBuilder: (context, i) => _NodeRow(
          node: matches[i],
          expanded: true,
          onToggle: null,
          onOpen: () => _openQuestions(matches[i]),
          preferNative: preferNative,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _Summary(tree: tree),
        if (state.blueprints.isNotEmpty) _BlueprintPanel(blueprints: state.blueprints),
        const Divider(height: 1),
        for (final node in tree.nodes)
          _NodeRow(
            node: node,
            expanded: _expanded.contains(node.id),
            onToggle: () => setState(() {
              if (!_expanded.remove(node.id)) _expanded.add(node.id);
            }),
            onOpen: () => _openQuestions(node),
            preferNative: preferNative,
          ),
      ],
    );
  }

  /// Hands the node to the existing quiz corpus route. Node questions are served
  /// by the server with answer keys stripped, so this stays a read.
  void _openQuestions(SyllabusNode node) {
    context.push('/quiz/browse?syllabus_node_id=${node.id}');
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.tree});

  final SyllabusTree tree;

  @override
  Widget build(BuildContext context) {
    // The version card advertises the full topic count while a depth-scoped tree
    // request returns only what it fetched, so the label says which it is rather
    // than letting the two numbers appear to contradict each other.
    final topicsLabel = tree.depthLimited ? 'topics loaded' : 'topics';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          _Stat(value: '${tree.nodeCount}', label: topicsLabel),
          const SizedBox(width: 24),
          _Stat(value: '${tree.examinableNodeCount}', label: 'examinable'),
          const SizedBox(width: 24),
          _Stat(value: '${tree.totalQuestionCount}', label: 'questions'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: theme.textTheme.titleLarge),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

/// Paper blueprints: how the marks are actually distributed.
///
/// This is the authority on marks, which is why `marks_hint` on a node is
/// advisory. Two things this renders honestly rather than smoothing over: a
/// section with no letter (the unnamed trailing "Part II") keeps its name instead
/// of rendering a blank chip, and a paper whose sections do not sum to its
/// declared total says so.
class _BlueprintPanel extends StatelessWidget {
  const _BlueprintPanel({required this.blueprints});

  final List<SyllabusBlueprint> blueprints;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExpansionTile(
      title: Text('Paper blueprint', style: theme.textTheme.titleSmall),
      subtitle: Text(
        blueprints.length == 1
            ? blueprints.first.name
            : '${blueprints.length} papers',
        style: theme.textTheme.labelSmall,
      ),
      children: [
        for (final paper in blueprints)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _PaperBody(paper: paper),
          ),
      ],
    );
  }
}

class _PaperBody extends StatelessWidget {
  const _PaperBody({required this.paper});

  final SyllabusBlueprint paper;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_num(paper.totalMarks)} marks · ${paper.totalQuestions} questions',
          style: theme.textTheme.bodyMedium,
        ),
        if (paper.negativeMarkingMode != null && paper.negativeMarkingMode != 'none')
          Text('Negative marking: ${paper.negativeMarkingMode}', style: theme.textTheme.labelSmall),
        const SizedBox(height: 8),
        for (final s in paper.sections)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                // A null section_code is the unnamed trailing part, so the name
                // leads rather than rendering as an empty " · Part II".
                Expanded(
                  child: Text(
                    s.sectionCode == null ? s.name : '${s.sectionCode} · ${s.name}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                Text('${_num(s.marks)} marks', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        if (!paper.marksReconcile)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'The section marks do not add up to the paper total. Treat this '
              'blueprint as unverified.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
            ),
          ),
        if (paper.rules.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Covers ${paper.rules.length} syllabus topics', style: theme.textTheme.labelSmall),
        ],
      ],
    );
  }
}

/// Whole numbers lose the trailing `.0` that Dart prints for a double.
String _num(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

class _NodeRow extends StatelessWidget {
  const _NodeRow({
    required this.node,
    required this.expanded,
    required this.onOpen,
    required this.preferNative,
    this.onToggle,
  });

  final SyllabusNode node;
  final bool expanded;
  final VoidCallback? onToggle;
  final VoidCallback onOpen;
  final bool preferNative;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _title(preferNative);
    final indent = 16.0 + (node.depth.clamp(0, 5) * 14);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: EdgeInsets.fromLTRB(indent, 10, 16, 10),
            child: Row(
              children: [
                if (node.hasChildren)
                  Icon(
                    expanded ? Icons.expand_more : Icons.chevron_right,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  )
                else
                  const SizedBox(width: 20),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: ScriptFonts.forText(
                          theme.textTheme.bodyLarge ?? const TextStyle(),
                          title,
                        ),
                      ),
                      if (_meta.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            _meta,
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                    ],
                  ),
                ),
                if (node.questionCount > 0)
                  TextButton(
                    onPressed: onOpen,
                    child: const Text('Practice'),
                  ),
              ],
            ),
          ),
        ),
        if (expanded)
          for (final child in node.children)
            _NodeRow(
              node: child,
              expanded: false,
              onToggle: null,
              onOpen: onOpen,
              preferNative: preferNative,
            ),
      ],
    );
  }

  String _title(bool preferNative) {
    if (preferNative && node.titleNe != null && node.titleNe!.trim().isNotEmpty) {
      return node.titleNe!;
    }
    return node.title;
  }

  /// Counts the server computed. Never recomputed locally: a client's own
  /// coverage arithmetic would be a guess presented as fact.
  String get _meta {
    final parts = <String>[];
    if (node.nodeCode != null) parts.add(node.nodeCode!);
    if (node.questionCount > 0) parts.add('${node.questionCount} Q');
    if (node.materialCount > 0) parts.add('${node.materialCount} files');
    final marks = node.marksLabel;
    if (marks != null) parts.add('$marks marks');
    if (node.isExaminable) parts.add('examinable');
    return parts.join('  ·  ');
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: TextField(
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search topics',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ),
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
  const _EmptyView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 48),
        Icon(Icons.account_tree_outlined, size: 48, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center),
      ],
    );
  }
}
