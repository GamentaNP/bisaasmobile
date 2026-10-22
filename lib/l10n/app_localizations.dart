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
  String streakDays(Object days);

  /// No description provided for @coinsBalance.
  ///
  /// In en, this message translates to:
  /// **'{count} coins'**
  String coinsBalance(Object count);

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
  String commonPoints(Object count);

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
  String authMinChars(Object count);

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

  /// No description provided for @onboardingStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String onboardingStepOf(Object current, Object total);

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
  String quizAttemptCombo(Object count);

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
  String quizResultCorrectOf(Object correct, Object total);

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
  String quizFunnelShown(Object count);

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
  String calcBrowserCount(Object count, Object domains);

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
  String calcInputsCount(Object count);

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
  String homeStars(Object earned, Object total);

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
  String homeMissionsReady(Object count);

  /// No description provided for @homeMissionsActive.
  ///
  /// In en, this message translates to:
  /// **'Missions — {count} active'**
  String homeMissionsActive(Object count);

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

  /// No description provided for @profileSearchSub.
  ///
  /// In en, this message translates to:
  /// **'find any question'**
  String get profileSearchSub;

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

  /// No description provided for @settingsAiUsageSub.
  ///
  /// In en, this message translates to:
  /// **'What AI used on your behalf, by feature'**
  String get settingsAiUsageSub;

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
  String streakBest(Object count);

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
  String streakDaysToNextTier(Object current, Object total);

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
  String streakFreezeLeft(Object count);

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
  String streakWagerDay(Object current, Object total, Object reward);

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
  String streakWagerDaysCount(Object count);

  /// No description provided for @streakWagerSummary.
  ///
  /// In en, this message translates to:
  /// **'Wager {coins} coins for {days} days'**
  String streakWagerSummary(Object coins, Object days);

  /// No description provided for @tutorStudyPlan.
  ///
  /// In en, this message translates to:
  /// **'Study Plan'**
  String get tutorStudyPlan;

  /// No description provided for @tutorChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get tutorChat;

  /// No description provided for @tutorPlanTab.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get tutorPlanTab;

  /// No description provided for @tutorInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get tutorInsights;

  /// No description provided for @tutorRevisions.
  ///
  /// In en, this message translates to:
  /// **'Revisions'**
  String get tutorRevisions;

  /// No description provided for @tutorWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get tutorWeekly;

  /// No description provided for @tutorNoTasksToday.
  ///
  /// In en, this message translates to:
  /// **'No tasks today — check back tomorrow'**
  String get tutorNoTasksToday;

  /// No description provided for @tutorDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get tutorDone;

  /// No description provided for @tutorTasksDone.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} tasks'**
  String tutorTasksDone(Object done, Object total);

  /// No description provided for @tutorDayCompleted.
  ///
  /// In en, this message translates to:
  /// **'Day completed — plan updated.'**
  String get tutorDayCompleted;

  /// No description provided for @tutorMarkDayComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark day complete'**
  String get tutorMarkDayComplete;

  /// No description provided for @tutorYourPlan.
  ///
  /// In en, this message translates to:
  /// **'Your plan — {title}'**
  String tutorYourPlan(Object title);

  /// No description provided for @tutorPlanDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days • current {current}'**
  String tutorPlanDays(Object days, Object current);

  /// No description provided for @tutorPlanNoDays.
  ///
  /// In en, this message translates to:
  /// **'Plan has no days yet — onboarding will generate it.'**
  String get tutorPlanNoDays;

  /// No description provided for @tutorMoreDays.
  ///
  /// In en, this message translates to:
  /// **'+ {count} more days'**
  String tutorMoreDays(Object count);

  /// No description provided for @tutorAdjustPlan.
  ///
  /// In en, this message translates to:
  /// **'Adjust plan'**
  String get tutorAdjustPlan;

  /// No description provided for @tutorNoPlanYet.
  ///
  /// In en, this message translates to:
  /// **'No plan yet'**
  String get tutorNoPlanYet;

  /// No description provided for @tutorOnboardingRequired.
  ///
  /// In en, this message translates to:
  /// **'Complete tutor onboarding to generate your personalized study plan.'**
  String get tutorOnboardingRequired;

  /// No description provided for @tutorStartOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Start onboarding'**
  String get tutorStartOnboarding;

  /// No description provided for @tutorAdjustExample.
  ///
  /// In en, this message translates to:
  /// **'e.g., \"I can do 3h/day\" or \"Focus more on soil mechanics\"'**
  String get tutorAdjustExample;

  /// No description provided for @tutorAdjustPrompt.
  ///
  /// In en, this message translates to:
  /// **'How should we adjust?'**
  String get tutorAdjustPrompt;

  /// No description provided for @tutorAdjustRequested.
  ///
  /// In en, this message translates to:
  /// **'Plan adjustment requested.'**
  String get tutorAdjustRequested;

  /// No description provided for @tutorSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get tutorSubmit;

  /// No description provided for @tutorProjectedScore.
  ///
  /// In en, this message translates to:
  /// **'Projected score'**
  String get tutorProjectedScore;

  /// No description provided for @tutorConfidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence {confidence}% • {trend}'**
  String tutorConfidence(Object confidence, Object trend);

  /// No description provided for @tutorWeakAreas.
  ///
  /// In en, this message translates to:
  /// **'Weak areas'**
  String get tutorWeakAreas;

  /// No description provided for @tutorNoWeakAreas.
  ///
  /// In en, this message translates to:
  /// **'No weak areas — great work! Keep practicing to stay sharp.'**
  String get tutorNoWeakAreas;

  /// No description provided for @tutorAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy {accuracy}% • {attempts} attempts'**
  String tutorAccuracy(Object accuracy, Object attempts);

  /// No description provided for @tutorNoRevisionsDue.
  ///
  /// In en, this message translates to:
  /// **'No revisions due — you are on track.'**
  String get tutorNoRevisionsDue;

  /// No description provided for @tutorDueLabel.
  ///
  /// In en, this message translates to:
  /// **'due {date}'**
  String tutorDueLabel(Object date);

  /// No description provided for @tutorTopicDue.
  ///
  /// In en, this message translates to:
  /// **'{topic} • due {date}'**
  String tutorTopicDue(Object topic, Object date);

  /// No description provided for @tutorCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get tutorCompleted;

  /// No description provided for @tutorOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get tutorOverdue;

  /// No description provided for @tutorDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get tutorDue;

  /// No description provided for @tutorWeekRange.
  ///
  /// In en, this message translates to:
  /// **'Week {start} → {end}'**
  String tutorWeekRange(Object start, Object end);

  /// No description provided for @tutorAvgScore.
  ///
  /// In en, this message translates to:
  /// **'Avg score'**
  String get tutorAvgScore;

  /// No description provided for @tutorHours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get tutorHours;

  /// No description provided for @tutorCompletion.
  ///
  /// In en, this message translates to:
  /// **'{percent}% completion'**
  String tutorCompletion(Object percent);

  /// No description provided for @tutorHighlights.
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get tutorHighlights;

  /// No description provided for @tutorWeeklyReportPending.
  ///
  /// In en, this message translates to:
  /// **'Weekly report appears after a week of activity.'**
  String get tutorWeeklyReportPending;

  /// No description provided for @tutorOnboardingSaved.
  ///
  /// In en, this message translates to:
  /// **'Onboarding saved — plan will generate shortly.'**
  String get tutorOnboardingSaved;

  /// No description provided for @tutorOnboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Tutor Onboarding'**
  String get tutorOnboardingTitle;

  /// No description provided for @tutorPersonalised.
  ///
  /// In en, this message translates to:
  /// **'Personalized tutor'**
  String get tutorPersonalised;

  /// No description provided for @tutorOnboardingExplain.
  ///
  /// In en, this message translates to:
  /// **'Tell us your goal — the server builds your plan. No user_id required (token-bound).'**
  String get tutorOnboardingExplain;

  /// No description provided for @tutorSessionLabel.
  ///
  /// In en, this message translates to:
  /// **'Session: {session}'**
  String tutorSessionLabel(Object session);

  /// No description provided for @tutorYourGoal.
  ///
  /// In en, this message translates to:
  /// **'Your goal'**
  String get tutorYourGoal;

  /// No description provided for @tutorGoalExample.
  ///
  /// In en, this message translates to:
  /// **'e.g., Crack PSC Civil in 6 months'**
  String get tutorGoalExample;

  /// No description provided for @tutorCurrentLevel.
  ///
  /// In en, this message translates to:
  /// **'Current level'**
  String get tutorCurrentLevel;

  /// No description provided for @tutorLevelExample.
  ///
  /// In en, this message translates to:
  /// **'e.g., Final year B.E. Civil'**
  String get tutorLevelExample;

  /// No description provided for @tutorHoursPerDay.
  ///
  /// In en, this message translates to:
  /// **'Hours per day'**
  String get tutorHoursPerDay;

  /// No description provided for @tutorHoursExample.
  ///
  /// In en, this message translates to:
  /// **'e.g., 2'**
  String get tutorHoursExample;

  /// No description provided for @tutorOnboardingComplete.
  ///
  /// In en, this message translates to:
  /// **'Onboarding complete — your plan is ready.'**
  String get tutorOnboardingComplete;

  /// No description provided for @tutorViewPlan.
  ///
  /// In en, this message translates to:
  /// **'View Plan'**
  String get tutorViewPlan;

  /// No description provided for @tutorCompleteOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Complete onboarding'**
  String get tutorCompleteOnboarding;

  /// No description provided for @tutorSkipToChat.
  ///
  /// In en, this message translates to:
  /// **'Skip → Chat with tutor'**
  String get tutorSkipToChat;

  /// No description provided for @tutorSavedToAccount.
  ///
  /// In en, this message translates to:
  /// **'Saved to your account. Safe to retry if the connection drops.'**
  String get tutorSavedToAccount;

  /// No description provided for @tutorTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Tutor'**
  String get tutorTitle;

  /// No description provided for @tutorClearChat.
  ///
  /// In en, this message translates to:
  /// **'Clear chat'**
  String get tutorClearChat;

  /// No description provided for @tutorNotEnoughHistory.
  ///
  /// In en, this message translates to:
  /// **'Not enough history yet — complete a few quizzes to personalize.'**
  String get tutorNotEnoughHistory;

  /// No description provided for @tutorDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get tutorDismiss;

  /// No description provided for @tutorWriting.
  ///
  /// In en, this message translates to:
  /// **'The tutor is writing its reply. It can take a moment on longer questions.'**
  String get tutorWriting;

  /// No description provided for @tutorAskAnything.
  ///
  /// In en, this message translates to:
  /// **'Ask anything'**
  String get tutorAskAnything;

  /// No description provided for @tutorChatExplain.
  ///
  /// In en, this message translates to:
  /// **'Exam concepts, beam deflection, soil mechanics — AI answers via Laravel gateway (never direct provider).'**
  String get tutorChatExplain;

  /// No description provided for @tutorExample1.
  ///
  /// In en, this message translates to:
  /// **'Explain proctor compaction'**
  String get tutorExample1;

  /// No description provided for @tutorExample2.
  ///
  /// In en, this message translates to:
  /// **'Weekly plan help'**
  String get tutorExample2;

  /// No description provided for @tutorExample3.
  ///
  /// In en, this message translates to:
  /// **'Weak areas?'**
  String get tutorExample3;

  /// No description provided for @tutorTyping.
  ///
  /// In en, this message translates to:
  /// **'Tutor is typing…'**
  String get tutorTyping;

  /// No description provided for @tutorInputHint.
  ///
  /// In en, this message translates to:
  /// **'Ask tutor…'**
  String get tutorInputHint;

  /// No description provided for @aiUsageTitle.
  ///
  /// In en, this message translates to:
  /// **'Your AI usage'**
  String get aiUsageTitle;

  /// No description provided for @aiUsageOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get aiUsageOverview;

  /// No description provided for @aiUsageRequests.
  ///
  /// In en, this message translates to:
  /// **'requests'**
  String get aiUsageRequests;

  /// No description provided for @aiUsageTokens.
  ///
  /// In en, this message translates to:
  /// **'tokens'**
  String get aiUsageTokens;

  /// No description provided for @aiUsageTutorChats.
  ///
  /// In en, this message translates to:
  /// **'tutor chats (all time)'**
  String get aiUsageTutorChats;

  /// No description provided for @aiUsageNone.
  ///
  /// In en, this message translates to:
  /// **'No AI features were used in this period.'**
  String get aiUsageNone;

  /// No description provided for @aiUsageByFeature.
  ///
  /// In en, this message translates to:
  /// **'By feature'**
  String get aiUsageByFeature;

  /// No description provided for @aiUsageTutorConversations.
  ///
  /// In en, this message translates to:
  /// **'Tutor conversations'**
  String get aiUsageTutorConversations;

  /// No description provided for @aiUsageNoConversations.
  ///
  /// In en, this message translates to:
  /// **'No tutor conversations yet.'**
  String get aiUsageNoConversations;

  /// No description provided for @aiUsageLoadMoreConversations.
  ///
  /// In en, this message translates to:
  /// **'Load more conversations'**
  String get aiUsageLoadMoreConversations;

  /// No description provided for @aiUsageWeeklyReport.
  ///
  /// In en, this message translates to:
  /// **'Weekly report card'**
  String get aiUsageWeeklyReport;

  /// No description provided for @aiUsageNoWeeks.
  ///
  /// In en, this message translates to:
  /// **'No weekly summaries stored yet.'**
  String get aiUsageNoWeeks;

  /// No description provided for @aiUsageLoadMoreWeeks.
  ///
  /// In en, this message translates to:
  /// **'Load more weeks'**
  String get aiUsageLoadMoreWeeks;

  /// No description provided for @aiUsageConversationNumber.
  ///
  /// In en, this message translates to:
  /// **'Conversation #{number}'**
  String aiUsageConversationNumber(Object number);

  /// No description provided for @aiUsageQuestionNumber.
  ///
  /// In en, this message translates to:
  /// **'Question {number}'**
  String aiUsageQuestionNumber(Object number);

  /// No description provided for @aiUsageTurns.
  ///
  /// In en, this message translates to:
  /// **'{count} turns'**
  String aiUsageTurns(Object count);

  /// No description provided for @aiUsageWeekOf.
  ///
  /// In en, this message translates to:
  /// **'Week of {date}'**
  String aiUsageWeekOf(Object date);

  /// No description provided for @aiUsageWeekSummary.
  ///
  /// In en, this message translates to:
  /// **'{accuracy}% accuracy • {xp} XP • {coins} coins • {streak} day streak'**
  String aiUsageWeekSummary(
    Object accuracy,
    Object xp,
    Object coins,
    Object streak,
  );

  /// No description provided for @aiUsageHoursShort.
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String aiUsageHoursShort(Object hours);

  /// No description provided for @aiKeysTitle.
  ///
  /// In en, this message translates to:
  /// **'Your AI keys'**
  String get aiKeysTitle;

  /// No description provided for @aiKeysExplain.
  ///
  /// In en, this message translates to:
  /// **'Your key is encrypted on our servers and never shown again. Only the last four characters are ever displayed.'**
  String get aiKeysExplain;

  /// No description provided for @aiKeysAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a key'**
  String get aiKeysAddTitle;

  /// No description provided for @aiKeysNoneYet.
  ///
  /// In en, this message translates to:
  /// **'No keys yet'**
  String get aiKeysNoneYet;

  /// No description provided for @aiKeysNoneExplain.
  ///
  /// In en, this message translates to:
  /// **'Add a provider key to run AI features on your own quota instead of the shared one.'**
  String get aiKeysNoneExplain;

  /// No description provided for @aiKeysStored.
  ///
  /// In en, this message translates to:
  /// **'Stored keys'**
  String get aiKeysStored;

  /// No description provided for @aiKeysTokensUsed.
  ///
  /// In en, this message translates to:
  /// **'{used} of {total} daily tokens used'**
  String aiKeysTokensUsed(Object used, Object total);

  /// No description provided for @aiKeysRevoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get aiKeysRevoke;

  /// No description provided for @aiKeysTooShort.
  ///
  /// In en, this message translates to:
  /// **'The key must be at least 8 characters'**
  String get aiKeysTooShort;

  /// No description provided for @aiKeysAddProvider.
  ///
  /// In en, this message translates to:
  /// **'Add a provider key'**
  String get aiKeysAddProvider;

  /// No description provided for @aiKeysProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get aiKeysProvider;

  /// No description provided for @aiKeysApiKey.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get aiKeysApiKey;

  /// No description provided for @aiKeysSentOnce.
  ///
  /// In en, this message translates to:
  /// **'Sent once and never shown again.'**
  String get aiKeysSentOnce;

  /// No description provided for @aiKeysLabelOptional.
  ///
  /// In en, this message translates to:
  /// **'Label (optional)'**
  String get aiKeysLabelOptional;

  /// No description provided for @aiKeysSaveKey.
  ///
  /// In en, this message translates to:
  /// **'Save key'**
  String get aiKeysSaveKey;

  /// No description provided for @aiKeysSaved.
  ///
  /// In en, this message translates to:
  /// **'{name} saved. It is encrypted on our servers and never shown again.'**
  String aiKeysSaved(Object name);

  /// No description provided for @aiKeysRevoked.
  ///
  /// In en, this message translates to:
  /// **'Key revoked.'**
  String get aiKeysRevoked;

  /// No description provided for @practiceBookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get practiceBookmarks;

  /// No description provided for @practiceWeakTopics.
  ///
  /// In en, this message translates to:
  /// **'Weak Topics'**
  String get practiceWeakTopics;

  /// No description provided for @practiceSelfChallenge.
  ///
  /// In en, this message translates to:
  /// **'Self Challenge'**
  String get practiceSelfChallenge;

  /// No description provided for @practiceHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get practiceHistory;

  /// No description provided for @practiceNoBookmarks.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks to practice'**
  String get practiceNoBookmarks;

  /// No description provided for @practiceBookmarkedPractice.
  ///
  /// In en, this message translates to:
  /// **'Bookmarked Practice'**
  String get practiceBookmarkedPractice;

  /// No description provided for @practiceBookmarksUnavailable.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} bookmarks could not be drilled — the server does not publish their answer options yet.'**
  String practiceBookmarksUnavailable(Object count, Object total);

  /// No description provided for @practiceDrill.
  ///
  /// In en, this message translates to:
  /// **'Practice Drill'**
  String get practiceDrill;

  /// No description provided for @practiceDrillCount.
  ///
  /// In en, this message translates to:
  /// **'Drill: {count}'**
  String practiceDrillCount(Object count);

  /// No description provided for @practiceNoBookmarksBody.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks'**
  String get practiceNoBookmarksBody;

  /// No description provided for @practiceNoBookmarksHint.
  ///
  /// In en, this message translates to:
  /// **'Bookmark questions while you take a quiz and they will show up here for drilling later.'**
  String get practiceNoBookmarksHint;

  /// No description provided for @practiceBrowseQuizzes.
  ///
  /// In en, this message translates to:
  /// **'Browse quizzes'**
  String get practiceBrowseQuizzes;

  /// No description provided for @practiceBookmarkedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} bookmarked'**
  String practiceBookmarkedCount(Object count);

  /// No description provided for @practiceAll.
  ///
  /// In en, this message translates to:
  /// **'Practice all'**
  String get practiceAll;

  /// No description provided for @practiceQuestionNumber.
  ///
  /// In en, this message translates to:
  /// **'Question #{number}'**
  String practiceQuestionNumber(Object number);

  /// No description provided for @practiceQuestionMeta.
  ///
  /// In en, this message translates to:
  /// **'{meta} • difficulty {difficulty} • {points} pts'**
  String practiceQuestionMeta(Object meta, Object difficulty, Object points);

  /// No description provided for @practiceBookmarked.
  ///
  /// In en, this message translates to:
  /// **'Bookmarked'**
  String get practiceBookmarked;

  /// No description provided for @practiceLoadMoreCursor.
  ///
  /// In en, this message translates to:
  /// **'Load more (cursor)'**
  String get practiceLoadMoreCursor;

  /// No description provided for @practiceWeakTopicsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your weak topics'**
  String get practiceWeakTopicsLoadFailed;

  /// No description provided for @practiceWeakTopicsExplained.
  ///
  /// In en, this message translates to:
  /// **'These are worked out from your own answer history. Nothing is shown unless it is real.'**
  String get practiceWeakTopicsExplained;

  /// No description provided for @practiceNoWeakTopics.
  ///
  /// In en, this message translates to:
  /// **'No weak topics yet'**
  String get practiceNoWeakTopics;

  /// No description provided for @practiceWeakTopicsNeedsAttempts.
  ///
  /// In en, this message translates to:
  /// **'The server needs graded attempts before it can spot weak areas. Take a quiz from the Quiz tab and check back.'**
  String get practiceWeakTopicsNeedsAttempts;

  /// No description provided for @practiceWeakTopicsServerNote.
  ///
  /// In en, this message translates to:
  /// **'Weak topics are worked out on our servers from your answer history, so nothing here is guessed.'**
  String get practiceWeakTopicsServerNote;

  /// No description provided for @practiceYourWeakTopics.
  ///
  /// In en, this message translates to:
  /// **'Your weak topics'**
  String get practiceYourWeakTopics;

  /// No description provided for @practiceDrillAction.
  ///
  /// In en, this message translates to:
  /// **'Drill'**
  String get practiceDrillAction;

  /// No description provided for @practiceDrillTen.
  ///
  /// In en, this message translates to:
  /// **'Drill 10 questions (practice mode, untimed)'**
  String get practiceDrillTen;

  /// No description provided for @practiceUntimedNote.
  ///
  /// In en, this message translates to:
  /// **'Practice is untimed and does not affect your rank or coin balance.'**
  String get practiceUntimedNote;

  /// No description provided for @practiceSelfChallengeExplain.
  ///
  /// In en, this message translates to:
  /// **'Pick question count & difficulty — mirrors Elite Quiz self-challenge but sourced from adaptive engine.'**
  String get practiceSelfChallengeExplain;

  /// No description provided for @practiceQuestionCount.
  ///
  /// In en, this message translates to:
  /// **'Question count: {count}'**
  String practiceQuestionCount(Object count);

  /// No description provided for @practiceDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get practiceDifficulty;

  /// No description provided for @practiceStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get practiceStarting;

  /// No description provided for @practiceStartChallenge.
  ///
  /// In en, this message translates to:
  /// **'Start challenge ({count} Qs)'**
  String practiceStartChallenge(Object count);

  /// No description provided for @practiceResultsLabelled.
  ///
  /// In en, this message translates to:
  /// **'Results are labelled as practice, so they never count towards your rank.'**
  String get practiceResultsLabelled;

  /// No description provided for @practiceNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No history'**
  String get practiceNoHistory;

  /// No description provided for @practiceNoHistoryBody.
  ///
  /// In en, this message translates to:
  /// **'Your completed practice sessions will appear here.'**
  String get practiceNoHistoryBody;

  /// No description provided for @practiceAttemptMeta.
  ///
  /// In en, this message translates to:
  /// **'Attempt #{number} • {mode}'**
  String practiceAttemptMeta(Object number, Object mode);

  /// No description provided for @practiceAttemptSummary.
  ///
  /// In en, this message translates to:
  /// **'{meta} • score {score} • {correct}✓ {wrong}✗ {skipped}– • {questions} Qs'**
  String practiceAttemptSummary(
    Object meta,
    Object score,
    Object correct,
    Object wrong,
    Object skipped,
    Object questions,
  );

  /// No description provided for @economyInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get economyInventory;

  /// No description provided for @economyYourResources.
  ///
  /// In en, this message translates to:
  /// **'Your resources'**
  String get economyYourResources;

  /// No description provided for @economyResourceSummary.
  ///
  /// In en, this message translates to:
  /// **'{held} held • {catalog} catalog • {recent} recent'**
  String economyResourceSummary(Object held, Object catalog, Object recent);

  /// No description provided for @economyNoResources.
  ///
  /// In en, this message translates to:
  /// **'No resources yet'**
  String get economyNoResources;

  /// No description provided for @economyResourcesExplain.
  ///
  /// In en, this message translates to:
  /// **'Resources are earned via city / economy flows and quiz rewards. They appear here when available.'**
  String get economyResourcesExplain;

  /// No description provided for @economyCatalog.
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get economyCatalog;

  /// No description provided for @economyCatalogEmpty.
  ///
  /// In en, this message translates to:
  /// **'Catalog empty — server will populate material list.'**
  String get economyCatalogEmpty;

  /// No description provided for @economyRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get economyRecentActivity;

  /// No description provided for @economyNoRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'No recent activity.'**
  String get economyNoRecentActivity;

  /// No description provided for @economyDonations.
  ///
  /// In en, this message translates to:
  /// **'Donations'**
  String get economyDonations;

  /// No description provided for @economyDonationsExplain.
  ///
  /// In en, this message translates to:
  /// **'Live leaderboard and feed. Coins can freeze a donor streak.'**
  String get economyDonationsExplain;

  /// No description provided for @economyLeaderboardFeed.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard/feed: {status}'**
  String economyLeaderboardFeed(Object status);

  /// No description provided for @economyStreakMonths.
  ///
  /// In en, this message translates to:
  /// **'{name} • {months} mo streak'**
  String economyStreakMonths(Object name, Object months);

  /// No description provided for @economyLiveFeed.
  ///
  /// In en, this message translates to:
  /// **'Live feed'**
  String get economyLiveFeed;

  /// No description provided for @economyDonationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Donation leaderboard and feed are empty.'**
  String get economyDonationsEmpty;

  /// No description provided for @economySyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get economySyncing;

  /// No description provided for @economyLedger.
  ///
  /// In en, this message translates to:
  /// **'Ledger'**
  String get economyLedger;

  /// No description provided for @economyLedgerExplain.
  ///
  /// In en, this message translates to:
  /// **'Grouped by day. Source labels come from credits.description (not metadata.source).'**
  String get economyLedgerExplain;

  /// No description provided for @economyWhereCoinsWent.
  ///
  /// In en, this message translates to:
  /// **'Where your coins went'**
  String get economyWhereCoinsWent;

  /// No description provided for @economyPeriodSummary.
  ///
  /// In en, this message translates to:
  /// **'Last {days} days • earned {earned} • spent {spent}'**
  String economyPeriodSummary(Object days, Object earned, Object spent);

  /// No description provided for @economyNoActivity.
  ///
  /// In en, this message translates to:
  /// **'No coin activity in this period.'**
  String get economyNoActivity;

  /// No description provided for @economyHowYouEarn.
  ///
  /// In en, this message translates to:
  /// **'How you earn'**
  String get economyHowYouEarn;

  /// No description provided for @economyMintingExplain.
  ///
  /// In en, this message translates to:
  /// **'Coins are credited after each graded quiz and server-side daily actions. They are never minted on your device, so your balance cannot drift.'**
  String get economyMintingExplain;

  /// No description provided for @economyNoTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get economyNoTransactions;

  /// No description provided for @economyNoTransactionsBody.
  ///
  /// In en, this message translates to:
  /// **'Complete a quiz to earn coins. Every credit is recorded on our servers.'**
  String get economyNoTransactionsBody;

  /// No description provided for @economyTitle.
  ///
  /// In en, this message translates to:
  /// **'Economy'**
  String get economyTitle;

  /// No description provided for @economyXpTotal.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP total'**
  String economyXpTotal(Object xp);

  /// No description provided for @economyLiveExplain.
  ///
  /// In en, this message translates to:
  /// **'Balance, ledger, shop and store are all live. Coins are minted server-side when a graded attempt completes.'**
  String get economyLiveExplain;

  /// No description provided for @economyWalletTile.
  ///
  /// In en, this message translates to:
  /// **'Wallet - balance + ledger by day'**
  String get economyWalletTile;

  /// No description provided for @economyWalletTileSub.
  ///
  /// In en, this message translates to:
  /// **'Balance, lifetime totals and your coin history'**
  String get economyWalletTileSub;

  /// No description provided for @economyShopTile.
  ///
  /// In en, this message translates to:
  /// **'Coin Shop - resources & bundles'**
  String get economyShopTile;

  /// No description provided for @economyShopTileSub.
  ///
  /// In en, this message translates to:
  /// **'Spend coins on materials and bundles'**
  String get economyShopTileSub;

  /// No description provided for @economyInventoryTile.
  ///
  /// In en, this message translates to:
  /// **'Inventory — resources + donations'**
  String get economyInventoryTile;

  /// No description provided for @economyInventoryTileSub.
  ///
  /// In en, this message translates to:
  /// **'8 materials + catalog + live donations feed/leaderboard'**
  String get economyInventoryTileSub;

  /// No description provided for @economyStoreTile.
  ///
  /// In en, this message translates to:
  /// **'Premium Store - assets & skins'**
  String get economyStoreTile;

  /// No description provided for @economyStoreTileSub.
  ///
  /// In en, this message translates to:
  /// **'Buy frames, themes, badges and avatars'**
  String get economyStoreTileSub;

  /// No description provided for @economyWardrobeTile.
  ///
  /// In en, this message translates to:
  /// **'Wardrobe - equip'**
  String get economyWardrobeTile;

  /// No description provided for @economyWardrobeTileSub.
  ///
  /// In en, this message translates to:
  /// **'Equip or clear the assets you own'**
  String get economyWardrobeTileSub;

  /// No description provided for @economyShopTitle.
  ///
  /// In en, this message translates to:
  /// **'Coin Shop'**
  String get economyShopTitle;

  /// No description provided for @economyNothingForSale.
  ///
  /// In en, this message translates to:
  /// **'Nothing for sale yet'**
  String get economyNothingForSale;

  /// No description provided for @economyShopEmpty.
  ///
  /// In en, this message translates to:
  /// **'The shop has no items published on the server right now.'**
  String get economyShopEmpty;

  /// No description provided for @economyBundles.
  ///
  /// In en, this message translates to:
  /// **'Bundles'**
  String get economyBundles;

  /// No description provided for @economyMaterials.
  ///
  /// In en, this message translates to:
  /// **'Materials'**
  String get economyMaterials;

  /// No description provided for @economyPurchaseSafe.
  ///
  /// In en, this message translates to:
  /// **'If a purchase does not go through, retrying is safe — you are never charged twice.'**
  String get economyPurchaseSafe;

  /// No description provided for @economySellsBackFor.
  ///
  /// In en, this message translates to:
  /// **'sells back for {coins}'**
  String economySellsBackFor(Object coins);

  /// No description provided for @economySave.
  ///
  /// In en, this message translates to:
  /// **'save {coins}'**
  String economySave(Object coins);

  /// No description provided for @libraryUnlockedCoins.
  ///
  /// In en, this message translates to:
  /// **'Unlocked! Coins spent: {coins}'**
  String libraryUnlockedCoins(Object coins);

  /// No description provided for @libraryDownloadStarted.
  ///
  /// In en, this message translates to:
  /// **'Download started — opening browser'**
  String get libraryDownloadStarted;

  /// No description provided for @libraryDownloadUrl.
  ///
  /// In en, this message translates to:
  /// **'Download URL: {url}'**
  String libraryDownloadUrl(Object url);

  /// No description provided for @libraryRatingRange.
  ///
  /// In en, this message translates to:
  /// **'Rating must be 1-5'**
  String get libraryRatingRange;

  /// No description provided for @libraryReviewSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Review submitted'**
  String get libraryReviewSubmitted;

  /// No description provided for @libraryAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get libraryAbout;

  /// No description provided for @libraryReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get libraryReviews;

  /// No description provided for @libraryNoReviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet — be the first to review after unlocking!'**
  String get libraryNoReviews;

  /// No description provided for @libraryLoadMoreReviews.
  ///
  /// In en, this message translates to:
  /// **'Load more reviews'**
  String get libraryLoadMoreReviews;

  /// No description provided for @librarySignedUrls.
  ///
  /// In en, this message translates to:
  /// **'Download URLs are signed and short-lived. If a download fails, tap Download again to get a fresh URL. Respect library-api-download throttle.'**
  String get librarySignedUrls;

  /// No description provided for @libraryFree.
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get libraryFree;

  /// No description provided for @libraryCoinsLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} COINS'**
  String libraryCoinsLabel(Object count);

  /// No description provided for @libraryFeatured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get libraryFeatured;

  /// No description provided for @libraryByUploader.
  ///
  /// In en, this message translates to:
  /// **'by {name}'**
  String libraryByUploader(Object name);

  /// No description provided for @libraryUnlockedFor.
  ///
  /// In en, this message translates to:
  /// **'Unlocked • {coins} coins'**
  String libraryUnlockedFor(Object coins);

  /// No description provided for @libraryUnlocking.
  ///
  /// In en, this message translates to:
  /// **'Unlocking…'**
  String get libraryUnlocking;

  /// No description provided for @libraryGettingLink.
  ///
  /// In en, this message translates to:
  /// **'Getting link…'**
  String get libraryGettingLink;

  /// No description provided for @libraryDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get libraryDownload;

  /// No description provided for @libraryUnlockNote.
  ///
  /// In en, this message translates to:
  /// **'Unlocking is charged to your coin balance once, even if the tap does not register the first time. You need to unlock a file before you can download it.'**
  String get libraryUnlockNote;

  /// No description provided for @libraryReviewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String libraryReviewsCount(Object count);

  /// No description provided for @libraryDownloads.
  ///
  /// In en, this message translates to:
  /// **'downloads'**
  String get libraryDownloads;

  /// No description provided for @libraryAccess.
  ///
  /// In en, this message translates to:
  /// **'access'**
  String get libraryAccess;

  /// No description provided for @libraryWriteReview.
  ///
  /// In en, this message translates to:
  /// **'Write a review (must unlock first)'**
  String get libraryWriteReview;

  /// No description provided for @libraryCommentOptional.
  ///
  /// In en, this message translates to:
  /// **'Comment (optional)'**
  String get libraryCommentOptional;

  /// No description provided for @librarySubmitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get librarySubmitting;

  /// No description provided for @librarySubmitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit review'**
  String get librarySubmitReview;

  /// No description provided for @libraryReviewVerified.
  ///
  /// In en, this message translates to:
  /// **'Reviews are verified if you have downloaded/unlocked the file.'**
  String get libraryReviewVerified;

  /// No description provided for @libraryVerified.
  ///
  /// In en, this message translates to:
  /// **'verified'**
  String get libraryVerified;

  /// No description provided for @librarySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search files, categories…'**
  String get librarySearchHint;

  /// No description provided for @libraryTrendingFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the trending files.\n{reason}'**
  String libraryTrendingFailed(Object reason);

  /// No description provided for @libraryTrending.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get libraryTrending;

  /// No description provided for @libraryRecommendedFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your recommendations.\n{reason}'**
  String libraryRecommendedFailed(Object reason);

  /// No description provided for @libraryRecommendedForYou.
  ///
  /// In en, this message translates to:
  /// **'Recommended for you'**
  String get libraryRecommendedForYou;

  /// No description provided for @libraryFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get libraryFiles;

  /// No description provided for @libraryTotalCount.
  ///
  /// In en, this message translates to:
  /// **'{count} total'**
  String libraryTotalCount(Object count);

  /// No description provided for @libraryNoFiles.
  ///
  /// In en, this message translates to:
  /// **'No files yet'**
  String get libraryNoFiles;

  /// No description provided for @libraryNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String libraryNoResults(Object query);

  /// No description provided for @libraryNoFilesBody.
  ///
  /// In en, this message translates to:
  /// **'Library files will appear here once published and approved on the server.'**
  String get libraryNoFilesBody;

  /// No description provided for @libraryTryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term or clear filters.'**
  String get libraryTryDifferentSearch;

  /// No description provided for @libraryClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get libraryClearSearch;

  /// No description provided for @libraryNoCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories published'**
  String get libraryNoCategories;

  /// No description provided for @commonLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get commonLoadMore;

  /// No description provided for @commonLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get commonLeaderboard;

  /// No description provided for @commonWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get commonWallet;

  /// No description provided for @commonLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get commonLibrary;

  /// No description provided for @practiceDrillComplete.
  ///
  /// In en, this message translates to:
  /// **'Drill complete'**
  String get practiceDrillComplete;

  /// No description provided for @practiceDoesNotAffect.
  ///
  /// In en, this message translates to:
  /// **'Practice — does not affect rank, XP or streak'**
  String get practiceDoesNotAffect;

  /// No description provided for @practiceAnsweredSkipped.
  ///
  /// In en, this message translates to:
  /// **'{answered} answered • {skipped} skipped'**
  String practiceAnsweredSkipped(Object answered, Object skipped);

  /// No description provided for @practiceScore.
  ///
  /// In en, this message translates to:
  /// **'Score {score}'**
  String practiceScore(Object score);

  /// No description provided for @practiceGradedByServer.
  ///
  /// In en, this message translates to:
  /// **'Graded by the server'**
  String get practiceGradedByServer;

  /// No description provided for @practiceCorrectWrongSkipped.
  ///
  /// In en, this message translates to:
  /// **'{correct} correct • {wrong} wrong • {skipped} skipped'**
  String practiceCorrectWrongSkipped(
    Object correct,
    Object wrong,
    Object skipped,
  );

  /// No description provided for @practiceGradingFailed.
  ///
  /// In en, this message translates to:
  /// **'The server could not grade this drill: {reason}'**
  String practiceGradingFailed(Object reason);

  /// No description provided for @practiceReviewPassNote.
  ///
  /// In en, this message translates to:
  /// **'This was a review pass. No attempt was created, so there is no score to show.'**
  String get practiceReviewPassNote;

  /// No description provided for @practiceNoQuestionsInSet.
  ///
  /// In en, this message translates to:
  /// **'No questions in this set'**
  String get practiceNoQuestionsInSet;

  /// No description provided for @practiceQuestionCounter.
  ///
  /// In en, this message translates to:
  /// **'Q {current}/{total}'**
  String practiceQuestionCounter(Object current, Object total);

  /// No description provided for @practiceUntimedPractice.
  ///
  /// In en, this message translates to:
  /// **'Untimed • Practice'**
  String get practiceUntimedPractice;

  /// No description provided for @practiceDifficultyLabel.
  ///
  /// In en, this message translates to:
  /// **'Difficulty: {difficulty}'**
  String practiceDifficultyLabel(Object difficulty);

  /// No description provided for @practiceNoOptionsNotice.
  ///
  /// In en, this message translates to:
  /// **'The server sent this question without answer options, so it cannot be drilled here. Try the graded Quiz tab, which loads a full session.'**
  String get practiceNoOptionsNotice;

  /// No description provided for @practiceAnswerSentNotice.
  ///
  /// In en, this message translates to:
  /// **'Answer sent to the server. It grades the attempt — this screen never guesses a score.'**
  String get practiceAnswerSentNotice;

  /// No description provided for @practicePrev.
  ///
  /// In en, this message translates to:
  /// **'Prev'**
  String get practicePrev;

  /// No description provided for @practiceGrading.
  ///
  /// In en, this message translates to:
  /// **'Grading…'**
  String get practiceGrading;

  /// No description provided for @practiceNoEffectNote.
  ///
  /// In en, this message translates to:
  /// **'Practice is untimed and carries no score, XP, coins or streak effect.'**
  String get practiceNoEffectNote;

  /// No description provided for @liveEventNotFound.
  ///
  /// In en, this message translates to:
  /// **'Live event not found'**
  String get liveEventNotFound;

  /// No description provided for @liveEventParticipant.
  ///
  /// In en, this message translates to:
  /// **'Participant #{number} • {status} • Score {score}'**
  String liveEventParticipant(Object number, Object status, Object score);

  /// No description provided for @liveEventSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Snapshot'**
  String get liveEventSnapshot;

  /// No description provided for @liveEventNoSnapshot.
  ///
  /// In en, this message translates to:
  /// **'No snapshot yet — register and check in to load current question.'**
  String get liveEventNoSnapshot;

  /// No description provided for @liveEventAnswer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get liveEventAnswer;

  /// No description provided for @liveEventQIndex.
  ///
  /// In en, this message translates to:
  /// **'Q index'**
  String get liveEventQIndex;

  /// No description provided for @liveEventSubmitAnswer.
  ///
  /// In en, this message translates to:
  /// **'Submit Answer'**
  String get liveEventSubmitAnswer;

  /// No description provided for @liveEventNoLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'No leaderboard yet.'**
  String get liveEventNoLeaderboard;

  /// No description provided for @liveEventRegistered.
  ///
  /// In en, this message translates to:
  /// **'Registered!'**
  String get liveEventRegistered;

  /// No description provided for @liveEventRegisterFailed.
  ///
  /// In en, this message translates to:
  /// **'Register failed'**
  String get liveEventRegisterFailed;

  /// No description provided for @liveEventUnregistered.
  ///
  /// In en, this message translates to:
  /// **'Unregistered'**
  String get liveEventUnregistered;

  /// No description provided for @liveEventUnregisterFailed.
  ///
  /// In en, this message translates to:
  /// **'Unregister failed'**
  String get liveEventUnregisterFailed;

  /// No description provided for @liveEventCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Checked in!'**
  String get liveEventCheckedIn;

  /// No description provided for @liveEventCheckInFailed.
  ///
  /// In en, this message translates to:
  /// **'Check-in failed'**
  String get liveEventCheckInFailed;

  /// No description provided for @liveEventEnterAnswer.
  ///
  /// In en, this message translates to:
  /// **'Enter an answer'**
  String get liveEventEnterAnswer;

  /// No description provided for @liveEventAnswerRecorded.
  ///
  /// In en, this message translates to:
  /// **'Answer recorded — score {score}'**
  String liveEventAnswerRecorded(Object score);

  /// No description provided for @liveEventQuestionsEach.
  ///
  /// In en, this message translates to:
  /// **'{questions} Qs • {seconds}s each'**
  String liveEventQuestionsEach(Object questions, Object seconds);

  /// No description provided for @liveEventActive.
  ///
  /// In en, this message translates to:
  /// **'{count} active'**
  String liveEventActive(Object count);

  /// No description provided for @liveEventWaitlisted.
  ///
  /// In en, this message translates to:
  /// **'{count} waitlisted'**
  String liveEventWaitlisted(Object count);

  /// No description provided for @liveEventStarts.
  ///
  /// In en, this message translates to:
  /// **'Starts {date} {hour}:{minute}'**
  String liveEventStarts(Object date, Object hour, Object minute);

  /// No description provided for @liveEventEnds.
  ///
  /// In en, this message translates to:
  /// **'Ends {date}'**
  String liveEventEnds(Object date);

  /// No description provided for @liveEventEntryFee.
  ///
  /// In en, this message translates to:
  /// **'{coins} entry'**
  String liveEventEntryFee(Object coins);

  /// No description provided for @liveEventPrize.
  ///
  /// In en, this message translates to:
  /// **'{coins} prize'**
  String liveEventPrize(Object coins);

  /// No description provided for @liveEventLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get liveEventLeave;

  /// No description provided for @liveEventCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get liveEventCheckIn;

  /// No description provided for @liveEventScoreMeta.
  ///
  /// In en, this message translates to:
  /// **'Score {score} • {correct}/{total}'**
  String liveEventScoreMeta(Object score, Object correct, Object total);

  /// No description provided for @liveEventQuestionPoints.
  ///
  /// In en, this message translates to:
  /// **'Q{number} • {points} pts'**
  String liveEventQuestionPoints(Object number, Object points);

  /// No description provided for @liveEventRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining: {seconds}s • Locks at {locks}'**
  String liveEventRemaining(Object seconds, Object locks);

  /// No description provided for @liveEventWaitingForHost.
  ///
  /// In en, this message translates to:
  /// **'No current question — waiting for host.'**
  String get liveEventWaitingForHost;

  /// No description provided for @liveEventRawKeys.
  ///
  /// In en, this message translates to:
  /// **'Raw keys: {keys}'**
  String liveEventRawKeys(Object keys);

  /// No description provided for @coachingTutorChat.
  ///
  /// In en, this message translates to:
  /// **'Tutor chat'**
  String get coachingTutorChat;

  /// No description provided for @coachingStudyPlan.
  ///
  /// In en, this message translates to:
  /// **'Study plan'**
  String get coachingStudyPlan;

  /// No description provided for @coachingTutorOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Tutor onboarding'**
  String get coachingTutorOnboarding;

  /// No description provided for @coachingGoalIdHint.
  ///
  /// In en, this message translates to:
  /// **'Goal ID for readiness (e.g., psc-civil)'**
  String get coachingGoalIdHint;

  /// No description provided for @coachingLoad.
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get coachingLoad;

  /// No description provided for @coachingNoData.
  ///
  /// In en, this message translates to:
  /// **'No coaching data yet — complete onboarding or chat with tutor to seed.'**
  String get coachingNoData;

  /// No description provided for @coachingPartial.
  ///
  /// In en, this message translates to:
  /// **'Some coaching surfaces are temporarily unavailable — showing available data.'**
  String get coachingPartial;

  /// No description provided for @coachingNoReadinessForGoal.
  ///
  /// In en, this message translates to:
  /// **'Readiness: no data for this goal yet.'**
  String get coachingNoReadinessForGoal;

  /// No description provided for @coachingAskTutor.
  ///
  /// In en, this message translates to:
  /// **'Ask tutor'**
  String get coachingAskTutor;

  /// No description provided for @coachingOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Onboarding'**
  String get coachingOnboarding;

  /// No description provided for @coachingReadinessExplained.
  ///
  /// In en, this message translates to:
  /// **'Readiness is worked out from your goals, tracks and tutor activity. Some sections stay hidden until you use them.'**
  String get coachingReadinessExplained;

  /// No description provided for @coachingReadiness.
  ///
  /// In en, this message translates to:
  /// **'Readiness'**
  String get coachingReadiness;

  /// No description provided for @coachingFocusNext.
  ///
  /// In en, this message translates to:
  /// **'Focus next:'**
  String get coachingFocusNext;

  /// No description provided for @coachingNoReadiness.
  ///
  /// In en, this message translates to:
  /// **'No readiness yet — attempt a few quizzes under this goal.'**
  String get coachingNoReadiness;

  /// No description provided for @coachingGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal {goal}'**
  String coachingGoalLabel(Object goal);

  /// No description provided for @coachingMore.
  ///
  /// In en, this message translates to:
  /// **'+ {count} more'**
  String coachingMore(Object count);

  /// No description provided for @coachingNoTasksToday.
  ///
  /// In en, this message translates to:
  /// **'No tasks today'**
  String get coachingNoTasksToday;

  /// No description provided for @coachingConfidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence {confidence}%'**
  String coachingConfidence(Object confidence);

  /// No description provided for @coachingLearningTracks.
  ///
  /// In en, this message translates to:
  /// **'Learning tracks'**
  String get coachingLearningTracks;

  /// No description provided for @coachingThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get coachingThisWeek;

  /// No description provided for @coachingWeekTasks.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} tasks • avg {average}'**
  String coachingWeekTasks(Object done, Object total, Object average);

  /// No description provided for @coachingNoRevisions.
  ///
  /// In en, this message translates to:
  /// **'No revisions due'**
  String get coachingNoRevisions;

  /// No description provided for @coachingRevisionsDue.
  ///
  /// In en, this message translates to:
  /// **'{count} revisions due'**
  String coachingRevisionsDue(Object count);

  /// No description provided for @socialInviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite friends'**
  String get socialInviteFriends;

  /// No description provided for @socialReferralUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Referral information is unavailable right now.'**
  String get socialReferralUnavailable;

  /// No description provided for @socialEarnCoins.
  ///
  /// In en, this message translates to:
  /// **'Earn {coins} coins'**
  String socialEarnCoins(Object coins);

  /// No description provided for @socialNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get socialNo;

  /// No description provided for @socialYourInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Your invite code'**
  String get socialYourInviteCode;

  /// No description provided for @socialShareInviteLink.
  ///
  /// In en, this message translates to:
  /// **'Share invite link'**
  String get socialShareInviteLink;

  /// No description provided for @socialCopyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get socialCopyCode;

  /// No description provided for @socialRewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get socialRewards;

  /// No description provided for @socialRewardPerSignup.
  ///
  /// In en, this message translates to:
  /// **'You earn per friend who signs up'**
  String get socialRewardPerSignup;

  /// No description provided for @socialTheyEarn.
  ///
  /// In en, this message translates to:
  /// **'They earn when they sign up'**
  String get socialTheyEarn;

  /// No description provided for @socialBonusFirstQuiz.
  ///
  /// In en, this message translates to:
  /// **'Bonus when they finish their first quiz'**
  String get socialBonusFirstQuiz;

  /// No description provided for @socialYourReferrals.
  ///
  /// In en, this message translates to:
  /// **'Your referrals'**
  String get socialYourReferrals;

  /// No description provided for @socialInvited.
  ///
  /// In en, this message translates to:
  /// **'invited'**
  String get socialInvited;

  /// No description provided for @socialRewarded.
  ///
  /// In en, this message translates to:
  /// **'rewarded'**
  String get socialRewarded;

  /// No description provided for @socialCoinsEarned.
  ///
  /// In en, this message translates to:
  /// **'coins earned'**
  String get socialCoinsEarned;

  /// No description provided for @socialNoReferralsYet.
  ///
  /// In en, this message translates to:
  /// **'No one has used your code yet.'**
  String get socialNoReferralsYet;

  /// No description provided for @socialRewardPaid.
  ///
  /// In en, this message translates to:
  /// **'Reward paid: {coins} coins'**
  String socialRewardPaid(Object coins);

  /// No description provided for @socialStatus.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String socialStatus(Object status);

  /// No description provided for @socialGotCode.
  ///
  /// In en, this message translates to:
  /// **'Got a code from a friend?'**
  String get socialGotCode;

  /// No description provided for @socialReferralCode.
  ///
  /// In en, this message translates to:
  /// **'Referral code'**
  String get socialReferralCode;

  /// No description provided for @socialApplyCode.
  ///
  /// In en, this message translates to:
  /// **'Apply code'**
  String get socialApplyCode;

  /// No description provided for @socialShareSheetFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the share sheet'**
  String get socialShareSheetFailed;

  /// No description provided for @socialCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get socialCodeCopied;

  /// No description provided for @socialSharedChallenge.
  ///
  /// In en, this message translates to:
  /// **'Shared challenge'**
  String get socialSharedChallenge;

  /// No description provided for @socialSomeoneShared.
  ///
  /// In en, this message translates to:
  /// **'Someone shared a challenge with you'**
  String get socialSomeoneShared;

  /// No description provided for @socialSharedBy.
  ///
  /// In en, this message translates to:
  /// **'Shared by {name}'**
  String socialSharedBy(Object name);

  /// No description provided for @socialLinkExpired.
  ///
  /// In en, this message translates to:
  /// **'This link has expired.'**
  String get socialLinkExpired;

  /// No description provided for @socialNoPlayableChallenge.
  ///
  /// In en, this message translates to:
  /// **'No playable challenge here'**
  String get socialNoPlayableChallenge;

  /// No description provided for @socialNotPlayable.
  ///
  /// In en, this message translates to:
  /// **'This link does not offer a playable challenge. You can still browse the public catalogue.'**
  String get socialNotPlayable;

  /// No description provided for @socialPlayChallenge.
  ///
  /// In en, this message translates to:
  /// **'Play the challenge'**
  String get socialPlayChallenge;

  /// No description provided for @socialGuestNeverAwards.
  ///
  /// In en, this message translates to:
  /// **'A guest challenge never awards coins, XP or streak. Create a free account to keep your progress.'**
  String get socialGuestNeverAwards;

  /// No description provided for @socialChallengeNoQuestions.
  ///
  /// In en, this message translates to:
  /// **'This challenge has no questions'**
  String get socialChallengeNoQuestions;

  /// No description provided for @socialChallengeEmpty.
  ///
  /// In en, this message translates to:
  /// **'The server opened the attempt without sending any questions, so there is nothing to play.'**
  String get socialChallengeEmpty;

  /// No description provided for @socialQuestionOf.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String socialQuestionOf(Object current, Object total);

  /// No description provided for @socialCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct.'**
  String get socialCorrect;

  /// No description provided for @socialNotThisTime.
  ///
  /// In en, this message translates to:
  /// **'Not this time — the server has marked it.'**
  String get socialNotThisTime;

  /// No description provided for @socialSubmitAnswer.
  ///
  /// In en, this message translates to:
  /// **'Submit answer'**
  String get socialSubmitAnswer;

  /// No description provided for @socialFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get socialFinish;

  /// No description provided for @socialNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get socialNext;

  /// No description provided for @socialChallengeComplete.
  ///
  /// In en, this message translates to:
  /// **'Challenge complete'**
  String get socialChallengeComplete;

  /// No description provided for @socialYouScored.
  ///
  /// In en, this message translates to:
  /// **'You scored {score}'**
  String socialYouScored(Object score);

  /// No description provided for @socialChallengeSummary.
  ///
  /// In en, this message translates to:
  /// **'{correct} correct • {wrong} wrong • {skipped} skipped • {questions} questions'**
  String socialChallengeSummary(
    Object correct,
    Object wrong,
    Object skipped,
    Object questions,
  );

  /// No description provided for @socialGuestChallengeNote.
  ///
  /// In en, this message translates to:
  /// **'A guest challenge never awards coins, XP or streak.'**
  String get socialGuestChallengeNote;

  /// No description provided for @socialNiceOne.
  ///
  /// In en, this message translates to:
  /// **'Nice one — that was {name}\'s challenge. A guest challenge never awards coins, XP or streak.'**
  String socialNiceOne(Object name);

  /// No description provided for @socialCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create a free account'**
  String get socialCreateAccount;

  /// No description provided for @socialBrowseSamples.
  ///
  /// In en, this message translates to:
  /// **'Browse sample questions'**
  String get socialBrowseSamples;

  /// No description provided for @contestNotFound.
  ///
  /// In en, this message translates to:
  /// **'Contest not found'**
  String get contestNotFound;

  /// No description provided for @contestAttemptStarted.
  ///
  /// In en, this message translates to:
  /// **'Attempt #{number} started. Expires: {expires}'**
  String contestAttemptStarted(Object number, Object expires);

  /// No description provided for @contestNoLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'No leaderboard entries yet — be the first!'**
  String get contestNoLeaderboard;

  /// No description provided for @contestGeneratedMeta.
  ///
  /// In en, this message translates to:
  /// **'Generated: {generated} • Refresh budget: {budget} • {mode}'**
  String contestGeneratedMeta(Object generated, Object budget, Object mode);

  /// No description provided for @contestRecap.
  ///
  /// In en, this message translates to:
  /// **'Recap'**
  String get contestRecap;

  /// No description provided for @contestWinners.
  ///
  /// In en, this message translates to:
  /// **'Winners'**
  String get contestWinners;

  /// No description provided for @contestRawStats.
  ///
  /// In en, this message translates to:
  /// **'Raw stats: {count} keys'**
  String contestRawStats(Object count);

  /// No description provided for @contestRecapPending.
  ///
  /// In en, this message translates to:
  /// **'Recap available after contest ends.'**
  String get contestRecapPending;

  /// No description provided for @contestJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined contest!'**
  String get contestJoined;

  /// No description provided for @contestJoinFailed.
  ///
  /// In en, this message translates to:
  /// **'Join failed'**
  String get contestJoinFailed;

  /// No description provided for @contestLeft.
  ///
  /// In en, this message translates to:
  /// **'Left contest'**
  String get contestLeft;

  /// No description provided for @contestLeaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Leave failed'**
  String get contestLeaveFailed;

  /// No description provided for @contestRegisteredBadge.
  ///
  /// In en, this message translates to:
  /// **'REGISTERED'**
  String get contestRegisteredBadge;

  /// No description provided for @contestMax.
  ///
  /// In en, this message translates to:
  /// **'Max {count}'**
  String contestMax(Object count);

  /// No description provided for @contestStarts.
  ///
  /// In en, this message translates to:
  /// **'Starts {date}'**
  String contestStarts(Object date);

  /// No description provided for @contestJoinFree.
  ///
  /// In en, this message translates to:
  /// **'Join (Free)'**
  String get contestJoinFree;

  /// No description provided for @contestJoinCoins.
  ///
  /// In en, this message translates to:
  /// **'Join ({coins} coins)'**
  String contestJoinCoins(Object coins);

  /// No description provided for @contestEnter.
  ///
  /// In en, this message translates to:
  /// **'Enter Contest'**
  String get contestEnter;

  /// No description provided for @leaderboardGlobal.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get leaderboardGlobal;

  /// No description provided for @leaderboardFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get leaderboardFriends;

  /// No description provided for @leaderboardLeague.
  ///
  /// In en, this message translates to:
  /// **'League'**
  String get leaderboardLeague;

  /// No description provided for @leaderboardDonors.
  ///
  /// In en, this message translates to:
  /// **'Donors'**
  String get leaderboardDonors;

  /// No description provided for @leaderboardNoRank.
  ///
  /// In en, this message translates to:
  /// **'No rank yet — complete a quiz to enter the leaderboard.'**
  String get leaderboardNoRank;

  /// No description provided for @leaderboardMyRank.
  ///
  /// In en, this message translates to:
  /// **'MY RANK'**
  String get leaderboardMyRank;

  /// No description provided for @leaderboardRankIn.
  ///
  /// In en, this message translates to:
  /// **'#{rank} in {scope}'**
  String leaderboardRankIn(Object rank, Object scope);

  /// No description provided for @leaderboardUnrankedIn.
  ///
  /// In en, this message translates to:
  /// **'Unranked in {scope}'**
  String leaderboardUnrankedIn(Object scope);

  /// No description provided for @leaderboardScore.
  ///
  /// In en, this message translates to:
  /// **'Score: {score}'**
  String leaderboardScore(Object score);

  /// No description provided for @leaderboardNoEntries.
  ///
  /// In en, this message translates to:
  /// **'No entries yet'**
  String get leaderboardNoEntries;

  /// No description provided for @leaderboardBeFirst.
  ///
  /// In en, this message translates to:
  /// **'Be the first to claim the top spot!'**
  String get leaderboardBeFirst;

  /// No description provided for @leaderboardFriendsHint.
  ///
  /// In en, this message translates to:
  /// **'Add friends to compete — server segments friends automatically.'**
  String get leaderboardFriendsHint;

  /// No description provided for @leaderboardLeagueHint.
  ///
  /// In en, this message translates to:
  /// **'League is seasonal — join via events/contests to qualify.'**
  String get leaderboardLeagueHint;

  /// No description provided for @leaderboardNoEntriesShort.
  ///
  /// In en, this message translates to:
  /// **'No entries'**
  String get leaderboardNoEntriesShort;

  /// No description provided for @leaderboardCompeteToAppear.
  ///
  /// In en, this message translates to:
  /// **'Compete to appear here.'**
  String get leaderboardCompeteToAppear;

  /// No description provided for @leaderboardNoDonors.
  ///
  /// In en, this message translates to:
  /// **'No donors yet'**
  String get leaderboardNoDonors;

  /// No description provided for @leaderboardSupportToAppear.
  ///
  /// In en, this message translates to:
  /// **'Support the platform to appear here.'**
  String get leaderboardSupportToAppear;

  /// No description provided for @leaderboardScoreAttempts.
  ///
  /// In en, this message translates to:
  /// **'Score {score} • {attempts} attempts'**
  String leaderboardScoreAttempts(Object score, Object attempts);

  /// No description provided for @learningGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal #{number}'**
  String learningGoalLabel(Object number);

  /// No description provided for @learningToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get learningToday;

  /// No description provided for @learningGoalId.
  ///
  /// In en, this message translates to:
  /// **'Goal ID'**
  String get learningGoalId;

  /// No description provided for @learningTrackId.
  ///
  /// In en, this message translates to:
  /// **'Track ID'**
  String get learningTrackId;

  /// No description provided for @learningTargetDate.
  ///
  /// In en, this message translates to:
  /// **'Target date'**
  String get learningTargetDate;

  /// No description provided for @learningDailyMinutes.
  ///
  /// In en, this message translates to:
  /// **'Daily minutes'**
  String get learningDailyMinutes;

  /// No description provided for @learningIntensity.
  ///
  /// In en, this message translates to:
  /// **'Intensity'**
  String get learningIntensity;

  /// No description provided for @learningPlacement.
  ///
  /// In en, this message translates to:
  /// **'Placement'**
  String get learningPlacement;

  /// No description provided for @learningMastery.
  ///
  /// In en, this message translates to:
  /// **'{percent}% mastery across {topics} topics (MasteryService::computeReadiness)'**
  String learningMastery(Object percent, Object topics);

  /// No description provided for @learningReadinessValue.
  ///
  /// In en, this message translates to:
  /// **'Readiness: {value}'**
  String learningReadinessValue(Object value);

  /// No description provided for @learningDeleteGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete goal?'**
  String get learningDeleteGoalTitle;

  /// No description provided for @learningDeleteGoalBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the goal. Daily plans remain but no new plans will be built.'**
  String get learningDeleteGoalBody;

  /// No description provided for @learningGoalDeleted.
  ///
  /// In en, this message translates to:
  /// **'Goal deleted'**
  String get learningGoalDeleted;

  /// No description provided for @learningDeleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting…'**
  String get learningDeleting;

  /// No description provided for @learningDeleteGoal.
  ///
  /// In en, this message translates to:
  /// **'Delete goal'**
  String get learningDeleteGoal;

  /// No description provided for @learningOpenTodayPlan.
  ///
  /// In en, this message translates to:
  /// **'Open Today plan'**
  String get learningOpenTodayPlan;

  /// No description provided for @learningBackToTracks.
  ///
  /// In en, this message translates to:
  /// **'Back to tracks'**
  String get learningBackToTracks;

  /// No description provided for @learningTodaysPlan.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Plan'**
  String get learningTodaysPlan;

  /// No description provided for @learningNoActiveGoal.
  ///
  /// In en, this message translates to:
  /// **'No active goal'**
  String get learningNoActiveGoal;

  /// No description provided for @learningNoActiveGoalBody.
  ///
  /// In en, this message translates to:
  /// **'Create a learning goal from Tracks to get a Today plan. If you already have one, it will show up here.'**
  String get learningNoActiveGoalBody;

  /// No description provided for @learningBrowseTracks.
  ///
  /// In en, this message translates to:
  /// **'Browse tracks'**
  String get learningBrowseTracks;

  /// No description provided for @learningPlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Plan #{number}'**
  String learningPlanLabel(Object number);

  /// No description provided for @learningPlanGoal.
  ///
  /// In en, this message translates to:
  /// **'{meta} • Goal #{number}'**
  String learningPlanGoal(Object meta, Object number);

  /// No description provided for @learningCompletedCount.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} completed'**
  String learningCompletedCount(Object done, Object total);

  /// No description provided for @learningMinBudget.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min budget'**
  String learningMinBudget(Object minutes);

  /// No description provided for @learningNoTasksBody.
  ///
  /// In en, this message translates to:
  /// **'Check back tomorrow — daily autopilot builds Review-first + new topics.'**
  String get learningNoTasksBody;

  /// No description provided for @learningMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String learningMinutes(Object minutes);

  /// No description provided for @learningItemCompleted.
  ///
  /// In en, this message translates to:
  /// **'Item completed'**
  String get learningItemCompleted;

  /// No description provided for @learningReviewsDue.
  ///
  /// In en, this message translates to:
  /// **'Reviews due'**
  String get learningReviewsDue;

  /// No description provided for @learningTitle.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get learningTitle;

  /// No description provided for @learningReviewsCountFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your reviews due count'**
  String get learningReviewsCountFailed;

  /// No description provided for @learningTracks.
  ///
  /// In en, this message translates to:
  /// **'Tracks'**
  String get learningTracks;

  /// No description provided for @learningNoTracks.
  ///
  /// In en, this message translates to:
  /// **'No tracks yet — they are published by our team as they finish'**
  String get learningNoTracks;

  /// No description provided for @learningAskAiTutor.
  ///
  /// In en, this message translates to:
  /// **'Ask AI Tutor'**
  String get learningAskAiTutor;

  /// No description provided for @learningStreamingNote.
  ///
  /// In en, this message translates to:
  /// **'Answers come back a little at a time rather than all at once, so you can start reading straight away.'**
  String get learningStreamingNote;

  /// No description provided for @learningNoTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks — check back tomorrow'**
  String get learningNoTasks;

  /// No description provided for @learningReviewsDueSrs.
  ///
  /// In en, this message translates to:
  /// **'{count} reviews due (SRS)'**
  String learningReviewsDueSrs(Object count);

  /// No description provided for @learningReviewAction.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get learningReviewAction;

  /// No description provided for @learningGoalCreatedForTrack.
  ///
  /// In en, this message translates to:
  /// **'Goal created for track #{number}'**
  String learningGoalCreatedForTrack(Object number);

  /// No description provided for @learningTracksTitle.
  ///
  /// In en, this message translates to:
  /// **'Learning Tracks'**
  String get learningTracksTitle;

  /// No description provided for @learningTodayPlan.
  ///
  /// In en, this message translates to:
  /// **'Today plan'**
  String get learningTodayPlan;

  /// No description provided for @learningNodesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} nodes'**
  String learningNodesCount(Object count);

  /// No description provided for @learningGoalsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} goals'**
  String learningGoalsCount(Object count);

  /// No description provided for @learningCreating.
  ///
  /// In en, this message translates to:
  /// **'Creating…'**
  String get learningCreating;

  /// No description provided for @learningCreateGoal.
  ///
  /// In en, this message translates to:
  /// **'Create goal'**
  String get learningCreateGoal;

  /// No description provided for @learningReviewsDueTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviews Due'**
  String get learningReviewsDueTitle;

  /// No description provided for @learningAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You are all caught up! FSRS will schedule the next reviews after you master new atoms.'**
  String get learningAllCaughtUp;

  /// No description provided for @learningReviewMeta.
  ///
  /// In en, this message translates to:
  /// **'Review #{number} • atom {atom} • {state}'**
  String learningReviewMeta(Object number, Object atom, Object state);

  /// No description provided for @learningInterval.
  ///
  /// In en, this message translates to:
  /// **'I{index}'**
  String learningInterval(Object index);

  /// No description provided for @learningDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String learningDueDate(Object date);

  /// No description provided for @learningLapses.
  ///
  /// In en, this message translates to:
  /// **'{count} lapses'**
  String learningLapses(Object count);

  /// No description provided for @learningGradeAgain.
  ///
  /// In en, this message translates to:
  /// **'Again'**
  String get learningGradeAgain;

  /// No description provided for @learningGradeHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get learningGradeHard;

  /// No description provided for @learningGradeGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get learningGradeGood;

  /// No description provided for @learningGradeEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get learningGradeEasy;

  /// No description provided for @learningGradingNote.
  ///
  /// In en, this message translates to:
  /// **'Grading is recorded safely, and your next review date is worked out for you. Double-tapping cannot lose your progress.'**
  String get learningGradingNote;

  /// No description provided for @syllabusTitle.
  ///
  /// In en, this message translates to:
  /// **'Syllabus'**
  String get syllabusTitle;

  /// No description provided for @syllabusNoNodes.
  ///
  /// In en, this message translates to:
  /// **'This syllabus has no published nodes yet.'**
  String get syllabusNoNodes;

  /// No description provided for @syllabusExaminable.
  ///
  /// In en, this message translates to:
  /// **'examinable'**
  String get syllabusExaminable;

  /// No description provided for @syllabusQuestions.
  ///
  /// In en, this message translates to:
  /// **'questions'**
  String get syllabusQuestions;

  /// No description provided for @syllabusPaperBlueprint.
  ///
  /// In en, this message translates to:
  /// **'Paper blueprint'**
  String get syllabusPaperBlueprint;

  /// No description provided for @syllabusPapersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} papers'**
  String syllabusPapersCount(Object count);

  /// No description provided for @syllabusMarksQuestions.
  ///
  /// In en, this message translates to:
  /// **'{marks} marks · {questions} questions'**
  String syllabusMarksQuestions(Object marks, Object questions);

  /// No description provided for @syllabusNegativeMarking.
  ///
  /// In en, this message translates to:
  /// **'Negative marking: {mode}'**
  String syllabusNegativeMarking(Object mode);

  /// No description provided for @syllabusMarks.
  ///
  /// In en, this message translates to:
  /// **'{marks} marks'**
  String syllabusMarks(Object marks);

  /// No description provided for @syllabusBlueprintMismatch.
  ///
  /// In en, this message translates to:
  /// **'The section marks do not add up to the paper total. Treat this blueprint as unverified.'**
  String get syllabusBlueprintMismatch;

  /// No description provided for @syllabusCoversTopics.
  ///
  /// In en, this message translates to:
  /// **'Covers {count} syllabus topics'**
  String syllabusCoversTopics(Object count);

  /// No description provided for @syllabusSearchTopics.
  ///
  /// In en, this message translates to:
  /// **'Search topics'**
  String get syllabusSearchTopics;

  /// No description provided for @syllabusNoPublished.
  ///
  /// In en, this message translates to:
  /// **'No syllabus has been published yet.'**
  String get syllabusNoPublished;

  /// No description provided for @syllabusTopicsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} topics'**
  String syllabusTopicsCount(Object count);

  /// No description provided for @syllabusNotCurrent.
  ///
  /// In en, this message translates to:
  /// **'Not current'**
  String get syllabusNotCurrent;

  /// No description provided for @booksTitle.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get booksTitle;

  /// No description provided for @booksSearch.
  ///
  /// In en, this message translates to:
  /// **'Search books'**
  String get booksSearch;

  /// No description provided for @booksNonePublished.
  ///
  /// In en, this message translates to:
  /// **'No books have been published yet.'**
  String get booksNonePublished;

  /// No description provided for @booksNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No books match \"{query}\".'**
  String booksNoMatch(Object query);

  /// No description provided for @booksProgress.
  ///
  /// In en, this message translates to:
  /// **'{percent}% · page {page}'**
  String booksProgress(Object percent, Object page);

  /// No description provided for @booksChapters.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get booksChapters;

  /// No description provided for @booksNoChapters.
  ///
  /// In en, this message translates to:
  /// **'No chapters published yet.'**
  String get booksNoChapters;

  /// No description provided for @booksChapterTest.
  ///
  /// In en, this message translates to:
  /// **'Chapter test'**
  String get booksChapterTest;

  /// No description provided for @booksReadChapter.
  ///
  /// In en, this message translates to:
  /// **'Read the chapter'**
  String get booksReadChapter;

  /// No description provided for @booksTakeTest.
  ///
  /// In en, this message translates to:
  /// **'Take test ({count})'**
  String booksTakeTest(Object count);

  /// No description provided for @booksNoTopics.
  ///
  /// In en, this message translates to:
  /// **'This chapter has no topics to open yet.'**
  String get booksNoTopics;

  /// No description provided for @downloadsClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear offline content?'**
  String get downloadsClearTitle;

  /// No description provided for @downloadsClearBody.
  ///
  /// In en, this message translates to:
  /// **'This removes all cached questions. You can re-download anytime while online.'**
  String get downloadsClearBody;

  /// No description provided for @downloadsClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get downloadsClear;

  /// No description provided for @downloadsStorageUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Could not read offline storage'**
  String get downloadsStorageUnreadable;

  /// No description provided for @downloadsNothingReported.
  ///
  /// In en, this message translates to:
  /// **'Nothing is reported rather than showing a false zero.'**
  String get downloadsNothingReported;

  /// No description provided for @downloadsCachedQuestions.
  ///
  /// In en, this message translates to:
  /// **'{count} questions cached'**
  String downloadsCachedQuestions(Object count);

  /// No description provided for @downloadsCacheSize.
  ///
  /// In en, this message translates to:
  /// **'{subjects} subjects · ~{size} KB'**
  String downloadsCacheSize(Object subjects, Object size);

  /// No description provided for @downloadsLastCached.
  ///
  /// In en, this message translates to:
  /// **'Last cached'**
  String get downloadsLastCached;

  /// No description provided for @downloadsAutoDownload.
  ///
  /// In en, this message translates to:
  /// **'Auto-download'**
  String get downloadsAutoDownload;

  /// No description provided for @downloadsPrefetchNow.
  ///
  /// In en, this message translates to:
  /// **'Prefetch daily pack now'**
  String get downloadsPrefetchNow;

  /// No description provided for @downloadsClearAction.
  ///
  /// In en, this message translates to:
  /// **'Clear offline content'**
  String get downloadsClearAction;

  /// No description provided for @rewardsSpinWheel.
  ///
  /// In en, this message translates to:
  /// **'Spin the wheel'**
  String get rewardsSpinWheel;

  /// No description provided for @rewardsCheckInUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Check-in unavailable'**
  String get rewardsCheckInUnavailable;

  /// No description provided for @rewardsDailyCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Daily check-in'**
  String get rewardsDailyCheckIn;

  /// No description provided for @rewardsDayStreak.
  ///
  /// In en, this message translates to:
  /// **'day {count}'**
  String rewardsDayStreak(Object count);

  /// No description provided for @rewardsToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get rewardsToday;

  /// No description provided for @rewardsTomorrow.
  ///
  /// In en, this message translates to:
  /// **'tomorrow'**
  String get rewardsTomorrow;

  /// No description provided for @rewardsClaimedToday.
  ///
  /// In en, this message translates to:
  /// **'Claimed today'**
  String get rewardsClaimedToday;

  /// No description provided for @rewardsCheckInFor.
  ///
  /// In en, this message translates to:
  /// **'Check in for {coins} coins'**
  String rewardsCheckInFor(Object coins);

  /// No description provided for @rewardsSpinUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Spin wheel unavailable'**
  String get rewardsSpinUnavailable;

  /// No description provided for @rewardsSpin.
  ///
  /// In en, this message translates to:
  /// **'Spin'**
  String get rewardsSpin;

  /// No description provided for @rewardsComeBackLater.
  ///
  /// In en, this message translates to:
  /// **'Come back later'**
  String get rewardsComeBackLater;

  /// No description provided for @rewardsNextSpin.
  ///
  /// In en, this message translates to:
  /// **'Next spin {date}'**
  String rewardsNextSpin(Object date);

  /// No description provided for @gameLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'Level {number}'**
  String gameLevelLabel(Object number);

  /// No description provided for @gameBossLevel.
  ///
  /// In en, this message translates to:
  /// **'Boss level'**
  String get gameBossLevel;

  /// No description provided for @gameChapterLevel.
  ///
  /// In en, this message translates to:
  /// **'Chapter level'**
  String get gameChapterLevel;

  /// No description provided for @gameSecondsPerQuestion.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s per question'**
  String gameSecondsPerQuestion(Object seconds);

  /// No description provided for @gameBestScore.
  ///
  /// In en, this message translates to:
  /// **'Best score'**
  String get gameBestScore;

  /// No description provided for @gameBestAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Best accuracy'**
  String get gameBestAccuracy;

  /// No description provided for @gameBestTime.
  ///
  /// In en, this message translates to:
  /// **'Best time'**
  String get gameBestTime;

  /// No description provided for @gameStartLevel.
  ///
  /// In en, this message translates to:
  /// **'Start level'**
  String get gameStartLevel;

  /// No description provided for @gameNotPlayable.
  ///
  /// In en, this message translates to:
  /// **'Not playable yet'**
  String get gameNotPlayable;

  /// No description provided for @gameWorldNoCourse.
  ///
  /// In en, this message translates to:
  /// **'This world has no quiz course linked to it yet, so there is nothing to play. Ask an admin to set the world\'s course.'**
  String get gameWorldNoCourse;

  /// No description provided for @gameWorldsTitle.
  ///
  /// In en, this message translates to:
  /// **'Worlds'**
  String get gameWorldsTitle;

  /// No description provided for @gameWorldsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load worlds'**
  String get gameWorldsLoadFailed;

  /// No description provided for @gameNoWorlds.
  ///
  /// In en, this message translates to:
  /// **'No worlds yet'**
  String get gameNoWorlds;

  /// No description provided for @gameNoWorldsBody.
  ///
  /// In en, this message translates to:
  /// **'The server has not published any game worlds.'**
  String get gameNoWorldsBody;

  /// No description provided for @gameNeedsSubscription.
  ///
  /// In en, this message translates to:
  /// **'Requires a subscription plan.'**
  String get gameNeedsSubscription;

  /// No description provided for @gameWorldNotFound.
  ///
  /// In en, this message translates to:
  /// **'World not found'**
  String get gameWorldNotFound;

  /// No description provided for @gameStarsProgress.
  ///
  /// In en, this message translates to:
  /// **'{earned} / {total} stars'**
  String gameStarsProgress(Object earned, Object total);

  /// No description provided for @gameWorldMapFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load world map'**
  String get gameWorldMapFailed;

  /// No description provided for @gameMissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Missions'**
  String get gameMissionsTitle;

  /// No description provided for @gameMissionsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load missions'**
  String get gameMissionsFailed;

  /// No description provided for @gameNoMissions.
  ///
  /// In en, this message translates to:
  /// **'No missions yet'**
  String get gameNoMissions;

  /// No description provided for @gameNoMissionsBody.
  ///
  /// In en, this message translates to:
  /// **'The server has not published any missions for you.'**
  String get gameNoMissionsBody;

  /// No description provided for @gameClaimAll.
  ///
  /// In en, this message translates to:
  /// **'Claim all'**
  String get gameClaimAll;

  /// No description provided for @gameClaimCoins.
  ///
  /// In en, this message translates to:
  /// **'Claim {coins} coins'**
  String gameClaimCoins(Object coins);

  /// No description provided for @gameClaimed.
  ///
  /// In en, this message translates to:
  /// **'Claimed'**
  String get gameClaimed;

  /// No description provided for @numericalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Numerical'**
  String get numericalsTitle;

  /// No description provided for @numericalsNew.
  ///
  /// In en, this message translates to:
  /// **'New numbers'**
  String get numericalsNew;

  /// No description provided for @numericalsCheck.
  ///
  /// In en, this message translates to:
  /// **'Check answer'**
  String get numericalsCheck;

  /// No description provided for @numericalsShowSolution.
  ///
  /// In en, this message translates to:
  /// **'Show worked solution'**
  String get numericalsShowSolution;

  /// No description provided for @numericalsCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct{reason}'**
  String numericalsCorrect(Object reason);

  /// No description provided for @numericalsNotCorrect.
  ///
  /// In en, this message translates to:
  /// **'Not correct. Try again, or open the worked solution.'**
  String get numericalsNotCorrect;

  /// No description provided for @numericalsFlagged.
  ///
  /// In en, this message translates to:
  /// **'The server has flagged this problem for review.'**
  String get numericalsFlagged;

  /// No description provided for @numericalsWorkedSolution.
  ///
  /// In en, this message translates to:
  /// **'Worked solution'**
  String get numericalsWorkedSolution;

  /// No description provided for @numericalsComputedBy.
  ///
  /// In en, this message translates to:
  /// **'Computed by: {source}'**
  String numericalsComputedBy(Object source);

  /// No description provided for @numericalsFlaggedWarning.
  ///
  /// In en, this message translates to:
  /// **'Flagged by the server for review — treat this answer with care.'**
  String get numericalsFlaggedWarning;

  /// No description provided for @numericalsOpenInCalculator.
  ///
  /// In en, this message translates to:
  /// **'Open in calculator'**
  String get numericalsOpenInCalculator;

  /// No description provided for @storeEquipped.
  ///
  /// In en, this message translates to:
  /// **'Equipped!'**
  String get storeEquipped;

  /// No description provided for @storeEquipFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not equip that item.'**
  String get storeEquipFailed;

  /// No description provided for @storeWardrobeTitle.
  ///
  /// In en, this message translates to:
  /// **'Wardrobe'**
  String get storeWardrobeTitle;

  /// No description provided for @storeEquippedLabel.
  ///
  /// In en, this message translates to:
  /// **'Equipped'**
  String get storeEquippedLabel;

  /// No description provided for @storeNothingEquipped.
  ///
  /// In en, this message translates to:
  /// **'Nothing equipped'**
  String get storeNothingEquipped;

  /// No description provided for @storeNothingEquippedBody.
  ///
  /// In en, this message translates to:
  /// **'Buy assets in the Premium Store, then equip them here.'**
  String get storeNothingEquippedBody;

  /// No description provided for @storeAvailableToEquip.
  ///
  /// In en, this message translates to:
  /// **'Available to equip'**
  String get storeAvailableToEquip;

  /// No description provided for @storeEquipHint.
  ///
  /// In en, this message translates to:
  /// **'Tap Equip to try it on. If you tap twice you are never equipped twice.'**
  String get storeEquipHint;

  /// No description provided for @storeNoAssets.
  ///
  /// In en, this message translates to:
  /// **'No assets yet — visit Premium Store.'**
  String get storeNoAssets;

  /// No description provided for @storeClearSlot.
  ///
  /// In en, this message translates to:
  /// **'Clear {slot}'**
  String storeClearSlot(Object slot);

  /// No description provided for @storeTitle.
  ///
  /// In en, this message translates to:
  /// **'Premium Store'**
  String get storeTitle;

  /// No description provided for @storeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get storeAll;

  /// No description provided for @storeAssetsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} assets'**
  String storeAssetsCount(Object count);

  /// No description provided for @storeNoAssetsInCategory.
  ///
  /// In en, this message translates to:
  /// **'No assets in this category.'**
  String get storeNoAssetsInCategory;

  /// No description provided for @storeTrading.
  ///
  /// In en, this message translates to:
  /// **'Trading'**
  String get storeTrading;

  /// No description provided for @storeTradingExplain.
  ///
  /// In en, this message translates to:
  /// **'Buy resources and bundles with coins, or sell what you no longer need.'**
  String get storeTradingExplain;

  /// No description provided for @storeCoinShop.
  ///
  /// In en, this message translates to:
  /// **'Coin shop'**
  String get storeCoinShop;

  /// No description provided for @storeSellItems.
  ///
  /// In en, this message translates to:
  /// **'Sell items'**
  String get storeSellItems;

  /// No description provided for @storeOwnedBadge.
  ///
  /// In en, this message translates to:
  /// **'OWNED'**
  String get storeOwnedBadge;

  /// No description provided for @storeOwned.
  ///
  /// In en, this message translates to:
  /// **'Owned'**
  String get storeOwned;

  /// No description provided for @storeEmptyEquip.
  ///
  /// In en, this message translates to:
  /// **'Empty - equip from store'**
  String get storeEmptyEquip;

  /// No description provided for @eiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Exam Intelligence'**
  String get eiceTitle;

  /// No description provided for @eiceExplain.
  ///
  /// In en, this message translates to:
  /// **'Everything here is worked out on our servers from your real answer history, so nothing is shown unless it is true.'**
  String get eiceExplain;

  /// No description provided for @eiceCoach.
  ///
  /// In en, this message translates to:
  /// **'Coach — your plan'**
  String get eiceCoach;

  /// No description provided for @eiceSprint.
  ///
  /// In en, this message translates to:
  /// **'Sprint — 7-day recall queue'**
  String get eiceSprint;

  /// No description provided for @eiceWeeklyReport.
  ///
  /// In en, this message translates to:
  /// **'Weekly report'**
  String get eiceWeeklyReport;

  /// No description provided for @eiceTriage.
  ///
  /// In en, this message translates to:
  /// **'Triage — cover or skip'**
  String get eiceTriage;

  /// No description provided for @battleArena.
  ///
  /// In en, this message translates to:
  /// **'Battle Arena'**
  String get battleArena;

  /// No description provided for @battleNoActiveMatch.
  ///
  /// In en, this message translates to:
  /// **'No active match'**
  String get battleNoActiveMatch;

  /// No description provided for @battleFindMatch.
  ///
  /// In en, this message translates to:
  /// **'Find a Match'**
  String get battleFindMatch;

  /// No description provided for @battleNoQuestions.
  ///
  /// In en, this message translates to:
  /// **'This match has no questions'**
  String get battleNoQuestions;

  /// No description provided for @battleQuestionCounter.
  ///
  /// In en, this message translates to:
  /// **'Battle · Q{current}/{total}'**
  String battleQuestionCounter(Object current, Object total);

  /// No description provided for @battleOpponentAnswered.
  ///
  /// In en, this message translates to:
  /// **'Opponent answered!'**
  String get battleOpponentAnswered;

  /// No description provided for @battleResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Battle Result'**
  String get battleResultTitle;

  /// No description provided for @battleNoMatchToDisplay.
  ///
  /// In en, this message translates to:
  /// **'No match to display'**
  String get battleNoMatchToDisplay;

  /// No description provided for @battleVs.
  ///
  /// In en, this message translates to:
  /// **'VS'**
  String get battleVs;

  /// No description provided for @battleRematch.
  ///
  /// In en, this message translates to:
  /// **'Rematch'**
  String get battleRematch;

  /// No description provided for @battleYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get battleYou;

  /// No description provided for @liveEventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Live Events'**
  String get liveEventsTitle;

  /// No description provided for @liveEventsNone.
  ///
  /// In en, this message translates to:
  /// **'No live events'**
  String get liveEventsNone;

  /// No description provided for @liveEventsNoneBody.
  ///
  /// In en, this message translates to:
  /// **'Scheduled and live events will appear here.'**
  String get liveEventsNoneBody;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsNone.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get notificationsNone;

  /// No description provided for @notificationsNoneBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing new right now.'**
  String get notificationsNoneBody;

  /// No description provided for @notificationsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load notifications'**
  String get notificationsLoadFailed;

  /// No description provided for @notificationsMarkFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not mark that as read. Try again.'**
  String get notificationsMarkFailed;

  /// No description provided for @notificationsMarkAllFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not mark everything as read.'**
  String get notificationsMarkAllFailed;

  /// No description provided for @coursesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load courses. Check connection.'**
  String get coursesLoadFailed;

  /// No description provided for @coursesNone.
  ///
  /// In en, this message translates to:
  /// **'No courses available'**
  String get coursesNone;

  /// No description provided for @coursesNoneBody.
  ///
  /// In en, this message translates to:
  /// **'Civil engineering syllabi will appear here once published.'**
  String get coursesNoneBody;

  /// No description provided for @coursesTracksCount.
  ///
  /// In en, this message translates to:
  /// **'{count} syllabus tracks'**
  String coursesTracksCount(Object count);

  /// No description provided for @coursesBrowseQuestions.
  ///
  /// In en, this message translates to:
  /// **'Browse questions'**
  String get coursesBrowseQuestions;

  /// No description provided for @pscTitle.
  ///
  /// In en, this message translates to:
  /// **'PSC / Loksewa'**
  String get pscTitle;

  /// No description provided for @pscBlueprintsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the PSC blueprints.\n{reason}'**
  String pscBlueprintsFailed(Object reason);

  /// No description provided for @pscNoBlueprints.
  ///
  /// In en, this message translates to:
  /// **'No blueprints are published yet. Pull down to retry.'**
  String get pscNoBlueprints;

  /// No description provided for @pscBlueprintMeta.
  ///
  /// In en, this message translates to:
  /// **'id: {id} • {questions} Qs'**
  String pscBlueprintMeta(Object id, Object questions);

  /// No description provided for @pscStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Start exam failed (offline or 404)'**
  String get pscStartFailed;

  /// No description provided for @pscStarted.
  ///
  /// In en, this message translates to:
  /// **'Exam started: {id}'**
  String pscStarted(Object id);

  /// No description provided for @achievementsBadges.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get achievementsBadges;

  /// No description provided for @achievementsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load achievements: {reason}'**
  String achievementsFailed(Object reason);

  /// No description provided for @achievementsNone.
  ///
  /// In en, this message translates to:
  /// **'No achievements yet — start quizzing!'**
  String get achievementsNone;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search questions, calculators, courses…'**
  String get searchHint;

  /// No description provided for @searchTry.
  ///
  /// In en, this message translates to:
  /// **'Try: levelling, RCC, Bernoulli'**
  String get searchTry;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get searchNoResults;

  /// No description provided for @searchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search failed: {reason}'**
  String searchFailed(Object reason);

  /// No description provided for @xpLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'LVL {level}'**
  String xpLevelLabel(Object level);

  /// No description provided for @xpProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total} XP'**
  String xpProgress(Object current, Object total);

  /// No description provided for @xpTotal.
  ///
  /// In en, this message translates to:
  /// **'{amount} XP'**
  String xpTotal(Object amount);

  /// No description provided for @xpToNext.
  ///
  /// In en, this message translates to:
  /// **'{amount} to next'**
  String xpToNext(Object amount);

  /// No description provided for @xpDayStreak.
  ///
  /// In en, this message translates to:
  /// **'{count} day streak'**
  String xpDayStreak(Object count);

  /// No description provided for @lottieOverlay.
  ///
  /// In en, this message translates to:
  /// **'lottie-overlay'**
  String get lottieOverlay;

  /// No description provided for @lottieTapToDismiss.
  ///
  /// In en, this message translates to:
  /// **'Tap to dismiss'**
  String get lottieTapToDismiss;

  /// No description provided for @lifelineCost.
  ///
  /// In en, this message translates to:
  /// **'{name} lifeline, {coins} coins'**
  String lifelineCost(Object name, Object coins);

  /// No description provided for @lifelineUnavailable.
  ///
  /// In en, this message translates to:
  /// **'{name} lifeline unavailable: {reason}'**
  String lifelineUnavailable(Object name, Object reason);

  /// No description provided for @offlineCannotReach.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach our servers — progress syncs when the connection is back'**
  String get offlineCannotReach;

  /// No description provided for @offlineBackOnline.
  ///
  /// In en, this message translates to:
  /// **'Back online — syncing your queued activity'**
  String get offlineBackOnline;

  /// No description provided for @learningNoResponse.
  ///
  /// In en, this message translates to:
  /// **'No response (tutor offline).'**
  String get learningNoResponse;

  /// No description provided for @socialApplyFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not apply that code'**
  String get socialApplyFailed;

  /// No description provided for @responseCached.
  ///
  /// In en, this message translates to:
  /// **'OK (cached)'**
  String get responseCached;

  /// No description provided for @battleTimer.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s · {current}/{total}'**
  String battleTimer(Object seconds, Object current, Object total);

  /// No description provided for @battleShareUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Share unavailable'**
  String get battleShareUnavailable;

  /// No description provided for @bookPageLabel.
  ///
  /// In en, this message translates to:
  /// **'Page {number}'**
  String bookPageLabel(Object number);

  /// No description provided for @bookMyHighlights.
  ///
  /// In en, this message translates to:
  /// **'My highlights'**
  String get bookMyHighlights;

  /// No description provided for @bookNoExtractableText.
  ///
  /// In en, this message translates to:
  /// **'This page has no extractable text. It may be an image-only scan.'**
  String get bookNoExtractableText;

  /// No description provided for @bookPreviousPage.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get bookPreviousPage;

  /// No description provided for @bookNextPage.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get bookNextPage;

  /// No description provided for @bookYourHighlights.
  ///
  /// In en, this message translates to:
  /// **'Your highlights'**
  String get bookYourHighlights;

  /// No description provided for @bookNoHighlights.
  ///
  /// In en, this message translates to:
  /// **'You have not highlighted anything yet.'**
  String get bookNoHighlights;

  /// No description provided for @bookImageNotText.
  ///
  /// In en, this message translates to:
  /// **'Image or diagram (not available as text)'**
  String get bookImageNotText;

  /// No description provided for @bookValueNotText.
  ///
  /// In en, this message translates to:
  /// **'{value} (not available as text)'**
  String bookValueNotText(Object value);

  /// No description provided for @contestsNone.
  ///
  /// In en, this message translates to:
  /// **'No contests yet'**
  String get contestsNone;

  /// No description provided for @contestsNoneBody.
  ///
  /// In en, this message translates to:
  /// **'Active and upcoming contests will appear here.'**
  String get contestsNoneBody;

  /// No description provided for @eiceNoData.
  ///
  /// In en, this message translates to:
  /// **'No data available yet.'**
  String get eiceNoData;

  /// No description provided for @eiceNoDetails.
  ///
  /// In en, this message translates to:
  /// **'No details available yet.'**
  String get eiceNoDetails;

  /// No description provided for @eiceNothingHere.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet.'**
  String get eiceNothingHere;

  /// No description provided for @eiceAndMore.
  ///
  /// In en, this message translates to:
  /// **'and {count} more…'**
  String eiceAndMore(Object count);

  /// No description provided for @gameNoRewardData.
  ///
  /// In en, this message translates to:
  /// **'The server sent no reward data for this level yet.'**
  String get gameNoRewardData;

  /// No description provided for @gameMissionsReady.
  ///
  /// In en, this message translates to:
  /// **'{count} missions ready to claim'**
  String gameMissionsReady(Object count);

  /// No description provided for @gameRewardsWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count} rewards waiting'**
  String gameRewardsWaiting(Object count);

  /// No description provided for @leaderboardFriendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Friends leaderboard'**
  String get leaderboardFriendsTitle;

  /// No description provided for @leaderboardLeagueTitle.
  ///
  /// In en, this message translates to:
  /// **'League leaderboard'**
  String get leaderboardLeagueTitle;

  /// No description provided for @leaderboardMonthsShort.
  ///
  /// In en, this message translates to:
  /// **'{months}m'**
  String leaderboardMonthsShort(Object months);

  /// No description provided for @learningNoTracksTitle.
  ///
  /// In en, this message translates to:
  /// **'No tracks yet'**
  String get learningNoTracksTitle;

  /// No description provided for @learningTracksBody.
  ///
  /// In en, this message translates to:
  /// **'Tracks will appear here as they are published. Check back soon.'**
  String get learningTracksBody;

  /// No description provided for @learningGradedNextDue.
  ///
  /// In en, this message translates to:
  /// **'Graded as {grade} — next due {date}'**
  String learningGradedNextDue(Object grade, Object date);

  /// No description provided for @learningNoReviewsDue.
  ///
  /// In en, this message translates to:
  /// **'No reviews due'**
  String get learningNoReviewsDue;

  /// No description provided for @liveEventsActive.
  ///
  /// In en, this message translates to:
  /// **'{count}{capacity} active'**
  String liveEventsActive(Object count, Object capacity);

  /// No description provided for @liveEventsQuestions.
  ///
  /// In en, this message translates to:
  /// **'{count} Qs'**
  String liveEventsQuestions(Object count);

  /// No description provided for @liveEventsSecondsPerQuestion.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s / Q'**
  String liveEventsSecondsPerQuestion(Object seconds);

  /// No description provided for @liveEventsJoined.
  ///
  /// In en, this message translates to:
  /// **'{count}{capacity} joined'**
  String liveEventsJoined(Object count, Object capacity);

  /// No description provided for @numericalsAnswer.
  ///
  /// In en, this message translates to:
  /// **'Answer: {value}{unit}'**
  String numericalsAnswer(Object value, Object unit);

  /// No description provided for @storeAssetMeta.
  ///
  /// In en, this message translates to:
  /// **'{rarity} • {slot} • {coins} coins'**
  String storeAssetMeta(Object rarity, Object slot, Object coins);

  /// No description provided for @syllabusNoTopicMatch.
  ///
  /// In en, this message translates to:
  /// **'No topic matches \"{query}\".'**
  String syllabusNoTopicMatch(Object query);

  /// No description provided for @syllabusExaminableCount.
  ///
  /// In en, this message translates to:
  /// **'{count} examinable'**
  String syllabusExaminableCount(Object count);

  /// No description provided for @errSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get errSessionExpired;

  /// No description provided for @errForbidden.
  ///
  /// In en, this message translates to:
  /// **'You do not have access to this resource.'**
  String get errForbidden;

  /// No description provided for @errNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found.'**
  String get errNotFound;

  /// No description provided for @errValidationRejected.
  ///
  /// In en, this message translates to:
  /// **'Some of the submitted values were rejected.'**
  String get errValidationRejected;

  /// No description provided for @errUpgradeRequired.
  ///
  /// In en, this message translates to:
  /// **'A newer version of the app is required.'**
  String get errUpgradeRequired;

  /// No description provided for @errRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please try again shortly.'**
  String get errRateLimited;

  /// No description provided for @errServerTrouble.
  ///
  /// In en, this message translates to:
  /// **'The server is having trouble. Please try again.'**
  String get errServerTrouble;

  /// No description provided for @errRequestFailedStatus.
  ///
  /// In en, this message translates to:
  /// **'Request failed with status {status}.'**
  String errRequestFailedStatus(Object status);

  /// No description provided for @errTimeout.
  ///
  /// In en, this message translates to:
  /// **'The request timed out. Check your connection and try again.'**
  String get errTimeout;

  /// No description provided for @errUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Check your connection and try again.'**
  String get errUnreachable;

  /// No description provided for @errCancelled.
  ///
  /// In en, this message translates to:
  /// **'The request was cancelled.'**
  String get errCancelled;

  /// No description provided for @errBadCertificate.
  ///
  /// In en, this message translates to:
  /// **'The server certificate could not be verified.'**
  String get errBadCertificate;

  /// No description provided for @errTransformTimeout.
  ///
  /// In en, this message translates to:
  /// **'The server took too long to deliver the response.'**
  String get errTransformTimeout;

  /// No description provided for @lifelineWrongRemoved.
  ///
  /// In en, this message translates to:
  /// **'{count} wrong option(s) removed.'**
  String lifelineWrongRemoved(Object count);

  /// No description provided for @lifelineCorrectAnswer.
  ///
  /// In en, this message translates to:
  /// **'Correct answer: {answer}'**
  String lifelineCorrectAnswer(Object answer);

  /// No description provided for @lifelineTimeAdded.
  ///
  /// In en, this message translates to:
  /// **'+{seconds}s added.'**
  String lifelineTimeAdded(Object seconds);

  /// No description provided for @lifelineTimerFrozen.
  ///
  /// In en, this message translates to:
  /// **'Timer frozen for {seconds}s.'**
  String lifelineTimerFrozen(Object seconds);

  /// No description provided for @lifelineShieldActive.
  ///
  /// In en, this message translates to:
  /// **'Shield active — one wrong answer forgiven.'**
  String get lifelineShieldActive;

  /// No description provided for @lifelineDoubleXp.
  ///
  /// In en, this message translates to:
  /// **'Double XP active on the next correct answer.'**
  String get lifelineDoubleXp;

  /// No description provided for @lifelineAudiencePoll.
  ///
  /// In en, this message translates to:
  /// **'Audience poll coming up.'**
  String get lifelineAudiencePoll;

  /// No description provided for @lifelineSecondChance.
  ///
  /// In en, this message translates to:
  /// **'Second chance saved for this question.'**
  String get lifelineSecondChance;

  /// No description provided for @lifelineNotEnoughCoins.
  ///
  /// In en, this message translates to:
  /// **'Not enough coins.'**
  String get lifelineNotEnoughCoins;

  /// No description provided for @lifelineNotValidForQuestion.
  ///
  /// In en, this message translates to:
  /// **'Not valid for this question.'**
  String get lifelineNotValidForQuestion;

  /// No description provided for @lifelineAlreadyUsed.
  ///
  /// In en, this message translates to:
  /// **'Already used on this attempt.'**
  String get lifelineAlreadyUsed;

  /// No description provided for @lifelineNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available for this attempt.'**
  String get lifelineNotAvailable;

  /// No description provided for @lifelineTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Please try again.'**
  String get lifelineTryAgain;

  /// No description provided for @lifelineNeedsCoins.
  ///
  /// In en, this message translates to:
  /// **'Needs {cost} coins (you have {balance})'**
  String lifelineNeedsCoins(Object cost, Object balance);

  /// No description provided for @lifelineUnavailableNow.
  ///
  /// In en, this message translates to:
  /// **'Unavailable right now'**
  String get lifelineUnavailableNow;

  /// No description provided for @streakAtRisk.
  ///
  /// In en, this message translates to:
  /// **'At risk — complete a quiz before midnight to keep {days} days alive.'**
  String streakAtRisk(Object days);

  /// No description provided for @streakCompleteToGrow.
  ///
  /// In en, this message translates to:
  /// **'Complete today\'s quiz to grow your streak.'**
  String get streakCompleteToGrow;

  /// No description provided for @streakTierLegend.
  ///
  /// In en, this message translates to:
  /// **'Legend 100+'**
  String get streakTierLegend;

  /// No description provided for @streakTierChampion.
  ///
  /// In en, this message translates to:
  /// **'Champion 30+'**
  String get streakTierChampion;

  /// No description provided for @streakTierWarrior.
  ///
  /// In en, this message translates to:
  /// **'Warrior 7+'**
  String get streakTierWarrior;

  /// No description provided for @streakTierStarter.
  ///
  /// In en, this message translates to:
  /// **'Starter'**
  String get streakTierStarter;

  /// No description provided for @streakCheckingRepair.
  ///
  /// In en, this message translates to:
  /// **'Checking repair eligibility…'**
  String get streakCheckingRepair;

  /// No description provided for @streakMissedDayGeneric.
  ///
  /// In en, this message translates to:
  /// **'You missed a day. Repair it now to keep the streak.'**
  String get streakMissedDayGeneric;

  /// No description provided for @streakMissedDayWhen.
  ///
  /// In en, this message translates to:
  /// **'You missed {when}. Repair it now to keep the streak.'**
  String streakMissedDayWhen(Object when);

  /// No description provided for @streakInsuranceBanked.
  ///
  /// In en, this message translates to:
  /// **'{count} of {max} insurance token{plural} banked. One auto-repairs a missed day.'**
  String streakInsuranceBanked(Object count, Object max, Object plural);

  /// No description provided for @streakInsuranceExplain.
  ///
  /// In en, this message translates to:
  /// **'Bank a token and it auto-repairs one missed day for you. Up to {max} at a time.'**
  String streakInsuranceExplain(Object max);

  /// No description provided for @streakInsuranceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Insurance is not available on your account yet.'**
  String get streakInsuranceUnavailable;

  /// No description provided for @streakNoInsuranceToUse.
  ///
  /// In en, this message translates to:
  /// **'No insurance available to use.'**
  String get streakNoInsuranceToUse;

  /// No description provided for @privacyUnreachable.
  ///
  /// In en, this message translates to:
  /// **'We could not reach the server to show what is stored about this device.'**
  String get privacyUnreachable;

  /// No description provided for @privacyUnreadable.
  ///
  /// In en, this message translates to:
  /// **'We could not read what is stored about this device. Your local choices are unaffected.'**
  String get privacyUnreadable;

  /// No description provided for @privacyEraseViaAccount.
  ///
  /// In en, this message translates to:
  /// **'This profile is linked to your account, so erasing it is handled by the account deletion flow. Use Delete account in Settings to remove everything.'**
  String get privacyEraseViaAccount;

  /// No description provided for @privacyLocalConsentNote.
  ///
  /// In en, this message translates to:
  /// **'Analytics, functional and marketing consent are stored on this device and applied immediately, independently of the anonymous profile above.'**
  String get privacyLocalConsentNote;

  /// No description provided for @privacyNoChoiceYet.
  ///
  /// In en, this message translates to:
  /// **'You have not made a choice yet.'**
  String get privacyNoChoiceYet;

  /// No description provided for @settingsLanguageSection.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageSection;

  /// No description provided for @settingsSecuritySection.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settingsSecuritySection;

  /// No description provided for @settingsAiSection.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get settingsAiSection;

  /// No description provided for @settingsAccountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccountSection;

  /// No description provided for @bookPageRangeOpen.
  ///
  /// In en, this message translates to:
  /// **'p. {start}+'**
  String bookPageRangeOpen(Object start);

  /// No description provided for @bookPageRangeSingle.
  ///
  /// In en, this message translates to:
  /// **'p. {page}'**
  String bookPageRangeSingle(Object page);

  /// No description provided for @bookPageRange.
  ///
  /// In en, this message translates to:
  /// **'p. {start}–{end}'**
  String bookPageRange(Object start, Object end);

  /// No description provided for @bookSessionNotCounted.
  ///
  /// In en, this message translates to:
  /// **'This reading session was not counted.'**
  String get bookSessionNotCounted;

  /// No description provided for @bookSessionNotCountedReason.
  ///
  /// In en, this message translates to:
  /// **'This reading session was not counted: {reason}'**
  String bookSessionNotCountedReason(Object reason);

  /// No description provided for @bookPagesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pages'**
  String bookPagesCount(Object count);

  /// No description provided for @bookChaptersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} chapters'**
  String bookChaptersCount(Object count);

  /// No description provided for @bookReadingTime.
  ///
  /// In en, this message translates to:
  /// **'{count} h'**
  String bookReadingTime(Object count);

  /// No description provided for @bookCoinsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} coins'**
  String bookCoinsCount(Object count);

  /// No description provided for @bookFormulasCount.
  ///
  /// In en, this message translates to:
  /// **'{count} formulas'**
  String bookFormulasCount(Object count);

  /// No description provided for @bookNumericalsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} numericals'**
  String bookNumericalsCount(Object count);

  /// No description provided for @bookFreePreview.
  ///
  /// In en, this message translates to:
  /// **'Free preview'**
  String get bookFreePreview;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least {count} characters.'**
  String authPasswordTooShort(Object count);

  /// No description provided for @authPasswordConfirmRequired.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your new password.'**
  String get authPasswordConfirmRequired;

  /// No description provided for @authPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'The two passwords do not match.'**
  String get authPasswordMismatch;

  /// No description provided for @gameClaimedCoins.
  ///
  /// In en, this message translates to:
  /// **'Claimed {coins} coins'**
  String gameClaimedCoins(Object coins);

  /// No description provided for @gameNothingClaimable.
  ///
  /// In en, this message translates to:
  /// **'Nothing was claimable'**
  String get gameNothingClaimable;

  /// No description provided for @gameClaimedMission.
  ///
  /// In en, this message translates to:
  /// **'Claimed {count} mission{plural} for {coins} coins'**
  String gameClaimedMission(Object count, Object plural, Object coins);

  /// No description provided for @homeCalculatorsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Calculators'**
  String homeCalculatorsCount(Object count);

  /// No description provided for @libraryUnlockFree.
  ///
  /// In en, this message translates to:
  /// **'Unlock (Free)'**
  String get libraryUnlockFree;

  /// No description provided for @libraryUnlockCoins.
  ///
  /// In en, this message translates to:
  /// **'Unlock • {coins} coins'**
  String libraryUnlockCoins(Object coins);

  /// No description provided for @quizQuestionsPlus.
  ///
  /// In en, this message translates to:
  /// **'{count}+ questions'**
  String quizQuestionsPlus(Object count);

  /// No description provided for @quizQuestionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} questions'**
  String quizQuestionsCount(Object count);

  /// No description provided for @socialReferralApplied.
  ///
  /// In en, this message translates to:
  /// **'Referral code applied.'**
  String get socialReferralApplied;

  /// No description provided for @socialReferralRejected.
  ///
  /// In en, this message translates to:
  /// **'That code could not be applied. It may already have been used.'**
  String get socialReferralRejected;

  /// No description provided for @socialTryThis.
  ///
  /// In en, this message translates to:
  /// **'Try this on CivilCal'**
  String get socialTryThis;

  /// No description provided for @socialShareInvite.
  ///
  /// In en, this message translates to:
  /// **'Use my code {code} on CivilCal — civil engineering calculators and Loksewa MCQs.\n{url}'**
  String socialShareInvite(Object code, Object url);

  /// No description provided for @tutorRetrievalFailed.
  ///
  /// In en, this message translates to:
  /// **'Retrieval temporarily failed — showing deterministic plan.'**
  String get tutorRetrievalFailed;

  /// No description provided for @tutorDegradedNote.
  ///
  /// In en, this message translates to:
  /// **'Answers may be less personalized (degraded).'**
  String get tutorDegradedNote;

  /// No description provided for @eiceSectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this section. {reason}'**
  String eiceSectionFailed(Object reason);

  /// No description provided for @numericalNotCorrect.
  ///
  /// In en, this message translates to:
  /// **'Not correct. Try again or view the worked solution.'**
  String get numericalNotCorrect;

  /// No description provided for @quizAnswerSavedNote.
  ///
  /// In en, this message translates to:
  /// **'Answer saved — the breakdown unlocks on the results screen.'**
  String get quizAnswerSavedNote;

  /// No description provided for @quizShareResult.
  ///
  /// In en, this message translates to:
  /// **'I scored {correct}/{total} ({percent}%) on \"{title}\" — {grade}! XP +{xp}, Coins +{coins} via CivilCal (BiSaaS). Try: https://bisaas.com'**
  String quizShareResult(
    Object correct,
    Object total,
    Object percent,
    Object title,
    Object grade,
    Object xp,
    Object coins,
  );

  /// No description provided for @quizGradeExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get quizGradeExcellent;

  /// No description provided for @quizGradeGoodJob.
  ///
  /// In en, this message translates to:
  /// **'Good Job'**
  String get quizGradeGoodJob;

  /// No description provided for @quizGradeKeepPracticing.
  ///
  /// In en, this message translates to:
  /// **'Keep Practicing'**
  String get quizGradeKeepPracticing;

  /// No description provided for @quizDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'CivilCal Quiz'**
  String get quizDefaultTitle;

  /// No description provided for @syllabusTopicsLoaded.
  ///
  /// In en, this message translates to:
  /// **'topics loaded'**
  String get syllabusTopicsLoaded;

  /// No description provided for @syllabusTopicsLabel.
  ///
  /// In en, this message translates to:
  /// **'topics'**
  String get syllabusTopicsLabel;

  /// No description provided for @quizIntroGradesInstantly.
  ///
  /// In en, this message translates to:
  /// **'Server grades your answer instantly.'**
  String get quizIntroGradesInstantly;

  /// No description provided for @quizIntroCorrectRule.
  ///
  /// In en, this message translates to:
  /// **'Correct: +10 XP, streak combo bonus.'**
  String get quizIntroCorrectRule;

  /// No description provided for @quizIntroWrongRule.
  ///
  /// In en, this message translates to:
  /// **'Wrong: -2 XP, streak resets.'**
  String get quizIntroWrongRule;

  /// No description provided for @quizIntroBackRule.
  ///
  /// In en, this message translates to:
  /// **'Tap the back button to exit (progress lost).'**
  String get quizIntroBackRule;

  /// No description provided for @tutorExampleProctor.
  ///
  /// In en, this message translates to:
  /// **'Explain proctor compaction simply'**
  String get tutorExampleProctor;

  /// No description provided for @tutorExamplePlanWeek.
  ///
  /// In en, this message translates to:
  /// **'Help me plan this week'**
  String get tutorExamplePlanWeek;

  /// No description provided for @privacyLinkedToAccount.
  ///
  /// In en, this message translates to:
  /// **'Linked to an account'**
  String get privacyLinkedToAccount;

  /// No description provided for @authPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a new password.'**
  String get authPasswordRequired;

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
