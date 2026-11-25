/// Shared façade for the generic Lottie overlay owned by gamification.
///
/// Keeps quiz result screens from importing a sibling feature's presentation
/// directory while preserving the public widget name and behaviour.
library;

export '../../features/gamification/presentation/widgets/lottie_overlay.dart'
    show LottieOverlay;
