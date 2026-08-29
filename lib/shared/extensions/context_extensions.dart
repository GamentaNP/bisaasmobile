import 'package:flutter/material.dart';

extension ContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colors => theme.colorScheme;
  Size get size => MediaQuery.sizeOf(this);
  double get width => size.width;
  bool get isDark => theme.brightness == Brightness.dark;
  void hideKeyboard() => FocusScope.of(this).unfocus();
}
