import 'package:flutter/material.dart';

class KeyboardDismisser extends StatelessWidget {
  const KeyboardDismisser({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      GestureDetector(onTap: () => FocusScope.of(context).unfocus(), child: child);
}
