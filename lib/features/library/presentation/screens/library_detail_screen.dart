import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/security/sensitive_screen_guard.dart';
import '../../../../shared/widgets/error_view.dart';
import '../controllers/library_controller.dart';
import '../../domain/entities/library.dart';

/// File detail — `GET /library/files/{slug}`, unlock, download, reviews.
///
/// Handles 403 FILE_NOT_UNLOCKED, 402 INSUFFICIENT_COINS, and tolerant parsing.
/// Download URLs are signed and short-lived — launched immediately, never cached.
class LibraryDetailScreen extends ConsumerStatefulWidget {
  const LibraryDetailScreen({required this.slug, super.key});
  final String slug;

  @override
  ConsumerState<LibraryDetailScreen> createState() => _LibraryDetailScreenState();
}

class _LibraryDetailScreenState extends ConsumerState<LibraryDetailScreen> {
  final _commentCtrl = TextEditingController();
  int _rating = 5;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final n = ref.read(libraryControllerProvider.notifier);
      n.fetchFile(widget.slug);
      n.fetchReviews(widget.slug);
    });
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _onUnlock() async {
    final notifier = ref.read(libraryControllerProvider.notifier);
    final res = await notifier.unlock(widget.slug);
    if (!mounted) return;
    if (res != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unlocked! Coins spent: ${res.coinsSpent}')),
      );
    } else {
      final err = ref.read(libraryControllerProvider).unlockError;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.wrongRed));
      }
    }
  }

  Future<void> _onDownload() async {
    final notifier = ref.read(libraryControllerProvider.notifier);
    final url = await notifier.download(widget.slug);
    if (!mounted) return;
    if (url != null && url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download started — opening browser')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download URL: $url')));
      }
    } else {
      final err = ref.read(libraryControllerProvider).downloadError;
      final msg = err ?? 'Download failed — file may need unlocking first.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.wrongRed));
    }
  }

  Future<void> _onSubmitReview() async {
    if (_rating < 1 || _rating > 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rating must be 1-5')));
      return;
    }
    final notifier = ref.read(libraryControllerProvider.notifier);
    final review = await notifier.submitReview(widget.slug, rating: _rating, comment: _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim());
    if (!mounted) return;
    if (review != null) {
      _commentCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review submitted')));
    } else {
      final err = ref.read(libraryControllerProvider).submitReviewError;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'Review failed'), backgroundColor: AppColors.wrongRed));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(libraryControllerProvider);
    final theme = Theme.of(context);
    final file = state.selectedFile;

    final body = Builder(
      builder: (context) {
          if (state.isFileLoading && file == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.fileError != null && file == null) {
            return Center(child: ErrorView(message: state.fileError!, onRetry: () => ref.read(libraryControllerProvider.notifier).fetchFile(widget.slug)));
          }
          if (file == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(libraryControllerProvider.notifier).fetchFile(widget.slug);
              await ref.read(libraryControllerProvider.notifier).fetchReviews(widget.slug);
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FileHeaderCard(file: file),
                  const SizedBox(height: 16),

                  // Actions: Unlock / Download
                  _ActionRow(
                    file: file,
                    isUnlocking: state.isUnlocking,
                    isDownloading: state.isDownloading,
                    unlockError: state.unlockError,
                    downloadError: state.downloadError,
                    onUnlock: _onUnlock,
                    onDownload: _onDownload,
                    lastUnlockResult: state.lastUnlockResult,
                  ),
                  if (state.unlockError != null) ...[
                    const SizedBox(height: 8),
                    _InlineError(message: state.unlockError!),
                  ],
                  if (state.downloadError != null) ...[
                    const SizedBox(height: 8),
                    _InlineError(message: state.downloadError!),
                  ],

                  const SizedBox(height: 24),
                  // Description + meta
                  if (file.description != null && file.description!.isNotEmpty) ...[
                    Text('About', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(file.description!, style: theme.textTheme.bodySmall?.copyWith(height: 1.5)),
                    const SizedBox(height: 16),
                  ],

                  if (file.tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: file.tags.map((t) => Chip(label: Text(t, style: const TextStyle(fontSize: 12)), visualDensity: VisualDensity.compact)).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Stats row
                  _StatsRow(file: file),

                  const Divider(height: 32),

                  // Reviews header
                  Row(
                    children: [
                      Text('Reviews', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                        child: Text('${file.reviewCount}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.brand)),
                      ),
                      const Spacer(),
                      Text('${file.averageRating.toStringAsFixed(1)} ★', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.xpGold)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Submit review
                  _SubmitReviewCard(
                    rating: _rating,
                    commentCtrl: _commentCtrl,
                    isSubmitting: state.isSubmittingReview,
                    onRatingChanged: (v) => setState(() => _rating = v),
                    onSubmit: _onSubmitReview,
                  ),
                  if (state.submitReviewError != null) ...[
                    const SizedBox(height: 8),
                    _InlineError(message: state.submitReviewError!),
                  ],
                  const SizedBox(height: 16),

                  // Reviews list
                  if (state.isReviewsLoading && state.reviews.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                  else if (state.reviewsError != null && state.reviews.isEmpty)
                    ErrorView(message: state.reviewsError!, onRetry: () => ref.read(libraryControllerProvider.notifier).fetchReviews(widget.slug))
                  else if (state.reviews.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('No reviews yet — be the first to review after unlocking!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ...state.reviews.map((r) => _ReviewTile(review: r)),

                  if (state.reviewsPagination != null && (state.reviewsPagination!.hasMore ?? false)) ...[
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: state.isReviewsLoading
                          ? null
                          : () {
                              final next = (state.reviewsPagination!.currentPage ?? 1) + 1;
                              ref.read(libraryControllerProvider.notifier).fetchReviews(widget.slug, page: next, append: true);
                            },
                      child: const Text('Load more reviews'),
                    ),
                  ],

                  const SizedBox(height: 24),
                  const Text(
                    'Download URLs are signed and short-lived. If a download fails, tap Download again to get a fresh URL. Respect library-api-download throttle.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
    );

    // FLAG_SECURE on paid content only (security plan W2.7): free files stay
    // screenshot-friendly, premium/coin-gated material does not.
    final isPaidContent =
        file?.visibility == 'premium_only' || file?.visibility == 'coin_gated';
    return Scaffold(
      appBar: AppBar(
        title: Text(file?.title ?? widget.slug.replaceAll('-', ' ')),
      ),
      body: isPaidContent
          ? SensitiveScreenGuard.guard(child: body)
          : body,
    );
  }
}

class _FileHeaderCard extends StatelessWidget {
  const _FileHeaderCard({required this.file});
  final LibraryFile file;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Text(file.fileType.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.brand, letterSpacing: 0.6)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: file.isFree ? AppColors.correctGreen.withValues(alpha: 0.12) : AppColors.coinYellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(file.isFree ? 'FREE' : '${file.coinPrice} COINS',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: file.isFree ? AppColors.correctGreen : AppColors.coinYellow)),
              ),
              const Spacer(),
              if (file.isFeatured) const Icon(Icons.star_rounded, size: 18, color: AppColors.xpGold),
              if (file.isFeatured) const SizedBox(width: 4),
              if (file.isFeatured) const Text('Featured', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.xpGold)),
            ],
          ),
          const SizedBox(height: 10),
          Text(file.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(
            children: [
              if (file.category != null) ...[
                Icon(Icons.folder_rounded, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                Text(file.category!.name, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                const SizedBox(width: 12),
              ],
              Icon(Icons.visibility_rounded, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: 4),
              Text(file.visibility, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            ],
          ),
          if (file.uploader != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.person_rounded, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('by ${file.uploader!.name}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const Spacer(),
                if (file.createdAt != null)
                  Text(_formatDate(file.createdAt!), style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.file,
    required this.isUnlocking,
    required this.isDownloading,
    required this.unlockError,
    required this.downloadError,
    required this.onUnlock,
    required this.onDownload,
    required this.lastUnlockResult,
  });

  final LibraryFile file;
  final bool isUnlocking;
  final bool isDownloading;
  final String? unlockError;
  final String? downloadError;
  final VoidCallback onUnlock;
  final VoidCallback onDownload;
  final LibraryUnlockResult? lastUnlockResult;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (lastUnlockResult != null)
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: AppColors.correctGreen.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.correctGreen.withValues(alpha: 0.25))),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.correctGreen, size: 18),
                const SizedBox(width: 8),
                Text('Unlocked • ${lastUnlockResult!.coinsSpent} coins', style: const TextStyle(color: AppColors.correctGreen, fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: isUnlocking ? null : onUnlock,
                icon: isUnlocking
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.lock_open_rounded, size: 18),
                label: Text(isUnlocking ? 'Unlocking…' : file.isFree ? 'Unlock (Free)' : 'Unlock • ${file.coinPrice} coins'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: isDownloading ? null : onDownload,
                icon: isDownloading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.download_rounded, size: 18),
                label: Text(isDownloading ? 'Getting link…' : 'Download'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.correctGreen),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Unlock uses Idempotency-Key and is server-charged. Download requires unlock (403 FILE_NOT_UNLOCKED otherwise). Coins are server-authoritative.',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.file});
  final LibraryFile file;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Stat(icon: Icons.star_rounded, color: AppColors.xpGold, value: file.averageRating.toStringAsFixed(1), label: '${file.reviewCount} reviews'),
        const SizedBox(width: 12),
        _Stat(icon: Icons.download_rounded, color: AppColors.brand, value: '${file.downloadCount}', label: 'downloads'),
        const SizedBox(width: 12),
        _Stat(icon: Icons.visibility_rounded, color: Colors.grey, value: file.visibility, label: 'access'),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.color, required this.value, required this.label});
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
            Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }
}

class _SubmitReviewCard extends StatelessWidget {
  const _SubmitReviewCard({
    required this.rating,
    required this.commentCtrl,
    required this.isSubmitting,
    required this.onRatingChanged,
    required this.onSubmit,
  });

  final int rating;
  final TextEditingController commentCtrl;
  final bool isSubmitting;
  final void Function(int) onRatingChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Write a review (must unlock first)', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (i) {
              final idx = i + 1;
              final filled = idx <= rating;
              return IconButton(
                icon: Icon(filled ? Icons.star_rounded : Icons.star_border_rounded, color: filled ? AppColors.xpGold : Colors.grey, size: 28),
                onPressed: () => onRatingChanged(idx),
              );
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: commentCtrl,
            decoration: const InputDecoration(
              hintText: 'Comment (optional)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            minLines: 2,
            maxLines: 4,
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: isSubmitting ? null : onSubmit,
            icon: isSubmitting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.rate_review_rounded, size: 18),
            label: Text(isSubmitting ? 'Submitting…' : 'Submit review'),
          ),
          const SizedBox(height: 4),
          const Text('Reviews are verified if you have downloaded/unlocked the file.', style: TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});
  final LibraryReview review;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.brand.withValues(alpha: 0.15),
                child: Text((review.user?.name.isNotEmpty == true ? review.user!.name[0].toUpperCase() : '?'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.brand)),
              ),
              const SizedBox(width: 8),
              Text(review.user?.name ?? 'Anonymous', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(width: 8),
              if (review.isVerifiedDownload)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.correctGreen.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [Icon(Icons.verified_rounded, size: 12, color: AppColors.correctGreen), SizedBox(width: 2), Text('verified', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.correctGreen))],
                  ),
                ),
              const Spacer(),
              Row(
                children: List.generate(5, (i) => Icon(i < review.rating ? Icons.star_rounded : Icons.star_border_rounded, size: 14, color: AppColors.xpGold)),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.comment!, style: Theme.of(context).textTheme.bodySmall),
          ],
          if (review.createdAt != null) ...[
            const SizedBox(height: 6),
            Text(_formatDate(review.createdAt!), style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.wrongRed.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.wrongRed.withValues(alpha: 0.25))),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.wrongRed, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(color: AppColors.wrongRed, fontSize: 12))),
        ],
      ),
    );
  }
}
