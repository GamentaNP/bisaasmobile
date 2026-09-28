import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/widgets/chunky/chunky_button.dart';
import '../../../../shared/widgets/chunky/chunky_kit.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../data/datasources/rewards_remote_data_source.dart';
import '../../data/models/rewards_dto.dart';

/// Rewards — daily check-in and the spin wheel.
///
/// Both features are live server-side (`/rewards/daily-checkin*`,
/// `/rewards/spin*`). The spin endpoints answer **raw JSON outside the
/// envelope**, which is handled in the data source, and the server — not this
/// screen — decides both the prize and whether a spin is allowed.
class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

final rewardsDataSourceProvider = Provider<RewardsRemoteDataSource>((ref) {
  return RewardsRemoteDataSource(DioClient.instance.dio);
});

final checkInStatusProvider = FutureProvider.autoDispose<CheckInStatusDto>((ref) {
  return ref.watch(rewardsDataSourceProvider).getCheckInStatus();
});

final spinStatusProvider = FutureProvider.autoDispose<SpinStatusDto>((ref) {
  return ref.watch(rewardsDataSourceProvider).getSpinStatus();
});

class _RewardsScreenState extends ConsumerState<RewardsScreen> {
  bool _claiming = false;
  bool _spinning = false;

  Future<void> _claimCheckIn() async {
    setState(() => _claiming = true);
    try {
      final result = await ref.read(rewardsDataSourceProvider).claimCheckIn();
      ref.invalidate(checkInStatusProvider);
      if (!mounted) return;
      _toast(
        context,
        result.credited
            ? '+${result.amount} coins · day ${result.streakDay} streak'
            : (result.reason == null ? 'Already claimed today' : 'Already claimed: ${result.reason}'),
        ok: result.credited,
      );
    } catch (e) {
      if (!mounted) return;
      _toast(context, 'Check-in failed: $e', ok: false);
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  Future<void> _spin() async {
    setState(() => _spinning = true);
    try {
      final result = await ref.read(rewardsDataSourceProvider).spin();
      ref.invalidate(spinStatusProvider);
      if (!mounted) return;
      _toast(
        context,
        result.spun ? result.label : (result.reason ?? 'No spin available right now'),
        ok: result.spun,
      );
    } catch (e) {
      if (!mounted) return;
      _toast(context, 'Spin failed: $e', ok: false);
    } finally {
      if (mounted) setState(() => _spinning = false);
    }
  }

  void _toast(BuildContext context, String message, {required bool ok}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ok ? AppColors.correctGreen : AppColors.warnAmber,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rewards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(checkInStatusProvider);
              ref.invalidate(spinStatusProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(checkInStatusProvider);
          ref.invalidate(spinStatusProvider);
          // RefreshIndicator must always complete, so a failed re-read is
          // swallowed here — each card renders its own error state.
          await Future.wait([
            ref.read(checkInStatusProvider.future).then<void>((_) {}, onError: (_, __) {}),
            ref.read(spinStatusProvider.future).then<void>((_) {}, onError: (_, __) {}),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _CheckInCard(
              status: ref.watch(checkInStatusProvider),
              busy: _claiming,
              onClaim: _claimCheckIn,
            ),
            const SizedBox(height: 20),
            Text('Spin the wheel', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            _SpinCard(
              status: ref.watch(spinStatusProvider),
              busy: _spinning,
              onSpin: _spin,
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckInCard extends StatelessWidget {
  const _CheckInCard({required this.status, required this.busy, required this.onClaim});

  final AsyncValue<CheckInStatusDto> status;
  final bool busy;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    return status.when(
      loading: () => const ChunkyCard(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => ErrorView(
        title: 'Check-in unavailable',
        message: '$e',
        onRetry: onClaim,
      ),
      data: (data) {
        return ChunkyCard(
          padding: const EdgeInsets.all(16),
          side: data.claimedToday ? AppColors.dividerLight : AppColors.streakOrange,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.event_available_rounded, color: AppColors.streakOrange, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Daily check-in',
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (data.streakDay > 0)
                    Text(
                      'day ${data.streakDay}',
                      style: AppTypography.titleSmall.copyWith(color: AppColors.streakOrange),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _Pill(coins: data.todayReward, label: 'today'),
                  const SizedBox(width: 10),
                  if (data.nextReward > 0) _Pill(coins: data.nextReward, label: 'tomorrow'),
                ],
              ),
              const SizedBox(height: 14),
              ChunkyButton(
                label: data.claimedToday ? 'Claimed today' : 'Check in for ${data.todayReward} coins',
                icon: data.claimedToday ? Icons.check_rounded : Icons.card_giftcard_rounded,
                variant: data.claimedToday ? ChunkyVariant.muted : ChunkyVariant.primary,
                loading: busy,
                onPressed: data.canClaim && !busy ? onClaim : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SpinCard extends StatelessWidget {
  const _SpinCard({required this.status, required this.busy, required this.onSpin});

  final AsyncValue<SpinStatusDto> status;
  final bool busy;
  final VoidCallback onSpin;

  @override
  Widget build(BuildContext context) {
    return status.when(
      loading: () => const ChunkyCard(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => ErrorView(
        title: 'Spin wheel unavailable',
        message: '$e',
        onRetry: onSpin,
      ),
      data: (data) {
        return ChunkyCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 190,
                child: Center(child: _SpinWheel(prizes: data.prizes, spinning: busy)),
              ),
              const SizedBox(height: 12),
              // Prize labels come straight from the server.
              if (data.prizes.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final p in data.prizes)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: p.color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          p.label,
                          style: AppTypography.labelSmall.copyWith(color: p.color),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 14),
              ChunkyButton(
                label: data.canSpin ? 'Spin' : 'Come back later',
                icon: Icons.casino_rounded,
                variant: data.canSpin ? ChunkyVariant.warning : ChunkyVariant.muted,
                loading: busy,
                onPressed: data.canSpin && !busy ? onSpin : null,
              ),
              if (!data.canSpin && data.nextSpinAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Next spin ${data.nextSpinAt!.toLocal().toString().split('.').first}',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiaryLight),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Decorative wheel built from the server's prize list and its own colours.
///
/// This does not decide the outcome — `POST /rewards/spin` does, and returns the
/// prize index. The wheel only illustrates it.
class _SpinWheel extends StatefulWidget {
  const _SpinWheel({required this.prizes, required this.spinning});

  final List<SpinPrizeDto> prizes;
  final bool spinning;

  @override
  State<_SpinWheel> createState() => _SpinWheelState();
}

class _SpinWheelState extends State<_SpinWheel> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.spinning) _forward();
  }

  @override
  void didUpdateWidget(_SpinWheel old) {
    super.didUpdateWidget(old);
    if (widget.spinning && !old.spinning) _forward();
  }

  void _forward() {
    // The number of turns is presentation only; the prize is server-decided.
    _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.prizes.isEmpty) {
      return const Icon(Icons.casino_outlined, size: 56, color: AppColors.textTertiaryLight);
    }
    final prizes = widget.prizes;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final turns = _ctrl.value * 4 * 2 * math.pi;
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: turns,
              child: CustomPaint(
                size: const Size(180, 180),
                painter: _WheelPainter(prizes),
              ),
            ),
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.dividerLight, width: 3),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.casino_rounded, color: AppColors.brand, size: 26),
            ),
            // Pointer.
            const Positioned(
              top: 0,
              child: Icon(Icons.arrow_drop_down_rounded, color: AppColors.wrongRed, size: 30),
            ),
          ],
        );
      },
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter(this.prizes);

  final List<SpinPrizeDto> prizes;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweep = 2 * math.pi / prizes.length;

    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < prizes.length; i++) {
      paint.color = prizes[i].color;
      canvas.drawArc(rect, -math.pi / 2 + i * sweep, sweep, true, paint);
    }

    // Separator lines.
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < prizes.length; i++) {
      final angle = -math.pi / 2 + i * sweep;
      canvas.drawLine(
        center,
        center + Offset(math.cos(angle) * radius, math.sin(angle) * radius),
        line,
      );
    }

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.dividerLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_WheelPainter old) => old.prizes != prizes;
}

class _Pill extends StatelessWidget {
  const _Pill({required this.coins, required this.label});

  final int coins;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.coinYellow.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on_rounded, size: 14, color: AppColors.coinYellow),
          const SizedBox(width: 4),
          Text(
            '$coins · $label',
            style: AppTypography.labelSmall.copyWith(color: AppColors.coinYellow),
          ),
        ],
      ),
    );
  }
}
