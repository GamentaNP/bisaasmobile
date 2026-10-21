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

  /// No description provided for @authPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get authPasswordRequired;

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

  /// No description provided for @practiceQuestionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} questions'**
  String practiceQuestionsCount(Object count);

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
