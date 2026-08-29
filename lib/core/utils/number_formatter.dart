import 'package:intl/intl.dart';

abstract final class NumberFormatter {
  static String compact(int n) => NumberFormat.compact().format(n);
  static String decimal(double v, [int digits = 2]) =>
      NumberFormat.decimalPattern().format(double.parse(v.toStringAsFixed(digits)));
}
