// ignore_for_file: avoid_dynamic_calls

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../controllers/calculator_controller.dart';

/// Catalog browser — `GET /calculators` (cached, public).
/// Groups 232 calculators by domain; search local; tap → dynamic form.
class CalculatorBrowserScreen extends ConsumerStatefulWidget {
  const CalculatorBrowserScreen({super.key});

  @override
  ConsumerState<CalculatorBrowserScreen> createState() => _CalculatorBrowserScreenState();
}

class _CalculatorBrowserScreenState extends ConsumerState<CalculatorBrowserScreen> {
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(calculatorCatalogProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculators'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search 232 calculators…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => setState(() {
                          _query = '';
                          _searchCtrl.clear();
                        }),
                      ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
        ),
      ),
      body: catalogAsync.when(
        data: (catalog) {
          if (catalog.domains.isEmpty) {
            return const Center(child: Text('No calculators published'));
          }
          final total = catalog.totalCalculators;
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(calculatorCatalogProvider),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text(
                      '$total calculators • ${catalog.domains.length} domains • server-authoritative',
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  ),
                ),
                for (final domain in catalog.domains)
                  _DomainSection(
                    domainLabel: domain.label,
                    domainSlug: domain.domain,
                    calculators: _query.isEmpty
                        ? domain.calculators
                        : domain.calculators
                            .where((c) =>
                                c.label.toLowerCase().contains(_query) ||
                                c.slug.toLowerCase().contains(_query) ||
                                c.domain.toLowerCase().contains(_query))
                            .toList(),
                    onTap: (c) => context.push('/calculators/${c.domain}/${c.slug}'),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.wrongRed),
                const SizedBox(height: 12),
                Text('Could not load calculators', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(e.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),
                FilledButton(onPressed: () => ref.invalidate(calculatorCatalogProvider), child: const Text('Retry')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DomainSection extends StatelessWidget {
  const _DomainSection({
    required this.domainLabel,
    required this.domainSlug,
    required this.calculators,
    required this.onTap,
  });

  final String domainLabel;
  final String domainSlug;
  final List<dynamic> calculators;
  final void Function(dynamic) onTap;

  Color _colorFor(String domain) {
    return switch (domain) {
      'civil' => const Color(0xFF0EA5E9),
      'structural' => const Color(0xFF8B5CF6),
      'electrical' => const Color(0xFFEAB308),
      'plumbing' => const Color(0xFF06B6D4),
      'hvac' => const Color(0xFF10B981),
      'fire' => const Color(0xFFEF4444),
      'estimation' => const Color(0xFFF59E0B),
      'medical-gas' => const Color(0xFFEC4899),
      _ => AppColors.brand,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (calculators.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    final color = _colorFor(domainSlug);
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(width: 4, height: 18, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                const SizedBox(width: 8),
                Text(domainLabel, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text('${calculators.length}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final c = calculators[i] as dynamic;
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onTap(c),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                          child: Icon(_iconFor(c.slug as String), size: 18, color: color),
                        ),
                        const Spacer(),
                        Text(c.label as String, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, height: 1.2)),
                        const SizedBox(height: 4),
                        Text('${c.domain as String}/${c.slug as String}', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                      ],
                    ),
                  ),
                );
              },
              childCount: calculators.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.65,
            ),
          ),
        ),
      ],
    );
  }

  IconData _iconFor(String slug) {
    if (slug.contains('beam') || slug.contains('column') || slug.contains('slab')) return Icons.view_in_ar_rounded;
    if (slug.contains('brick') || slug.contains('plaster') || slug.contains('tile')) return Icons.grid_view_rounded;
    if (slug.contains('concrete')) return Icons.foundation_rounded;
    if (slug.contains('cable') || slug.contains('voltage') || slug.contains('power')) return Icons.electrical_services_rounded;
    if (slug.contains('pump') || slug.contains('pipe') || slug.contains('water')) return Icons.water_drop_rounded;
    if (slug.contains('duct') || slug.contains('cooling') || slug.contains('ahu')) return Icons.air_rounded;
    if (slug.contains('sprinkler') || slug.contains('fire') || slug.contains('hydrant')) return Icons.local_fire_department_rounded;
    if (slug.contains('cost') || slug.contains('estimator')) return Icons.request_quote_rounded;
    return Icons.calculate_rounded;
  }
}
