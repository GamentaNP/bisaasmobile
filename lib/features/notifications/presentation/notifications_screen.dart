// ignore_for_file: avoid_dynamic_calls

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/network/api_response.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';

/// Notifications inbox — `GET /api/v1/notifications`.
///
/// `data` is a Map `{items: [...], pagination}` (not a bare list).
///
/// Failures propagate instead of collapsing to `[]`. The previous
/// `catch (_) { return []; }` made a dead inbox look like an empty one, and the
/// screen's `error:` branch was therefore unreachable.
final _notificationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = DioClient.instance.dio;
  final res = await dio.get<Map<String, dynamic>>('/notifications');
  final body = res.data;
  if (body == null) return const [];
  final data = body['data'];
  if (data is Map<String, dynamic>) {
    final items = data['items'];
    if (items is List) return items.cast<Map<String, dynamic>>();
    return const [];
  }
  if (data is List) return data.cast<Map<String, dynamic>>();
  final env = ApiResponse.fromJson(body, (j) => (j as List?)?.cast<Map<String, dynamic>>() ?? []);
  return env.data ?? const [];
});

/// Notifications inbox — deep links to payload route.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_notificationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: async.when(
        data: (list) => list.isEmpty
            ? const Center(
                child: EmptyState(
                  title: 'No notifications',
                  subtitle: 'Nothing new right now.',
                  icon: Icons.notifications_none_rounded,
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final m = list[i];
                  return Card(child: ListTile(leading: const Icon(Icons.notifications_rounded), title: Text((m['title'] ?? m['data']?['title'] ?? 'Notification').toString(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)), subtitle: Text((m['body'] ?? m['data']?['body'] ?? '').toString(), style: const TextStyle(fontSize: 12, color: Colors.grey)), trailing: Text((m['created_at'] ?? '').toString().split('T').first, style: const TextStyle(fontSize: 10, color: Colors.grey))));
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          title: 'Could not load notifications',
          message: '$e',
          onRetry: () => ref.invalidate(_notificationsProvider),
        ),
      ),
    );
  }
}
