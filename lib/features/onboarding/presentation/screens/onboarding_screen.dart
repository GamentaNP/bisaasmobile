import "package:flutter/material.dart";
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Onboarding")), body: const Center(child: Text("Onboarding - 3-step flow")));
}
