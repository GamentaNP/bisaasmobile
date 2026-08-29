extension StringX on String {
  String get capitalized => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  String get trimmed => trim();
  bool get isEmail => RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(this);
  String truncate(int max) => length <= max ? this : '${substring(0, max)}…';
}
