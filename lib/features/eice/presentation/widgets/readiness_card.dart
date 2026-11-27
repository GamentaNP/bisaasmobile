import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/eice_data.dart';

/// Renders the server's strict readiness verdict. There is no readiness
/// arithmetic here: every number and reason comes from the API payload.
class ReadinessCard extends StatefulWidget {
  const ReadinessCard({
    super.key,
    required this.coach,
    required this.readiness,
  });

  final Future<EicePayload?> Function() coach;
  final Future<EicePayload?> Function(int examId) readiness;

  @override
  State<ReadinessCard> createState() => _ReadinessCardState();
}

class _ReadinessCardState extends State<ReadinessCard> {
  EicePayload? data;
  bool loading = false;
  String? err;

  Future<void> _load() async {
    setState(() {
      loading = true;
      err = null;
    });
    try {
      final coach = await widget.coach();
      final examId = coach?.examId;
      if (examId == null) {
        if (!mounted) return;
        setState(() {
          data = null;
          loading = false;
          err = 'No target exam is set up, so there is nothing to verify.';
        });
        return;
      }
      final res = await widget.readiness(examId);
      if (!mounted) return;
      setState(() {
        data = res;
        loading = false;
        if (res == null) err = 'Nothing to show for this section yet.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        data = null;
        loading = false;
        err = ErrorHandler.handle(e).message;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final payload = data;

    Color verdictColor(String? verdict) {
      switch (verdict) {
        case 'ready':
          return AppColors.correctGreen;
        case 'not_ready':
          return const Color(0xFFD97706);
        default:
          return AppColors.brand;
      }
    }

    String verdictLabel(String? verdict) {
      switch (verdict) {
        case 'ready':
          return l10n.eiceReadinessReady;
        case 'not_ready':
          return l10n.eiceReadinessNotReady;
        default:
          return l10n.eiceReadinessInsufficient;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 18,
                  color: AppColors.brand,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.eiceReadinessTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (loading) const LinearProgressIndicator(),
            if (err != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    err!,
                    style: TextStyle(fontSize: 12, color: colorScheme.error),
                  ),
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(l10n.retry),
                  ),
                ],
              ),
            if (!loading && err == null && payload != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: verdictColor(payload.readinessVerdict)
                      .withValues(alpha: 0.12),
                  borderRadius: AppRadii.smAll,
                ),
                child: Text(
                  verdictLabel(payload.readinessVerdict),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: verdictColor(payload.readinessVerdict),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _Stat(
                    label: l10n.eiceReadinessQuestions,
                    value:
                        '${payload.evidenceCount}/${payload.requiredQuestions}',
                  ),
                  const SizedBox(width: 12),
                  _Stat(
                    label: l10n.eiceReadinessRemaining,
                    value: '${payload.remainingQuestions}',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                payload.readinessExplanation,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (payload.readinessTopics.isNotEmpty) ...[
                const SizedBox(height: 10),
                ...payload.readinessTopics.map(
                  (topic) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: AppRadii.smAll,
                      boxShadow: AppShadows.shadowSm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                topic.name,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              topic.passed ? '✓' : '!',
                              style: TextStyle(
                                color: topic.passed
                                    ? AppColors.correctGreen
                                    : AppColors.brand,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          AppLocalizations.of(context)!.eiceReadinessMetrics(
                            '${topic.accuracyPercent}',
                            topic.bktPosterior.toStringAsFixed(2),
                            topic.ciMargin.toStringAsFixed(2),
                          ),
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (topic.reasons.isNotEmpty)
                          Text(
                            topic.reasons.join(' · '),
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.error,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: loading ? null : _load,
                child: Text(l10n.streakRefresh),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: AppRadii.smAll,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
