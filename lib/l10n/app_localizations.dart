import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ne.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ne'),
    Locale('hi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'CivilCal'**
  String get appTitle;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @quiz.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get quiz;

  /// No description provided for @practice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get practice;

  /// No description provided for @calculators.
  ///
  /// In en, this message translates to:
  /// **'Calculators'**
  String get calculators;

  /// No description provided for @courses.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get courses;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get continueAsGuest;

  /// No description provided for @backend.
  ///
  /// In en, this message translates to:
  /// **'Backend'**
  String get backend;

  /// No description provided for @env.
  ///
  /// In en, this message translates to:
  /// **'Env'**
  String get env;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get error;

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'Streak: {days} days'**
  String streakDays(int days);

  /// No description provided for @coinsBalance.
  ///
  /// In en, this message translates to:
  /// **'{count} coins'**
  String coinsBalance(int count);

  /// No description provided for @appLocked.
  ///
  /// In en, this message translates to:
  /// **'CivilCal is locked'**
  String get appLocked;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @unlockCivilCal.
  ///
  /// In en, this message translates to:
  /// **'Unlock CivilCal'**
  String get unlockCivilCal;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get commonGoBack;

  /// No description provided for @commonStay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get commonStay;

  /// No description provided for @commonExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get commonExit;

  /// No description provided for @commonEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get commonEmail;

  /// No description provided for @commonPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get commonPassword;

  /// No description provided for @commonContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get commonContinueWithGoogle;

  /// No description provided for @commonContinueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get commonContinueWithApple;

  /// No description provided for @commonOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get commonOr;

  /// No description provided for @commonSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get commonSkip;

  /// No description provided for @commonCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get commonCheckAgain;

  /// No description provided for @commonContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get commonContactSupport;

  /// No description provided for @commonShareResult.
  ///
  /// In en, this message translates to:
  /// **'Share Result'**
  String get commonShareResult;

  /// No description provided for @commonPoints.
  ///
  /// In en, this message translates to:
  /// **'{count} pts'**
  String commonPoints(int count);

  /// No description provided for @commonPercent.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String commonPercent(Object value);

  /// No description provided for @commonXpGained.
  ///
  /// In en, this message translates to:
  /// **'+{amount} XP'**
  String commonXpGained(Object amount);

  /// No description provided for @authWelcomeBackTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authWelcomeBackTitle;

  /// No description provided for @authWelcomeBackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to access your quizzes, formulas, and ranking'**
  String get authWelcomeBackSubtitle;

  /// No description provided for @authForgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get authForgotPasswordTitle;

  /// No description provided for @authForgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your registered email and we will send you instructions to reset your password.'**
  String get authForgotPasswordSubtitle;

  /// No description provided for @authEmailAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get authEmailAddressLabel;

  /// No description provided for @authSendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get authSendResetLink;

  /// No description provided for @authCheckEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get authCheckEmailTitle;

  /// No description provided for @authCheckEmailBody.
  ///
  /// In en, this message translates to:
  /// **'If an account exists with {email}, you will receive a password reset link shortly.'**
  String authCheckEmailBody(Object email);

  /// No description provided for @authReturnToLogin.
  ///
  /// In en, this message translates to:
  /// **'Return to Login'**
  String get authReturnToLogin;

  /// No description provided for @authJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join CivilCal'**
  String get authJoinTitle;

  /// No description provided for @authJoinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your companion for engineering exams and calculations'**
  String get authJoinSubtitle;

  /// No description provided for @authFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get authFullNameLabel;

  /// No description provided for @authConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get authConfirmPasswordLabel;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get authCreateAccount;

  /// No description provided for @authAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authAlreadyHaveAccount;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get authNoAccount;

  /// No description provided for @authSetNewPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a new password'**
  String get authSetNewPasswordTitle;

  /// No description provided for @authResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password'**
  String get authResetTitle;

  /// No description provided for @authResetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You will be signed out everywhere, including this device.'**
  String get authResetSubtitle;

  /// No description provided for @authResetMissingToken.
  ///
  /// In en, this message translates to:
  /// **'This link is missing its reset token. Open the link from your email, or request a new one.'**
  String get authResetMissingToken;

  /// No description provided for @authRequestNewLink.
  ///
  /// In en, this message translates to:
  /// **'Request a new link'**
  String get authRequestNewLink;

  /// No description provided for @authRequestNewLinkInstead.
  ///
  /// In en, this message translates to:
  /// **'Request a new link instead'**
  String get authRequestNewLinkInstead;

  /// No description provided for @authNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get authNewPasswordLabel;

  /// No description provided for @authConfirmNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get authConfirmNewPasswordLabel;

  /// No description provided for @authMinChars.
  ///
  /// In en, this message translates to:
  /// **'At least {count} characters'**
  String authMinChars(int count);

  /// No description provided for @authVerifyEmailBanner.
  ///
  /// In en, this message translates to:
  /// **'Verify your email to unlock every feature.'**
  String get authVerifyEmailBanner;

  /// No description provided for @authSplashTagline.
  ///
  /// In en, this message translates to:
  /// **'BiSaaS Engineering Learning Ecosystem'**
  String get authSplashTagline;

  /// No description provided for @authInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get authInvalidEmail;

  /// No description provided for @authPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get authPasswordRequired;

  /// No description provided for @onboardingStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String onboardingStepOf(int current, int total);

  /// No description provided for @onboardingTargetExamTitle.
  ///
  /// In en, this message translates to:
  /// **'Target Examination'**
  String get onboardingTargetExamTitle;

  /// No description provided for @onboardingTargetExamBody.
  ///
  /// In en, this message translates to:
  /// **'Sets the syllabus this account studies towards.'**
  String get onboardingTargetExamBody;

  /// No description provided for @onboardingDailyGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Practice Goal'**
  String get onboardingDailyGoalTitle;

  /// No description provided for @onboardingDailyGoalBody.
  ///
  /// In en, this message translates to:
  /// **'How much time would you like to dedicate each day? You can change this anytime.'**
  String get onboardingDailyGoalBody;

  /// No description provided for @onboardingMinutesPerDay.
  ///
  /// In en, this message translates to:
  /// **'{minutes} mins / day — {label}'**
  String onboardingMinutesPerDay(Object minutes, Object label);

  /// No description provided for @onboardingCurrentLevelTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Current Level'**
  String get onboardingCurrentLevelTitle;

  /// No description provided for @onboardingCurrentLevelBody.
  ///
  /// In en, this message translates to:
  /// **'Sets where your streak and revision queue start from.'**
  String get onboardingCurrentLevelBody;

  /// No description provided for @quizHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Practice & Quiz'**
  String get quizHomeTitle;

  /// No description provided for @quizHomeLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load quiz'**
  String get quizHomeLoadError;

  /// No description provided for @quizHomeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No quizzes yet'**
  String get quizHomeEmptyTitle;

  /// No description provided for @quizHomeEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Question sets for your exam are being prepared. Check back soon.'**
  String get quizHomeEmptyBody;

  /// No description provided for @quizPlayWorlds.
  ///
  /// In en, this message translates to:
  /// **'Play Worlds'**
  String get quizPlayWorlds;

  /// No description provided for @quizPlayWorldsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Chapters, levels and bosses — earn stars as you go'**
  String get quizPlayWorldsSubtitle;

  /// No description provided for @quizPracticeDrill.
  ///
  /// In en, this message translates to:
  /// **'Practice drill'**
  String get quizPracticeDrill;

  /// No description provided for @quizPracticeDrillSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Drill your bookmarks and weak topics — untimed, no rank effect'**
  String get quizPracticeDrillSubtitle;

  /// No description provided for @quizIntroDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiz Details'**
  String get quizIntroDetailsTitle;

  /// No description provided for @quizIntroLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load quiz: {reason}'**
  String quizIntroLoadFailed(Object reason);

  /// No description provided for @quizIntroQuestions.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get quizIntroQuestions;

  /// No description provided for @quizIntroMinutes.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get quizIntroMinutes;

  /// No description provided for @quizIntroStart.
  ///
  /// In en, this message translates to:
  /// **'Start Quiz'**
  String get quizIntroStart;

  /// No description provided for @quizIntroHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get quizIntroHowItWorks;

  /// No description provided for @quizAttemptLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load quiz'**
  String get quizAttemptLoadError;

  /// No description provided for @quizAttemptOfflineNotice.
  ///
  /// In en, this message translates to:
  /// **'Offline practice — not official. XP/coins will reconcile when back online.'**
  String get quizAttemptOfflineNotice;

  /// No description provided for @quizAttemptUnsupportedEffect.
  ///
  /// In en, this message translates to:
  /// **'{effect} used — the server returned an effect this app cannot show yet.'**
  String quizAttemptUnsupportedEffect(Object effect);

  /// No description provided for @quizAttemptCombo.
  ///
  /// In en, this message translates to:
  /// **'×{count} Combo!'**
  String quizAttemptCombo(int count);

  /// No description provided for @quizAttemptExitTitle.
  ///
  /// In en, this message translates to:
  /// **'Exit Quiz?'**
  String get quizAttemptExitTitle;

  /// No description provided for @quizAttemptExitBody.
  ///
  /// In en, this message translates to:
  /// **'Your current progress will be lost. Are you sure you want to exit?'**
  String get quizAttemptExitBody;

  /// No description provided for @quizResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiz Complete!'**
  String get quizResultTitle;

  /// No description provided for @quizResultAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get quizResultAccuracy;

  /// No description provided for @quizResultCorrectOf.
  ///
  /// In en, this message translates to:
  /// **'{correct} of {total} correct'**
  String quizResultCorrectOf(Object correct, int total);

  /// No description provided for @quizResultCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get quizResultCorrect;

  /// No description provided for @quizResultXpEarned.
  ///
  /// In en, this message translates to:
  /// **'XP Earned'**
  String get quizResultXpEarned;

  /// No description provided for @quizResultCoins.
  ///
  /// In en, this message translates to:
  /// **'Coins'**
  String get quizResultCoins;

  /// No description provided for @quizResultAnswerReview.
  ///
  /// In en, this message translates to:
  /// **'Answer Review'**
  String get quizResultAnswerReview;

  /// No description provided for @quizResultBackToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get quizResultBackToHome;

  /// No description provided for @quizResultReviewAll.
  ///
  /// In en, this message translates to:
  /// **'Review All Answers'**
  String get quizResultReviewAll;

  /// No description provided for @quizResultMorePractice.
  ///
  /// In en, this message translates to:
  /// **'More Practice'**
  String get quizResultMorePractice;

  /// No description provided for @quizResultShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Share unavailable: {reason}'**
  String quizResultShareFailed(Object reason);

  /// No description provided for @quizReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review Answers'**
  String get quizReviewTitle;

  /// No description provided for @quizReviewLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load review: {reason}'**
  String quizReviewLoadFailed(Object reason);

  /// No description provided for @quizReviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'No answers to review'**
  String get quizReviewEmpty;

  /// No description provided for @quizReviewYourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Your answer'**
  String get quizReviewYourAnswer;

  /// No description provided for @quizReviewNotAnswered.
  ///
  /// In en, this message translates to:
  /// **'Not answered'**
  String get quizReviewNotAnswered;

  /// No description provided for @quizReviewQuestionNumber.
  ///
  /// In en, this message translates to:
  /// **'Q{number}'**
  String quizReviewQuestionNumber(Object number);

  /// No description provided for @quizFunnelTryItOut.
  ///
  /// In en, this message translates to:
  /// **'Try it out'**
  String get quizFunnelTryItOut;

  /// No description provided for @quizFunnelSampleTitle.
  ///
  /// In en, this message translates to:
  /// **'Sample questions'**
  String get quizFunnelSampleTitle;

  /// No description provided for @quizFunnelShown.
  ///
  /// In en, this message translates to:
  /// **'{count} shown'**
  String quizFunnelShown(int count);

  /// No description provided for @quizFunnelEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No sample questions yet'**
  String get quizFunnelEmptyTitle;

  /// No description provided for @quizFunnelEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'The catalogue has no public questions published right now. Sign up and you will see everything.'**
  String get quizFunnelEmptyBody;

  /// No description provided for @quizFunnelCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create a free account to play'**
  String get quizFunnelCreateAccount;

  /// No description provided for @quizFunnelPlayGraded.
  ///
  /// In en, this message translates to:
  /// **'Play a graded quiz'**
  String get quizFunnelPlayGraded;

  /// No description provided for @quizFunnelPracticeNote.
  ///
  /// In en, this message translates to:
  /// **'Practice mode never affects rank, XP or streak.'**
  String get quizFunnelPracticeNote;

  /// No description provided for @quizOfflinePractice.
  ///
  /// In en, this message translates to:
  /// **'Offline Practice — {subject}'**
  String quizOfflinePractice(Object subject);

  /// No description provided for @quizFinishFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not finish the quiz. Please try again.'**
  String get quizFinishFailed;

  /// No description provided for @quizCountUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Count unavailable'**
  String get quizCountUnavailable;

  /// No description provided for @calcBrowserEmpty.
  ///
  /// In en, this message translates to:
  /// **'No calculators published'**
  String get calcBrowserEmpty;

  /// No description provided for @calcBrowserCount.
  ///
  /// In en, this message translates to:
  /// **'{count} calculators • {domains} domains'**
  String calcBrowserCount(int count, Object domains);

  /// No description provided for @calcBrowserLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load calculators'**
  String get calcBrowserLoadError;

  /// No description provided for @calcShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not share this result: {reason}'**
  String calcShareFailed(Object reason);

  /// No description provided for @calcNoInputNamed.
  ///
  /// In en, this message translates to:
  /// **'No input named \"{name}\" on this calculator'**
  String calcNoInputNamed(Object name);

  /// No description provided for @calcAddInput.
  ///
  /// In en, this message translates to:
  /// **'Add at least one input'**
  String get calcAddInput;

  /// No description provided for @calcInputsLabel.
  ///
  /// In en, this message translates to:
  /// **'Inputs · {label}'**
  String calcInputsLabel(Object label);

  /// No description provided for @calcInputsLegacy.
  ///
  /// In en, this message translates to:
  /// **'Inputs (legacy)'**
  String get calcInputsLegacy;

  /// No description provided for @calcKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'key'**
  String get calcKeyLabel;

  /// No description provided for @calcKeyExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. length'**
  String get calcKeyExample;

  /// No description provided for @calcValueLabel.
  ///
  /// In en, this message translates to:
  /// **'value'**
  String get calcValueLabel;

  /// No description provided for @calcValueExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. 12.5'**
  String get calcValueExample;

  /// No description provided for @calcAssistantTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask the assistant'**
  String get calcAssistantTitle;

  /// No description provided for @calcAssistantExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. a 3 m wide, 4 m deep slab for a 25 MPa mix'**
  String get calcAssistantExample;

  /// No description provided for @calcAssistantSuggested.
  ///
  /// In en, this message translates to:
  /// **'Suggested values'**
  String get calcAssistantSuggested;

  /// No description provided for @calcAssistantAlso.
  ///
  /// In en, this message translates to:
  /// **'You could also ask'**
  String get calcAssistantAlso;

  /// No description provided for @calcHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'{subject} · history'**
  String calcHistoryTitle(Object subject);

  /// No description provided for @calcHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved calculations yet'**
  String get calcHistoryEmpty;

  /// No description provided for @calcStepByStep.
  ///
  /// In en, this message translates to:
  /// **'Step-by-step'**
  String get calcStepByStep;

  /// No description provided for @calcShareResult.
  ///
  /// In en, this message translates to:
  /// **'Share result'**
  String get calcShareResult;

  /// No description provided for @calcPracticeRelated.
  ///
  /// In en, this message translates to:
  /// **'Practice related questions'**
  String get calcPracticeRelated;

  /// No description provided for @calcViewHistory.
  ///
  /// In en, this message translates to:
  /// **'View history'**
  String get calcViewHistory;

  /// No description provided for @calcNoSchema.
  ///
  /// In en, this message translates to:
  /// **'Server did not return a field schema. Falling back to generic key/value editor.'**
  String get calcNoSchema;

  /// No description provided for @calcAddField.
  ///
  /// In en, this message translates to:
  /// **'Add field'**
  String get calcAddField;

  /// No description provided for @calcInputsCount.
  ///
  /// In en, this message translates to:
  /// **'inputs: {count}'**
  String calcInputsCount(int count);

  /// No description provided for @calcAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask'**
  String get calcAsk;

  /// No description provided for @calcApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get calcApply;

  /// No description provided for @calcAssistantDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'The assistant suggests; you decide. Calculations are always performed by the server.'**
  String get calcAssistantDisclaimer;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name} 👋'**
  String homeGreeting(Object name);

  /// No description provided for @homeLevel.
  ///
  /// In en, this message translates to:
  /// **'Level {level} • {xp} XP'**
  String homeLevel(Object level, Object xp);

  /// No description provided for @homeDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get homeDaily;

  /// No description provided for @homeBattle.
  ///
  /// In en, this message translates to:
  /// **'Battle'**
  String get homeBattle;

  /// No description provided for @homeBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get homeBrowse;

  /// No description provided for @homeExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get homeExplore;

  /// No description provided for @homeCurrentCourse.
  ///
  /// In en, this message translates to:
  /// **'CURRENT COURSE'**
  String get homeCurrentCourse;

  /// No description provided for @homePercentDone.
  ///
  /// In en, this message translates to:
  /// **'{percent}% Done'**
  String homePercentDone(Object percent);

  /// No description provided for @homeMissionsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Missions unavailable'**
  String get homeMissionsUnavailable;

  /// No description provided for @homeWorldsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your worlds'**
  String get homeWorldsLoadError;

  /// No description provided for @homeWorldsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No worlds published yet — browse topics to keep practising.'**
  String get homeWorldsEmpty;

  /// No description provided for @homeYourWorlds.
  ///
  /// In en, this message translates to:
  /// **'Your worlds'**
  String get homeYourWorlds;

  /// No description provided for @homeStars.
  ///
  /// In en, this message translates to:
  /// **'{earned} / {total} ⭐'**
  String homeStars(Object earned, int total);

  /// No description provided for @homeContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue: {title}'**
  String homeContinue(Object title);

  /// No description provided for @homeDashboardLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your dashboard'**
  String get homeDashboardLoadError;

  /// No description provided for @homeDashboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing is shown rather than guessing. Pull to refresh, or retry below.'**
  String get homeDashboardEmpty;

  /// No description provided for @homeDashboardUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server, so the dashboard cannot be shown.'**
  String get homeDashboardUnreachable;

  /// No description provided for @consentTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy choices'**
  String get consentTitle;

  /// No description provided for @consentIntro.
  ///
  /// In en, this message translates to:
  /// **'Your account and quiz progress are stored on our servers so you can sign in on any device. To make that work and to keep the app stable we also send a device identifier, a push-notification token, crash reports and a device security check. With your permission we also send anonymous usage events. You can change this at any time in Settings → Privacy.'**
  String get consentIntro;

  /// No description provided for @consentNecessary.
  ///
  /// In en, this message translates to:
  /// **'Necessary'**
  String get consentNecessary;

  /// No description provided for @consentNecessaryBody.
  ///
  /// In en, this message translates to:
  /// **'Sign-in and your saved work, your push-notification token, crash reports, and a device security check. Required for the app to work.'**
  String get consentNecessaryBody;

  /// No description provided for @consentFunctional.
  ///
  /// In en, this message translates to:
  /// **'Functional'**
  String get consentFunctional;

  /// No description provided for @consentFunctionalBody.
  ///
  /// In en, this message translates to:
  /// **'Remember settings such as your language and filters on this device.'**
  String get consentFunctionalBody;

  /// No description provided for @consentAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get consentAnalytics;

  /// No description provided for @consentAnalyticsBody.
  ///
  /// In en, this message translates to:
  /// **'Usage events that tell us which features are useful. They are tied to a device identifier rather than to your account. No question content is ever included.'**
  String get consentAnalyticsBody;

  /// No description provided for @consentMarketing.
  ///
  /// In en, this message translates to:
  /// **'Marketing'**
  String get consentMarketing;

  /// No description provided for @consentMarketingBody.
  ///
  /// In en, this message translates to:
  /// **'Offers and promotions. Off unless you ask for it.'**
  String get consentMarketingBody;

  /// No description provided for @consentSaveChoices.
  ///
  /// In en, this message translates to:
  /// **'Save choices'**
  String get consentSaveChoices;

  /// No description provided for @consentNecessaryOnly.
  ///
  /// In en, this message translates to:
  /// **'Continue with necessary only'**
  String get consentNecessaryOnly;

  /// No description provided for @consentLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your choices'**
  String get consentLoadError;

  /// No description provided for @consentNecessaryAlwaysOn.
  ///
  /// In en, this message translates to:
  /// **'Always on. Your account, saved work, push token, crash reports and device security check.'**
  String get consentNecessaryAlwaysOn;

  /// No description provided for @consentDataStored.
  ///
  /// In en, this message translates to:
  /// **'Data stored about this device'**
  String get consentDataStored;

  /// No description provided for @consentDataStoredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View, and erase, the anonymous profile'**
  String get consentDataStoredSubtitle;

  /// No description provided for @consentFootnote.
  ///
  /// In en, this message translates to:
  /// **'Turning off a category stops that collection from that moment. It does not delete data already collected — for that, use the link above or contact privacy@bisaas.com.'**
  String get consentFootnote;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get privacyTitle;

  /// No description provided for @privacyAnonymousProfile.
  ///
  /// In en, this message translates to:
  /// **'Anonymous profile'**
  String get privacyAnonymousProfile;

  /// No description provided for @privacyReference.
  ///
  /// In en, this message translates to:
  /// **'Reference {reference}'**
  String privacyReference(Object reference);

  /// No description provided for @privacyEraseData.
  ///
  /// In en, this message translates to:
  /// **'Erase stored data'**
  String get privacyEraseData;

  /// No description provided for @privacyLocalChoices.
  ///
  /// In en, this message translates to:
  /// **'Local choices'**
  String get privacyLocalChoices;

  /// No description provided for @privacyEraseTitle.
  ///
  /// In en, this message translates to:
  /// **'Erase stored data?'**
  String get privacyEraseTitle;

  /// No description provided for @privacyEraseBody.
  ///
  /// In en, this message translates to:
  /// **'This deletes the anonymous profile and every intent event stored for this device. It cannot be undone.'**
  String get privacyEraseBody;

  /// No description provided for @privacyErased.
  ///
  /// In en, this message translates to:
  /// **'Stored data erased'**
  String get privacyErased;

  /// No description provided for @privacyEraseFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not erase your data. Try again.'**
  String get privacyEraseFailed;

  /// No description provided for @privacyEraseConfirm.
  ///
  /// In en, this message translates to:
  /// **'Erase'**
  String get privacyEraseConfirm;

  /// No description provided for @privacyMenu.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacyMenu;

  /// No description provided for @notificationDailyTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Sprint ready ⚡'**
  String get notificationDailyTitle;

  /// No description provided for @notificationDailyBody.
  ///
  /// In en, this message translates to:
  /// **'Your daily MCQs are waiting — keep the streak alive!'**
  String get notificationDailyBody;

  /// No description provided for @forceUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get forceUpdateTitle;

  /// No description provided for @forceUpdateYourVersion.
  ///
  /// In en, this message translates to:
  /// **'Your version: {version}'**
  String forceUpdateYourVersion(Object version);

  /// No description provided for @forceUpdateNow.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get forceUpdateNow;

  /// No description provided for @forceUpdateReassurance.
  ///
  /// In en, this message translates to:
  /// **'Your account and progress are safe — nothing is lost by updating.'**
  String get forceUpdateReassurance;

  /// No description provided for @forceUpdateStoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the store. Visit {url}'**
  String forceUpdateStoreFailed(Object url);

  /// No description provided for @maintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll be right back'**
  String get maintenanceTitle;

  /// No description provided for @maintenanceBody.
  ///
  /// In en, this message translates to:
  /// **'CivilCal is down for a short maintenance. Your account, coins and progress are safe — nothing has been lost.'**
  String get maintenanceBody;

  /// No description provided for @versionUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This app version is no longer supported.'**
  String get versionUnsupported;

  /// No description provided for @authUpdating.
  ///
  /// In en, this message translates to:
  /// **'Updating…'**
  String get authUpdating;

  /// No description provided for @authUpdatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get authUpdatePassword;

  /// No description provided for @authVerificationResentBody.
  ///
  /// In en, this message translates to:
  /// **'If that address still needs verifying, a new link is on its way. Check your inbox and spam folder.'**
  String get authVerificationResentBody;

  /// No description provided for @authVerificationResentHint.
  ///
  /// In en, this message translates to:
  /// **'We send a one-tap verification link to the address on your account.'**
  String get authVerificationResentHint;

  /// No description provided for @authVerificationSent.
  ///
  /// In en, this message translates to:
  /// **'Verification sent'**
  String get authVerificationSent;

  /// No description provided for @authResendVerification.
  ///
  /// In en, this message translates to:
  /// **'Resend verification email'**
  String get authResendVerification;

  /// No description provided for @calcSearchInDomain.
  ///
  /// In en, this message translates to:
  /// **'Search {scope} calculators…'**
  String calcSearchInDomain(Object scope);

  /// No description provided for @calcSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search calculators…'**
  String get calcSearchPlaceholder;

  /// No description provided for @calcCalculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating…'**
  String get calcCalculating;

  /// No description provided for @calcCalculateServer.
  ///
  /// In en, this message translates to:
  /// **'Calculate (server)'**
  String get calcCalculateServer;

  /// No description provided for @calcVia.
  ///
  /// In en, this message translates to:
  /// **'via {source}'**
  String calcVia(Object source);

  /// No description provided for @homeMissionsReady.
  ///
  /// In en, this message translates to:
  /// **'{count} missions ready to claim'**
  String homeMissionsReady(int count);

  /// No description provided for @homeMissionsActive.
  ///
  /// In en, this message translates to:
  /// **'Missions — {count} active'**
  String homeMissionsActive(int count);

  /// No description provided for @onboardingStartLearning.
  ///
  /// In en, this message translates to:
  /// **'Start Learning'**
  String get onboardingStartLearning;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// No description provided for @privacyLinkedToAccount.
  ///
  /// In en, this message translates to:
  /// **'This profile is linked to your account. Delete the account to erase everything.'**
  String get privacyLinkedToAccount;

  /// No description provided for @quizSeeResults.
  ///
  /// In en, this message translates to:
  /// **'See Results'**
  String get quizSeeResults;

  /// No description provided for @quizNextQuestion.
  ///
  /// In en, this message translates to:
  /// **'Next Question'**
  String get quizNextQuestion;

  /// No description provided for @quizAnswerSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Answer submitted'**
  String get quizAnswerSubmitted;

  /// No description provided for @quizBrowseQuizzes.
  ///
  /// In en, this message translates to:
  /// **'Browse Quizzes'**
  String get quizBrowseQuizzes;

  /// No description provided for @quizPickTopic.
  ///
  /// In en, this message translates to:
  /// **'Pick a Topic'**
  String get quizPickTopic;

  /// No description provided for @quizSearchCourses.
  ///
  /// In en, this message translates to:
  /// **'Search courses…'**
  String get quizSearchCourses;

  /// No description provided for @quizSearchTopics.
  ///
  /// In en, this message translates to:
  /// **'Search topics…'**
  String get quizSearchTopics;

  /// No description provided for @quizNoCoursesYet.
  ///
  /// In en, this message translates to:
  /// **'No courses yet'**
  String get quizNoCoursesYet;

  /// No description provided for @quizNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get quizNoMatches;

  /// No description provided for @quizSetsBeingPrepared.
  ///
  /// In en, this message translates to:
  /// **'Question sets for your exam are being prepared.'**
  String get quizSetsBeingPrepared;

  /// No description provided for @quizTryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different search'**
  String get quizTryDifferentSearch;

  /// No description provided for @quizNoTopicsYet.
  ///
  /// In en, this message translates to:
  /// **'No topics yet'**
  String get quizNoTopicsYet;

  /// No description provided for @quizCourseNoActiveTopics.
  ///
  /// In en, this message translates to:
  /// **'This course has no active topics yet.'**
  String get quizCourseNoActiveTopics;

  /// No description provided for @quizFunnelSampleBody.
  ///
  /// In en, this message translates to:
  /// **'Sample questions from our catalogue. Open the Quiz tab to play a full graded session.'**
  String get quizFunnelSampleBody;

  /// No description provided for @quizFunnelPublicBody.
  ///
  /// In en, this message translates to:
  /// **'Public questions from our catalogue. Answers unlock when you create a free account.'**
  String get quizFunnelPublicBody;

  /// No description provided for @quizFreshQuestions.
  ///
  /// In en, this message translates to:
  /// **'Fresh questions were added recently.'**
  String get quizFreshQuestions;

  /// No description provided for @quizNewIn.
  ///
  /// In en, this message translates to:
  /// **'New in {scope}'**
  String quizNewIn(Object scope);

  /// No description provided for @quizNoQuestionText.
  ///
  /// In en, this message translates to:
  /// **'This question has no text on the server.'**
  String get quizNoQuestionText;

  /// No description provided for @quizGraded.
  ///
  /// In en, this message translates to:
  /// **'Graded'**
  String get quizGraded;

  /// No description provided for @quizXp.
  ///
  /// In en, this message translates to:
  /// **'XP'**
  String get quizXp;

  /// No description provided for @quizByServer.
  ///
  /// In en, this message translates to:
  /// **'by server'**
  String get quizByServer;

  /// No description provided for @profileAvatarUploaded.
  ///
  /// In en, this message translates to:
  /// **'Avatar uploaded'**
  String get profileAvatarUploaded;

  /// No description provided for @profileAvatarUpdated.
  ///
  /// In en, this message translates to:
  /// **'Avatar updated'**
  String get profileAvatarUpdated;

  /// No description provided for @profileUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {reason}'**
  String profileUploadFailed(Object reason);

  /// No description provided for @profileEditName.
  ///
  /// In en, this message translates to:
  /// **'Edit name'**
  String get profileEditName;

  /// No description provided for @profileDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get profileDisplayName;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @profileUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed: {reason}'**
  String profileUpdateFailed(Object reason);

  /// No description provided for @profileShareCardText.
  ///
  /// In en, this message translates to:
  /// **'My CivilCal profile — Level {level} Engineer. https://bisaas.com'**
  String profileShareCardText(Object level);

  /// No description provided for @profileShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Share failed: {reason}'**
  String profileShareFailed(Object reason);

  /// No description provided for @profileShareCard.
  ///
  /// In en, this message translates to:
  /// **'Share card'**
  String get profileShareCard;

  /// No description provided for @profileLevel.
  ///
  /// In en, this message translates to:
  /// **'Lv {level}'**
  String profileLevel(Object level);

  /// No description provided for @profileChangeAvatar.
  ///
  /// In en, this message translates to:
  /// **'Change avatar'**
  String get profileChangeAvatar;

  /// No description provided for @profileEditAvatar.
  ///
  /// In en, this message translates to:
  /// **'Edit avatar'**
  String get profileEditAvatar;

  /// No description provided for @profileStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get profileStreak;

  /// No description provided for @profileSkillRadar.
  ///
  /// In en, this message translates to:
  /// **'Skill Radar'**
  String get profileSkillRadar;

  /// No description provided for @profileSkillsFailed.
  ///
  /// In en, this message translates to:
  /// **'Skills failed: {reason}'**
  String profileSkillsFailed(Object reason);

  /// No description provided for @profileAchievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get profileAchievements;

  /// No description provided for @profileAchievementsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load achievements'**
  String get profileAchievementsLoadFailed;

  /// No description provided for @profileNoBadges.
  ///
  /// In en, this message translates to:
  /// **'No badges yet — complete quizzes to earn them!'**
  String get profileNoBadges;

  /// No description provided for @profileUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get profileUnlocked;

  /// No description provided for @profileSkillRadarEmpty.
  ///
  /// In en, this message translates to:
  /// **'Take quizzes to reveal your skill radar.'**
  String get profileSkillRadarEmpty;

  /// No description provided for @profileSkillRadarEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Answer more categories to reveal your skill radar.'**
  String get profileSkillRadarEmptyHint;

  /// No description provided for @profileLearning.
  ///
  /// In en, this message translates to:
  /// **'Learning — tracks & AI tutor'**
  String get profileLearning;

  /// No description provided for @profileLearningSub.
  ///
  /// In en, this message translates to:
  /// **'study plans • revisions • tutor'**
  String get profileLearningSub;

  /// No description provided for @profileEice.
  ///
  /// In en, this message translates to:
  /// **'Exam Intelligence (EICE)'**
  String get profileEice;

  /// No description provided for @profileEiceSub.
  ///
  /// In en, this message translates to:
  /// **'coach • triage • sprint'**
  String get profileEiceSub;

  /// No description provided for @profilePsc.
  ///
  /// In en, this message translates to:
  /// **'PSC / Loksewa'**
  String get profilePsc;

  /// No description provided for @profilePscSub.
  ///
  /// In en, this message translates to:
  /// **'exam blueprints & syllabus'**
  String get profilePscSub;

  /// No description provided for @profilePracticeSub.
  ///
  /// In en, this message translates to:
  /// **'drill bookmarks • weak topics'**
  String get profilePracticeSub;

  /// No description provided for @profileLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get profileLeaderboard;

  /// No description provided for @profileLeaderboardSub.
  ///
  /// In en, this message translates to:
  /// **'global • friends • league'**
  String get profileLeaderboardSub;

  /// No description provided for @profileContests.
  ///
  /// In en, this message translates to:
  /// **'Contests'**
  String get profileContests;

  /// No description provided for @profileContestsSub.
  ///
  /// In en, this message translates to:
  /// **'live quizzes & leaderboards'**
  String get profileContestsSub;

  /// No description provided for @profileLiveEvents.
  ///
  /// In en, this message translates to:
  /// **'Live events'**
  String get profileLiveEvents;

  /// No description provided for @profileLiveEventsSub.
  ///
  /// In en, this message translates to:
  /// **'scheduled sessions & check-in'**
  String get profileLiveEventsSub;

  /// No description provided for @profileCoaching.
  ///
  /// In en, this message translates to:
  /// **'Coaching'**
  String get profileCoaching;

  /// No description provided for @profileCoachingSub.
  ///
  /// In en, this message translates to:
  /// **'weak areas • readiness • sprint'**
  String get profileCoachingSub;

  /// No description provided for @profileSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get profileSearch;

  /// No description provided for @profileSearchSub.
  ///
  /// In en, this message translates to:
  /// **'find any question'**
  String get profileSearchSub;

  /// No description provided for @profileNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get profileNotifications;

  /// No description provided for @profileNotificationsSub.
  ///
  /// In en, this message translates to:
  /// **'activity & reminders'**
  String get profileNotificationsSub;

  /// No description provided for @profileSocial.
  ///
  /// In en, this message translates to:
  /// **'Social & Referral'**
  String get profileSocial;

  /// No description provided for @profileSocialSub.
  ///
  /// In en, this message translates to:
  /// **'share • streak • leaderboard'**
  String get profileSocialSub;

  /// No description provided for @profileWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get profileWallet;

  /// No description provided for @profileWalletSub.
  ///
  /// In en, this message translates to:
  /// **'coins & ledger'**
  String get profileWalletSub;

  /// No description provided for @profileAchievementsSub.
  ///
  /// In en, this message translates to:
  /// **'streak + badges'**
  String get profileAchievementsSub;

  /// No description provided for @profileOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline content'**
  String get profileOffline;

  /// No description provided for @profileOfflineSub.
  ///
  /// In en, this message translates to:
  /// **'cached packs + prefetch'**
  String get profileOfflineSub;

  /// No description provided for @profileCalculatorsSub.
  ///
  /// In en, this message translates to:
  /// **'Civil formula engines'**
  String get profileCalculatorsSub;

  /// No description provided for @profileSettingsSub.
  ///
  /// In en, this message translates to:
  /// **'language • biometrics • logout'**
  String get profileSettingsSub;

  /// No description provided for @settingsSubscriptionActive.
  ///
  /// In en, this message translates to:
  /// **'Subscription must be cancelled before deletion'**
  String get settingsSubscriptionActive;

  /// No description provided for @settingsDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete account — please try again'**
  String get settingsDeleteFailed;

  /// No description provided for @settingsAccountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted'**
  String get settingsAccountDeleted;

  /// No description provided for @settingsNoBiometrics.
  ///
  /// In en, this message translates to:
  /// **'No biometrics enrolled on this device'**
  String get settingsNoBiometrics;

  /// No description provided for @settingsLanguageLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'Language saved on this device only — could not reach the server.'**
  String get settingsLanguageLocalOnly;

  /// No description provided for @settingsSystemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsSystemDefault;

  /// No description provided for @settingsAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get settingsAppLanguage;

  /// No description provided for @settingsBiometricLock.
  ///
  /// In en, this message translates to:
  /// **'Biometric app lock'**
  String get settingsBiometricLock;

  /// No description provided for @settingsBiometricLockSub.
  ///
  /// In en, this message translates to:
  /// **'Require biometrics after 30s in background'**
  String get settingsBiometricLockSub;

  /// No description provided for @settingsPrivacySub.
  ///
  /// In en, this message translates to:
  /// **'Analytics, functional and marketing consent'**
  String get settingsPrivacySub;

  /// No description provided for @settingsAiUsage.
  ///
  /// In en, this message translates to:
  /// **'Your AI usage'**
  String get settingsAiUsage;

  /// No description provided for @settingsAiUsageSub.
  ///
  /// In en, this message translates to:
  /// **'What AI used on your behalf, by feature'**
  String get settingsAiUsageSub;

  /// No description provided for @settingsAiKeys.
  ///
  /// In en, this message translates to:
  /// **'Your AI keys'**
  String get settingsAiKeys;

  /// No description provided for @settingsAiKeysSub.
  ///
  /// In en, this message translates to:
  /// **'Run AI features on your own provider quota'**
  String get settingsAiKeysSub;

  /// No description provided for @settingsLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get settingsLogOut;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsDeleteAccountSub.
  ///
  /// In en, this message translates to:
  /// **'Permanently erase your account, attempts and purchases'**
  String get settingsDeleteAccountSub;

  /// No description provided for @settingsDeleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get settingsDeleteAccountTitle;

  /// No description provided for @settingsDeleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account, quiz history, coins and purchases. This cannot be undone.'**
  String get settingsDeleteAccountBody;

  /// No description provided for @settingsTypeDeleteToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type \'DELETE\' to confirm'**
  String get settingsTypeDeleteToConfirm;

  /// No description provided for @settingsDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get settingsDeleteConfirm;

  /// No description provided for @streakRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get streakRefresh;

  /// No description provided for @streakNoneTitle.
  ///
  /// In en, this message translates to:
  /// **'No streak yet'**
  String get streakNoneTitle;

  /// No description provided for @streakNoneBody.
  ///
  /// In en, this message translates to:
  /// **'Complete a quiz to start your fire streak.'**
  String get streakNoneBody;

  /// No description provided for @streakCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get streakCalendar;

  /// No description provided for @streakOnFire.
  ///
  /// In en, this message translates to:
  /// **'You are on fire today — keep it up!'**
  String get streakOnFire;

  /// No description provided for @streakProtect.
  ///
  /// In en, this message translates to:
  /// **'Protect your streak'**
  String get streakProtect;

  /// No description provided for @streakFrozen.
  ///
  /// In en, this message translates to:
  /// **'Streak frozen for 30 days!'**
  String get streakFrozen;

  /// No description provided for @streakCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get streakCurrent;

  /// No description provided for @streakDaysUnit.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get streakDaysUnit;

  /// No description provided for @streakBest.
  ///
  /// In en, this message translates to:
  /// **'Best: {count} days'**
  String streakBest(int count);

  /// No description provided for @streakMultiplier.
  ///
  /// In en, this message translates to:
  /// **'multiplier'**
  String get streakMultiplier;

  /// No description provided for @streakMaxMultiplier.
  ///
  /// In en, this message translates to:
  /// **'Max multiplier reached — legendary!'**
  String get streakMaxMultiplier;

  /// No description provided for @streakDaysToNextTier.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total} days to next tier'**
  String streakDaysToNextTier(int current, int total);

  /// No description provided for @streakTiers.
  ///
  /// In en, this message translates to:
  /// **'1–6d → 1.0× • 7–29d → 1.5× • 30–99d → 2.0× • 100+d → 3.0×'**
  String get streakTiers;

  /// No description provided for @streakFreezeSection.
  ///
  /// In en, this message translates to:
  /// **'Streak freeze'**
  String get streakFreezeSection;

  /// No description provided for @streakFreezeLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} left'**
  String streakFreezeLeft(int count);

  /// No description provided for @streakFrozenUntil.
  ///
  /// In en, this message translates to:
  /// **'Frozen until {date}'**
  String streakFrozenUntil(Object date);

  /// No description provided for @streakFreezeHint.
  ///
  /// In en, this message translates to:
  /// **'Spend 50 coins to freeze streak for 30 days when you cannot play. Donor badge required.'**
  String get streakFreezeHint;

  /// No description provided for @streakExtendFreeze.
  ///
  /// In en, this message translates to:
  /// **'Extend freeze'**
  String get streakExtendFreeze;

  /// No description provided for @streakFreezeAction.
  ///
  /// In en, this message translates to:
  /// **'Freeze streak (50 coins)'**
  String get streakFreezeAction;

  /// No description provided for @streakRepairTitle.
  ///
  /// In en, this message translates to:
  /// **'Repair a missed day'**
  String get streakRepairTitle;

  /// No description provided for @streakRepairAction.
  ///
  /// In en, this message translates to:
  /// **'Repair streak'**
  String get streakRepairAction;

  /// No description provided for @streakInsurance.
  ///
  /// In en, this message translates to:
  /// **'Streak insurance'**
  String get streakInsurance;

  /// No description provided for @streakInsuranceChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking insurance…'**
  String get streakInsuranceChecking;

  /// No description provided for @streakBuy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get streakBuy;

  /// No description provided for @streakUseNow.
  ///
  /// In en, this message translates to:
  /// **'Use now'**
  String get streakUseNow;

  /// No description provided for @streakWager.
  ///
  /// In en, this message translates to:
  /// **'Streak wager'**
  String get streakWager;

  /// No description provided for @streakWagerDescription.
  ///
  /// In en, this message translates to:
  /// **'Stake coins on hitting a target streak. Meet it and you win the pot back with interest — miss and the coins are gone.'**
  String get streakWagerDescription;

  /// No description provided for @streakWagerDay.
  ///
  /// In en, this message translates to:
  /// **'Day {current} of {total} — keep playing to win {reward} coins.'**
  String streakWagerDay(int current, int total, Object reward);

  /// No description provided for @streakWagerStart.
  ///
  /// In en, this message translates to:
  /// **'Start a wager'**
  String get streakWagerStart;

  /// No description provided for @streakWagerInProgress.
  ///
  /// In en, this message translates to:
  /// **'Wager in progress'**
  String get streakWagerInProgress;

  /// No description provided for @streakWagerStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Start a streak wager'**
  String get streakWagerStartTitle;

  /// No description provided for @streakWagerStartBody.
  ///
  /// In en, this message translates to:
  /// **'Hit the target streak to win double. Miss it and the stake is gone.'**
  String get streakWagerStartBody;

  /// No description provided for @streakWagerStake.
  ///
  /// In en, this message translates to:
  /// **'Stake (coins)'**
  String get streakWagerStake;

  /// No description provided for @streakWagerDays.
  ///
  /// In en, this message translates to:
  /// **'Days to sustain'**
  String get streakWagerDays;

  /// No description provided for @streakXpMultiplier.
  ///
  /// In en, this message translates to:
  /// **'×{value} XP'**
  String streakXpMultiplier(Object value);

  /// No description provided for @streakWagerProgress.
  ///
  /// In en, this message translates to:
  /// **'{percent}% complete'**
  String streakWagerProgress(Object percent);

  /// No description provided for @streakFreezeDuration.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get streakFreezeDuration;

  /// No description provided for @streakWagerDaysCount.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String streakWagerDaysCount(int count);

  /// No description provided for @streakWagerSummary.
  ///
  /// In en, this message translates to:
  /// **'Wager {coins} coins for {days} days'**
  String streakWagerSummary(Object coins, int days);

  /// No description provided for @forceUpdateUnsupportedLatest.
  ///
  /// In en, this message translates to:
  /// **'This version of CivilCal is no longer supported. Please update to the latest version to continue.'**
  String get forceUpdateUnsupportedLatest;

  /// No description provided for @forceUpdateUnsupportedVersion.
  ///
  /// In en, this message translates to:
  /// **'This version of CivilCal is no longer supported. Please update to version {version} or later to continue.'**
  String forceUpdateUnsupportedVersion(Object version);

  /// No description provided for @routeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Route not found: {path}'**
  String routeNotFound(Object path);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'ne'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'ne':
      return AppLocalizationsNe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
