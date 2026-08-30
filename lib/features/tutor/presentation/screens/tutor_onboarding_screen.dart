import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../controllers/tutor_controller.dart';

/// Onboarding for AI Tutor — POST /learning/ai-tutor/onboarding/start & /complete.
/// Idempotent via Idempotency-Key header; tolerant to missing backend.
class TutorOnboardingScreen extends ConsumerStatefulWidget {
  const TutorOnboardingScreen({super.key});

  @override
  ConsumerState<TutorOnboardingScreen> createState() => _TutorOnboardingScreenState();
}

class _TutorOnboardingScreenState extends ConsumerState<TutorOnboardingScreen> {
  final _goalCtrl = TextEditingController();
  final _levelCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();

  @override
  void dispose() {
    _goalCtrl.dispose();
    _levelCtrl.dispose();
    _hoursCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Auto-start session if none
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = ref.read(tutorOnboardingControllerProvider);
      if (s.session == null && !s.isStarting) {
        ref.read(tutorOnboardingControllerProvider.notifier).start();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tutorOnboardingControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutor Onboarding'),
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.brand.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.school_rounded, color: AppColors.brandDark, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Personalized tutor', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text('Tell us your goal — the server builds your plan. No user_id required (token-bound).', style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.3)),
                  ]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (state.isStarting) const LinearProgressIndicator(),
          if (state.startError != null)
            _ErrorBanner(message: state.startError!, onRetry: () => ref.read(tutorOnboardingControllerProvider.notifier).start()),
          if (state.session != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Session: ${state.session!.sessionId.isEmpty ? '— (offline preview)' : state.session!.sessionId}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                if (state.session!.prompt != null) ...[
                  const SizedBox(height: 8),
                  Text(state.session!.prompt!, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                ],
                if (state.session!.stage != null) ...[
                  const SizedBox(height: 4),
                  Chip(label: Text(state.session!.stage!, style: const TextStyle(fontSize: 11)), visualDensity: VisualDensity.compact),
                ],
              ]),
            ),
            const SizedBox(height: 16),
          ],
          Text('Your goal', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _goalCtrl,
            decoration: const InputDecoration(
              hintText: 'e.g., Crack PSC Civil in 6 months',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.flag_rounded),
            ),
          ),
          const SizedBox(height: 12),
          Text('Current level', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _levelCtrl,
            decoration: const InputDecoration(
              hintText: 'e.g., Final year B.E. Civil',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.bar_chart_rounded),
            ),
          ),
          const SizedBox(height: 12),
          Text('Hours per day', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _hoursCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'e.g., 2',
              border: OutlineInputBorder(),
              isDense: true,
              prefixIcon: Icon(Icons.schedule_rounded),
            ),
          ),
          const SizedBox(height: 16),
          if (state.completeError != null)
            _ErrorBanner(message: state.completeError!, onRetry: () {}),
          if (state.isCompleted)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.correctGreen.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.correctGreen.withValues(alpha: 0.2))),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.correctGreen),
                const SizedBox(width: 10),
                const Expanded(child: Text('Onboarding complete — your plan is ready.', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.correctGreen))),
                TextButton(onPressed: () => context.go('/tutor/plan'), child: const Text('View Plan')),
              ]),
            ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: state.isStarting || state.isCompleting
                ? null
                : () async {
                    // Start if needed
                    if (state.session == null) {
                      await ref.read(tutorOnboardingControllerProvider.notifier).start();
                    }
                    final ok = await ref.read(tutorOnboardingControllerProvider.notifier).complete(payload: {
                      'goal': _goalCtrl.text.trim(),
                      'level': _levelCtrl.text.trim(),
                      'hours_per_day': int.tryParse(_hoursCtrl.text.trim()) ?? 2,
                    });
                    if (ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Onboarding saved — plan will generate shortly.')));
                    }
                  },
            icon: state.isCompleting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_rounded),
            label: Text(state.isCompleted ? 'Completed' : 'Complete onboarding'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => context.go('/tutor/chat'),
            child: const Text('Skip → Chat with tutor'),
          ),
          const SizedBox(height: 12),
          const Text(
            'POST /learning/ai-tutor/onboarding/start & /complete — idempotent with Idempotency-Key. Token-bound, no user_id.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.wrongRed.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.wrongRed),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 12, color: AppColors.wrongRed))),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
