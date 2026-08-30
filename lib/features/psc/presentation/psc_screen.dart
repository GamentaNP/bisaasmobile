// ignore_for_file: avoid_dynamic_calls

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../data/psc_remote_data_source.dart';

final pscRemoteProvider = Provider<PscRemoteDataSource>((ref) => PscRemoteDataSource(DioClient.instance.dio));

class PscScreen extends ConsumerWidget {
  const PscScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('PSC / Loksewa')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ref.read(pscRemoteProvider).getBlueprints(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final list = snap.data ?? [];
          if (list.isEmpty) return const Center(child: Text('No blueprints — GET /psc/blueprints empty or offline', textAlign: TextAlign.center));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final m = list[i];
              return Card(
                child: ListTile(
                  title: Text((m['title'] ?? m['name'] ?? 'Blueprint') as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text('id: ${m['id'] ?? ''} • ${m['question_count'] ?? m['questions_count'] ?? ''} Qs', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  trailing: const Icon(Icons.arrow_forward_rounded),
                  onTap: () async {
                    final id = (m['id'] ?? '').toString();
                    final exam = await ref.read(pscRemoteProvider).startExam(id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exam == null ? 'Start exam failed (offline or 404)' : 'Exam started: ${exam['id'] ?? ''}')));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
