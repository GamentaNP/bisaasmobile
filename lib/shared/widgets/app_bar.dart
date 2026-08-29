import 'package:flutter/material.dart';

class CivilAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CivilAppBar({super.key, required this.title, this.actions, this.centerTitle = true});
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) =>
      AppBar(title: Text(title), centerTitle: centerTitle, actions: actions);
}
