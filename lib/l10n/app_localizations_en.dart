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
  String streakDays(Object days) {
    return 'Streak: $days days';
  }

  @override
  String coinsBalance(Object count) {
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
  String commonPoints(Object count) {
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
  String authMinChars(Object count) {
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
  String onboardingStepOf(Object current, Object total) {
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
  String quizAttemptCombo(Object count) {
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
  String quizResultCorrectOf(Object correct, Object total) {
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
  String quizFunnelShown(Object count) {
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
  String calcBrowserCount(Object count, Object domains) {
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
  String calcInputsCount(Object count) {
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
  String homeStars(Object earned, Object total) {
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
  String homeMissionsReady(Object count) {
    return '$count missions ready to claim';
  }

  @override
  String homeMissionsActive(Object count) {
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
  String get profilePscSub => 'exam blueprints & syllabus';

  @override
  String get profilePracticeSub => 'drill bookmarks • weak topics';

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
  String get profileSearchSub => 'find any question';

  @override
  String get profileNotificationsSub => 'activity & reminders';

  @override
  String get profileSocial => 'Social & Referral';

  @override
  String get profileSocialSub => 'share • streak • leaderboard';

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
  String get settingsAiUsageSub => 'What AI used on your behalf, by feature';

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
  String streakBest(Object count) {
    return 'Best: $count days';
  }

  @override
  String get streakMultiplier => 'multiplier';

  @override
  String get streakMaxMultiplier => 'Max multiplier reached — legendary!';

  @override
  String streakDaysToNextTier(Object current, Object total) {
    return '$current / $total days to next tier';
  }

  @override
  String get streakTiers =>
      '1–6d → 1.0× • 7–29d → 1.5× • 30–99d → 2.0× • 100+d → 3.0×';

  @override
  String get streakFreezeSection => 'Streak freeze';

  @override
  String streakFreezeLeft(Object count) {
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
  String streakWagerDay(Object current, Object total, Object reward) {
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
  String streakWagerDaysCount(Object count) {
    return '$count days';
  }

  @override
  String streakWagerSummary(Object coins, Object days) {
    return 'Wager $coins coins for $days days';
  }

  @override
  String get tutorStudyPlan => 'Study Plan';

  @override
  String get tutorChat => 'Chat';

  @override
  String get tutorPlanTab => 'Plan';

  @override
  String get tutorInsights => 'Insights';

  @override
  String get tutorRevisions => 'Revisions';

  @override
  String get tutorWeekly => 'Weekly';

  @override
  String get tutorNoTasksToday => 'No tasks today — check back tomorrow';

  @override
  String get tutorDone => 'Done';

  @override
  String tutorTasksDone(Object done, Object total) {
    return '$done/$total tasks';
  }

  @override
  String get tutorDayCompleted => 'Day completed — plan updated.';

  @override
  String get tutorMarkDayComplete => 'Mark day complete';

  @override
  String tutorYourPlan(Object title) {
    return 'Your plan — $title';
  }

  @override
  String tutorPlanDays(Object days, Object current) {
    return '$days days • current $current';
  }

  @override
  String get tutorPlanNoDays =>
      'Plan has no days yet — onboarding will generate it.';

  @override
  String tutorMoreDays(Object count) {
    return '+ $count more days';
  }

  @override
  String get tutorAdjustPlan => 'Adjust plan';

  @override
  String get tutorNoPlanYet => 'No plan yet';

  @override
  String get tutorOnboardingRequired =>
      'Complete tutor onboarding to generate your personalized study plan.';

  @override
  String get tutorStartOnboarding => 'Start onboarding';

  @override
  String get tutorAdjustExample =>
      'e.g., \"I can do 3h/day\" or \"Focus more on soil mechanics\"';

  @override
  String get tutorAdjustPrompt => 'How should we adjust?';

  @override
  String get tutorAdjustRequested => 'Plan adjustment requested.';

  @override
  String get tutorSubmit => 'Submit';

  @override
  String get tutorProjectedScore => 'Projected score';

  @override
  String tutorConfidence(Object confidence, Object trend) {
    return 'Confidence $confidence% • $trend';
  }

  @override
  String get tutorWeakAreas => 'Weak areas';

  @override
  String get tutorNoWeakAreas =>
      'No weak areas — great work! Keep practicing to stay sharp.';

  @override
  String tutorAccuracy(Object accuracy, Object attempts) {
    return 'Accuracy $accuracy% • $attempts attempts';
  }

  @override
  String get tutorNoRevisionsDue => 'No revisions due — you are on track.';

  @override
  String tutorDueLabel(Object date) {
    return 'due $date';
  }

  @override
  String tutorTopicDue(Object topic, Object date) {
    return '$topic • due $date';
  }

  @override
  String get tutorCompleted => 'Completed';

  @override
  String get tutorOverdue => 'Overdue';

  @override
  String get tutorDue => 'Due';

  @override
  String tutorWeekRange(Object start, Object end) {
    return 'Week $start → $end';
  }

  @override
  String get tutorAvgScore => 'Avg score';

  @override
  String get tutorHours => 'Hours';

  @override
  String tutorCompletion(Object percent) {
    return '$percent% completion';
  }

  @override
  String get tutorHighlights => 'Highlights';

  @override
  String get tutorWeeklyReportPending =>
      'Weekly report appears after a week of activity.';

  @override
  String get tutorOnboardingSaved =>
      'Onboarding saved — plan will generate shortly.';

  @override
  String get tutorOnboardingTitle => 'Tutor Onboarding';

  @override
  String get tutorPersonalised => 'Personalized tutor';

  @override
  String get tutorOnboardingExplain =>
      'Tell us your goal — the server builds your plan. No user_id required (token-bound).';

  @override
  String tutorSessionLabel(Object session) {
    return 'Session: $session';
  }

  @override
  String get tutorYourGoal => 'Your goal';

  @override
  String get tutorGoalExample => 'e.g., Crack PSC Civil in 6 months';

  @override
  String get tutorCurrentLevel => 'Current level';

  @override
  String get tutorLevelExample => 'e.g., Final year B.E. Civil';

  @override
  String get tutorHoursPerDay => 'Hours per day';

  @override
  String get tutorHoursExample => 'e.g., 2';

  @override
  String get tutorOnboardingComplete =>
      'Onboarding complete — your plan is ready.';

  @override
  String get tutorViewPlan => 'View Plan';

  @override
  String get tutorCompleteOnboarding => 'Complete onboarding';

  @override
  String get tutorSkipToChat => 'Skip → Chat with tutor';

  @override
  String get tutorSavedToAccount =>
      'Saved to your account. Safe to retry if the connection drops.';

  @override
  String get tutorTitle => 'AI Tutor';

  @override
  String get tutorClearChat => 'Clear chat';

  @override
  String get tutorNotEnoughHistory =>
      'Not enough history yet — complete a few quizzes to personalize.';

  @override
  String get tutorDismiss => 'Dismiss';

  @override
  String get tutorWriting =>
      'The tutor is writing its reply. It can take a moment on longer questions.';

  @override
  String get tutorAskAnything => 'Ask anything';

  @override
  String get tutorChatExplain =>
      'Exam concepts, beam deflection, soil mechanics — AI answers via Laravel gateway (never direct provider).';

  @override
  String get tutorExample1 => 'Explain proctor compaction';

  @override
  String get tutorExample2 => 'Weekly plan help';

  @override
  String get tutorExample3 => 'Weak areas?';

  @override
  String get tutorTyping => 'Tutor is typing…';

  @override
  String get tutorInputHint => 'Ask tutor…';

  @override
  String get aiUsageTitle => 'Your AI usage';

  @override
  String get aiUsageOverview => 'Overview';

  @override
  String get aiUsageRequests => 'requests';

  @override
  String get aiUsageTokens => 'tokens';

  @override
  String get aiUsageTutorChats => 'tutor chats (all time)';

  @override
  String get aiUsageNone => 'No AI features were used in this period.';

  @override
  String get aiUsageByFeature => 'By feature';

  @override
  String get aiUsageTutorConversations => 'Tutor conversations';

  @override
  String get aiUsageNoConversations => 'No tutor conversations yet.';

  @override
  String get aiUsageLoadMoreConversations => 'Load more conversations';

  @override
  String get aiUsageWeeklyReport => 'Weekly report card';

  @override
  String get aiUsageNoWeeks => 'No weekly summaries stored yet.';

  @override
  String get aiUsageLoadMoreWeeks => 'Load more weeks';

  @override
  String aiUsageConversationNumber(Object number) {
    return 'Conversation #$number';
  }

  @override
  String aiUsageQuestionNumber(Object number) {
    return 'Question $number';
  }

  @override
  String aiUsageTurns(Object count) {
    return '$count turns';
  }

  @override
  String aiUsageWeekOf(Object date) {
    return 'Week of $date';
  }

  @override
  String aiUsageWeekSummary(
    Object accuracy,
    Object xp,
    Object coins,
    Object streak,
  ) {
    return '$accuracy% accuracy • $xp XP • $coins coins • $streak day streak';
  }

  @override
  String aiUsageHoursShort(Object hours) {
    return '${hours}h';
  }

  @override
  String get aiKeysTitle => 'Your AI keys';

  @override
  String get aiKeysExplain =>
      'Your key is encrypted on our servers and never shown again. Only the last four characters are ever displayed.';

  @override
  String get aiKeysAddTitle => 'Add a key';

  @override
  String get aiKeysNoneYet => 'No keys yet';

  @override
  String get aiKeysNoneExplain =>
      'Add a provider key to run AI features on your own quota instead of the shared one.';

  @override
  String get aiKeysStored => 'Stored keys';

  @override
  String aiKeysTokensUsed(Object used, Object total) {
    return '$used of $total daily tokens used';
  }

  @override
  String get aiKeysRevoke => 'Revoke';

  @override
  String get aiKeysTooShort => 'The key must be at least 8 characters';

  @override
  String get aiKeysAddProvider => 'Add a provider key';

  @override
  String get aiKeysProvider => 'Provider';

  @override
  String get aiKeysApiKey => 'API key';

  @override
  String get aiKeysSentOnce => 'Sent once and never shown again.';

  @override
  String get aiKeysLabelOptional => 'Label (optional)';

  @override
  String get aiKeysSaveKey => 'Save key';

  @override
  String aiKeysSaved(Object name) {
    return '$name saved. It is encrypted on our servers and never shown again.';
  }

  @override
  String get aiKeysRevoked => 'Key revoked.';

  @override
  String get practiceBookmarks => 'Bookmarks';

  @override
  String get practiceWeakTopics => 'Weak Topics';

  @override
  String get practiceSelfChallenge => 'Self Challenge';

  @override
  String get practiceHistory => 'History';

  @override
  String get practiceNoBookmarks => 'No bookmarks to practice';

  @override
  String get practiceBookmarkedPractice => 'Bookmarked Practice';

  @override
  String practiceBookmarksUnavailable(Object count, Object total) {
    return '$count of $total bookmarks could not be drilled — the server does not publish their answer options yet.';
  }

  @override
  String get practiceDrill => 'Practice Drill';

  @override
  String practiceDrillCount(Object count) {
    return 'Drill: $count';
  }

  @override
  String get practiceNoBookmarksBody => 'No bookmarks';

  @override
  String get practiceNoBookmarksHint =>
      'Bookmark questions while you take a quiz and they will show up here for drilling later.';

  @override
  String get practiceBrowseQuizzes => 'Browse quizzes';

  @override
  String practiceBookmarkedCount(Object count) {
    return '$count bookmarked';
  }

  @override
  String get practiceAll => 'Practice all';

  @override
  String practiceQuestionNumber(Object number) {
    return 'Question #$number';
  }

  @override
  String practiceQuestionMeta(Object meta, Object difficulty, Object points) {
    return '$meta • difficulty $difficulty • $points pts';
  }

  @override
  String get practiceBookmarked => 'Bookmarked';

  @override
  String get practiceLoadMoreCursor => 'Load more (cursor)';

  @override
  String get practiceWeakTopicsLoadFailed => 'Could not load your weak topics';

  @override
  String get practiceWeakTopicsExplained =>
      'These are worked out from your own answer history. Nothing is shown unless it is real.';

  @override
  String get practiceNoWeakTopics => 'No weak topics yet';

  @override
  String get practiceWeakTopicsNeedsAttempts =>
      'The server needs graded attempts before it can spot weak areas. Take a quiz from the Quiz tab and check back.';

  @override
  String get practiceWeakTopicsServerNote =>
      'Weak topics are worked out on our servers from your answer history, so nothing here is guessed.';

  @override
  String get practiceYourWeakTopics => 'Your weak topics';

  @override
  String get practiceDrillAction => 'Drill';

  @override
  String get practiceDrillTen => 'Drill 10 questions (practice mode, untimed)';

  @override
  String get practiceUntimedNote =>
      'Practice is untimed and does not affect your rank or coin balance.';

  @override
  String get practiceSelfChallengeExplain =>
      'Pick question count & difficulty — mirrors Elite Quiz self-challenge but sourced from adaptive engine.';

  @override
  String practiceQuestionCount(Object count) {
    return 'Question count: $count';
  }

  @override
  String get practiceDifficulty => 'Difficulty';

  @override
  String get practiceStarting => 'Starting…';

  @override
  String practiceStartChallenge(Object count) {
    return 'Start challenge ($count Qs)';
  }

  @override
  String get practiceResultsLabelled =>
      'Results are labelled as practice, so they never count towards your rank.';

  @override
  String get practiceNoHistory => 'No history';

  @override
  String get practiceNoHistoryBody =>
      'Your completed practice sessions will appear here.';

  @override
  String practiceAttemptMeta(Object number, Object mode) {
    return 'Attempt #$number • $mode';
  }

  @override
  String practiceAttemptSummary(
    Object meta,
    Object score,
    Object correct,
    Object wrong,
    Object skipped,
    Object questions,
  ) {
    return '$meta • score $score • $correct✓ $wrong✗ $skipped– • $questions Qs';
  }

  @override
  String get economyInventory => 'Inventory';

  @override
  String get economyYourResources => 'Your resources';

  @override
  String economyResourceSummary(Object held, Object catalog, Object recent) {
    return '$held held • $catalog catalog • $recent recent';
  }

  @override
  String get economyNoResources => 'No resources yet';

  @override
  String get economyResourcesExplain =>
      'Resources are earned via city / economy flows and quiz rewards. They appear here when available.';

  @override
  String get economyCatalog => 'Catalog';

  @override
  String get economyCatalogEmpty =>
      'Catalog empty — server will populate material list.';

  @override
  String get economyRecentActivity => 'Recent activity';

  @override
  String get economyNoRecentActivity => 'No recent activity.';

  @override
  String get economyDonations => 'Donations';

  @override
  String get economyDonationsExplain =>
      'Live leaderboard and feed. Coins can freeze a donor streak.';

  @override
  String economyLeaderboardFeed(Object status) {
    return 'Leaderboard/feed: $status';
  }

  @override
  String economyStreakMonths(Object name, Object months) {
    return '$name • $months mo streak';
  }

  @override
  String get economyLiveFeed => 'Live feed';

  @override
  String get economyDonationsEmpty =>
      'Donation leaderboard and feed are empty.';

  @override
  String get economySyncing => 'Syncing…';

  @override
  String get economyLedger => 'Ledger';

  @override
  String get economyLedgerExplain =>
      'Grouped by day. Source labels come from credits.description (not metadata.source).';

  @override
  String get economyWhereCoinsWent => 'Where your coins went';

  @override
  String economyPeriodSummary(Object days, Object earned, Object spent) {
    return 'Last $days days • earned $earned • spent $spent';
  }

  @override
  String get economyNoActivity => 'No coin activity in this period.';

  @override
  String get economyHowYouEarn => 'How you earn';

  @override
  String get economyMintingExplain =>
      'Coins are credited after each graded quiz and server-side daily actions. They are never minted on your device, so your balance cannot drift.';

  @override
  String get economyNoTransactions => 'No transactions yet';

  @override
  String get economyNoTransactionsBody =>
      'Complete a quiz to earn coins. Every credit is recorded on our servers.';

  @override
  String get economyTitle => 'Economy';

  @override
  String economyXpTotal(Object xp) {
    return '$xp XP total';
  }

  @override
  String get economyLiveExplain =>
      'Balance, ledger, shop and store are all live. Coins are minted server-side when a graded attempt completes.';

  @override
  String get economyWalletTile => 'Wallet - balance + ledger by day';

  @override
  String get economyWalletTileSub =>
      'Balance, lifetime totals and your coin history';

  @override
  String get economyShopTile => 'Coin Shop - resources & bundles';

  @override
  String get economyShopTileSub => 'Spend coins on materials and bundles';

  @override
  String get economyInventoryTile => 'Inventory — resources + donations';

  @override
  String get economyInventoryTileSub =>
      '8 materials + catalog + live donations feed/leaderboard';

  @override
  String get economyStoreTile => 'Premium Store - assets & skins';

  @override
  String get economyStoreTileSub => 'Buy frames, themes, badges and avatars';

  @override
  String get economyWardrobeTile => 'Wardrobe - equip';

  @override
  String get economyWardrobeTileSub => 'Equip or clear the assets you own';

  @override
  String get economyShopTitle => 'Coin Shop';

  @override
  String get economyNothingForSale => 'Nothing for sale yet';

  @override
  String get economyShopEmpty =>
      'The shop has no items published on the server right now.';

  @override
  String get economyBundles => 'Bundles';

  @override
  String get economyMaterials => 'Materials';

  @override
  String get economyPurchaseSafe =>
      'If a purchase does not go through, retrying is safe — you are never charged twice.';

  @override
  String economySellsBackFor(Object coins) {
    return 'sells back for $coins';
  }

  @override
  String economySave(Object coins) {
    return 'save $coins';
  }

  @override
  String libraryUnlockedCoins(Object coins) {
    return 'Unlocked! Coins spent: $coins';
  }

  @override
  String get libraryDownloadStarted => 'Download started — opening browser';

  @override
  String libraryDownloadUrl(Object url) {
    return 'Download URL: $url';
  }

  @override
  String get libraryRatingRange => 'Rating must be 1-5';

  @override
  String get libraryReviewSubmitted => 'Review submitted';

  @override
  String get libraryAbout => 'About';

  @override
  String get libraryReviews => 'Reviews';

  @override
  String get libraryNoReviews =>
      'No reviews yet — be the first to review after unlocking!';

  @override
  String get libraryLoadMoreReviews => 'Load more reviews';

  @override
  String get librarySignedUrls =>
      'Download URLs are signed and short-lived. If a download fails, tap Download again to get a fresh URL. Respect library-api-download throttle.';

  @override
  String get libraryFree => 'FREE';

  @override
  String libraryCoinsLabel(Object count) {
    return '$count COINS';
  }

  @override
  String get libraryFeatured => 'Featured';

  @override
  String libraryByUploader(Object name) {
    return 'by $name';
  }

  @override
  String libraryUnlockedFor(Object coins) {
    return 'Unlocked • $coins coins';
  }

  @override
  String get libraryUnlocking => 'Unlocking…';

  @override
  String get libraryGettingLink => 'Getting link…';

  @override
  String get libraryDownload => 'Download';

  @override
  String get libraryUnlockNote =>
      'Unlocking is charged to your coin balance once, even if the tap does not register the first time. You need to unlock a file before you can download it.';

  @override
  String libraryReviewsCount(Object count) {
    return '$count reviews';
  }

  @override
  String get libraryDownloads => 'downloads';

  @override
  String get libraryAccess => 'access';

  @override
  String get libraryWriteReview => 'Write a review (must unlock first)';

  @override
  String get libraryCommentOptional => 'Comment (optional)';

  @override
  String get librarySubmitting => 'Submitting…';

  @override
  String get librarySubmitReview => 'Submit review';

  @override
  String get libraryReviewVerified =>
      'Reviews are verified if you have downloaded/unlocked the file.';

  @override
  String get libraryVerified => 'verified';

  @override
  String get librarySearchHint => 'Search files, categories…';

  @override
  String libraryTrendingFailed(Object reason) {
    return 'Could not load the trending files.\n$reason';
  }

  @override
  String get libraryTrending => 'Trending';

  @override
  String libraryRecommendedFailed(Object reason) {
    return 'Could not load your recommendations.\n$reason';
  }

  @override
  String get libraryRecommendedForYou => 'Recommended for you';

  @override
  String get libraryFiles => 'Files';

  @override
  String libraryTotalCount(Object count) {
    return '$count total';
  }

  @override
  String get libraryNoFiles => 'No files yet';

  @override
  String libraryNoResults(Object query) {
    return 'No results for \"$query\"';
  }

  @override
  String get libraryNoFilesBody =>
      'Library files will appear here once published and approved on the server.';

  @override
  String get libraryTryDifferentSearch =>
      'Try a different search term or clear filters.';

  @override
  String get libraryClearSearch => 'Clear search';

  @override
  String get libraryNoCategories => 'No categories published';

  @override
  String get commonLoadMore => 'Load more';

  @override
  String get commonLeaderboard => 'Leaderboard';

  @override
  String get commonWallet => 'Wallet';

  @override
  String get commonLibrary => 'Library';

  @override
  String get practiceDrillComplete => 'Drill complete';

  @override
  String get practiceDoesNotAffect =>
      'Practice — does not affect rank, XP or streak';

  @override
  String practiceQuestionsCount(Object count) {
    return '$count questions';
  }

  @override
  String practiceAnsweredSkipped(Object answered, Object skipped) {
    return '$answered answered • $skipped skipped';
  }

  @override
  String practiceScore(Object score) {
    return 'Score $score';
  }

  @override
  String get practiceGradedByServer => 'Graded by the server';

  @override
  String practiceCorrectWrongSkipped(
    Object correct,
    Object wrong,
    Object skipped,
  ) {
    return '$correct correct • $wrong wrong • $skipped skipped';
  }

  @override
  String practiceGradingFailed(Object reason) {
    return 'The server could not grade this drill: $reason';
  }

  @override
  String get practiceReviewPassNote =>
      'This was a review pass. No attempt was created, so there is no score to show.';

  @override
  String get practiceNoQuestionsInSet => 'No questions in this set';

  @override
  String practiceQuestionCounter(Object current, Object total) {
    return 'Q $current/$total';
  }

  @override
  String get practiceUntimedPractice => 'Untimed • Practice';

  @override
  String practiceDifficultyLabel(Object difficulty) {
    return 'Difficulty: $difficulty';
  }

  @override
  String get practiceNoOptionsNotice =>
      'The server sent this question without answer options, so it cannot be drilled here. Try the graded Quiz tab, which loads a full session.';

  @override
  String get practiceAnswerSentNotice =>
      'Answer sent to the server. It grades the attempt — this screen never guesses a score.';

  @override
  String get practicePrev => 'Prev';

  @override
  String get practiceGrading => 'Grading…';

  @override
  String get practiceNoEffectNote =>
      'Practice is untimed and carries no score, XP, coins or streak effect.';

  @override
  String get liveEventNotFound => 'Live event not found';

  @override
  String liveEventParticipant(Object number, Object status, Object score) {
    return 'Participant #$number • $status • Score $score';
  }

  @override
  String get liveEventSnapshot => 'Snapshot';

  @override
  String get liveEventNoSnapshot =>
      'No snapshot yet — register and check in to load current question.';

  @override
  String get liveEventAnswer => 'Answer';

  @override
  String get liveEventQIndex => 'Q index';

  @override
  String get liveEventSubmitAnswer => 'Submit Answer';

  @override
  String get liveEventNoLeaderboard => 'No leaderboard yet.';

  @override
  String get liveEventRegistered => 'Registered!';

  @override
  String get liveEventRegisterFailed => 'Register failed';

  @override
  String get liveEventUnregistered => 'Unregistered';

  @override
  String get liveEventUnregisterFailed => 'Unregister failed';

  @override
  String get liveEventCheckedIn => 'Checked in!';

  @override
  String get liveEventCheckInFailed => 'Check-in failed';

  @override
  String get liveEventEnterAnswer => 'Enter an answer';

  @override
  String liveEventAnswerRecorded(Object score) {
    return 'Answer recorded — score $score';
  }

  @override
  String liveEventQuestionsEach(Object questions, Object seconds) {
    return '$questions Qs • ${seconds}s each';
  }

  @override
  String liveEventActive(Object count) {
    return '$count active';
  }

  @override
  String liveEventWaitlisted(Object count) {
    return '$count waitlisted';
  }

  @override
  String liveEventStarts(Object date, Object hour, Object minute) {
    return 'Starts $date $hour:$minute';
  }

  @override
  String liveEventEnds(Object date) {
    return 'Ends $date';
  }

  @override
  String liveEventEntryFee(Object coins) {
    return '$coins entry';
  }

  @override
  String liveEventPrize(Object coins) {
    return '$coins prize';
  }

  @override
  String get liveEventLeave => 'Leave';

  @override
  String get liveEventCheckIn => 'Check-in';

  @override
  String liveEventScoreMeta(Object score, Object correct, Object total) {
    return 'Score $score • $correct/$total';
  }

  @override
  String liveEventQuestionPoints(Object number, Object points) {
    return 'Q$number • $points pts';
  }

  @override
  String liveEventRemaining(Object seconds, Object locks) {
    return 'Remaining: ${seconds}s • Locks at $locks';
  }

  @override
  String get liveEventWaitingForHost =>
      'No current question — waiting for host.';

  @override
  String liveEventRawKeys(Object keys) {
    return 'Raw keys: $keys';
  }

  @override
  String get coachingTutorChat => 'Tutor chat';

  @override
  String get coachingStudyPlan => 'Study plan';

  @override
  String get coachingTutorOnboarding => 'Tutor onboarding';

  @override
  String get coachingGoalIdHint => 'Goal ID for readiness (e.g., psc-civil)';

  @override
  String get coachingLoad => 'Load';

  @override
  String get coachingNoData =>
      'No coaching data yet — complete onboarding or chat with tutor to seed.';

  @override
  String get coachingPartial =>
      'Some coaching surfaces are temporarily unavailable — showing available data.';

  @override
  String get coachingNoReadinessForGoal =>
      'Readiness: no data for this goal yet.';

  @override
  String get coachingAskTutor => 'Ask tutor';

  @override
  String get coachingOnboarding => 'Onboarding';

  @override
  String get coachingReadinessExplained =>
      'Readiness is worked out from your goals, tracks and tutor activity. Some sections stay hidden until you use them.';

  @override
  String get coachingReadiness => 'Readiness';

  @override
  String get coachingFocusNext => 'Focus next:';

  @override
  String get coachingNoReadiness =>
      'No readiness yet — attempt a few quizzes under this goal.';

  @override
  String coachingGoalLabel(Object goal) {
    return 'Goal $goal';
  }

  @override
  String coachingMore(Object count) {
    return '+ $count more';
  }

  @override
  String get coachingNoTasksToday => 'No tasks today';

  @override
  String coachingConfidence(Object confidence) {
    return 'Confidence $confidence%';
  }

  @override
  String get coachingLearningTracks => 'Learning tracks';

  @override
  String get coachingThisWeek => 'This week';

  @override
  String coachingWeekTasks(Object done, Object total, Object average) {
    return '$done/$total tasks • avg $average';
  }

  @override
  String get coachingNoRevisions => 'No revisions due';

  @override
  String coachingRevisionsDue(Object count) {
    return '$count revisions due';
  }

  @override
  String get socialInviteFriends => 'Invite friends';

  @override
  String get socialReferralUnavailable =>
      'Referral information is unavailable right now.';

  @override
  String socialEarnCoins(Object coins) {
    return 'Earn $coins coins';
  }

  @override
  String get socialNo => 'No';

  @override
  String get socialYourInviteCode => 'Your invite code';

  @override
  String get socialShareInviteLink => 'Share invite link';

  @override
  String get socialCopyCode => 'Copy code';

  @override
  String get socialRewards => 'Rewards';

  @override
  String get socialRewardPerSignup => 'You earn per friend who signs up';

  @override
  String get socialTheyEarn => 'They earn when they sign up';

  @override
  String get socialBonusFirstQuiz => 'Bonus when they finish their first quiz';

  @override
  String get socialYourReferrals => 'Your referrals';

  @override
  String get socialInvited => 'invited';

  @override
  String get socialRewarded => 'rewarded';

  @override
  String get socialCoinsEarned => 'coins earned';

  @override
  String get socialNoReferralsYet => 'No one has used your code yet.';

  @override
  String socialRewardPaid(Object coins) {
    return 'Reward paid: $coins coins';
  }

  @override
  String socialStatus(Object status) {
    return 'Status: $status';
  }

  @override
  String get socialGotCode => 'Got a code from a friend?';

  @override
  String get socialReferralCode => 'Referral code';

  @override
  String get socialApplyCode => 'Apply code';

  @override
  String get socialShareSheetFailed => 'Could not open the share sheet';

  @override
  String get socialCodeCopied => 'Code copied';

  @override
  String get socialSharedChallenge => 'Shared challenge';

  @override
  String get socialSomeoneShared => 'Someone shared a challenge with you';

  @override
  String socialSharedBy(Object name) {
    return 'Shared by $name';
  }

  @override
  String get socialLinkExpired => 'This link has expired.';

  @override
  String get socialNoPlayableChallenge => 'No playable challenge here';

  @override
  String get socialNotPlayable =>
      'This link does not offer a playable challenge. You can still browse the public catalogue.';

  @override
  String get socialPlayChallenge => 'Play the challenge';

  @override
  String get socialGuestNeverAwards =>
      'A guest challenge never awards coins, XP or streak. Create a free account to keep your progress.';

  @override
  String get socialChallengeNoQuestions => 'This challenge has no questions';

  @override
  String get socialChallengeEmpty =>
      'The server opened the attempt without sending any questions, so there is nothing to play.';

  @override
  String socialQuestionOf(Object current, Object total) {
    return 'Question $current of $total';
  }

  @override
  String get socialCorrect => 'Correct.';

  @override
  String get socialNotThisTime => 'Not this time — the server has marked it.';

  @override
  String get socialSubmitAnswer => 'Submit answer';

  @override
  String get socialFinish => 'Finish';

  @override
  String get socialNext => 'Next';

  @override
  String get socialChallengeComplete => 'Challenge complete';

  @override
  String socialYouScored(Object score) {
    return 'You scored $score';
  }

  @override
  String socialChallengeSummary(
    Object correct,
    Object wrong,
    Object skipped,
    Object questions,
  ) {
    return '$correct correct • $wrong wrong • $skipped skipped • $questions questions';
  }

  @override
  String get socialGuestChallengeNote =>
      'A guest challenge never awards coins, XP or streak.';

  @override
  String socialNiceOne(Object name) {
    return 'Nice one — that was $name\'s challenge. A guest challenge never awards coins, XP or streak.';
  }

  @override
  String get socialCreateAccount => 'Create a free account';

  @override
  String get socialBrowseSamples => 'Browse sample questions';

  @override
  String get contestNotFound => 'Contest not found';

  @override
  String contestAttemptStarted(Object number, Object expires) {
    return 'Attempt #$number started. Expires: $expires';
  }

  @override
  String get contestNoLeaderboard =>
      'No leaderboard entries yet — be the first!';

  @override
  String contestGeneratedMeta(Object generated, Object budget, Object mode) {
    return 'Generated: $generated • Refresh budget: $budget • $mode';
  }

  @override
  String get contestRecap => 'Recap';

  @override
  String get contestWinners => 'Winners';

  @override
  String contestRawStats(Object count) {
    return 'Raw stats: $count keys';
  }

  @override
  String get contestRecapPending => 'Recap available after contest ends.';

  @override
  String get contestJoined => 'Joined contest!';

  @override
  String get contestJoinFailed => 'Join failed';

  @override
  String get contestLeft => 'Left contest';

  @override
  String get contestLeaveFailed => 'Leave failed';

  @override
  String get contestRegisteredBadge => 'REGISTERED';

  @override
  String contestMax(Object count) {
    return 'Max $count';
  }

  @override
  String contestStarts(Object date) {
    return 'Starts $date';
  }

  @override
  String get contestJoinFree => 'Join (Free)';

  @override
  String contestJoinCoins(Object coins) {
    return 'Join ($coins coins)';
  }

  @override
  String get contestEnter => 'Enter Contest';

  @override
  String get leaderboardGlobal => 'Global';

  @override
  String get leaderboardFriends => 'Friends';

  @override
  String get leaderboardLeague => 'League';

  @override
  String get leaderboardDonors => 'Donors';

  @override
  String get leaderboardNoRank =>
      'No rank yet — complete a quiz to enter the leaderboard.';

  @override
  String get leaderboardMyRank => 'MY RANK';

  @override
  String leaderboardRankIn(Object rank, Object scope) {
    return '#$rank in $scope';
  }

  @override
  String leaderboardUnrankedIn(Object scope) {
    return 'Unranked in $scope';
  }

  @override
  String leaderboardScore(Object score) {
    return 'Score: $score';
  }

  @override
  String get leaderboardNoEntries => 'No entries yet';

  @override
  String get leaderboardBeFirst => 'Be the first to claim the top spot!';

  @override
  String get leaderboardFriendsHint =>
      'Add friends to compete — server segments friends automatically.';

  @override
  String get leaderboardLeagueHint =>
      'League is seasonal — join via events/contests to qualify.';

  @override
  String get leaderboardNoEntriesShort => 'No entries';

  @override
  String get leaderboardCompeteToAppear => 'Compete to appear here.';

  @override
  String get leaderboardNoDonors => 'No donors yet';

  @override
  String get leaderboardSupportToAppear =>
      'Support the platform to appear here.';

  @override
  String leaderboardScoreAttempts(Object score, Object attempts) {
    return 'Score $score • $attempts attempts';
  }

  @override
  String learningGoalLabel(Object number) {
    return 'Goal #$number';
  }

  @override
  String get learningToday => 'Today';

  @override
  String get learningGoalId => 'Goal ID';

  @override
  String get learningTrackId => 'Track ID';

  @override
  String get learningTargetDate => 'Target date';

  @override
  String get learningDailyMinutes => 'Daily minutes';

  @override
  String get learningIntensity => 'Intensity';

  @override
  String get learningPlacement => 'Placement';

  @override
  String learningMastery(Object percent, Object topics) {
    return '$percent% mastery across $topics topics (MasteryService::computeReadiness)';
  }

  @override
  String learningReadinessValue(Object value) {
    return 'Readiness: $value';
  }

  @override
  String get learningDeleteGoalTitle => 'Delete goal?';

  @override
  String get learningDeleteGoalBody =>
      'This will permanently delete the goal. Daily plans remain but no new plans will be built.';

  @override
  String get learningGoalDeleted => 'Goal deleted';

  @override
  String get learningDeleting => 'Deleting…';

  @override
  String get learningDeleteGoal => 'Delete goal';

  @override
  String get learningOpenTodayPlan => 'Open Today plan';

  @override
  String get learningBackToTracks => 'Back to tracks';

  @override
  String get learningTodaysPlan => 'Today\'s Plan';

  @override
  String get learningNoActiveGoal => 'No active goal';

  @override
  String get learningNoActiveGoalBody =>
      'Create a learning goal from Tracks to get a Today plan. If you already have one, it will show up here.';

  @override
  String get learningBrowseTracks => 'Browse tracks';

  @override
  String learningPlanLabel(Object number) {
    return 'Plan #$number';
  }

  @override
  String learningPlanGoal(Object meta, Object number) {
    return '$meta • Goal #$number';
  }

  @override
  String learningCompletedCount(Object done, Object total) {
    return '$done/$total completed';
  }

  @override
  String learningMinBudget(Object minutes) {
    return '$minutes min budget';
  }

  @override
  String get learningNoTasksBody =>
      'Check back tomorrow — daily autopilot builds Review-first + new topics.';

  @override
  String learningMinutes(Object minutes) {
    return '$minutes min';
  }

  @override
  String get learningItemCompleted => 'Item completed';

  @override
  String get learningReviewsDue => 'Reviews due';

  @override
  String get learningTitle => 'Learning';

  @override
  String get learningReviewsCountFailed =>
      'Could not load your reviews due count';

  @override
  String get learningTracks => 'Tracks';

  @override
  String get learningNoTracks =>
      'No tracks yet — they are published by our team as they finish';

  @override
  String get learningAskAiTutor => 'Ask AI Tutor';

  @override
  String get learningStreamingNote =>
      'Answers come back a little at a time rather than all at once, so you can start reading straight away.';

  @override
  String get learningNoTasks => 'No tasks — check back tomorrow';

  @override
  String learningReviewsDueSrs(Object count) {
    return '$count reviews due (SRS)';
  }

  @override
  String get learningReviewAction => 'Review';

  @override
  String learningGoalCreatedForTrack(Object number) {
    return 'Goal created for track #$number';
  }

  @override
  String get learningTracksTitle => 'Learning Tracks';

  @override
  String get learningTodayPlan => 'Today plan';

  @override
  String learningNodesCount(Object count) {
    return '$count nodes';
  }

  @override
  String learningGoalsCount(Object count) {
    return '$count goals';
  }

  @override
  String get learningCreating => 'Creating…';

  @override
  String get learningCreateGoal => 'Create goal';

  @override
  String get learningReviewsDueTitle => 'Reviews Due';

  @override
  String get learningAllCaughtUp =>
      'You are all caught up! FSRS will schedule the next reviews after you master new atoms.';

  @override
  String learningReviewMeta(Object number, Object atom, Object state) {
    return 'Review #$number • atom $atom • $state';
  }

  @override
  String learningInterval(Object index) {
    return 'I$index';
  }

  @override
  String learningDueDate(Object date) {
    return 'Due $date';
  }

  @override
  String learningLapses(Object count) {
    return '$count lapses';
  }

  @override
  String get learningGradeAgain => 'Again';

  @override
  String get learningGradeHard => 'Hard';

  @override
  String get learningGradeGood => 'Good';

  @override
  String get learningGradeEasy => 'Easy';

  @override
  String get learningGradingNote =>
      'Grading is recorded safely, and your next review date is worked out for you. Double-tapping cannot lose your progress.';

  @override
  String get syllabusTitle => 'Syllabus';

  @override
  String get syllabusNoNodes => 'This syllabus has no published nodes yet.';

  @override
  String get syllabusExaminable => 'examinable';

  @override
  String get syllabusQuestions => 'questions';

  @override
  String get syllabusPaperBlueprint => 'Paper blueprint';

  @override
  String syllabusPapersCount(Object count) {
    return '$count papers';
  }

  @override
  String syllabusMarksQuestions(Object marks, Object questions) {
    return '$marks marks · $questions questions';
  }

  @override
  String syllabusNegativeMarking(Object mode) {
    return 'Negative marking: $mode';
  }

  @override
  String syllabusMarks(Object marks) {
    return '$marks marks';
  }

  @override
  String get syllabusBlueprintMismatch =>
      'The section marks do not add up to the paper total. Treat this blueprint as unverified.';

  @override
  String syllabusCoversTopics(Object count) {
    return 'Covers $count syllabus topics';
  }

  @override
  String get syllabusSearchTopics => 'Search topics';

  @override
  String get syllabusNoPublished => 'No syllabus has been published yet.';

  @override
  String syllabusTopicsCount(Object count) {
    return '$count topics';
  }

  @override
  String get syllabusNotCurrent => 'Not current';

  @override
  String get booksTitle => 'Books';

  @override
  String get booksSearch => 'Search books';

  @override
  String get booksNonePublished => 'No books have been published yet.';

  @override
  String booksNoMatch(Object query) {
    return 'No books match \"$query\".';
  }

  @override
  String booksProgress(Object percent, Object page) {
    return '$percent% · page $page';
  }

  @override
  String get booksChapters => 'Chapters';

  @override
  String get booksNoChapters => 'No chapters published yet.';

  @override
  String get booksChapterTest => 'Chapter test';

  @override
  String get booksReadChapter => 'Read the chapter';

  @override
  String booksTakeTest(Object count) {
    return 'Take test ($count)';
  }

  @override
  String get booksNoTopics => 'This chapter has no topics to open yet.';

  @override
  String get downloadsClearTitle => 'Clear offline content?';

  @override
  String get downloadsClearBody =>
      'This removes all cached questions. You can re-download anytime while online.';

  @override
  String get downloadsClear => 'Clear';

  @override
  String get downloadsStorageUnreadable => 'Could not read offline storage';

  @override
  String get downloadsNothingReported =>
      'Nothing is reported rather than showing a false zero.';

  @override
  String downloadsCachedQuestions(Object count) {
    return '$count questions cached';
  }

  @override
  String downloadsCacheSize(Object subjects, Object size) {
    return '$subjects subjects · ~$size KB';
  }

  @override
  String get downloadsLastCached => 'Last cached';

  @override
  String get downloadsAutoDownload => 'Auto-download';

  @override
  String get downloadsPrefetchNow => 'Prefetch daily pack now';

  @override
  String get downloadsClearAction => 'Clear offline content';

  @override
  String get rewardsSpinWheel => 'Spin the wheel';

  @override
  String get rewardsCheckInUnavailable => 'Check-in unavailable';

  @override
  String get rewardsDailyCheckIn => 'Daily check-in';

  @override
  String rewardsDayStreak(Object count) {
    return 'day $count';
  }

  @override
  String get rewardsToday => 'today';

  @override
  String get rewardsTomorrow => 'tomorrow';

  @override
  String get rewardsClaimedToday => 'Claimed today';

  @override
  String rewardsCheckInFor(Object coins) {
    return 'Check in for $coins coins';
  }

  @override
  String get rewardsSpinUnavailable => 'Spin wheel unavailable';

  @override
  String get rewardsSpin => 'Spin';

  @override
  String get rewardsComeBackLater => 'Come back later';

  @override
  String rewardsNextSpin(Object date) {
    return 'Next spin $date';
  }

  @override
  String gameLevelLabel(Object number) {
    return 'Level $number';
  }

  @override
  String get gameBossLevel => 'Boss level';

  @override
  String get gameChapterLevel => 'Chapter level';

  @override
  String gameSecondsPerQuestion(Object seconds) {
    return '${seconds}s per question';
  }

  @override
  String get gameBestScore => 'Best score';

  @override
  String get gameBestAccuracy => 'Best accuracy';

  @override
  String get gameBestTime => 'Best time';

  @override
  String get gameStartLevel => 'Start level';

  @override
  String get gameNotPlayable => 'Not playable yet';

  @override
  String get gameWorldNoCourse =>
      'This world has no quiz course linked to it yet, so there is nothing to play. Ask an admin to set the world\'s course.';

  @override
  String get gameWorldsTitle => 'Worlds';

  @override
  String get gameWorldsLoadFailed => 'Could not load worlds';

  @override
  String get gameNoWorlds => 'No worlds yet';

  @override
  String get gameNoWorldsBody =>
      'The server has not published any game worlds.';

  @override
  String get gameNeedsSubscription => 'Requires a subscription plan.';

  @override
  String get gameWorldNotFound => 'World not found';

  @override
  String gameStarsProgress(Object earned, Object total) {
    return '$earned / $total stars';
  }

  @override
  String get gameWorldMapFailed => 'Could not load world map';

  @override
  String get gameMissionsTitle => 'Missions';

  @override
  String get gameMissionsFailed => 'Could not load missions';

  @override
  String get gameNoMissions => 'No missions yet';

  @override
  String get gameNoMissionsBody =>
      'The server has not published any missions for you.';

  @override
  String get gameClaimAll => 'Claim all';

  @override
  String gameClaimCoins(Object coins) {
    return 'Claim $coins coins';
  }

  @override
  String get gameClaimed => 'Claimed';

  @override
  String get numericalsTitle => 'Numerical';

  @override
  String get numericalsNew => 'New numbers';

  @override
  String get numericalsCheck => 'Check answer';

  @override
  String get numericalsShowSolution => 'Show worked solution';

  @override
  String numericalsCorrect(Object reason) {
    return 'Correct$reason';
  }

  @override
  String get numericalsNotCorrect =>
      'Not correct. Try again, or open the worked solution.';

  @override
  String get numericalsFlagged =>
      'The server has flagged this problem for review.';

  @override
  String get numericalsWorkedSolution => 'Worked solution';

  @override
  String numericalsComputedBy(Object source) {
    return 'Computed by: $source';
  }

  @override
  String get numericalsFlaggedWarning =>
      'Flagged by the server for review — treat this answer with care.';

  @override
  String get numericalsOpenInCalculator => 'Open in calculator';

  @override
  String get storeEquipped => 'Equipped!';

  @override
  String get storeEquipFailed => 'Could not equip that item.';

  @override
  String get storeWardrobeTitle => 'Wardrobe';

  @override
  String get storeEquippedLabel => 'Equipped';

  @override
  String get storeNothingEquipped => 'Nothing equipped';

  @override
  String get storeNothingEquippedBody =>
      'Buy assets in the Premium Store, then equip them here.';

  @override
  String get storeAvailableToEquip => 'Available to equip';

  @override
  String get storeEquipHint =>
      'Tap Equip to try it on. If you tap twice you are never equipped twice.';

  @override
  String get storeNoAssets => 'No assets yet — visit Premium Store.';

  @override
  String storeClearSlot(Object slot) {
    return 'Clear $slot';
  }

  @override
  String get storeTitle => 'Premium Store';

  @override
  String get storeAll => 'All';

  @override
  String storeAssetsCount(Object count) {
    return '$count assets';
  }

  @override
  String get storeNoAssetsInCategory => 'No assets in this category.';

  @override
  String get storeTrading => 'Trading';

  @override
  String get storeTradingExplain =>
      'Buy resources and bundles with coins, or sell what you no longer need.';

  @override
  String get storeCoinShop => 'Coin shop';

  @override
  String get storeSellItems => 'Sell items';

  @override
  String get storeOwnedBadge => 'OWNED';

  @override
  String get storeOwned => 'Owned';

  @override
  String get storeEmptyEquip => 'Empty - equip from store';

  @override
  String get eiceTitle => 'Exam Intelligence';

  @override
  String get eiceExplain =>
      'Everything here is worked out on our servers from your real answer history, so nothing is shown unless it is true.';

  @override
  String get eiceCoach => 'Coach — your plan';

  @override
  String get eiceSprint => 'Sprint — 7-day recall queue';

  @override
  String get eiceWeeklyReport => 'Weekly report';

  @override
  String get eiceTriage => 'Triage — cover or skip';

  @override
  String get battleArena => 'Battle Arena';

  @override
  String get battleNoActiveMatch => 'No active match';

  @override
  String get battleFindMatch => 'Find a Match';

  @override
  String get battleNoQuestions => 'This match has no questions';

  @override
  String battleQuestionCounter(Object current, Object total) {
    return 'Battle · Q$current/$total';
  }

  @override
  String get battleOpponentAnswered => 'Opponent answered!';

  @override
  String get battleResultTitle => 'Battle Result';

  @override
  String get battleNoMatchToDisplay => 'No match to display';

  @override
  String get battleVs => 'VS';

  @override
  String get battleRematch => 'Rematch';

  @override
  String get battleYou => 'You';

  @override
  String get liveEventsTitle => 'Live Events';

  @override
  String get liveEventsNone => 'No live events';

  @override
  String get liveEventsNoneBody =>
      'Scheduled and live events will appear here.';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsMarkAllRead => 'Mark all read';

  @override
  String get notificationsNone => 'No notifications';

  @override
  String get notificationsNoneBody => 'Nothing new right now.';

  @override
  String get notificationsLoadFailed => 'Could not load notifications';

  @override
  String get notificationsMarkFailed =>
      'Could not mark that as read. Try again.';

  @override
  String get notificationsMarkAllFailed => 'Could not mark everything as read.';

  @override
  String get coursesLoadFailed => 'Could not load courses. Check connection.';

  @override
  String get coursesNone => 'No courses available';

  @override
  String get coursesNoneBody =>
      'Civil engineering syllabi will appear here once published.';

  @override
  String coursesTracksCount(Object count) {
    return '$count syllabus tracks';
  }

  @override
  String get coursesBrowseQuestions => 'Browse questions';

  @override
  String get pscTitle => 'PSC / Loksewa';

  @override
  String pscBlueprintsFailed(Object reason) {
    return 'Could not load the PSC blueprints.\n$reason';
  }

  @override
  String get pscNoBlueprints =>
      'No blueprints are published yet. Pull down to retry.';

  @override
  String pscBlueprintMeta(Object id, Object questions) {
    return 'id: $id • $questions Qs';
  }

  @override
  String get pscStartFailed => 'Start exam failed (offline or 404)';

  @override
  String pscStarted(Object id) {
    return 'Exam started: $id';
  }

  @override
  String get achievementsBadges => 'Badges';

  @override
  String achievementsFailed(Object reason) {
    return 'Could not load achievements: $reason';
  }

  @override
  String get achievementsNone => 'No achievements yet — start quizzing!';

  @override
  String get searchTitle => 'Search';

  @override
  String get searchHint => 'Search questions, calculators, courses…';

  @override
  String get searchTry => 'Try: levelling, RCC, Bernoulli';

  @override
  String get searchNoResults => 'No results';

  @override
  String searchFailed(Object reason) {
    return 'Search failed: $reason';
  }

  @override
  String xpLevelLabel(Object level) {
    return 'LVL $level';
  }

  @override
  String xpProgress(Object current, Object total) {
    return '$current / $total XP';
  }

  @override
  String xpTotal(Object amount) {
    return '$amount XP';
  }

  @override
  String xpToNext(Object amount) {
    return '$amount to next';
  }

  @override
  String xpDayStreak(Object count) {
    return '$count day streak';
  }

  @override
  String get lottieOverlay => 'lottie-overlay';

  @override
  String get lottieTapToDismiss => 'Tap to dismiss';

  @override
  String lifelineCost(Object name, Object coins) {
    return '$name lifeline, $coins coins';
  }

  @override
  String lifelineUnavailable(Object name, Object reason) {
    return '$name lifeline unavailable: $reason';
  }

  @override
  String get offlineCannotReach =>
      'Can\'t reach our servers — progress syncs when the connection is back';

  @override
  String get offlineBackOnline => 'Back online — syncing your queued activity';

  @override
  String get learningNoResponse => 'No response (tutor offline).';

  @override
  String get socialApplyFailed => 'Could not apply that code';

  @override
  String get responseCached => 'OK (cached)';

  @override
  String battleTimer(Object seconds, Object current, Object total) {
    return '${seconds}s · $current/$total';
  }

  @override
  String get battleShareUnavailable => 'Share unavailable';

  @override
  String bookPageLabel(Object number) {
    return 'Page $number';
  }

  @override
  String get bookMyHighlights => 'My highlights';

  @override
  String get bookNoExtractableText =>
      'This page has no extractable text. It may be an image-only scan.';

  @override
  String get bookPreviousPage => 'Previous page';

  @override
  String get bookNextPage => 'Next page';

  @override
  String get bookYourHighlights => 'Your highlights';

  @override
  String get bookNoHighlights => 'You have not highlighted anything yet.';

  @override
  String get bookImageNotText => 'Image or diagram (not available as text)';

  @override
  String bookValueNotText(Object value) {
    return '$value (not available as text)';
  }

  @override
  String get contestsNone => 'No contests yet';

  @override
  String get contestsNoneBody =>
      'Active and upcoming contests will appear here.';

  @override
  String get eiceNoData => 'No data available yet.';

  @override
  String get eiceNoDetails => 'No details available yet.';

  @override
  String get eiceNothingHere => 'Nothing here yet.';

  @override
  String eiceAndMore(Object count) {
    return 'and $count more…';
  }

  @override
  String get gameNoRewardData =>
      'The server sent no reward data for this level yet.';

  @override
  String gameMissionsReady(Object count) {
    return '$count missions ready to claim';
  }

  @override
  String gameRewardsWaiting(Object count) {
    return '$count rewards waiting';
  }

  @override
  String get leaderboardFriendsTitle => 'Friends leaderboard';

  @override
  String get leaderboardLeagueTitle => 'League leaderboard';

  @override
  String leaderboardMonthsShort(Object months) {
    return '${months}m';
  }

  @override
  String get learningNoTracksTitle => 'No tracks yet';

  @override
  String get learningTracksBody =>
      'Tracks will appear here as they are published. Check back soon.';

  @override
  String learningGradedNextDue(Object grade, Object date) {
    return 'Graded as $grade — next due $date';
  }

  @override
  String get learningNoReviewsDue => 'No reviews due';

  @override
  String liveEventsActive(Object count, Object capacity) {
    return '$count$capacity active';
  }

  @override
  String liveEventsQuestions(Object count) {
    return '$count Qs';
  }

  @override
  String liveEventsSecondsPerQuestion(Object seconds) {
    return '${seconds}s / Q';
  }

  @override
  String liveEventsJoined(Object count, Object capacity) {
    return '$count$capacity joined';
  }

  @override
  String numericalsAnswer(Object value, Object unit) {
    return 'Answer: $value$unit';
  }

  @override
  String storeAssetMeta(Object rarity, Object slot, Object coins) {
    return '$rarity • $slot • $coins coins';
  }

  @override
  String syllabusNoTopicMatch(Object query) {
    return 'No topic matches \"$query\".';
  }

  @override
  String syllabusExaminableCount(Object count) {
    return '$count examinable';
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
