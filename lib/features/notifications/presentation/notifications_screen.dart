// ignore_for_file: avoid_dynamic_calls

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/network/api_response.dart';

final _notificationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = DioClient.instance.dio;
  try {
    final res = await dio.get<Map<String, dynamic>>('/notifications');
    final body = res.data!;
    if (body['data'] is List) return (body['data'] as List).cast<Map<String, dynamic>>();
    final env = ApiResponse.fromJson(body, (j) => (j as List?)?.cast<Map<String, dynamic>>() ?? []);
    return env.data ?? [];
  } catch (_) { return []; }
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
            ? const Center(child: Text('No notifications', style: TextStyle(color: Colors.grey)))
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
        error: (e, _) => Center(child: Text('Inbox failed: $e')),
      ),
    );
  }
}
