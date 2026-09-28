import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import 'controllers/notifications_controller.dart';
import '../domain/notification_item.dart';

/// Notifications inbox — `GET /api/v1/notifications`.
///
/// `data` is a cursor envelope `{items: [...], pagination}` by default, or a
/// bare list with `?pagination=offset`; the controller tolerates both.
///
/// Failures propagate instead of collapsing to `[]`. The previous
/// `catch (_) { return []; }` made a dead inbox look like an empty one, and the
/// screen's `error:` branch was therefore unreachable.
///
/// Tapping a row marks it read (`PUT /notifications/{id}/read`) and the app bar
/// action marks everything read. Without those, the server-side unread badge in
/// `GET /me` could never clear, because nothing in the app ever told the server
/// a notification had been seen.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsControllerProvider);
    final unreadCount = async.value?.where((n) => n.isUnread).length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () => _markAllRead(context, ref),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: async.when(
        data: (list) => list.isEmpty
            ? const Center(
                child: EmptyState(
                  title: 'No notifications',
                  subtitle: 'Nothing new right now.',
                  icon: Icons.notifications_none_rounded,
                ),
              )
            : RefreshIndicator(
                onRefresh: () => ref.refresh(notificationsControllerProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _Tile(
                    item: list[i],
                    onTap: () => _markRead(context, ref, list[i]),
                  ),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          title: 'Could not load notifications',
          message: '$e',
          onRetry: () => ref.invalidate(notificationsControllerProvider),
        ),
      ),
    );
  }

  Future<void> _markRead(BuildContext context, WidgetRef ref, NotificationItem item) async {
    if (!item.isUnread) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(notificationsControllerProvider.notifier).markRead(item.id);
    } on Object {
      // The controller already rolled the row back, so say so rather than
      // letting the notification look like it was cleared.
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not mark that as read. Try again.')),
      );
    }
  }

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(notificationsControllerProvider.notifier).markAllRead();
    } on Object {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not mark everything as read.')),
      );
    }
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.item, required this.onTap});

  final NotificationItem item;
  final VoidCallback onTap;

  static String _day(DateTime? d) {
    if (d == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(d.year, d.month, d.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff > 1 && diff < 7) return '$diff days ago';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final unread = item.isUnread;
    return Card(
      // Unread rows are tinted and the title is bold, so the inbox shows at a
      // glance what still needs attention rather than being a flat list.
      color: unread
          ? AppColors.brand.withValues(alpha: 0.06)
          : Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: unread
              ? AppColors.brand.withValues(alpha: 0.35)
              : Theme.of(context).dividerColor,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          _iconFor(item.type),
          size: 22,
          color: unread ? AppColors.brand : Colors.grey,
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontWeight: unread ? FontWeight.w700 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
        subtitle: item.body.isEmpty
            ? null
            : Text(item.body, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (unread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: const BoxDecoration(
                  color: AppColors.brand,
                  shape: BoxShape.circle,
                ),
              ),
            Text(_day(item.createdAt), style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(String type) {
    final t = type.toLowerCase();
    if (t.contains('streak')) return Icons.local_fire_department_rounded;
    if (t.contains('battle')) return Icons.flash_on_rounded;
    if (t.contains('achievement')) return Icons.emoji_events_rounded;
    if (t.contains('exam') || t.contains('reminder')) return Icons.event_rounded;
    if (t.contains('reward') || t.contains('coin')) return Icons.monetization_on_rounded;
    return Icons.notifications_rounded;
  }
}
