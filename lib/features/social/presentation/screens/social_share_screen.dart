import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../domain/entities/social.dart';
import '../controllers/social_controller.dart';

/// The guest sandbox — a playable attempt for someone with no account.
///
/// Reached from a share link (`https://bisaas.com/s/{token}` → the
/// `civilcal://s/{token}` deep link).
///
/// The server owns the whole flow:
///  * `GET  /public/social/share/{token}` resolves the link.
///  * `POST /public/social/sandbox/{token}` starts an attempt bound to a
///    client-generated guest session id.
///  * `PUT  /public/social/sandbox/{attempt}/answer` grades each answer.
///  * `PUT  /public/social/sandbox/{attempt}/completion` closes it.
///
/// A sandbox attempt runs against a sentinel user and completes with **zero
/// progression grants** — no coins, no XP, no streak. The screen says so,
/// because a guest who plays a quiz and sees no reward deserves to know why.
class SocialShareScreen extends ConsumerStatefulWidget {
  const SocialShareScreen({super.key, required this.token});
  final String token;

  @override
  ConsumerState<SocialShareScreen> createState() => _SocialShareScreenState();
}

class _SocialShareScreenState extends ConsumerState<SocialShareScreen> {
  SharedLink? _link;
  SandboxAttempt? _attempt;
  String? _error;
  bool _loading = true;
  bool _starting = false;

  /// The guest session id the attempt is bound to.
  ///
  /// Generated on the device, 8..64 characters (the server's rule), and
  /// stable for the life of this screen so a retry re-uses it.
  ///
  /// The randomness comes from `uuid` rather than `DateTime.now().hashCode`:
  /// `hashCode` is not a cryptographic source and is not guaranteed stable
  /// across isolates, and this id is what binds a guest attempt to a device.
  late final String _guestSessionId = _generateGuestSessionId();

  static const _uuid = Uuid();

  static String _generateGuestSessionId() {
    return 'guest-${_uuid.v4()}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  Future<void> _resolve() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final link = await ref
          .read(socialControllerProvider.notifier)
          .resolveShare(widget.token);
      if (!mounted) return;
      setState(() {
        _link = link;
        _loading = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _startSandbox() async {
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final attempt = await ref
          .read(socialControllerProvider.notifier)
          .startSandbox(
            token: widget.token,
            guestSessionId: _guestSessionId,
          );
      if (!mounted) return;
      setState(() {
        _starting = false;
        _attempt = attempt;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final link = _link;

    return Scaffold(
      appBar: AppBar(title: const Text('Shared challenge')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (link == null)
                  ErrorView(message: _error ?? 'That share link could not be found.', onRetry: _resolve)
                else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.brand.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.brand.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Someone shared a challenge with you',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        if (link.creatorName != null)
                          Text(
                            'Shared by ${link.creatorName}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        if (link.isExpired) ...[
                          const SizedBox(height: 6),
                          const Text(
                            'This link has expired.',
                            style: TextStyle(fontSize: 12, color: AppColors.wrongRed),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.wrongRedBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.wrongRed.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(fontSize: 12, color: AppColors.wrongRed),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                if (_attempt != null)
                  _SandboxReady(questionCount: _attempt!.questionCount)

                  else if (link.sandboxAvailable && !link.isExpired)
                    FilledButton.icon(
                      onPressed: _starting ? null : _startSandbox,
                      icon: _starting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.play_arrow_rounded),
                      label: Text(_starting ? 'Starting…' : 'Play the challenge'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    )
                  else
                    const EmptyState(
                      title: 'No playable challenge here',
                      subtitle:
                          'This link does not offer a playable challenge. You can '
                          'still browse the public catalogue.',
                      icon: Icons.link_off_rounded,
                    ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/quiz/funnel'),
                    icon: const Icon(Icons.explore_outlined),
                    label: const Text('Browse sample questions'),
                  ),
                ],
              ],
            ),
    );
  }
}

/// Shown once the sandbox attempt exists.
///
/// **Honest about what the client can do.** The sandbox payload publishes the
/// attempt id and a question *count* — the server picks the preview set
/// server-side and does not publish the questions to an unauthenticated
/// client. So the challenge cannot be rendered or answered here yet, and this
/// panel says exactly that instead of showing a green "Challenge ready" box
/// that leads nowhere.
///
/// The wiring for the playable flow is already in place
/// (`answerSandbox` / `completeSandbox`); it becomes reachable the moment the
/// server publishes the sandbox questions.
class _SandboxReady extends StatelessWidget {
  const _SandboxReady({required this.questionCount});

  final int questionCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warnAmberBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warnAmber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 18, color: AppColors.warningShadow),
              const SizedBox(width: 8),
              Text(
                'Challenge started',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            questionCount > 0
                ? 'Your $questionCount-question sandbox attempt is open on our '
                    'servers. The questions themselves are not published to '
                    'guests yet, so they cannot be played in the app.'
                : 'Your sandbox attempt is open on our servers. The questions '
                    'themselves are not published to guests yet, so they '
                    'cannot be played in the app.',
            style: const TextStyle(fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 8),
          const Text(
            'A guest challenge never awards coins, XP or streak. Create a free '
            'account to play the full catalogue and keep your progress.',
            style: TextStyle(fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => context.go('/register'),
            icon: const Icon(Icons.person_add_alt_rounded),
            label: const Text('Create a free account'),
          ),
        ],
      ),
    );
  }
}
