import "package:flutter/material.dart";
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Home")), body: ListView(padding: const EdgeInsets.all(16), children: const [Text("Streak, daily quiz, progress ring - server authoritative")] ));
}
