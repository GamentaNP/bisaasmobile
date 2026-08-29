library;
import 'package:flutter/material.dart';

class QuizHomePage extends StatelessWidget {
  const QuizHomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CivilCal — Quiz')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          FilledButton(onPressed: () {}, child: const Text('Start Quiz (→ POST /api/v1/quiz/attempts/start)')),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: () {}, child: const Text('Calculators (→ /api/v1/calculators/*)')),
          const SizedBox(height: 12),
          const Text('Backend docs: C:\\laragon\\www\\bisaas\\docs\\mobileapp\\FLUTTER_APP_MASTER_PLAN_2026.md\nAPI guide: C:\\laragon\\www\\bisaas\\docs\\MOBILE_API_INTEGRATION_GUIDE.md\nOpenAPI: GET /api/v1/openapi.json'),
        ],
      ),
    );
  }
}
