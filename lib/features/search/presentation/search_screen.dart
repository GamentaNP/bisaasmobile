// ignore_for_file: avoid_dynamic_calls

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/network/api_response.dart';

final _searchProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, q) async {
  if (q.trim().isEmpty) return [];
  final dio = DioClient.instance.dio;
  final res = await dio.get<Map<String, dynamic>>('/quiz/questions', queryParameters: {'search': q, 'per_page': 10});
  final body = res.data!;
  if (body['data'] is List) return (body['data'] as List).cast<Map<String, dynamic>>();
  final env = ApiResponse.fromJson(body, (j) => (j as List?)?.cast<Map<String, dynamic>>() ?? []);
  return env.data ?? [];
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
    final results = _q.isEmpty ? null : ref.watch(_searchProvider(_q));
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _ctrl,
              decoration: InputDecoration(hintText: 'Search questions, calculators, courses…', prefixIcon: const Icon(Icons.search_rounded), suffixIcon: IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () => setState(() { _q = ''; _ctrl.clear(); })), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              onSubmitted: (v) => setState(() => _q = v.trim()),
            ),
          ),
          if (_q.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('Try: levelling, RCC, Bernoulli', style: TextStyle(color: Colors.grey))),
          if (results != null)
            Expanded(
              child: results.when(
                data: (list) => list.isEmpty ? const Center(child: Text('No results')) : ListView.separated(padding: const EdgeInsets.all(12), itemCount: list.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (context, i) => Card(child: ListTile(title: Text((list[i]['body'] ?? list[i]['title'] ?? '').toString(), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)), subtitle: Text((list[i]['subject_slug'] ?? '').toString(), style: const TextStyle(fontSize: 11, color: Colors.grey))))),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Search failed: $e', style: const TextStyle(color: Colors.red, fontSize: 12))),
              ),
            ),
        ],
      ),
    );
  }
}
