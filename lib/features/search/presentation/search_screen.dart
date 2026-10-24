

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../l10n/app_localizations.dart';
import '../data/search_remote_data_source.dart';

final _searchDataSourceProvider = Provider<SearchRemoteDataSource>((ref) {
  return SearchRemoteDataSource(DioClient.instance.dio);
});

final _searchProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, q) async {
  if (q.trim().isEmpty) return [];
  return ref.watch(_searchDataSourceProvider).searchQuestions(q);
});

/// Global search — `GET /quiz/questions?search=...` (server query builder 7.3).
/// [initialQuery] lets other features (e.g. calculator "Practice Questions")
/// deep-link straight into a filtered result set.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({this.initialQuery = '', super.key});
  final String initialQuery;
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.initialQuery);
  late String _q = widget.initialQuery.trim();
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final results = _q.isEmpty ? null : ref.watch(_searchProvider(_q));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.searchTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _ctrl,
              decoration: InputDecoration(hintText: l10n.searchHint, prefixIcon: const Icon(Icons.search_rounded), suffixIcon: IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () => setState(() { _q = ''; _ctrl.clear(); })), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              onSubmitted: (v) => setState(() => _q = v.trim()),
            ),
          ),
          if (_q.isEmpty) Padding(padding: EdgeInsets.all(24), child: Text(l10n.searchTry, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
          if (results != null)
            Expanded(
              child: results.when(
                data: (list) => list.isEmpty ? Center(child: Text(l10n.searchNoResults)) : ListView.separated(padding: const EdgeInsets.all(12), itemCount: list.length, separatorBuilder: (_, __) => SizedBox(height: 8), itemBuilder: (context, i) => Card(child: ListTile(title: Text((list[i]['body'] ?? list[i]['title'] ?? '').toString(), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)), subtitle: Text((list[i]['subject_slug'] ?? '').toString(), style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant))))),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(l10n.searchFailed(e), style: const TextStyle(color: Colors.red, fontSize: 12))),
              ),
            ),
        ],
      ),
    );
  }
}
