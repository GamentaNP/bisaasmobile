/// Shared façade for the XP / coin / streak chips owned by gamification.
///
/// The widgets genuinely are app-wide HUD pieces (profile and achievements
/// both render them), so consumers import this stable shared path instead of
/// reaching into the gamification feature's presentation folder.
library;

export '../../features/gamification/presentation/widgets/xp_progress_bar.dart'
    show CoinChip, StreakFire, XpProgressBar;
