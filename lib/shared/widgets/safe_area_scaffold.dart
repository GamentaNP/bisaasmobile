import 'package:flutter/material.dart';

class SafeAreaScaffold extends StatelessWidget {
  const SafeAreaScaffold({super.key, required this.body, this.appBar, this.bottomNavigationBar, this.floatingActionButton});
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: SafeArea(child: body),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
