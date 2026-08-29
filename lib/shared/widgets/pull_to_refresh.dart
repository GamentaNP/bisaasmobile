import 'package:flutter/material.dart';

class AppPullToRefresh extends StatelessWidget {
  const AppPullToRefresh({super.key, required this.onRefresh, required this.child});
  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) => RefreshIndicator(onRefresh: onRefresh, child: child);
}
