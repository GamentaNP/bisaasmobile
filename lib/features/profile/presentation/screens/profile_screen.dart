import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../../../shared/widgets/glassmorphic_card.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/safe_area_scaffold.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../gamification/presentation/screens/achievements_screen.dart';
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
    if (newName == null || newName.trim().isEmpty || newName.trim() == current) return;
    setState(() => _uploading = true);
    try {
      await ref.read(profileRemoteDataSourceProvider).updateProfile(name: newName);
      if (!mounted) return;
      ref.invalidate(authControllerProvider);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
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
    final achievementsAsync = ref.watch(achievementsDataProvider);
    final theme = Theme.of(context);
    return SafeAreaScaffold(
      appBar: CivilAppBar(
        title: 'Profile',
        actions: [
          IconButton(icon: const Icon(Icons.share_rounded), onPressed: _shareCard, tooltip: 'Share card'),
          // go, not push — shell routes require go() on web
          IconButton(icon: const Icon(Icons.settings_rounded), onPressed: () => context.go('/settings')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RepaintBoundary(
            key: _repaintKey,
            child: GlassmorphicCard(
              padding: const EdgeInsets.all(16),
              glow: true,
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.brand.withValues(alpha: 0.15),
                        backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
                        child: user?.avatarUrl == null
                            ? Text(
                                user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'C',
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.brand),
                              )
                            : null,
                      ),
                      if (_uploading)
                        const Positioned.fill(
                          child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                        ),
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
                      Text(user?.email ?? 'offline@bisaas.test', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.xpGold.withValues(alpha: 0.15), borderRadius: AppRadii.smAll),
                          child: Text('Lv ${user?.level ?? 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.xpGold)),
                        ),
                        const SizedBox(width: 8),
                        CoinChip(coins: user?.coins ?? 0),
                      ]),
                    ]),
                  ),
                  IconButton(icon: const Icon(Icons.camera_alt_rounded, size: 20), onPressed: _uploading ? null : _pickAndUploadAvatar, tooltip: 'Change avatar'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: _shareCard, icon: const Icon(Icons.share_rounded, size: 16), label: const Text('Share card'))),
            const SizedBox(width: 10),
            Expanded(child: GradientButton(label: 'Edit avatar', icon: Icons.photo_rounded, onPressed: _uploading ? null : _pickAndUploadAvatar)),
          ]),
          const SizedBox(height: 16),
          // Stats grid — Streak (not quiz count), XP, Coins
          Row(
            children: [
              _StatChip(label: 'Streak', value: '${user?.streakDays ?? 0}d', icon: Icons.local_fire_department_rounded, color: AppColors.streakOrange),
              const SizedBox(width: 8),
              _StatChip(label: 'XP', value: '${user?.xp ?? 0}', icon: Icons.bolt_rounded, color: AppColors.xpGold),
              const SizedBox(width: 8),
              _StatChip(label: 'Coins', value: '${user?.coins ?? 0}', icon: Icons.monetization_on_rounded, color: AppColors.coinYellow),
            ],
          ),
          const SizedBox(height: 16),
          Text('Skill Radar', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          skillsAsync.when(
            data: (axes) => SkillRadarChart(axes: axes),
            loading: () => const SizedBox(height: 160, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.wrongRed.withValues(alpha: 0.08), borderRadius: AppRadii.smAll),
              child: Text('Skills failed: $e', style: const TextStyle(color: AppColors.wrongRed, fontSize: 12)),
            ),
          ),
          const SizedBox(height: 16),
          // Achievement gallery — live from /economy/achievements + /me/achievements/progress
          Text('Achievements', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          achievementsAsync.when(
            loading: () => const SizedBox(height: 96, child: Center(child: CircularProgressIndicator())),
            // Do not silently drop the section; say it failed.
            error: (e, _) => SizedBox(
              height: 56,
              child: Center(
                child: Text(
                  'Could not load achievements',
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
              ),
            ),
            data: (data) {
              final recent = data.achievements.where((a) => a.isCompleted).take(8).toList();
              if (recent.isEmpty) {
                return const SizedBox(
                  height: 64,
                  child: Center(child: Text('No badges yet — complete quizzes to earn them!', style: TextStyle(color: Colors.grey, fontSize: 12))),
                );
              }
              return SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: recent.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final a = recent[i];
                    final color = a.rarityColor;
                    return GlassmorphicCard(
                      padding: const EdgeInsets.all(10),
                      color: theme.colorScheme.surface,
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.verified_rounded, color: color, size: 22),
                        const SizedBox(height: 6),
                        Text(a.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('Unlocked', style: TextStyle(fontSize: 9, color: AppColors.correctGreen)),
                      ]),
                    );
                  },
                ),
              );
            },
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
          _Tile(icon: Icons.calculate_rounded, title: 'Calculators', subtitle: 'Civil formula engines', onTapRoute: '/calculators'),
          _Tile(icon: Icons.settings_rounded, title: 'Settings', subtitle: 'language • biometrics • logout', onTapRoute: '/settings'),
          const SizedBox(height: 24),
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
      child: GlassmorphicCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        color: c.withValues(alpha: 0.08),
        child: Row(children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 6),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: c)),
            Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiaryDark)),
          ]),
        ]),
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
    return GlassmorphicCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      // go, not push — shell route navigation requires go() on web
      onTap: () => context.go(onTapRoute),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.08), borderRadius: AppRadii.smAll),
          child: Icon(icon, size: 18, color: AppColors.brand),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Text(subtitle, style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiaryDark)),
        trailing: const Icon(Icons.chevron_right_rounded, size: 18),
      ),
    );
  }
}
