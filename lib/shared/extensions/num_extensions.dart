import 'package:intl/intl.dart';

extension NumX on num {
  String get compact => NumberFormat.compact().format(this);
  String fixed(int digits) => toStringAsFixed(digits);
  Duration get ms => Duration(milliseconds: toInt());
  Duration get seconds => Duration(seconds: toInt());
}
