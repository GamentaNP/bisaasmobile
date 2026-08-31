import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../gamification/presentation/widgets/xp_progress_bar.dart';
import '../controllers/profile_skills_controller.dart';
import '../widgets/skill_radar_chart.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _repaintKey = GlobalKey();
  bool _uploading = false;

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final url = await ref.read(profileRemoteDataSourceProvider).uploadAvatar(file);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(url.isEmpty ? 'Avatar uploaded' : 'Avatar updated')));
      ref.invalidate(authControllerProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _editName(String current) async {
    final controller = TextEditingController(text: current);
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Display name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newName == null || newName.trim().isEmpty || newName.trim() == current) {
      return;
    }
    setState(() => _uploading = true);
    try {
      await ref.read(profileRemoteDataSourceProvider).updateProfile(name: newName);
      if (!mounted) return;
      ref.invalidate(authControllerProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _shareCard() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      // Share via share_plus XFile from bytes
      await SharePlus.instance.share(ShareParams(
        text: 'My CivilCal profile — Level ${ref.read(authControllerProvider).value?.level ?? 1} Engineer. https://bisaas.com',
        files: [XFile.fromData(bytes, name: 'civilcal-profile.png', mimeType: 'image/png')],
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Share failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    final skillsAsync = ref.watch(profileSkillsProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [IconButton(icon: const Icon(Icons.share_rounded), onPressed: _shareCard, tooltip: 'Share card'), IconButton(icon: const Icon(Icons.settings_rounded), onPressed: () => context.push('/settings'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Shareable card boundary
          RepaintBoundary(
            key: _repaintKey,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.brand.withValues(alpha: 0.15),
                        backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
                        child: user?.avatarUrl == null ? Text(user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'C', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.brand)) : null,
                      ),
                      if (_uploading) const Positioned.fill(child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Flexible(
                          child: Text(user?.name ?? 'Engineer', overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          tooltip: 'Edit name',
                          onPressed: _uploading ? null : () => _editName(user?.name ?? ''),
                        ),
                      ]),
                      Text(user?.email ?? 'offline@bisaas.test', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                      const SizedBox(height: 4),
                      Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.xpGold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: Text('Lv ${user?.level ?? 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.xpGold))), const SizedBox(width: 8), CoinChip(coins: user?.coins ?? 0)]),
                    ]),
                  ),
                  IconButton(icon: const Icon(Icons.camera_alt_rounded, size: 20), onPressed: _uploading ? null : _pickAndUploadAvatar, tooltip: 'Change avatar'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: OutlinedButton.icon(onPressed: _shareCard, icon: const Icon(Icons.share_rounded, size: 16), label: const Text('Share card'))), const SizedBox(width: 10), Expanded(child: FilledButton.icon(onPressed: _pickAndUploadAvatar, icon: const Icon(Icons.photo_rounded, size: 16), label: const Text('Edit avatar')))]),
          const SizedBox(height: 16),
          // Stats grid
          Row(
            children: [
              _StatChip(label: 'Quizzes', value: '${user?.streakDays ?? 0}', icon: Icons.quiz_rounded),
              const SizedBox(width: 8),
              _StatChip(label: 'XP', value: '${user?.xp ?? 0}', icon: Icons.bolt_rounded, color: AppColors.xpGold),
              const SizedBox(width: 8),
              _StatChip(label: 'Coins', value: '${user?.coins ?? 0}', icon: Icons.monetization_on_rounded, color: AppColors.coinYellow),
            ],
          ),
          const SizedBox(height: 16),
          // Skill radar
          Text('Skill Radar', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          skillsAsync.when(
            data: (axes) => SkillRadarChart(axes: axes),
            loading: () => const SizedBox(height: 160, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.wrongRed.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
              child: Text('Skills failed: $e', style: const TextStyle(color: AppColors.wrongRed, fontSize: 12)),
            ),
          ),
          const SizedBox(height: 16),
          // Achievement gallery
          Text('Achievements', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 6,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final unlocked = i < 3;
                final colors = [AppColors.brand, AppColors.streakOrange, AppColors.comboPurple, AppColors.correctGreen, AppColors.coinYellow, Colors.grey];
                final color = colors[i % colors.length];
                return Opacity(
                  opacity: unlocked ? 1 : 0.45,
                  child: Container(
                    width: 96,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: (unlocked ? color : theme.colorScheme.outlineVariant).withValues(alpha: 0.3))),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(unlocked ? Icons.verified_rounded : Icons.lock_rounded, color: color, size: 22),
                      const SizedBox(height: 6),
                      Text('Badge ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text(unlocked ? 'Unlocked' : 'Locked', style: TextStyle(fontSize: 10, color: unlocked ? AppColors.correctGreen : Colors.grey)),
                    ]),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          _Tile(icon: Icons.school_rounded, title: 'Learning — tracks & AI tutor', subtitle: 'GET /learning/*', onTapRoute: '/learning'),
          _Tile(icon: Icons.psychology_rounded, title: 'Exam Intelligence (EICE)', subtitle: 'coach • triage • sprint', onTapRoute: '/eice'),
          _Tile(icon: Icons.account_balance_rounded, title: 'PSC / Loksewa', subtitle: 'GET /psc/blueprints', onTapRoute: '/psc'),
          _Tile(icon: Icons.search_rounded, title: 'Search', subtitle: 'GET /quiz/questions?search=', onTapRoute: '/search'),
          _Tile(icon: Icons.notifications_rounded, title: 'Notifications', subtitle: 'GET /notifications', onTapRoute: '/notifications'),
          _Tile(icon: Icons.share_rounded, title: 'Social & Referral', subtitle: 'share + leaderboard', onTapRoute: '/social'),
          _Tile(icon: Icons.account_balance_wallet_rounded, title: 'Wallet', subtitle: 'coins via GET /me', onTapRoute: '/economy'),
          _Tile(icon: Icons.emoji_events_rounded, title: 'Achievements', subtitle: 'streak + badges', onTapRoute: '/achievements'),
          _Tile(icon: Icons.download_for_offline_rounded, title: 'Offline content', subtitle: 'cached packs + prefetch', onTapRoute: '/downloads'),
          _Tile(icon: Icons.calculate_rounded, title: 'Calculators 232', subtitle: 'Civil formula engines', onTapRoute: '/calculators'),
          _Tile(icon: Icons.settings_rounded, title: 'Settings', subtitle: 'language • biometrics • logout', onTapRoute: '/settings'),
          const SizedBox(height: 12),
          const Text('Library is now built via co-agent — backend `GET /library/files` ready. Offline packs (42MB) via Drift + path_provider + file_service.', style: TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, required this.icon, this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.brand;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: c.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: c.withValues(alpha: 0.2))),
        child: Row(children: [Icon(icon, size: 16, color: c), const SizedBox(width: 6), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: c)), Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)))])]),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.title, required this.subtitle, required this.onTapRoute});
  final IconData icon;
  final String title;
  final String subtitle;
  final String onTapRoute;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: AppColors.brand)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right_rounded, size: 18),
        onTap: () => context.push(onTapRoute),
      ),
    );
  }
}
