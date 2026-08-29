abstract final class StringUtils {
  static String capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
  static String truncate(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max)}…';
  static bool isEmail(String s) => RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(s);
}
