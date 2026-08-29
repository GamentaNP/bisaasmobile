abstract final class Validators {
  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email required';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Invalid email';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password required';
    if (v.length < 8) return 'Min 8 characters';
    return null;
  }

  static String? requiredField(String? v, String label) {
    if (v == null || v.trim().isEmpty) return '$label required';
    return null;
  }
}
