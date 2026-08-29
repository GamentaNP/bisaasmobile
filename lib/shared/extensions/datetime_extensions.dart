import 'package:intl/intl.dart';

extension DateTimeX on DateTime {
  String toShortDate() => DateFormat.yMMMd().format(this);
  String toIso() => toIso8601String();
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  String timeAgo() {
    final diff = DateTime.now().difference(this);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
