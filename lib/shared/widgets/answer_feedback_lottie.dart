/// Shared façade for the answer-feedback Lottie overlays owned by gamification.
///
/// Quiz is the consumer, but the animation is genuinely reusable feedback UI;
/// routing it through `shared/` keeps quiz from importing gamification.
library;

export '../../features/gamification/presentation/widgets/answer_feedback_lottie.dart'
    show AnswerFeedbackLottie, CoinFloat, XpFloat, XpFloatAnimator;
