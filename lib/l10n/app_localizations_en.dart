// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'CivilCal';

  @override
  String get signIn => 'Sign in';

  @override
  String get register => 'Register';

  @override
  String get quiz => 'Quiz';

  @override
  String get practice => 'Practice';

  @override
  String get calculators => 'Calculators';

  @override
  String get courses => 'Courses';

  @override
  String get continueAsGuest => 'Continue as guest';

  @override
  String get backend => 'Backend';

  @override
  String get env => 'Env';

  @override
  String get home => 'Home';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get offline => 'Offline';

  @override
  String get retry => 'Retry';

  @override
  String get error => 'Something went wrong';

  @override
  String streakDays(int days) {
    return 'Streak: $days days';
  }

  @override
  String coinsBalance(int count) {
    return '$count coins';
  }

  @override
  String get appLocked => 'CivilCal is locked';

  @override
  String get unlock => 'Unlock';

  @override
  String get unlockCivilCal => 'Unlock CivilCal';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonClose => 'Close';

  @override
  String get commonGoBack => 'Go Back';

  @override
  String get commonStay => 'Stay';

  @override
  String get commonExit => 'Exit';

  @override
  String get commonEmail => 'Email';

  @override
  String get commonPassword => 'Password';

  @override
  String get commonContinueWithGoogle => 'Continue with Google';

  @override
  String get commonContinueWithApple => 'Continue with Apple';

  @override
  String get commonOr => 'or';

  @override
  String get commonSkip => 'Skip';

  @override
  String get commonCheckAgain => 'Check again';

  @override
  String get commonContactSupport => 'Contact support';

  @override
  String get commonShareResult => 'Share Result';

  @override
  String commonPoints(int count) {
    return '$count pts';
  }

  @override
  String commonPercent(Object value) {
    return '$value%';
  }

  @override
  String commonXpGained(Object amount) {
    return '+$amount XP';
  }

  @override
  String get authWelcomeBackTitle => 'Welcome back';

  @override
  String get authWelcomeBackSubtitle =>
      'Sign in to access your quizzes, formulas, and ranking';

  @override
  String get authForgotPasswordTitle => 'Forgot Password?';

  @override
  String get authForgotPasswordSubtitle =>
      'Enter your registered email and we will send you instructions to reset your password.';

  @override
  String get authEmailAddressLabel => 'Email Address';

  @override
  String get authSendResetLink => 'Send Reset Link';

  @override
  String get authCheckEmailTitle => 'Check your email';

  @override
  String authCheckEmailBody(Object email) {
    return 'If an account exists with $email, you will receive a password reset link shortly.';
  }

  @override
  String get authReturnToLogin => 'Return to Login';

  @override
  String get authJoinTitle => 'Join CivilCal';

  @override
  String get authJoinSubtitle =>
      'Your companion for engineering exams and calculations';

  @override
  String get authFullNameLabel => 'Full Name';

  @override
  String get authConfirmPasswordLabel => 'Confirm Password';

  @override
  String get authCreateAccount => 'Create Account';

  @override
  String get authAlreadyHaveAccount => 'Already have an account?';

  @override
  String get authNoAccount => 'Don\'t have an account?';

  @override
  String get authSetNewPasswordTitle => 'Set a new password';

  @override
  String get authResetTitle => 'Choose a new password';

  @override
  String get authResetSubtitle =>
      'You will be signed out everywhere, including this device.';

  @override
  String get authResetMissingToken =>
      'This link is missing its reset token. Open the link from your email, or request a new one.';

  @override
  String get authRequestNewLink => 'Request a new link';

  @override
  String get authRequestNewLinkInstead => 'Request a new link instead';

  @override
  String get authNewPasswordLabel => 'New password';

  @override
  String get authConfirmNewPasswordLabel => 'Confirm new password';

  @override
  String authMinChars(int count) {
    return 'At least $count characters';
  }

  @override
  String get authVerifyEmailBanner =>
      'Verify your email to unlock every feature.';

  @override
  String get authSplashTagline => 'BiSaaS Engineering Learning Ecosystem';

  @override
  String get authInvalidEmail => 'Enter a valid email';

  @override
  String get authPasswordRequired => 'Please enter your password';

  @override
  String onboardingStepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get onboardingTargetExamTitle => 'Target Examination';

  @override
  String get onboardingTargetExamBody =>
      'Sets the syllabus this account studies towards.';

  @override
  String get onboardingDailyGoalTitle => 'Daily Practice Goal';

  @override
  String get onboardingDailyGoalBody =>
      'How much time would you like to dedicate each day? You can change this anytime.';

  @override
  String onboardingMinutesPerDay(Object minutes, Object label) {
    return '$minutes mins / day — $label';
  }

  @override
  String get onboardingCurrentLevelTitle => 'Your Current Level';

  @override
  String get onboardingCurrentLevelBody =>
      'Sets where your streak and revision queue start from.';

  @override
  String get quizHomeTitle => 'Practice & Quiz';

  @override
  String get quizHomeLoadError => 'Could not load quiz';

  @override
  String get quizHomeEmptyTitle => 'No quizzes yet';

  @override
  String get quizHomeEmptyBody =>
      'Question sets for your exam are being prepared. Check back soon.';

  @override
  String get quizPlayWorlds => 'Play Worlds';

  @override
  String get quizPlayWorldsSubtitle =>
      'Chapters, levels and bosses — earn stars as you go';

  @override
  String get quizPracticeDrill => 'Practice drill';

  @override
  String get quizPracticeDrillSubtitle =>
      'Drill your bookmarks and weak topics — untimed, no rank effect';

  @override
  String get quizIntroDetailsTitle => 'Quiz Details';

  @override
  String quizIntroLoadFailed(Object reason) {
    return 'Failed to load quiz: $reason';
  }

  @override
  String get quizIntroQuestions => 'Questions';

  @override
  String get quizIntroMinutes => 'min';

  @override
  String get quizIntroStart => 'Start Quiz';

  @override
  String get quizIntroHowItWorks => 'How it works';

  @override
  String get quizAttemptLoadError => 'Could not load quiz';

  @override
  String get quizAttemptOfflineNotice =>
      'Offline practice — not official. XP/coins will reconcile when back online.';

  @override
  String quizAttemptUnsupportedEffect(Object effect) {
    return '$effect used — the server returned an effect this app cannot show yet.';
  }

  @override
  String quizAttemptCombo(int count) {
    return '×$count Combo!';
  }

  @override
  String get quizAttemptExitTitle => 'Exit Quiz?';

  @override
  String get quizAttemptExitBody =>
      'Your current progress will be lost. Are you sure you want to exit?';

  @override
  String get quizResultTitle => 'Quiz Complete!';

  @override
  String get quizResultAccuracy => 'Accuracy';

  @override
  String quizResultCorrectOf(Object correct, int total) {
    return '$correct of $total correct';
  }

  @override
  String get quizResultCorrect => 'Correct';

  @override
  String get quizResultXpEarned => 'XP Earned';

  @override
  String get quizResultCoins => 'Coins';

  @override
  String get quizResultAnswerReview => 'Answer Review';

  @override
  String get quizResultBackToHome => 'Back to Home';

  @override
  String get quizResultReviewAll => 'Review All Answers';

  @override
  String get quizResultMorePractice => 'More Practice';

  @override
  String quizResultShareFailed(Object reason) {
    return 'Share unavailable: $reason';
  }

  @override
  String get quizReviewTitle => 'Review Answers';

  @override
  String quizReviewLoadFailed(Object reason) {
    return 'Failed to load review: $reason';
  }

  @override
  String get quizReviewEmpty => 'No answers to review';

  @override
  String get quizReviewYourAnswer => 'Your answer';

  @override
  String get quizReviewNotAnswered => 'Not answered';

  @override
  String quizReviewQuestionNumber(Object number) {
    return 'Q$number';
  }

  @override
  String get quizFunnelTryItOut => 'Try it out';

  @override
  String get quizFunnelSampleTitle => 'Sample questions';

  @override
  String quizFunnelShown(int count) {
    return '$count shown';
  }

  @override
  String get quizFunnelEmptyTitle => 'No sample questions yet';

  @override
  String get quizFunnelEmptyBody =>
      'The catalogue has no public questions published right now. Sign up and you will see everything.';

  @override
  String get quizFunnelCreateAccount => 'Create a free account to play';

  @override
  String get quizFunnelPlayGraded => 'Play a graded quiz';

  @override
  String get quizFunnelPracticeNote =>
      'Practice mode never affects rank, XP or streak.';

  @override
  String quizOfflinePractice(Object subject) {
    return 'Offline Practice — $subject';
  }

  @override
  String get quizFinishFailed => 'Could not finish the quiz. Please try again.';

  @override
  String get quizCountUnavailable => 'Count unavailable';

  @override
  String get calcBrowserEmpty => 'No calculators published';

  @override
  String calcBrowserCount(int count, Object domains) {
    return '$count calculators • $domains domains';
  }

  @override
  String get calcBrowserLoadError => 'Could not load calculators';

  @override
  String calcShareFailed(Object reason) {
    return 'Could not share this result: $reason';
  }

  @override
  String calcNoInputNamed(Object name) {
    return 'No input named \"$name\" on this calculator';
  }

  @override
  String get calcAddInput => 'Add at least one input';

  @override
  String calcInputsLabel(Object label) {
    return 'Inputs · $label';
  }

  @override
  String get calcInputsLegacy => 'Inputs (legacy)';

  @override
  String get calcKeyLabel => 'key';

  @override
  String get calcKeyExample => 'e.g. length';

  @override
  String get calcValueLabel => 'value';

  @override
  String get calcValueExample => 'e.g. 12.5';

  @override
  String get calcAssistantTitle => 'Ask the assistant';

  @override
  String get calcAssistantExample =>
      'e.g. a 3 m wide, 4 m deep slab for a 25 MPa mix';

  @override
  String get calcAssistantSuggested => 'Suggested values';

  @override
  String get calcAssistantAlso => 'You could also ask';

  @override
  String calcHistoryTitle(Object subject) {
    return '$subject · history';
  }

  @override
  String get calcHistoryEmpty => 'No saved calculations yet';

  @override
  String get calcStepByStep => 'Step-by-step';

  @override
  String get calcShareResult => 'Share result';

  @override
  String get calcPracticeRelated => 'Practice related questions';

  @override
  String get calcViewHistory => 'View history';

  @override
  String get calcNoSchema =>
      'Server did not return a field schema. Falling back to generic key/value editor.';

  @override
  String get calcAddField => 'Add field';

  @override
  String calcInputsCount(int count) {
    return 'inputs: $count';
  }

  @override
  String get calcAsk => 'Ask';

  @override
  String get calcApply => 'Apply';

  @override
  String get calcAssistantDisclaimer =>
      'The assistant suggests; you decide. Calculations are always performed by the server.';

  @override
  String homeGreeting(Object name) {
    return 'Hi, $name 👋';
  }

  @override
  String homeLevel(Object level, Object xp) {
    return 'Level $level • $xp XP';
  }

  @override
  String get homeDaily => 'Daily';

  @override
  String get homeBattle => 'Battle';

  @override
  String get homeBrowse => 'Browse';

  @override
  String get homeExplore => 'Explore';

  @override
  String get homeCurrentCourse => 'CURRENT COURSE';

  @override
  String homePercentDone(Object percent) {
    return '$percent% Done';
  }

  @override
  String get homeMissionsUnavailable => 'Missions unavailable';

  @override
  String get homeWorldsLoadError => 'Could not load your worlds';

  @override
  String get homeWorldsEmpty =>
      'No worlds published yet — browse topics to keep practising.';

  @override
  String get homeYourWorlds => 'Your worlds';

  @override
  String homeStars(Object earned, int total) {
    return '$earned / $total ⭐';
  }

  @override
  String homeContinue(Object title) {
    return 'Continue: $title';
  }

  @override
  String get homeDashboardLoadError => 'Could not load your dashboard';

  @override
  String get homeDashboardEmpty =>
      'Nothing is shown rather than guessing. Pull to refresh, or retry below.';

  @override
  String get homeDashboardUnreachable =>
      'Could not reach the server, so the dashboard cannot be shown.';

  @override
  String get consentTitle => 'Privacy choices';

  @override
  String get consentIntro =>
      'Your account and quiz progress are stored on our servers so you can sign in on any device. To make that work and to keep the app stable we also send a device identifier, a push-notification token, crash reports and a device security check. With your permission we also send anonymous usage events. You can change this at any time in Settings → Privacy.';

  @override
  String get consentNecessary => 'Necessary';

  @override
  String get consentNecessaryBody =>
      'Sign-in and your saved work, your push-notification token, crash reports, and a device security check. Required for the app to work.';

  @override
  String get consentFunctional => 'Functional';

  @override
  String get consentFunctionalBody =>
      'Remember settings such as your language and filters on this device.';

  @override
  String get consentAnalytics => 'Analytics';

  @override
  String get consentAnalyticsBody =>
      'Usage events that tell us which features are useful. They are tied to a device identifier rather than to your account. No question content is ever included.';

  @override
  String get consentMarketing => 'Marketing';

  @override
  String get consentMarketingBody =>
      'Offers and promotions. Off unless you ask for it.';

  @override
  String get consentSaveChoices => 'Save choices';

  @override
  String get consentNecessaryOnly => 'Continue with necessary only';

  @override
  String get consentLoadError => 'Could not load your choices';

  @override
  String get consentNecessaryAlwaysOn =>
      'Always on. Your account, saved work, push token, crash reports and device security check.';

  @override
  String get consentDataStored => 'Data stored about this device';

  @override
  String get consentDataStoredSubtitle =>
      'View, and erase, the anonymous profile';

  @override
  String get consentFootnote =>
      'Turning off a category stops that collection from that moment. It does not delete data already collected — for that, use the link above or contact privacy@bisaas.com.';

  @override
  String get privacyTitle => 'Your data';

  @override
  String get privacyAnonymousProfile => 'Anonymous profile';

  @override
  String privacyReference(Object reference) {
    return 'Reference $reference';
  }

  @override
  String get privacyEraseData => 'Erase stored data';

  @override
  String get privacyLocalChoices => 'Local choices';

  @override
  String get privacyEraseTitle => 'Erase stored data?';

  @override
  String get privacyEraseBody =>
      'This deletes the anonymous profile and every intent event stored for this device. It cannot be undone.';

  @override
  String get privacyErased => 'Stored data erased';

  @override
  String get privacyEraseFailed => 'Could not erase your data. Try again.';

  @override
  String get privacyEraseConfirm => 'Erase';

  @override
  String get privacyMenu => 'Privacy';

  @override
  String get notificationDailyTitle => 'Daily Sprint ready ⚡';

  @override
  String get notificationDailyBody =>
      'Your daily MCQs are waiting — keep the streak alive!';

  @override
  String get forceUpdateTitle => 'Update required';

  @override
  String forceUpdateYourVersion(Object version) {
    return 'Your version: $version';
  }

  @override
  String get forceUpdateNow => 'Update now';

  @override
  String get forceUpdateReassurance =>
      'Your account and progress are safe — nothing is lost by updating.';

  @override
  String forceUpdateStoreFailed(Object url) {
    return 'Could not open the store. Visit $url';
  }

  @override
  String get maintenanceTitle => 'We\'ll be right back';

  @override
  String get maintenanceBody =>
      'CivilCal is down for a short maintenance. Your account, coins and progress are safe — nothing has been lost.';

  @override
  String get versionUnsupported => 'This app version is no longer supported.';

  @override
  String get authUpdating => 'Updating…';

  @override
  String get authUpdatePassword => 'Update password';

  @override
  String get authVerificationResentBody =>
      'If that address still needs verifying, a new link is on its way. Check your inbox and spam folder.';

  @override
  String get authVerificationResentHint =>
      'We send a one-tap verification link to the address on your account.';

  @override
  String get authVerificationSent => 'Verification sent';

  @override
  String get authResendVerification => 'Resend verification email';

  @override
  String calcSearchInDomain(Object scope) {
    return 'Search $scope calculators…';
  }

  @override
  String get calcSearchPlaceholder => 'Search calculators…';

  @override
  String get calcCalculating => 'Calculating…';

  @override
  String get calcCalculateServer => 'Calculate (server)';

  @override
  String calcVia(Object source) {
    return 'via $source';
  }

  @override
  String homeMissionsReady(int count) {
    return '$count missions ready to claim';
  }

  @override
  String homeMissionsActive(int count) {
    return 'Missions — $count active';
  }

  @override
  String get onboardingStartLearning => 'Start Learning';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get privacyLinkedToAccount =>
      'This profile is linked to your account. Delete the account to erase everything.';

  @override
  String get quizSeeResults => 'See Results';

  @override
  String get quizNextQuestion => 'Next Question';

  @override
  String get quizAnswerSubmitted => 'Answer submitted';

  @override
  String get quizBrowseQuizzes => 'Browse Quizzes';

  @override
  String get quizPickTopic => 'Pick a Topic';

  @override
  String get quizSearchCourses => 'Search courses…';

  @override
  String get quizSearchTopics => 'Search topics…';

  @override
  String get quizNoCoursesYet => 'No courses yet';

  @override
  String get quizNoMatches => 'No matches';

  @override
  String get quizSetsBeingPrepared =>
      'Question sets for your exam are being prepared.';

  @override
  String get quizTryDifferentSearch => 'Try a different search';

  @override
  String get quizNoTopicsYet => 'No topics yet';

  @override
  String get quizCourseNoActiveTopics =>
      'This course has no active topics yet.';

  @override
  String get quizFunnelSampleBody =>
      'Sample questions from our catalogue. Open the Quiz tab to play a full graded session.';

  @override
  String get quizFunnelPublicBody =>
      'Public questions from our catalogue. Answers unlock when you create a free account.';

  @override
  String get quizFreshQuestions => 'Fresh questions were added recently.';

  @override
  String quizNewIn(Object scope) {
    return 'New in $scope';
  }

  @override
  String get quizNoQuestionText => 'This question has no text on the server.';

  @override
  String get quizGraded => 'Graded';

  @override
  String get quizXp => 'XP';

  @override
  String get quizByServer => 'by server';

  @override
  String get profileAvatarUploaded => 'Avatar uploaded';

  @override
  String get profileAvatarUpdated => 'Avatar updated';

  @override
  String profileUploadFailed(Object reason) {
    return 'Upload failed: $reason';
  }

  @override
  String get profileEditName => 'Edit name';

  @override
  String get profileDisplayName => 'Display name';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String profileUpdateFailed(Object reason) {
    return 'Update failed: $reason';
  }

  @override
  String profileShareCardText(Object level) {
    return 'My CivilCal profile — Level $level Engineer. https://bisaas.com';
  }

  @override
  String profileShareFailed(Object reason) {
    return 'Share failed: $reason';
  }

  @override
  String get profileShareCard => 'Share card';

  @override
  String profileLevel(Object level) {
    return 'Lv $level';
  }

  @override
  String get profileChangeAvatar => 'Change avatar';

  @override
  String get profileEditAvatar => 'Edit avatar';

  @override
  String get profileStreak => 'Streak';

  @override
  String get profileSkillRadar => 'Skill Radar';

  @override
  String profileSkillsFailed(Object reason) {
    return 'Skills failed: $reason';
  }

  @override
  String get profileAchievements => 'Achievements';

  @override
  String get profileAchievementsLoadFailed => 'Could not load achievements';

  @override
  String get profileNoBadges =>
      'No badges yet — complete quizzes to earn them!';

  @override
  String get profileUnlocked => 'Unlocked';

  @override
  String get profileSkillRadarEmpty =>
      'Take quizzes to reveal your skill radar.';

  @override
  String get profileSkillRadarEmptyHint =>
      'Answer more categories to reveal your skill radar.';

  @override
  String get profileLearning => 'Learning — tracks & AI tutor';

  @override
  String get profileLearningSub => 'study plans • revisions • tutor';

  @override
  String get profileEice => 'Exam Intelligence (EICE)';

  @override
  String get profileEiceSub => 'coach • triage • sprint';

  @override
  String get profilePsc => 'PSC / Loksewa';

  @override
  String get profilePscSub => 'exam blueprints & syllabus';

  @override
  String get profilePracticeSub => 'drill bookmarks • weak topics';

  @override
  String get profileLeaderboard => 'Leaderboard';

  @override
  String get profileLeaderboardSub => 'global • friends • league';

  @override
  String get profileContests => 'Contests';

  @override
  String get profileContestsSub => 'live quizzes & leaderboards';

  @override
  String get profileLiveEvents => 'Live events';

  @override
  String get profileLiveEventsSub => 'scheduled sessions & check-in';

  @override
  String get profileCoaching => 'Coaching';

  @override
  String get profileCoachingSub => 'weak areas • readiness • sprint';

  @override
  String get profileSearch => 'Search';

  @override
  String get profileSearchSub => 'find any question';

  @override
  String get profileNotifications => 'Notifications';

  @override
  String get profileNotificationsSub => 'activity & reminders';

  @override
  String get profileSocial => 'Social & Referral';

  @override
  String get profileSocialSub => 'share • streak • leaderboard';

  @override
  String get profileWallet => 'Wallet';

  @override
  String get profileWalletSub => 'coins & ledger';

  @override
  String get profileAchievementsSub => 'streak + badges';

  @override
  String get profileOffline => 'Offline content';

  @override
  String get profileOfflineSub => 'cached packs + prefetch';

  @override
  String get profileCalculatorsSub => 'Civil formula engines';

  @override
  String get profileSettingsSub => 'language • biometrics • logout';

  @override
  String get settingsSubscriptionActive =>
      'Subscription must be cancelled before deletion';

  @override
  String get settingsDeleteFailed =>
      'Could not delete account — please try again';

  @override
  String get settingsAccountDeleted => 'Your account has been deleted';

  @override
  String get settingsNoBiometrics => 'No biometrics enrolled on this device';

  @override
  String get settingsLanguageLocalOnly =>
      'Language saved on this device only — could not reach the server.';

  @override
  String get settingsSystemDefault => 'System default';

  @override
  String get settingsAppLanguage => 'App language';

  @override
  String get settingsBiometricLock => 'Biometric app lock';

  @override
  String get settingsBiometricLockSub =>
      'Require biometrics after 30s in background';

  @override
  String get settingsPrivacySub =>
      'Analytics, functional and marketing consent';

  @override
  String get settingsAiUsage => 'Your AI usage';

  @override
  String get settingsAiUsageSub => 'What AI used on your behalf, by feature';

  @override
  String get settingsAiKeys => 'Your AI keys';

  @override
  String get settingsAiKeysSub => 'Run AI features on your own provider quota';

  @override
  String get settingsLogOut => 'Log out';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get settingsDeleteAccountSub =>
      'Permanently erase your account, attempts and purchases';

  @override
  String get settingsDeleteAccountTitle => 'Delete account?';

  @override
  String get settingsDeleteAccountBody =>
      'This permanently deletes your account, quiz history, coins and purchases. This cannot be undone.';

  @override
  String get settingsTypeDeleteToConfirm => 'Type \'DELETE\' to confirm';

  @override
  String get settingsDeleteConfirm => 'Delete';

  @override
  String get streakRefresh => 'Refresh';

  @override
  String get streakNoneTitle => 'No streak yet';

  @override
  String get streakNoneBody => 'Complete a quiz to start your fire streak.';

  @override
  String get streakCalendar => 'Calendar';

  @override
  String get streakOnFire => 'You are on fire today — keep it up!';

  @override
  String get streakProtect => 'Protect your streak';

  @override
  String get streakFrozen => 'Streak frozen for 30 days!';

  @override
  String get streakCurrent => 'Current streak';

  @override
  String get streakDaysUnit => 'days';

  @override
  String streakBest(int count) {
    return 'Best: $count days';
  }

  @override
  String get streakMultiplier => 'multiplier';

  @override
  String get streakMaxMultiplier => 'Max multiplier reached — legendary!';

  @override
  String streakDaysToNextTier(int current, int total) {
    return '$current / $total days to next tier';
  }

  @override
  String get streakTiers =>
      '1–6d → 1.0× • 7–29d → 1.5× • 30–99d → 2.0× • 100+d → 3.0×';

  @override
  String get streakFreezeSection => 'Streak freeze';

  @override
  String streakFreezeLeft(int count) {
    return '$count left';
  }

  @override
  String streakFrozenUntil(Object date) {
    return 'Frozen until $date';
  }

  @override
  String get streakFreezeHint =>
      'Spend 50 coins to freeze streak for 30 days when you cannot play. Donor badge required.';

  @override
  String get streakExtendFreeze => 'Extend freeze';

  @override
  String get streakFreezeAction => 'Freeze streak (50 coins)';

  @override
  String get streakRepairTitle => 'Repair a missed day';

  @override
  String get streakRepairAction => 'Repair streak';

  @override
  String get streakInsurance => 'Streak insurance';

  @override
  String get streakInsuranceChecking => 'Checking insurance…';

  @override
  String get streakBuy => 'Buy';

  @override
  String get streakUseNow => 'Use now';

  @override
  String get streakWager => 'Streak wager';

  @override
  String get streakWagerDescription =>
      'Stake coins on hitting a target streak. Meet it and you win the pot back with interest — miss and the coins are gone.';

  @override
  String streakWagerDay(int current, int total, Object reward) {
    return 'Day $current of $total — keep playing to win $reward coins.';
  }

  @override
  String get streakWagerStart => 'Start a wager';

  @override
  String get streakWagerInProgress => 'Wager in progress';

  @override
  String get streakWagerStartTitle => 'Start a streak wager';

  @override
  String get streakWagerStartBody =>
      'Hit the target streak to win double. Miss it and the stake is gone.';

  @override
  String get streakWagerStake => 'Stake (coins)';

  @override
  String get streakWagerDays => 'Days to sustain';

  @override
  String streakXpMultiplier(Object value) {
    return '×$value XP';
  }

  @override
  String streakWagerProgress(Object percent) {
    return '$percent% complete';
  }

  @override
  String get streakFreezeDuration => '30 days';

  @override
  String streakWagerDaysCount(int count) {
    return '$count days';
  }

  @override
  String streakWagerSummary(Object coins, int days) {
    return 'Wager $coins coins for $days days';
  }

  @override
  String get forceUpdateUnsupportedLatest =>
      'This version of CivilCal is no longer supported. Please update to the latest version to continue.';

  @override
  String forceUpdateUnsupportedVersion(Object version) {
    return 'This version of CivilCal is no longer supported. Please update to version $version or later to continue.';
  }

  @override
  String routeNotFound(Object path) {
    return 'Route not found: $path';
  }
}
