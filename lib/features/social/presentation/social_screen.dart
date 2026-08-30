// ignore_for_file: avoid_dynamic_calls

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/logging/app_logger.dart';

/// Social — share, referral, leaderboard views.
/// Server-authoritative: referral qualifies via POST /quiz/referrals, leaderboard via GET /quiz/leaderboards/{id}.
class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  Future<void> _share(BuildContext context) async {
    try {
      AppLogger.i('Social share');
      await SharePlus.instance.share(ShareParams(text: 'Join me on CivilCal — 232 calculators + Loksewa MCQs: https://bisaas.com', subject: 'CivilCal'));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Share failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Social')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Share is native sheet only — no local coin mint. Referral qualifies server-side (SEC-4).', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: () => _share(context), icon: const Icon(Icons.share_rounded), label: const Text('Share CivilCal')),
          const SizedBox(height: 16),
          const Divider(),
          ListTile(leading: const Icon(Icons.leaderboard_rounded), title: const Text('Leaderboard'), subtitle: const Text('GET /quiz/leaderboards/{board} (read-only RTDB)'), onTap: () {}),
          ListTile(leading: const Icon(Icons.card_giftcard_rounded), title: const Text('Referral'), subtitle: const Text('POST /quiz/referrals (server qualifies)'), onTap: () {}),
        ],
      ),
    );
  }
}
