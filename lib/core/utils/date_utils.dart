import 'package:intl/intl.dart';

abstract final class AppDateUtils {
  static String formatShort(DateTime d) => DateFormat.yMMMd().format(d);
  static String formatIso(DateTime d) => d.toIso8601String();
  static String timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
