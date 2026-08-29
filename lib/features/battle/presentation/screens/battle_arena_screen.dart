import "package:flutter/material.dart";
class BattleArenaScreen extends StatelessWidget {
  const BattleArenaScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Battle")), body: const Center(child: Text("Battle - matchmaking via Firebase")));
}
