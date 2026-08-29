import "package:flutter/material.dart";
class CalculatorBrowserScreen extends StatelessWidget {
  const CalculatorBrowserScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Calculators")), body: const Center(child: Text("Calculators - server reconciles offline preview")));
}
