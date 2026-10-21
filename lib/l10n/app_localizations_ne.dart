// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Nepali (`ne`).
class AppLocalizationsNe extends AppLocalizations {
  AppLocalizationsNe([String locale = 'ne']) : super(locale);

  @override
  String get appTitle => 'CivilCal';

  @override
  String get signIn => 'साइन इन गर्नुहोस्';

  @override
  String get register => 'दर्ता गर्नुहोस्';

  @override
  String get quiz => 'क्विज';

  @override
  String get practice => 'अभ्यास';

  @override
  String get calculators => 'क्यालकुलेटर';

  @override
  String get courses => 'कोर्स';

  @override
  String get continueAsGuest => 'अतिथिको रूपमा जारी राख्नुहोस्';

  @override
  String get backend => 'ब्याकइन्ड';

  @override
  String get env => 'वातावरण';

  @override
  String get home => 'गृहपृष्ठ';

  @override
  String get profile => 'प्रोफाइल';

  @override
  String get settings => 'सेटिङ';

  @override
  String get offline => 'अफलाइन';

  @override
  String get retry => 'फेरि प्रयास';

  @override
  String get error => 'केही गडबड भयो';

  @override
  String streakDays(Object days) {
    return 'स्ट्रिक: $days दिन';
  }

  @override
  String coinsBalance(Object count) {
    return '$count क्विन';
  }

  @override
  String get appLocked => 'CivilCal लक छ';

  @override
  String get unlock => 'खोल्नुहोस्';

  @override
  String get unlockCivilCal => 'CivilCal खोल्नुहोस्';

  @override
  String get commonCancel => 'रद्द गर्नुहोस्';

  @override
  String get commonSave => 'सुरक्षित गर्नुहोस्';

  @override
  String get commonClose => 'बन्द गर्नुहोस्';

  @override
  String get commonGoBack => 'पछाडि जानुहोस्';

  @override
  String get commonStay => 'यहै रहनुहोस्';

  @override
  String get commonExit => 'बाहिर निस्कनुहोस्';

  @override
  String get commonEmail => 'इमेल';

  @override
  String get commonPassword => 'पासवर्ड';

  @override
  String get commonContinueWithGoogle => 'Google सँग जारी राख्नुहोस्';

  @override
  String get commonContinueWithApple => 'Apple सँग जारी राख्नुहोस्';

  @override
  String get commonOr => 'वा';

  @override
  String get commonSkip => 'छोड्नुहोस्';

  @override
  String get commonCheckAgain => 'फेरि जाँच्नुहोस्';

  @override
  String get commonContactSupport => 'सहायता सम्पर्क गर्नुहोस्';

  @override
  String get commonShareResult => 'नतिजा साझेदार गर्नुहोस्';

  @override
  String commonPoints(Object count) {
    return '$count अंक';
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
  String get authWelcomeBackTitle => 'पुनः स्वागत छ';

  @override
  String get authWelcomeBackSubtitle =>
      'आफ्ना क्विज, सूत्र र अंक हेर्न साइन इन गर्नुहोस्';

  @override
  String get authForgotPasswordTitle => 'पासवर्ड बिर्सनुभयो?';

  @override
  String get authForgotPasswordSubtitle =>
      'तपाईंको दर्ता गरिएको इमेल लेख्नुहोस्, हामी पासवर्ड रिसेट गर्ने निर्देश पठाउनेछौं।';

  @override
  String get authEmailAddressLabel => 'इमेल ठेगाना';

  @override
  String get authSendResetLink => 'रिसेट लिंक पठाउनुहोस्';

  @override
  String get authCheckEmailTitle => 'आफ्नो इमेल हेर्नुहोस्';

  @override
  String authCheckEmailBody(Object email) {
    return '$email सँग खाता भए छुट्टै पासवर्ड रिसेट लिंक पठाइनेछौं।';
  }

  @override
  String get authReturnToLogin => 'लगइनमा फर्कनुहोस्';

  @override
  String get authJoinTitle => 'CivilCal मा सामेल हुनुहोस्';

  @override
  String get authJoinSubtitle =>
      'इन्जिनियरिङ परीक्षा र गणितका लागि तपाईंको साथी';

  @override
  String get authFullNameLabel => 'पूरा नाम';

  @override
  String get authConfirmPasswordLabel => 'पासवर्ड पुष्टि गर्नुहोस्';

  @override
  String get authCreateAccount => 'खाता खोल्नुहोस्';

  @override
  String get authAlreadyHaveAccount => 'पहिले नै खाता छ?';

  @override
  String get authNoAccount => 'खाता छैन?';

  @override
  String get authSetNewPasswordTitle => 'नयाँ पासवर्ड राख्नुहोस्';

  @override
  String get authResetTitle => 'नयाँ पासवर्ड छान्नुहोस्';

  @override
  String get authResetSubtitle =>
      'तपाईं सबै यन्त्रमा, यस यन्त्रमा पनि, साइन आउट हुनुहुनेछ।';

  @override
  String get authResetMissingToken =>
      'यो लिंकमा रिसेट टोकन छैन। इमेलबाट पठाइएको लिंक खोल्नुहोस्, वा नयाँ लिंक माग्नुहोस्।';

  @override
  String get authRequestNewLink => 'नयाँ लिंक माग्नुहोस्';

  @override
  String get authRequestNewLinkInstead => 'त्यसैले नयाँ लिंक माग्नुहोस्';

  @override
  String get authNewPasswordLabel => 'नयाँ पासवर्ड';

  @override
  String get authConfirmNewPasswordLabel => 'नयाँ पासवर्ड पुष्टि गर्नुहोस्';

  @override
  String authMinChars(Object count) {
    return 'कम्तीमा $count अक्षर';
  }

  @override
  String get authVerifyEmailBanner =>
      'सबै सुविधा खोल्न आफ्नो इमेल प्रमाणित गर्नुहोस्।';

  @override
  String get authSplashTagline => 'बिसास इन्जिनियरिङ लर्निङ इकोसिस्टम';

  @override
  String get authInvalidEmail => 'मान्य इमेल लेख्नुहोस्';

  @override
  String get authPasswordRequired => 'कृपया आफ्नो पासवर्ड लेख्नुहोस्';

  @override
  String onboardingStepOf(Object current, Object total) {
    return 'चरण $current / $total';
  }

  @override
  String get onboardingTargetExamTitle => 'लक्षित परीक्षा';

  @override
  String get onboardingTargetExamBody =>
      'यो खाताले कुन पाठ्यक्रमतर्फ अध्ययन गर्छ तो तोक्न्छ।';

  @override
  String get onboardingDailyGoalTitle => 'दैनिक अभ्यासको लक्ष्य';

  @override
  String get onboardingDailyGoalBody =>
      'तपाईं दैनिक कति समय दिन चाहनुहुन्छ? जुनसुकै बेला परिवर्तन गर्न सकिन्छ।';

  @override
  String onboardingMinutesPerDay(Object minutes, Object label) {
    return 'दिनमा $minutes मिनेट — $label';
  }

  @override
  String get onboardingCurrentLevelTitle => 'तपाईंको हालको तह';

  @override
  String get onboardingCurrentLevelBody =>
      'तपाईंको स्ट्रिक र दोहोराइ कतामा सुरु हुन्छ तो तोक्न्छ।';

  @override
  String get quizHomeTitle => 'अभ्यास र क्विज';

  @override
  String get quizHomeLoadError => 'क्विज लोड गर्न सकिएन';

  @override
  String get quizHomeEmptyTitle => 'अहिलेसम्म कुनै क्विज छैन';

  @override
  String get quizHomeEmptyBody =>
      'तपाईंको परीक्षाका प्रश्न संग्रह तयार हुँदैछ। छिट्टै फेरि जाँच्नुहोस्।';

  @override
  String get quizPlayWorlds => 'वर्ल्डहरू खेल्नुहोस्';

  @override
  String get quizPlayWorldsSubtitle =>
      'अध्याय, तह र बड — अघि बढ्दै स्टार कमाउनुहोस्';

  @override
  String get quizPracticeDrill => 'अभ्यास ड्रिल';

  @override
  String get quizPracticeDrillSubtitle =>
      'आफ्ना बुकमार्क र कमजोर विषय दोहोराउनुहोस् — समयसीमा छैन, अंकमा असर छैन';

  @override
  String get quizIntroDetailsTitle => 'क्विजको विवरण';

  @override
  String quizIntroLoadFailed(Object reason) {
    return 'क्विज लोड गर्न सकिएन: $reason';
  }

  @override
  String get quizIntroQuestions => 'प्रश्नहरू';

  @override
  String get quizIntroMinutes => 'मिनेट';

  @override
  String get quizIntroStart => 'क्विज सुरु गर्नुहोस्';

  @override
  String get quizIntroHowItWorks => 'यसरी काम गर्छ';

  @override
  String get quizAttemptLoadError => 'क्विज लोड गर्न सकिएन';

  @override
  String get quizAttemptOfflineNotice =>
      'अफलाइन अभ्यास — आधिकारिक होइन। इन्टरनेट फर्केपछि XP/क्विन मिलाइनेछन्।';

  @override
  String quizAttemptUnsupportedEffect(Object effect) {
    return '$effect प्रयोग भयो — सर्भरले यस्तो इफेक्ट फर्कायो जुन यो एपले अहिले देखाउन सक्दैन।';
  }

  @override
  String quizAttemptCombo(Object count) {
    return '×$count कम्बो!';
  }

  @override
  String get quizAttemptExitTitle => 'क्विजबाट निस्कने?';

  @override
  String get quizAttemptExitBody =>
      'तपाईंको हालको प्रगति हराउनेछ। निस्कनेमा पक्का हुनुहुन्छ?';

  @override
  String get quizResultTitle => 'क्विज पूरा भयो!';

  @override
  String get quizResultAccuracy => 'शुद्धता';

  @override
  String quizResultCorrectOf(Object correct, Object total) {
    return '$total मध्ये $correct सही';
  }

  @override
  String get quizResultCorrect => 'सही';

  @override
  String get quizResultXpEarned => 'कमाइएको XP';

  @override
  String get quizResultCoins => 'क्विन';

  @override
  String get quizResultAnswerReview => 'उत्तर पुनरावलोकन';

  @override
  String get quizResultBackToHome => 'गृहपृष्ठमा फर्कनुहोस्';

  @override
  String get quizResultReviewAll => 'सबै उत्तर हेर्नुहोस्';

  @override
  String get quizResultMorePractice => 'थप अभ्यास';

  @override
  String quizResultShareFailed(Object reason) {
    return 'साझेदारी उपलब्ध छैन: $reason';
  }

  @override
  String get quizReviewTitle => 'उत्तरहरू हेर्नुहोस्';

  @override
  String quizReviewLoadFailed(Object reason) {
    return 'पुनरावलोकन लोड गर्न सकिएन: $reason';
  }

  @override
  String get quizReviewEmpty => 'हेर्नुपर्ने कुनै उत्तर छैन';

  @override
  String get quizReviewYourAnswer => 'तपाईंको उत्तर';

  @override
  String get quizReviewNotAnswered => 'उत्तर दिइएको छैन';

  @override
  String quizReviewQuestionNumber(Object number) {
    return 'प्रश्न $number';
  }

  @override
  String get quizFunnelTryItOut => 'आजमाएर हेर्नुहोस्';

  @override
  String get quizFunnelSampleTitle => 'नमुना प्रश्नहरू';

  @override
  String quizFunnelShown(Object count) {
    return '$count देखाइएको';
  }

  @override
  String get quizFunnelEmptyTitle => 'अहिलेसम्म कुनै नमुना प्रश्न छैन';

  @override
  String get quizFunnelEmptyBody =>
      'अहिले सङ्ग्रहमा सार्वजनिक प्रश्न छैनन्। खाता खोल्नुहोस्, सबै कुरा देख्नुहुन्छ।';

  @override
  String get quizFunnelCreateAccount => 'खेल्न निःशुल्क खाता खोल्नुहोस्';

  @override
  String get quizFunnelPlayGraded => 'मूल्याङ्कनसहितको क्विज खेल्नुहोस्';

  @override
  String get quizFunnelPracticeNote =>
      'अभ्यास मोडले अंक, XP वा स्ट्रिकलाई कहिल्यै असर गर्दैन।';

  @override
  String quizOfflinePractice(Object subject) {
    return 'अफलाइन अभ्यास — $subject';
  }

  @override
  String get quizFinishFailed =>
      'क्विज समाप्त गर्न सकिएन। कृपया फेरि प्रयास गर्नुहोस्।';

  @override
  String get quizCountUnavailable => 'संख्या उपलब्ध छैन';

  @override
  String get calcBrowserEmpty => 'कुनै क्यालकुलेटर प्रकाशित छैन';

  @override
  String calcBrowserCount(Object count, Object domains) {
    return '$count क्यालकुलेटर • $domains क्षेत्र';
  }

  @override
  String get calcBrowserLoadError => 'क्यालकुलेटर लोड गर्न सकिएन';

  @override
  String calcShareFailed(Object reason) {
    return 'यो नतिजा साझेदार गर्न सकिएन: $reason';
  }

  @override
  String calcNoInputNamed(Object name) {
    return 'यस क्यालकुलेटरमा \"$name\" नामको इनपुट छैन';
  }

  @override
  String get calcAddInput => 'कम्तीमा एउटा इनपुट थप्नुहोस्';

  @override
  String calcInputsLabel(Object label) {
    return 'इनपुट · $label';
  }

  @override
  String get calcInputsLegacy => 'इनपुट (पुरानो)';

  @override
  String get calcKeyLabel => 'कुञ्जी';

  @override
  String get calcKeyExample => 'जस्तै: लम्बाइ';

  @override
  String get calcValueLabel => 'मान';

  @override
  String get calcValueExample => 'जस्तै: 12.5';

  @override
  String get calcAssistantTitle => 'सहायकलाई सोध्नुहोस्';

  @override
  String get calcAssistantExample =>
      'जस्तै: २५ MPa मिक्सका लागि ३ म चौडाइ, ४ म गहराइको स्ल्याब';

  @override
  String get calcAssistantSuggested => 'सुझाव दिइएका मान';

  @override
  String get calcAssistantAlso => 'तपाईं यो पनि सोध्न सक्नुहुन्छ';

  @override
  String calcHistoryTitle(Object subject) {
    return '$subject · इतिहास';
  }

  @override
  String get calcHistoryEmpty => 'अहिलेसम्म कुनै गणित सुरक्षित गरिएको छैन';

  @override
  String get calcStepByStep => 'चरणबद्ध';

  @override
  String get calcShareResult => 'नतिजा साझेदार गर्नुहोस्';

  @override
  String get calcPracticeRelated => 'सम्बन्धित प्रश्न अभ्यास गर्नुहोस्';

  @override
  String get calcViewHistory => 'इतिहास हेर्नुहोस्';

  @override
  String get calcNoSchema =>
      'सर्भरले फाँटको स्किमा दिएन। सामान्य कुञ्जी/मान सम्पादकमा प्रयोग गरिन्छ।';

  @override
  String get calcAddField => 'फाँट थप्नुहोस्';

  @override
  String calcInputsCount(Object count) {
    return 'इनपुट: $count';
  }

  @override
  String get calcAsk => 'सोध्नुहोस्';

  @override
  String get calcApply => 'प्रयोग गर्नुहोस्';

  @override
  String get calcAssistantDisclaimer =>
      'सहायकले सुझाव दिन्छ, निर्णय तपाईंको। गणित सधैँ सर्भरले गर्छ।';

  @override
  String homeGreeting(Object name) {
    return 'नमस्ते, $name 👋';
  }

  @override
  String homeLevel(Object level, Object xp) {
    return 'तह $level • $xp XP';
  }

  @override
  String get homeDaily => 'दैनिक';

  @override
  String get homeBattle => 'ब्याटल';

  @override
  String get homeBrowse => 'हेर्नुहोस्';

  @override
  String get homeExplore => 'घुम्नुहोस्';

  @override
  String get homeCurrentCourse => 'हालको कोर्स';

  @override
  String homePercentDone(Object percent) {
    return '$percent% पूरा';
  }

  @override
  String get homeMissionsUnavailable => 'मिसन उपलब्ध छैन';

  @override
  String get homeWorldsLoadError => 'तपाईंका वर्ल्ड लोड गर्न सकिएन';

  @override
  String get homeWorldsEmpty =>
      'अहिलेसम्म कुनै वर्ल्ड प्रकाशित छैन — अभ्यास जारी राख्न विषय हेर्नुहोस्।';

  @override
  String get homeYourWorlds => 'तपाईंका वर्ल्ड';

  @override
  String homeStars(Object earned, Object total) {
    return '$earned / $total ⭐';
  }

  @override
  String homeContinue(Object title) {
    return 'जारी राख्नुहोस्: $title';
  }

  @override
  String get homeDashboardLoadError => 'तपाईंको ड्यासबोर्ड लोड गर्न सकिएन';

  @override
  String get homeDashboardEmpty =>
      'अनुमान गर्नुको सट्टा केही देखाइएको छैन। तान्नुहोस्, वा तल फेरि प्रयास गर्नुहोस्।';

  @override
  String get homeDashboardUnreachable =>
      'सर्भरसम्म पुग्न सकिएन, त्यसैले ड्यासबोर्ड देखाउन सकिएन।';

  @override
  String get consentTitle => 'गोपनीयता विकल्प';

  @override
  String get consentIntro =>
      'तपाईंको खाता र क्विजको प्रगति हाम्रो सर्भरमा राखिन्छ, जसले तपाईं जुनसुकै यन्त्रमा साइन इन गर्न सक्नुहुन्छ। यसले काम गर्न र एप स्थिर रहनका लागि हामी यन्त्र पहिचान, पुश सूचना टोकन, क्र्यास रिपोर्ट र यन्त्र सुरक्षा जाँच पनि पठाउँछौं। तपाईंको अनुमति भए हामी प्रयोग सम्बन्धी घटना पनि पठाउँछौं। Settings → Privacy मा गएर जुनसुकै बेला परिवर्तन गर्न सकिन्छ।';

  @override
  String get consentNecessary => 'आवश्यक';

  @override
  String get consentNecessaryBody =>
      'साइन इन र तपाईंको सुरक्षित काम, पुश सूचना टोकन, क्र्यास रिपोर्ट र यन्त्र सुरक्षा जाँच। एप चल्नका लागि आवश्यक।';

  @override
  String get consentFunctional => 'कार्यक्षम';

  @override
  String get consentFunctionalBody =>
      'तपाईंको भाषा र फिल्टरजस्ता सेटिङ यस यन्त्रमा सम्झनुहोस्।';

  @override
  String get consentAnalytics => 'विश्लेषण';

  @override
  String get consentAnalyticsBody =>
      'प्रयोग सम्बन्धी घटना जुन सुविधाहरू उपयोगी छन् भनी देखाउँछ। तिनीहरू तपाईंको खातासँग होइन, यन्त्र पहिचानसँग जोडिन्छन्। प्रश्नको सामग्री कहिल्यै समावेश हुँदैन।';

  @override
  String get consentMarketing => 'प्रचार';

  @override
  String get consentMarketingBody => 'अफर र प्रचार। तपाईं नभाएसम्म बन्द।';

  @override
  String get consentSaveChoices => 'विकल्प सुरक्षित गर्नुहोस्';

  @override
  String get consentNecessaryOnly => 'आवश्यक मात्र राखेर जारी राख्नुहोस्';

  @override
  String get consentLoadError => 'तपाईंका विकल्प लोड गर्न सकिएन';

  @override
  String get consentNecessaryAlwaysOn =>
      'सधैं सक्रिय। तपाईंको खाता, सुरक्षित काम, पुश टोकन, क्र्यास रिपोर्ट र यन्त्र सुरक्षा जाँच।';

  @override
  String get consentDataStored => 'यस यन्त्रबारे सुरक्षित डाटा';

  @override
  String get consentDataStoredSubtitle =>
      'अनाम प्रोफाइल हेर्नुहोस् र मेटाउनुहोस्';

  @override
  String get consentFootnote =>
      'कुनै श्रेणी बन्द गर्दा त्यस संग्रह त्यस क्षणबाट रोकिन्छ। पहिले संग्रह भएको डाटा भने महिल्न्छ — त्यसका लागि माथिको लिंक प्रयोग गर्नुहोस् वा privacy@bisaas.com मा सम्पर्क गर्नुहोस्।';

  @override
  String get privacyTitle => 'तपाईंको डाटा';

  @override
  String get privacyAnonymousProfile => 'अनाम प्रोफाइल';

  @override
  String privacyReference(Object reference) {
    return 'सन्दर्भ $reference';
  }

  @override
  String get privacyEraseData => 'सुरक्षित डाटा मेटाउनुहोस्';

  @override
  String get privacyLocalChoices => 'यस यन्त्रका विकल्प';

  @override
  String get privacyEraseTitle => 'सुरक्षित डाटा मेटाउने?';

  @override
  String get privacyEraseBody =>
      'यसले अनाम प्रोफाइल र यस यन्त्रका लागि सुरक्षित भएका सबै इन्टेन्ट घटना मेटाउँछ। यो पूर्ववत् हुँदैन।';

  @override
  String get privacyErased => 'सुरक्षित डाटा मेटाइयो';

  @override
  String get privacyEraseFailed => 'डाटा मेटाउन सकिएन। फेरि प्रयास गर्नुहोस्।';

  @override
  String get privacyEraseConfirm => 'मेटाउनुहोस्';

  @override
  String get privacyMenu => 'गोपनीयता';

  @override
  String get notificationDailyTitle => 'दैनिक स्प्रिन्ट तयार छ ⚡';

  @override
  String get notificationDailyBody =>
      'तपाईंका दैनिक बहुविकल्पीय प्रश्न तयार छन् — स्ट्रिक जोगाउनुहोस्!';

  @override
  String get forceUpdateTitle => 'अद्यावधिक आवश्यक';

  @override
  String forceUpdateYourVersion(Object version) {
    return 'तपाईंको संस्करण: $version';
  }

  @override
  String get forceUpdateNow => 'अहिले अद्यावधिक गर्नुहोस्';

  @override
  String get forceUpdateReassurance =>
      'तपाईंको खाता र प्रगति सुरक्षित छ — अद्यावधिकले केही गुमाउँदैन।';

  @override
  String forceUpdateStoreFailed(Object url) {
    return 'स्टोर खोल्न सकिएन। $url मा जानुहोस्';
  }

  @override
  String get maintenanceTitle => 'हामी छिट्टै फर्कन्छौं';

  @override
  String get maintenanceBody =>
      'CivilCal सँक्षिप्त मर्मतका लागि बन्द छ। तपाईंको खाता, क्विन र प्रगति सुरक्षित छ — केही गुमेको छैन।';

  @override
  String get versionUnsupported => 'यो एप संस्करण अब समर्थित छैन।';

  @override
  String get authUpdating => 'अद्यावधिक हुँदैछ…';

  @override
  String get authUpdatePassword => 'पासवर्ड अद्यावधिक गर्नुहोस्';

  @override
  String get authVerificationResentBody =>
      'यो ठेगाना अझै प्रमाणित हुनुपर्ने छ भने नयाँ लिंक पठाइदैछौं। आफ्नो इनबक्स र स्प्याम फोल्डर हेर्नुहोस्।';

  @override
  String get authVerificationResentHint =>
      'हामी तपाईंको खाताको ठेगानामा एक ट्यापको प्रमाणीकरण लिंक पठाउँछौं।';

  @override
  String get authVerificationSent => 'प्रमाणीकरण पठाइयो';

  @override
  String get authResendVerification => 'प्रमाणीकरण इमेल पुनः पठाउनुहोस्';

  @override
  String calcSearchInDomain(Object scope) {
    return '$scope क्यालकुलेटर खोज्नुहोस्…';
  }

  @override
  String get calcSearchPlaceholder => 'क्यालकुलेटर खोज्नुहोस्…';

  @override
  String get calcCalculating => 'गणना हुँदैछ…';

  @override
  String get calcCalculateServer => 'गणना गर्नुहोस् (सर्भर)';

  @override
  String calcVia(Object source) {
    return '$source मार्फत';
  }

  @override
  String homeMissionsReady(Object count) {
    return '$count मिसन दावी गर्न तयार';
  }

  @override
  String homeMissionsActive(Object count) {
    return 'मिसन — $count सक्रिय';
  }

  @override
  String get onboardingStartLearning => 'सिकाइ सुरु गर्नुहोस्';

  @override
  String get onboardingContinue => 'जारी राख्नुहोस्';

  @override
  String get privacyLinkedToAccount =>
      'यो प्रोफाइल तपाईंको खातासँग जोडिएको छ। सबै मेटाउन खाता नै हटाउनुहोस्।';

  @override
  String get quizSeeResults => 'नतिजा हेर्नुहोस्';

  @override
  String get quizNextQuestion => 'अर्को प्रश्न';

  @override
  String get quizAnswerSubmitted => 'उत्तर पठाइयो';

  @override
  String get quizBrowseQuizzes => 'क्विजहरू हेर्नुहोस्';

  @override
  String get quizPickTopic => 'विषय छान्नुहोस्';

  @override
  String get quizSearchCourses => 'कोर्स खोज्नुहोस्…';

  @override
  String get quizSearchTopics => 'विषय खोज्नुहोस्…';

  @override
  String get quizNoCoursesYet => 'अहिलेसम्म कुनै कोर्स छैन';

  @override
  String get quizNoMatches => 'कुनै मिलान छैन';

  @override
  String get quizSetsBeingPrepared =>
      'तपाईंको परीक्षाका प्रश्न संग्रह तयार हुँदैछ।';

  @override
  String get quizTryDifferentSearch => 'अर्को खोजी प्रयास गर्नुहोस्';

  @override
  String get quizNoTopicsYet => 'अहिलेसम्म कुनै विषय छैन';

  @override
  String get quizCourseNoActiveTopics =>
      'यो कोर्समा अहिलेसम्म कुनै सक्रिय विषय छैन।';

  @override
  String get quizFunnelSampleBody =>
      'हाम्रो सङ्ग्रहबाट नमुना प्रश्नहरू। पूर्ण अंकयुक्त सत्र खेल्न Quiz ट्याब खोल्नुहोस्।';

  @override
  String get quizFunnelPublicBody =>
      'हाम्रो सङ्ग्रहबाट सार्वजनिक प्रश्नहरू। निःशुल्क खाता बनाएपछि उत्तरहरू खुल्छन्।';

  @override
  String get quizFreshQuestions => 'हालै नयाँ प्रश्नहरू थपिएका छन्।';

  @override
  String quizNewIn(Object scope) {
    return '$scope मा नयाँ';
  }

  @override
  String get quizNoQuestionText => 'यो प्रश्नको सर्भरमा कुनै पाठ छैन।';

  @override
  String get quizGraded => 'अंकयुक्त';

  @override
  String get quizXp => 'XP';

  @override
  String get quizByServer => 'सर्भरद्वारा';

  @override
  String get profileAvatarUploaded => 'अवतार अपलोड भयो';

  @override
  String get profileAvatarUpdated => 'अवतार अद्यावधिक भयो';

  @override
  String profileUploadFailed(Object reason) {
    return 'अपलोड असफल: $reason';
  }

  @override
  String get profileEditName => 'नाम सम्पादन गर्नुहोस्';

  @override
  String get profileDisplayName => 'प्रदर्शित नाम';

  @override
  String get profileUpdated => 'प्रोफाइल अद्यावधिक भयो';

  @override
  String profileUpdateFailed(Object reason) {
    return 'अद्यावधिक असफल: $reason';
  }

  @override
  String profileShareCardText(Object level) {
    return 'मेरो CivilCal प्रोफाइल — तह $level इन्जिनियर। https://bisaas.com';
  }

  @override
  String profileShareFailed(Object reason) {
    return 'साझेदारी असफल: $reason';
  }

  @override
  String get profileShareCard => 'कार्ड साझेदार गर्नुहोस्';

  @override
  String profileLevel(Object level) {
    return 'तह $level';
  }

  @override
  String get profileChangeAvatar => 'अवतार परिवर्तन गर्नुहोस्';

  @override
  String get profileEditAvatar => 'अवतार सम्पादन गर्नुहोस्';

  @override
  String get profileStreak => 'स्ट्रिक';

  @override
  String get profileSkillRadar => 'सीप रेडार';

  @override
  String profileSkillsFailed(Object reason) {
    return 'सीप लोड असफल: $reason';
  }

  @override
  String get profileAchievements => 'उपलब्धि';

  @override
  String get profileAchievementsLoadFailed => 'उपलब्धि लोड गर्न सकिएन';

  @override
  String get profileNoBadges =>
      'अहिलेसम्म कुनै ब्याज छैन — क्विज पूरा गरेर कमाउनुहोस्!';

  @override
  String get profileUnlocked => 'खुला';

  @override
  String get profileSkillRadarEmpty =>
      'आफ्नो सीप रेडार देख्न क्विज खेल्नुहोस्।';

  @override
  String get profileSkillRadarEmptyHint =>
      'आफ्नो सीप रेडार देख्न थप श्रेणीहरूमा उत्तर दिनुहोस्।';

  @override
  String get profileLearning => 'सिकाइ — ट्र्याक र AI ट्युटर';

  @override
  String get profileLearningSub => 'अध्ययन योजना • दोहोराइ • ट्युटर';

  @override
  String get profileEice => 'परीक्षा बुद्धि (EICE)';

  @override
  String get profileEiceSub => 'कोच • त्रायज • स्प्रिन्ट';

  @override
  String get profilePscSub => 'परीक्षा ढाँचा र पाठ्यक्रम';

  @override
  String get profilePracticeSub => 'बुकमार्क ड्रिल • कमजोर विषय';

  @override
  String get profileLeaderboardSub => 'विश्व • साथी • लिग';

  @override
  String get profileContests => 'प्रतियोगिता';

  @override
  String get profileContestsSub => 'प्रत्यक्ष क्विज र लिडरबोर्ड';

  @override
  String get profileLiveEvents => 'प्रत्यक्ष कार्यक्रम';

  @override
  String get profileLiveEventsSub => 'तोकिएका सत्र र चेक-इन';

  @override
  String get profileCoaching => 'कोचिङ';

  @override
  String get profileCoachingSub => 'कमजोर क्षेत्र • तयारी • स्प्रिन्ट';

  @override
  String get profileSearchSub => 'कुनै पनि प्रश्न खोज्नुहोस्';

  @override
  String get profileNotificationsSub => 'गतिविधि र सम्झना';

  @override
  String get profileSocial => 'सामाजिक र रेफरल';

  @override
  String get profileSocialSub => 'साझेदारी • स्ट्रिक • लिडरबोर्ड';

  @override
  String get profileWalletSub => 'क्विन र खाता';

  @override
  String get profileAchievementsSub => 'स्ट्रिक + ब्याज';

  @override
  String get profileOffline => 'अफलाइन सामग्री';

  @override
  String get profileOfflineSub => 'क्यास गरिएका प्याक + प्रीफेच';

  @override
  String get profileCalculatorsSub => 'सिभिल सूत्र इन्जिन';

  @override
  String get profileSettingsSub => 'भाषा • बायोमेट्रिक • लगआउट';

  @override
  String get settingsSubscriptionActive =>
      'खाता मेटाउनुअघि सदस्यता रद्द गर्नुपर्छ';

  @override
  String get settingsDeleteFailed =>
      'खाता मेटाउन सकिएन — कृपया फेरि प्रयास गर्नुहोस्';

  @override
  String get settingsAccountDeleted => 'तपाईंको खाता मेटाइएको छ';

  @override
  String get settingsNoBiometrics => 'यस यन्त्रमा कुनै बायोमेट्रिक दर्ता छैन';

  @override
  String get settingsLanguageLocalOnly =>
      'भाषा यस यन्त्रमा मात्र सुरक्षित भयो — सर्भरसम्म पुग्न सकिएन।';

  @override
  String get settingsSystemDefault => 'प्रणालीको सान्दर्भ';

  @override
  String get settingsAppLanguage => 'एपको भाषा';

  @override
  String get settingsBiometricLock => 'बायोमेट्रिक एप लक';

  @override
  String get settingsBiometricLockSub =>
      'पृष्ठभूमिमा ३० सेकेन्डपछि बायोमेट्रिक माग्नुहोस्';

  @override
  String get settingsPrivacySub => 'विश्लेषण, कार्यक्षम र प्रचारको सहमति';

  @override
  String get settingsAiUsageSub =>
      'तपाईंको तर्फमा AI ले के प्रयोग गर्यो, सुविधाअनुसार';

  @override
  String get settingsAiKeysSub =>
      'AI सुविधाहरू आफ्नै प्रोभाइडरको कोटामा चलाउनुहोस्';

  @override
  String get settingsLogOut => 'लगआउट';

  @override
  String get settingsDeleteAccount => 'खाता मेटाउनुहोस्';

  @override
  String get settingsDeleteAccountSub =>
      'तपाईंको खाता, प्रयास र खरोद स्थायी रूपमा मेटाउनुहोस्';

  @override
  String get settingsDeleteAccountTitle => 'खाता मेटाउने?';

  @override
  String get settingsDeleteAccountBody =>
      'यसले तपाईंको खाता, क्विज इतिहास, क्विन र खरोद स्थायी रूपमा मेटाउँछ। यो पूर्ववत् हुँदैन।';

  @override
  String get settingsTypeDeleteToConfirm => 'पुष्टि गर्न \'DELETE\' लेख्नुहोस्';

  @override
  String get settingsDeleteConfirm => 'मेटाउनुहोस्';

  @override
  String get streakRefresh => 'ताजा गर्नुहोस्';

  @override
  String get streakNoneTitle => 'अहिलेसम्म कुनै स्ट्रिक छैन';

  @override
  String get streakNoneBody =>
      'आफ्नो स्ट्रिक सुरु गर्न एउटा क्विज पूरा गर्नुहोस्।';

  @override
  String get streakCalendar => 'पात्रो';

  @override
  String get streakOnFire => 'आज तपाईंको स्ट्रिक उत्कर्ष छ — यसै गरिरहनुहोस्!';

  @override
  String get streakProtect => 'आफ्नो स्ट्रिक जोगाउनुहोस्';

  @override
  String get streakFrozen => 'स्ट्रिक ३० दिनका लागि फ्रिज गरियो!';

  @override
  String get streakCurrent => 'हालको स्ट्रिक';

  @override
  String get streakDaysUnit => 'दिन';

  @override
  String streakBest(Object count) {
    return 'उत्कृष्ट: $count दिन';
  }

  @override
  String get streakMultiplier => 'गुणक';

  @override
  String get streakMaxMultiplier => 'अधिकतम गुणक प्राप्त — किंवदन्ती!';

  @override
  String streakDaysToNextTier(Object current, Object total) {
    return 'अर्को तहसम्म $current / $total दिन';
  }

  @override
  String get streakTiers =>
      '१–६ दिन → १.०× • ७–२९ दिन → १.५× • ३०–९९ दिन → २.०× • १००+ दिन → ३.०×';

  @override
  String get streakFreezeSection => 'स्ट्रिक फ्रिज';

  @override
  String streakFreezeLeft(Object count) {
    return '$count बाँकी';
  }

  @override
  String streakFrozenUntil(Object date) {
    return '$date सम्म फ्रिज';
  }

  @override
  String get streakFreezeHint =>
      'खेल्न नसक्दा ३० दिनका लागि स्ट्रिक फ्रिज गर्न ५० क्विन खर्च्नुहोस्। दानकार ब्याज आवश्यक।';

  @override
  String get streakExtendFreeze => 'फ्रिज थप्नुहोस्';

  @override
  String get streakFreezeAction => 'स्ट्रिक फ्रिज गर्नुहोस् (५० क्विन)';

  @override
  String get streakRepairTitle => 'छुटेको दिन मर्मत गर्नुहोस्';

  @override
  String get streakRepairAction => 'स्ट्रिक मर्मत गर्नुहोस्';

  @override
  String get streakInsurance => 'स्ट्रिक बीमा';

  @override
  String get streakInsuranceChecking => 'बीमा जाँच्दै…';

  @override
  String get streakBuy => 'किन्नुहोस्';

  @override
  String get streakUseNow => 'अहिले प्रयोग गर्नुहोस्';

  @override
  String get streakWager => 'स्ट्रिक वागर';

  @override
  String get streakWagerDescription =>
      'लक्ष्य स्ट्रिक पुग्न क्विन लगाउनुहोस्। पुगेमा ब्याजसहित पुरोट फर्कन्छ, नपुगे क्विन गुम्छ।';

  @override
  String streakWagerDay(Object current, Object total, Object reward) {
    return '$total मध्येको $current दिन — $reward क्विन जित्न खेलिरहनुहोस्।';
  }

  @override
  String get streakWagerStart => 'वागर सुरु गर्नुहोस्';

  @override
  String get streakWagerInProgress => 'वागर चलिरहेको छ';

  @override
  String get streakWagerStartTitle => 'स्ट्रिक वागर सुरु गर्नुहोस्';

  @override
  String get streakWagerStartBody =>
      'दुब्बे जित्न लक्ष्य स्ट्रिक पुग्नुहोस्। नपुगे लगाइएको क्विन गुम्छ।';

  @override
  String get streakWagerStake => 'लगाउने क्विन';

  @override
  String get streakWagerDays => 'कायम राख्ने दिन';

  @override
  String streakXpMultiplier(Object value) {
    return '×$value XP';
  }

  @override
  String streakWagerProgress(Object percent) {
    return '$percent% पूरा';
  }

  @override
  String get streakFreezeDuration => '३० दिन';

  @override
  String streakWagerDaysCount(Object count) {
    return '$count दिन';
  }

  @override
  String streakWagerSummary(Object coins, Object days) {
    return '$days दिनका लागि $coins क्विनको वागर';
  }

  @override
  String get tutorStudyPlan => 'अध्ययन योजना';

  @override
  String get tutorChat => 'कुराकानी';

  @override
  String get tutorPlanTab => 'योजना';

  @override
  String get tutorInsights => 'विश्लेषण';

  @override
  String get tutorRevisions => 'दोहोराइ';

  @override
  String get tutorWeekly => 'साप्ताहिक';

  @override
  String get tutorNoTasksToday => 'आज कुनै काम छैन — भोलि हेर्नुहोस्';

  @override
  String get tutorDone => 'पूरा';

  @override
  String tutorTasksDone(Object done, Object total) {
    return '$done/$total काम';
  }

  @override
  String get tutorDayCompleted => 'दिन पूरा भयो — योजना अद्यावधिक भयो।';

  @override
  String get tutorMarkDayComplete => 'दिन पूरा भएको जनाउनुहोस्';

  @override
  String tutorYourPlan(Object title) {
    return 'तपाईंको योजना — $title';
  }

  @override
  String tutorPlanDays(Object days, Object current) {
    return '$days दिन • हालको $current';
  }

  @override
  String get tutorPlanNoDays =>
      'योजनामा अहिलेसम्म दिन छैनन् — अन onboarding ले बनाउनेछ।';

  @override
  String tutorMoreDays(Object count) {
    return '+ $count थप दिन';
  }

  @override
  String get tutorAdjustPlan => 'योजना मिलाउनुहोस्';

  @override
  String get tutorNoPlanYet => 'अहिलेसम्म कुनै योजना छैन';

  @override
  String get tutorOnboardingRequired =>
      'तपाईंको व्यक्तिगत अध्ययन योजना बनाउन ट्युटर onboarding पूरा गर्नुहोस्।';

  @override
  String get tutorStartOnboarding => 'Onboarding सुरु गर्नुहोस्';

  @override
  String get tutorAdjustExample =>
      'जस्तै, \"म दिनमा ३ घण्टा गर्न सक्छु\" वा \"माटोको यान्त्रिकीमा बढी ध्यान दिन्छु\"';

  @override
  String get tutorAdjustPrompt => 'कसरी मिलाउने?';

  @override
  String get tutorAdjustRequested => 'योजना मिलाउने अनुरोध भयो।';

  @override
  String get tutorSubmit => 'पेश गर्नुहोस्';

  @override
  String get tutorProjectedScore => 'अनुमानित अंक';

  @override
  String tutorConfidence(Object confidence, Object trend) {
    return 'विश्वास $confidence% • $trend';
  }

  @override
  String get tutorWeakAreas => 'कमजोर क्षेत्र';

  @override
  String get tutorNoWeakAreas =>
      'कुनै कमजोर क्षेत्र छैन — उत्कृष्ट काम! तल्कुल तयार रहनुहोस्।';

  @override
  String tutorAccuracy(Object accuracy, Object attempts) {
    return 'शुद्धता $accuracy% • $attempts प्रयास';
  }

  @override
  String get tutorNoRevisionsDue =>
      'कुनै दोहोराइ बाँकी छैन — तपाईं कुशलमा हुनुहुन्छ।';

  @override
  String tutorDueLabel(Object date) {
    return '$date सम्म';
  }

  @override
  String tutorTopicDue(Object topic, Object date) {
    return '$topic • $date सम्म';
  }

  @override
  String get tutorCompleted => 'पूरा भयो';

  @override
  String get tutorOverdue => 'समय बित्यो';

  @override
  String get tutorDue => 'बाकी';

  @override
  String tutorWeekRange(Object start, Object end) {
    return 'हप्ता $start → $end';
  }

  @override
  String get tutorAvgScore => 'औसत अंक';

  @override
  String get tutorHours => 'घण्टा';

  @override
  String tutorCompletion(Object percent) {
    return '$percent% पूरा';
  }

  @override
  String get tutorHighlights => 'मुख्य कुराहरू';

  @override
  String get tutorWeeklyReportPending =>
      'हप्ताको गतिविधि पछि साप्ताहिक प्रतिवेदन देखिन्छ।';

  @override
  String get tutorOnboardingSaved =>
      'Onboarding सुरक्षित भयो — योजना छिट्टै बनाइनेछ।';

  @override
  String get tutorOnboardingTitle => 'ट्युटर Onboarding';

  @override
  String get tutorPersonalised => 'व्यक्तिगत ट्युटर';

  @override
  String get tutorOnboardingExplain =>
      'आफ्नो लक्ष्य बताउनुहोस् — सर्भरले तपाईंको योजना बनाउँछ। user_id चाहिन्छैन (टोकनबाट)।';

  @override
  String tutorSessionLabel(Object session) {
    return 'सत्र: $session';
  }

  @override
  String get tutorYourGoal => 'तपाईंको लक्ष्य';

  @override
  String get tutorGoalExample => 'जस्तै, ६ महिनामा PSC सिभिल क्र्याक गर्ने';

  @override
  String get tutorCurrentLevel => 'हालको तह';

  @override
  String get tutorLevelExample => 'जस्तै: B.E. सिभिल अन्तिम वर्ष';

  @override
  String get tutorHoursPerDay => 'दिनमा घण्टा';

  @override
  String get tutorHoursExample => 'जस्तै: २';

  @override
  String get tutorOnboardingComplete =>
      'Onboarding पूरा भयो — तपाईंको योजना तयार छ।';

  @override
  String get tutorViewPlan => 'योजना हेर्नुहोस्';

  @override
  String get tutorCompleteOnboarding => 'Onboarding पूरा गर्नुहोस्';

  @override
  String get tutorSkipToChat => 'छोड्नुहोस् → ट्युटरसँग कुराकानी';

  @override
  String get tutorSavedToAccount =>
      'तपाईंको खातामा सुरक्षित भयो। जडान बिच्छ भने फेरि प्रयास गर्न सकिन्छ।';

  @override
  String get tutorTitle => 'AI ट्युटर';

  @override
  String get tutorClearChat => 'कुराकानी हटाउनुहोस्';

  @override
  String get tutorNotEnoughHistory =>
      'अहिलेसम्म पर्याप्त इतिहास छैन — व्यक्तिगत बनाउन केही क्विज पूरा गर्नुहोस्।';

  @override
  String get tutorDismiss => 'हटाउनुहोस्';

  @override
  String get tutorWriting =>
      'ट्युटरले आफ्नो जवाफ लेख्दैछ। लामो प्रश्नमा केही समय लाग्न सक्छ।';

  @override
  String get tutorAskAnything => 'केही पनि सोध्नुहोस्';

  @override
  String get tutorChatExplain =>
      'परीक्षाका कन्सेप्ट, बिम डिफ्लेक्सन, माटोको यान्त्रिकी — AI उत्तर Laravel गेटवेबहरूबाट दिन्छ (कहिल्यै सिधै प्रोभाइडरबाट होइन)।';

  @override
  String get tutorExample1 => 'प्रोक्टर कम्प्याक्सन बुझाउनुहोस्';

  @override
  String get tutorExample2 => 'साप्ताहिक योजनामा मद्दत';

  @override
  String get tutorExample3 => 'कमजोर क्षेत्रहरू?';

  @override
  String get tutorTyping => 'ट्युटर लेख्दैछ…';

  @override
  String get tutorInputHint => 'ट्युटरलाई सोध्नुहोस्…';

  @override
  String get aiUsageTitle => 'तपाईंको AI प्रयोग';

  @override
  String get aiUsageOverview => 'समग्र';

  @override
  String get aiUsageRequests => 'अनुरोध';

  @override
  String get aiUsageTokens => 'टोकन';

  @override
  String get aiUsageTutorChats => 'ट्युटर कुराकानी (सबै समय)';

  @override
  String get aiUsageNone => 'यो अवधिमा कुनै AI सुविधा प्रयोग भएको छैन।';

  @override
  String get aiUsageByFeature => 'सुविधाअनुसार';

  @override
  String get aiUsageTutorConversations => 'ट्युटर कुराकानीहरू';

  @override
  String get aiUsageNoConversations => 'अहिलेसम्म कुनै ट्युटर कुराकानी छैन।';

  @override
  String get aiUsageLoadMoreConversations => 'थप कुराकानीहरू हेर्नुहोस्';

  @override
  String get aiUsageWeeklyReport => 'साप्ताहिक प्रतिवेदन';

  @override
  String get aiUsageNoWeeks => 'अहिलेसम्म कुनै साप्ताहिक सारांश सुरक्षित छैन।';

  @override
  String get aiUsageLoadMoreWeeks => 'थप हप्ता हेर्नुहोस्';

  @override
  String aiUsageConversationNumber(Object number) {
    return 'कुराकानी #$number';
  }

  @override
  String aiUsageQuestionNumber(Object number) {
    return 'प्रश्न $number';
  }

  @override
  String aiUsageTurns(Object count) {
    return '$count पटक';
  }

  @override
  String aiUsageWeekOf(Object date) {
    return '$date को हप्ता';
  }

  @override
  String aiUsageWeekSummary(
    Object accuracy,
    Object xp,
    Object coins,
    Object streak,
  ) {
    return '$accuracy% शुद्धता • $xp XP • $coins क्विन • $streak दिन स्ट्रिक';
  }

  @override
  String aiUsageHoursShort(Object hours) {
    return '$hours घ';
  }

  @override
  String get aiKeysTitle => 'तपाईंका AI कुञ्जीहरू';

  @override
  String get aiKeysExplain =>
      'तपाईंको कुञ्जी हाम्रो सर्भरमा इन्क्रिप्टेड हुन्छ र पछि कहिल्यै देखाइँदैन। पछिल्लो चार अक्षर मात्र देखिन्छ।';

  @override
  String get aiKeysAddTitle => 'कुञ्जी थप्नुहोस्';

  @override
  String get aiKeysNoneYet => 'अहिलेसम्म कुनै कुञ्जी छैन';

  @override
  String get aiKeysNoneExplain =>
      'साझा कोटामा होरुनेभन्दा आफ्नै कोटामा AI सुविधाहरू चलाउन प्रोभाइडर कुञ्जी थप्नुहोस्।';

  @override
  String get aiKeysStored => 'सुरक्षित कुञ्जीहरू';

  @override
  String aiKeysTokensUsed(Object used, Object total) {
    return 'दैनिक $total टोकनमध्ये $used प्रयोग भयो';
  }

  @override
  String get aiKeysRevoke => 'रद्द गर्नुहोस्';

  @override
  String get aiKeysTooShort => 'कुञ्जी कम्तीमा ८ अक्षरको हुनुपर्छ';

  @override
  String get aiKeysAddProvider => 'प्रोभाइडर कुञ्जी थप्नुहोस्';

  @override
  String get aiKeysProvider => 'प्रोभाइडर';

  @override
  String get aiKeysApiKey => 'API कुञ्जी';

  @override
  String get aiKeysSentOnce => 'एक पटक पठाइन्छ अनि कहिल्यै देखाइँदैन।';

  @override
  String get aiKeysLabelOptional => 'लेबल (वैकल्पिक)';

  @override
  String get aiKeysSaveKey => 'कुञ्जी सुरक्षित गर्नुहोस्';

  @override
  String aiKeysSaved(Object name) {
    return '$name सुरक्षित भयो। यो हाम्रो सर्भरमा इन्क्रिप्टेड हुन्छ अनि कहिल्यै देखाइँदैन।';
  }

  @override
  String get aiKeysRevoked => 'कुञ्जी रद्द गरियो।';

  @override
  String get practiceBookmarks => 'बुकमार्क';

  @override
  String get practiceWeakTopics => 'कमजोर विषय';

  @override
  String get practiceSelfChallenge => 'आफैँ चुनौती';

  @override
  String get practiceHistory => 'इतिहास';

  @override
  String get practiceNoBookmarks => 'अभ्यास गर्न कुनै बुकमार्क छैन';

  @override
  String get practiceBookmarkedPractice => 'बुकमार्क अभ्यास';

  @override
  String practiceBookmarksUnavailable(Object count, Object total) {
    return '$total मध्ये $count बुकमार्क अभ्यास गर्न सकिएन — सर्भरले तिनका विकल्प अझै प्रकाशित गरेको छैन।';
  }

  @override
  String get practiceDrill => 'अभ्यास ड्रिल';

  @override
  String practiceDrillCount(Object count) {
    return 'ड्रिल: $count';
  }

  @override
  String get practiceNoBookmarksBody => 'कुनै बुकमार्क छैन';

  @override
  String get practiceNoBookmarksHint =>
      'क्विज खेल्दा प्रश्न बुकमार्क गर्नुहोस्, पछि तिनीहरू यहाँ ड्रिलका लागि देखिन्छन्।';

  @override
  String get practiceBrowseQuizzes => 'क्विजहरू हेर्नुहोस्';

  @override
  String practiceBookmarkedCount(Object count) {
    return '$count बुकमार्क';
  }

  @override
  String get practiceAll => 'सबै अभ्यास गर्नुहोस्';

  @override
  String practiceQuestionNumber(Object number) {
    return 'प्रश्न #$number';
  }

  @override
  String practiceQuestionMeta(Object meta, Object difficulty, Object points) {
    return '$meta • कठिनाई $difficulty • $points अंक';
  }

  @override
  String get practiceBookmarked => 'बुकमार्क गरिएको';

  @override
  String get practiceLoadMoreCursor => 'थप हेर्नुहोस् (cursor)';

  @override
  String get practiceWeakTopicsLoadFailed =>
      'तपाईंका कमजोर विषय लोड गर्न सकिएन';

  @override
  String get practiceWeakTopicsExplained =>
      'यी तपाईंको आफ्नै उत्तर इतिहासबाट निकालिएका हुन्। सत्य नभएसम्म केही देखाइँदैन।';

  @override
  String get practiceNoWeakTopics => 'अहिलेसम्म कुनै कमजोर विषय छैन';

  @override
  String get practiceWeakTopicsNeedsAttempts =>
      'कमजोर क्षेत्र पहिचान्न सर्भरलाई अंकयुक्त प्रयास चाहिन्छ। Quiz ट्याबबाट एउटा क्विज खेल्नुहोस् र फेरि हेर्नुहोस्।';

  @override
  String get practiceWeakTopicsServerNote =>
      'कमजोर विषयहरू हाम्रो सर्भरले तपाईंको उत्तर इतिहासबाट निकाल्छ, त्यसैले यहाँ केही अनुमान गरिएको हुँदैन।';

  @override
  String get practiceYourWeakTopics => 'तपाईंका कमजोर विषय';

  @override
  String get practiceDrillAction => 'ड्रिल गर्नुहोस्';

  @override
  String get practiceDrillTen =>
      '१० प्रश्न ड्रिल गर्नुहोस् (अभ्यास मोड, समयसीमा छैन)';

  @override
  String get practiceUntimedNote =>
      'अभ्यासमा समयसीमा छैन र यसले तपाईंको अंक वा क्विन बदल्दैन।';

  @override
  String get practiceSelfChallengeExplain =>
      'प्रश्न संख्या र कठिनाई छान्नुहोस् — Elite Quiz को आफैँ चुनौतीजस्तै, तर अनुकूली इन्जिनबाट।';

  @override
  String practiceQuestionCount(Object count) {
    return 'प्रश्न संख्या: $count';
  }

  @override
  String get practiceDifficulty => 'कठिनाई';

  @override
  String get practiceStarting => 'सुरु हुँदैछ…';

  @override
  String practiceStartChallenge(Object count) {
    return 'चुनौती सुरु गर्नुहोस् ($count प्रश्न)';
  }

  @override
  String get practiceResultsLabelled =>
      'नतिजालाई अभ्यासका रूपमा चिन्हित गरिन्छ, त्यसैले तिनले कहिल्यै अंकमा गनिन्छन्।';

  @override
  String get practiceNoHistory => 'कुनै इतिहास छैन';

  @override
  String get practiceNoHistoryBody =>
      'तपाईंका पूरा भएका अभ्यास सत्रहरू यहाँ देखिन्छन्।';

  @override
  String practiceAttemptMeta(Object number, Object mode) {
    return 'प्रयास #$number • $mode';
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
    return '$meta • अंक $score • $correct✓ $wrong✗ $skipped– • $questions प्रश्न';
  }

  @override
  String get economyInventory => 'सामग्री';

  @override
  String get economyYourResources => 'तपाईंका स्रोतहरू';

  @override
  String economyResourceSummary(Object held, Object catalog, Object recent) {
    return '$held सुरक्षित • $catalog सङ्ग्रह • $recent हालैका';
  }

  @override
  String get economyNoResources => 'अहिलेसम्म कुनै स्रोत छैन';

  @override
  String get economyResourcesExplain =>
      'स्रोतहरू सिटी/अर्थव्यवस्थाको प्रवाह र क्विज पुरस्कारबाट कमाइन्छन्। उपलब्ध भएपछि यहाँ देखिन्छन्।';

  @override
  String get economyCatalog => 'सङ्ग्रह';

  @override
  String get economyCatalogEmpty =>
      'सङ्ग्रह खाली छ — सर्भरले सामग्रीको सूची भर्नेछ।';

  @override
  String get economyRecentActivity => 'हालैका गतिविधि';

  @override
  String get economyNoRecentActivity => 'हालै कुनै गतिविधि छैन।';

  @override
  String get economyDonations => 'दान';

  @override
  String get economyDonationsExplain =>
      'प्रत्यक्ष लिडरबोर्ड र फिड। क्विनले दानकर्ताको स्ट्रिक फ्रिज गर्न सक्छ।';

  @override
  String economyLeaderboardFeed(Object status) {
    return 'लिडरबोर्ड/फिड: $status';
  }

  @override
  String economyStreakMonths(Object name, Object months) {
    return '$name • $months महिनाको स्ट्रिक';
  }

  @override
  String get economyLiveFeed => 'प्रत्यक्ष फिड';

  @override
  String get economyDonationsEmpty => 'दानको लिडरबोर्ड र फिड खाली छन्।';

  @override
  String get economySyncing => 'सिंक हुँदैछ…';

  @override
  String get economyLedger => 'खाता';

  @override
  String get economyLedgerExplain =>
      'दिनअनुसार समूहबद्ध। स्रोतका लेबल credits.description बाट आउँछन् (metadata.source बाट होइन)।';

  @override
  String get economyWhereCoinsWent => 'तपाईंका क्विन कहाँ गए';

  @override
  String economyPeriodSummary(Object days, Object earned, Object spent) {
    return 'गत $days दिन • कमाइ $earned • खर्च $spent';
  }

  @override
  String get economyNoActivity => 'यो अवधिमा कुनै क्विन गतिविधि छैन।';

  @override
  String get economyHowYouEarn => 'तपाईं कसरी कमाउनुहुन्छ';

  @override
  String get economyMintingExplain =>
      'क्विन हरेक अंकयुक्त क्विज र सर्भरका दैनिक कार्यपछि जम्मा हुन्छन्। तिनीहरू यन्त्रमा कहिल्यै बन्दैनन्, त्यसैले तपाईंको ब्यालेन्स बिग्रिँदैन।';

  @override
  String get economyNoTransactions => 'अहिलेसम्म कुनै कारोबार छैन';

  @override
  String get economyNoTransactionsBody =>
      'क्विन कमाउन एउटा क्विज पूरा गर्नुहोस्। हरेक जम्मा हाम्रो सर्भरमा दर्ज हुन्छ।';

  @override
  String get economyTitle => 'अर्थव्यवस्था';

  @override
  String economyXpTotal(Object xp) {
    return 'जम्मा $xp XP';
  }

  @override
  String get economyLiveExplain =>
      'ब्यालेन्स, खाता, शप र स्टोर सबै प्रत्यक्ष छन्। अंकयुक्त प्रयास पूरा भएपछि क्विन सर्भरमा बन्दैनन्।';

  @override
  String get economyWalletTile => 'वालेट - ब्यालेन्स + दिनअनुसार खाता';

  @override
  String get economyWalletTileSub =>
      'ब्यालेन्स, जीवनभरका जम्मा र तपाईंको क्विन इतिहास';

  @override
  String get economyShopTile => 'क्विन शप - स्रोत र बन्डल';

  @override
  String get economyShopTileSub => 'सामग्री र बन्डलमा क्विन खर्च्नुहोस्';

  @override
  String get economyInventoryTile => 'सामग्री - स्रोत + दान';

  @override
  String get economyInventoryTileSub =>
      '८ सामग्री + सङ्ग्रह + प्रत्यक्ष दान फिड/लिडरबोर्ड';

  @override
  String get economyStoreTile => 'प्रिमियम स्टोर - एसेट र स्किन';

  @override
  String get economyStoreTileSub => 'फ्रेम, थिम, ब्याज र अवतार किन्नुहोस्';

  @override
  String get economyWardrobeTile => 'वार्डरोब - लगाउनुहोस्';

  @override
  String get economyWardrobeTileSub =>
      'आफूले भएका एसेट लगाउनुहोस् वा हटाउनुहोस्';

  @override
  String get economyShopTitle => 'क्विन शप';

  @override
  String get economyNothingForSale => 'अहिलेसम्म बिक्रीका लागि केही छैन';

  @override
  String get economyShopEmpty =>
      'सर्भरमा अहिले शपका कुनै वस्तु प्रकाशित छैनन्।';

  @override
  String get economyBundles => 'बन्डल';

  @override
  String get economyMaterials => 'सामग्री';

  @override
  String get economyPurchaseSafe =>
      'खरिद नभए पुनः प्रयास गर्न सुरक्षित छ — दुब्बे तिरोस् हुँदैन।';

  @override
  String economySellsBackFor(Object coins) {
    return '$coins मा फिर्ता बिक्छ';
  }

  @override
  String economySave(Object coins) {
    return '$coins बचत';
  }

  @override
  String libraryUnlockedCoins(Object coins) {
    return 'खुल्यो! खर्च भएको क्विन: $coins';
  }

  @override
  String get libraryDownloadStarted => 'डाउनलोड सुरु भयो — ब्राउजर खुल्दै';

  @override
  String libraryDownloadUrl(Object url) {
    return 'डाउनलोड URL: $url';
  }

  @override
  String get libraryRatingRange => 'रेटिङ १-५ बीच हुनुपर्छ';

  @override
  String get libraryReviewSubmitted => 'समीक्षा पेश भयो';

  @override
  String get libraryAbout => 'बारेमा';

  @override
  String get libraryReviews => 'समीक्षाहरू';

  @override
  String get libraryNoReviews =>
      'अहिलेसम्म कुनै समीक्षा छैन — अनलोक गरेपछि पहिलो समीक्षा गर्नुहोस्!';

  @override
  String get libraryLoadMoreReviews => 'थप समीक्षा हेर्नुहोस्';

  @override
  String get librarySignedUrls =>
      'डाउनलोड URL हस्ताक्षरित र छोटो अवधिका हुन्छन्। डाउनलोड असफल भए फेरि Download थिच्नुहोस्। library-api-download को throttle मान्नुहोस्।';

  @override
  String get libraryFree => 'निःशुल्क';

  @override
  String libraryCoinsLabel(Object count) {
    return '$count क्विन';
  }

  @override
  String get libraryFeatured => 'विशेष';

  @override
  String libraryByUploader(Object name) {
    return '$name द्वारा';
  }

  @override
  String libraryUnlockedFor(Object coins) {
    return 'खुल्यो • $coins क्विन';
  }

  @override
  String get libraryUnlocking => 'खोल्दै…';

  @override
  String get libraryGettingLink => 'लिंक खोज्दै…';

  @override
  String get libraryDownload => 'डाउनलोड';

  @override
  String get libraryUnlockNote =>
      'अनलोक गर्दा तपाईंको क्विन ब्यालेन्सबाट एक पटक मात्र काटिन्छ, पहिलो थिचाइ नभए पनि। डाउनलोड गर्नुअघि फाइल अनलोक गर्नुपर्छ।';

  @override
  String libraryReviewsCount(Object count) {
    return '$count समीक्षा';
  }

  @override
  String get libraryDownloads => 'डाउनलोड';

  @override
  String get libraryAccess => 'पहुँच';

  @override
  String get libraryWriteReview => 'समीक्षा लेख्नुहोस् (पहिले अनलोक गर्नुपर्छ)';

  @override
  String get libraryCommentOptional => 'टिप्पणी (वैकल्पिक)';

  @override
  String get librarySubmitting => 'पेश गर्दै…';

  @override
  String get librarySubmitReview => 'समीक्षा पेश गर्नुहोस्';

  @override
  String get libraryReviewVerified =>
      'तपाईंले फाइल डाउनलोड/अनलोक गरेको भए समीक्षा प्रमाणित हुन्छ।';

  @override
  String get libraryVerified => 'प्रमाणित';

  @override
  String get librarySearchHint => 'फाइल, श्रेणी खोज्नुहोस्…';

  @override
  String libraryTrendingFailed(Object reason) {
    return 'प्रचलित फाइलहरू लोड गर्न सकिएन।\n$reason';
  }

  @override
  String get libraryTrending => 'प्रचलित';

  @override
  String libraryRecommendedFailed(Object reason) {
    return 'तपाईंका सुझावहरू लोड गर्न सकिएन।\n$reason';
  }

  @override
  String get libraryRecommendedForYou => 'तपाईंका लागि सुझाव';

  @override
  String get libraryFiles => 'फाइलहरू';

  @override
  String libraryTotalCount(Object count) {
    return 'जम्मा $count';
  }

  @override
  String get libraryNoFiles => 'अहिलेसम्म कुनै फाइल छैन';

  @override
  String libraryNoResults(Object query) {
    return '\"$query\" का कुनै नतिजा छैन';
  }

  @override
  String get libraryNoFilesBody =>
      'सर्भरमा प्रकाशित र स्वीकृत भएपछि लाइब्रेरीका फाइलहरू यहाँ देखिन्छन्।';

  @override
  String get libraryTryDifferentSearch =>
      'अर्को शब्द खोज्नुहोस् वा फिल्टर हटाउनुहोस्।';

  @override
  String get libraryClearSearch => 'खोजी हटाउनुहोस्';

  @override
  String get libraryNoCategories => 'कुनै श्रेणी प्रकाशित छैन';

  @override
  String get commonLoadMore => 'थप हेर्नुहोस्';

  @override
  String get commonLeaderboard => 'लिडरबोर्ड';

  @override
  String get commonWallet => 'वालेट';

  @override
  String get commonLibrary => 'लाइब्रेरी';

  @override
  String get practiceDrillComplete => 'ड्रिल पूरा भयो';

  @override
  String get practiceDoesNotAffect =>
      'अभ्यास — अंक, XP वा स्ट्रिकलाई असर गर्दैन';

  @override
  String practiceQuestionsCount(Object count) {
    return '$count प्रश्न';
  }

  @override
  String practiceAnsweredSkipped(Object answered, Object skipped) {
    return '$answered उत्तर दिइयो • $skipped छाडियो';
  }

  @override
  String practiceScore(Object score) {
    return 'अंक $score';
  }

  @override
  String get practiceGradedByServer => 'सर्भरद्वारा अंकित';

  @override
  String practiceCorrectWrongSkipped(
    Object correct,
    Object wrong,
    Object skipped,
  ) {
    return '$correct सही • $wrong गलत • $skipped छाडिएको';
  }

  @override
  String practiceGradingFailed(Object reason) {
    return 'सर्भरले यो ड्रिल अंकित गर्न सकेन: $reason';
  }

  @override
  String get practiceReviewPassNote =>
      'यो पुनरावलोकन थियो। कुनै प्रयास बनाइएको छैन, त्यसैले देखाउनुपर्ने अंक छैन।';

  @override
  String get practiceNoQuestionsInSet => 'यस सेटमा कुनै प्रश्न छैन';

  @override
  String practiceQuestionCounter(Object current, Object total) {
    return 'प्रश्न $current/$total';
  }

  @override
  String get practiceUntimedPractice => 'समयसीमा छैन • अभ्यास';

  @override
  String practiceDifficultyLabel(Object difficulty) {
    return 'कठिनाई: $difficulty';
  }

  @override
  String get practiceNoOptionsNotice =>
      'सर्भरले यो प्रश्न विकल्पबिना पठायो, त्यसैले यहाँ ड्रिल गर्न सकिँदैन। अंकयुक्त Quiz ट्याब प्रयास गर्नुहोस्, जसले पूरै सत्र लोड गर्छ।';

  @override
  String get practiceAnswerSentNotice =>
      'उत्तर सर्भरमा पठाइयो। सर्भरले प्रयास अंकित गर्छ — यो स्क्रिनले कहिल्यै अंक अनुमान गर्दैन।';

  @override
  String get practicePrev => 'अघिल्लो';

  @override
  String get practiceGrading => 'अंक गरिँदै…';

  @override
  String get practiceNoEffectNote =>
      'अभ्यासमा समयसीमा छैन र यसले अंक, XP, क्विन वा स्ट्रिकमा कुनै असर गर्दैन।';

  @override
  String get liveEventNotFound => 'प्रत्यक्ष कार्यक्रम भेटिएन';

  @override
  String liveEventParticipant(Object number, Object status, Object score) {
    return 'सहभागी #$number • $status • अंक $score';
  }

  @override
  String get liveEventSnapshot => 'स्न्यापसट';

  @override
  String get liveEventNoSnapshot =>
      'अहिलेसम्म स्न्यापसट छैन — दर्ता गरेर चेक-इन गर्नुहोस्, हालको प्रश्न आउनेछ।';

  @override
  String get liveEventAnswer => 'उत्तर';

  @override
  String get liveEventQIndex => 'प्रश्न क्रमाङ्क';

  @override
  String get liveEventSubmitAnswer => 'उत्तर पेश गर्नुहोस्';

  @override
  String get liveEventNoLeaderboard => 'अहिलेसम्म लिडरबोर्ड छैन।';

  @override
  String get liveEventRegistered => 'दर्ता भयो!';

  @override
  String get liveEventRegisterFailed => 'दर्ता असफल';

  @override
  String get liveEventUnregistered => 'दर्ता रद्द';

  @override
  String get liveEventUnregisterFailed => 'दर्ता रद्द गर्न असफल';

  @override
  String get liveEventCheckedIn => 'चेक-इन भयो!';

  @override
  String get liveEventCheckInFailed => 'चेक-इन असफल';

  @override
  String get liveEventEnterAnswer => 'उत्तर लेख्नुहोस्';

  @override
  String liveEventAnswerRecorded(Object score) {
    return 'उत्तर दर्ता भयो — अंक $score';
  }

  @override
  String liveEventQuestionsEach(Object questions, Object seconds) {
    return '$questions प्रश्न • प्रत्येक ${seconds}s';
  }

  @override
  String liveEventActive(Object count) {
    return '$count सक्रिय';
  }

  @override
  String liveEventWaitlisted(Object count) {
    return '$count प्रतिक्षामा';
  }

  @override
  String liveEventStarts(Object date, Object hour, Object minute) {
    return '$date $hour:$minute मा सुरु';
  }

  @override
  String liveEventEnds(Object date) {
    return '$date मा समाप्त';
  }

  @override
  String liveEventEntryFee(Object coins) {
    return '$coins प्रवेश शुल्क';
  }

  @override
  String liveEventPrize(Object coins) {
    return '$coins पुरस्कार';
  }

  @override
  String get liveEventLeave => 'छोड्नुहोस्';

  @override
  String get liveEventCheckIn => 'चेक-इन';

  @override
  String liveEventScoreMeta(Object score, Object correct, Object total) {
    return 'अंक $score • $correct/$total';
  }

  @override
  String liveEventQuestionPoints(Object number, Object points) {
    return 'प्रश्न$number • $points अंक';
  }

  @override
  String liveEventRemaining(Object seconds, Object locks) {
    return 'बाँकी: ${seconds}s • $locks मा बन्द';
  }

  @override
  String get liveEventWaitingForHost => 'हालको प्रश्न छैन — आयोजकको प्रतीक्षा।';

  @override
  String liveEventRawKeys(Object keys) {
    return 'कच्चा कुञ्जी: $keys';
  }

  @override
  String get coachingTutorChat => 'ट्युटर कुराकानी';

  @override
  String get coachingStudyPlan => 'अध्ययन योजना';

  @override
  String get coachingTutorOnboarding => 'ट्युटर onboarding';

  @override
  String get coachingGoalIdHint => 'तयारीका लागि Goal ID (जस्तै: psc-civil)';

  @override
  String get coachingLoad => 'लोड गर्नुहोस्';

  @override
  String get coachingNoData =>
      'अहिलेसम्म कुनै कोचिङ डाटा छैन — onboarding पूरा गर्नुहोस् वा ट्युटरसँग कुराकानी गर्नुहोस्।';

  @override
  String get coachingPartial =>
      'केही कोचिङ स्क्रिन अस्थायी रूपमा उपलब्ध छैनन् — उपलब्ध डाटा देखाइदैछौं।';

  @override
  String get coachingNoReadinessForGoal =>
      'तयारी: यो लक्ष्यका लागि अहिलेसम्म डाटा छैन।';

  @override
  String get coachingAskTutor => 'ट्युटरलाई सोध्नुहोस्';

  @override
  String get coachingOnboarding => 'Onboarding';

  @override
  String get coachingReadinessExplained =>
      'तयारी तपाईंका लक्ष्य, ट्र्याक र ट्युटर गतिविधिबाट निकालिन्छ। केही खण्ड प्रयोग नगरेसम्म लुकाइन्छन्।';

  @override
  String get coachingReadiness => 'तयारी';

  @override
  String get coachingFocusNext => 'अर्को केन्द्रमा:';

  @override
  String get coachingNoReadiness =>
      'अहिलेसम्म तयारी छैन — यो लक्ष्य अन्तर्गत केही क्विज खेल्नुहोस्।';

  @override
  String coachingGoalLabel(Object goal) {
    return 'लक्ष्य $goal';
  }

  @override
  String coachingMore(Object count) {
    return '+ $count थप';
  }

  @override
  String get coachingNoTasksToday => 'आज कुनै काम छैन';

  @override
  String coachingConfidence(Object confidence) {
    return 'विश्वास $confidence%';
  }

  @override
  String get coachingLearningTracks => 'सिकाइका ट्र्याक';

  @override
  String get coachingThisWeek => 'यो हप्ता';

  @override
  String coachingWeekTasks(Object done, Object total, Object average) {
    return '$done/$total काम • औसत $average';
  }

  @override
  String get coachingNoRevisions => 'कुनै दोहोराइ बाँकी छैन';

  @override
  String coachingRevisionsDue(Object count) {
    return '$count दोहोराइ बाँकी';
  }

  @override
  String get socialInviteFriends => 'साथीहरूलाई आमन्त्रित गर्नुहोस्';

  @override
  String get socialReferralUnavailable => 'रेफरल जानकारी अहिले उपलब्ध छैन।';

  @override
  String socialEarnCoins(Object coins) {
    return '$coins क्विन कमाउनुहोस्';
  }

  @override
  String get socialNo => 'होइन';

  @override
  String get socialYourInviteCode => 'तपाईंको निमन्त्रणा कोड';

  @override
  String get socialShareInviteLink => 'निमन्त्रणा लिंक साझेदार गर्नुहोस्';

  @override
  String get socialCopyCode => 'कोड प्रतिलिपि गर्नुहोस्';

  @override
  String get socialRewards => 'पुरस्कार';

  @override
  String get socialRewardPerSignup =>
      'दर्ता गर्ने हरेक साथीका लागि तपाईंले कमाउनुहुन्छ';

  @override
  String get socialTheyEarn => 'दर्ता गर्दा उनले पनि कमाउँछन्';

  @override
  String get socialBonusFirstQuiz => 'उनको पहिलो क्विज पूरा भएपछि बोनस';

  @override
  String get socialYourReferrals => 'तपाईंका रेफरल';

  @override
  String get socialInvited => 'आमन्त्रित';

  @override
  String get socialRewarded => 'पुरस्कृत';

  @override
  String get socialCoinsEarned => 'क्विन कमाए';

  @override
  String get socialNoReferralsYet =>
      'अहिलेसम्म कसैले तपाईंको कोड प्रयोग गरेको छैन।';

  @override
  String socialRewardPaid(Object coins) {
    return 'पुरस्कार भुक्तानी: $coins क्विन';
  }

  @override
  String socialStatus(Object status) {
    return 'स्थिति: $status';
  }

  @override
  String get socialGotCode => 'साथीबाट कोड पाउनुभयो?';

  @override
  String get socialReferralCode => 'रेफरल कोड';

  @override
  String get socialApplyCode => 'कोड लागू गर्नुहोस्';

  @override
  String get socialShareSheetFailed => 'साझेदारी पत्रक खोल्न सकिएन';

  @override
  String get socialCodeCopied => 'कोड प्रतिलिपि भयो';

  @override
  String get socialSharedChallenge => 'साझेदार चुनौती';

  @override
  String get socialSomeoneShared => 'कसैले तपाईंसँग चुनौती साझेदार गर्यो';

  @override
  String socialSharedBy(Object name) {
    return '$name ले साझेदार गर्यो';
  }

  @override
  String get socialLinkExpired => 'यो लिंकको म्याद सकियो।';

  @override
  String get socialNoPlayableChallenge => 'यहाँ खेल्न मिल्ने चुनौती छैन';

  @override
  String get socialNotPlayable =>
      'यो लिंकले खेल्न मिल्ने चुनौती दिँदैन। तपाईं सार्वजनिक सङ्ग्रह हेर्न सक्नुहुन्छ।';

  @override
  String get socialPlayChallenge => 'चुनौती खेल्नुहोस्';

  @override
  String get socialGuestNeverAwards =>
      'अतिथिको चुनौतीले कहिल्यै क्विन, XP वा स्ट्रिक दिँदैन। आफ्नो प्रगति राख्न निःशुल्क खाता खोल्नुहोस्।';

  @override
  String get socialChallengeNoQuestions => 'यो चुनौतीमा कुनै प्रश्न छैन';

  @override
  String get socialChallengeEmpty =>
      'सर्भरले कुनै प्रश्न नपठाई प्रयास सुरु गर्‍यो, त्यसैले खेल्नुपर्ने केही छैन।';

  @override
  String socialQuestionOf(Object current, Object total) {
    return '$total मध्येको $current प्रश्न';
  }

  @override
  String get socialCorrect => 'सही।';

  @override
  String get socialNotThisTime => 'यो पटक होइन — सर्भरले यसरी चिन्हित गरेको छ।';

  @override
  String get socialSubmitAnswer => 'उत्तर पेश गर्नुहोस्';

  @override
  String get socialFinish => 'समाप्त';

  @override
  String get socialNext => 'अर्को';

  @override
  String get socialChallengeComplete => 'चुनौती पूरा भयो';

  @override
  String socialYouScored(Object score) {
    return 'तपाईंले $score अंक गर्नुभयो';
  }

  @override
  String socialChallengeSummary(
    Object correct,
    Object wrong,
    Object skipped,
    Object questions,
  ) {
    return '$correct सही • $wrong गलत • $skipped छाडिएको • $questions प्रश्न';
  }

  @override
  String get socialGuestChallengeNote =>
      'अतिथिको चुनौतीले कहिल्यै क्विन, XP वा स्ट्रिक दिँदैन।';

  @override
  String socialNiceOne(Object name) {
    return 'राम्रो — यो $name को चुनौती थियो। अतिथिको चुनौतीले कहिल्यै क्विन, XP वा स्ट्रिक दिँदैन।';
  }

  @override
  String get socialCreateAccount => 'निःशुल्क खाता खोल्नुहोस्';

  @override
  String get socialBrowseSamples => 'नमुना प्रश्नहरू हेर्नुहोस्';

  @override
  String get contestNotFound => 'प्रतियोगिता भेटिएन';

  @override
  String contestAttemptStarted(Object number, Object expires) {
    return 'प्रयास #$number सुरु भयो। म्याद: $expires';
  }

  @override
  String get contestNoLeaderboard =>
      'अहिलेसम्म लिडरबोर्डमा कुनै प्रविष्टि छैन — पहिलो बन्नुहोस्!';

  @override
  String contestGeneratedMeta(Object generated, Object budget, Object mode) {
    return 'बनाइएको: $generated • ताजा बनाउने बजट: $budget • $mode';
  }

  @override
  String get contestRecap => 'समीक्षा';

  @override
  String get contestWinners => 'विजेता';

  @override
  String contestRawStats(Object count) {
    return 'कच्चा तथ्य: $count कुञ्जी';
  }

  @override
  String get contestRecapPending => 'प्रतियोगिता सकिएपछि समीक्षा उपलब्ध हुन्छ।';

  @override
  String get contestJoined => 'प्रतियोगितामा सामेल भयो!';

  @override
  String get contestJoinFailed => 'सामेल हुन असफल';

  @override
  String get contestLeft => 'प्रतियोगिता छोडियो';

  @override
  String get contestLeaveFailed => 'छोड्न असफल';

  @override
  String get contestRegisteredBadge => 'दर्ता भयो';

  @override
  String contestMax(Object count) {
    return 'बढीमा $count';
  }

  @override
  String contestStarts(Object date) {
    return '$date मा सुरु';
  }

  @override
  String get contestJoinFree => 'सामेल हुनुहोस् (निःशुल्क)';

  @override
  String contestJoinCoins(Object coins) {
    return 'सामेल हुनुहोस् ($coins क्विन)';
  }

  @override
  String get contestEnter => 'प्रतियोगितामा सामेल हुनुहोस्';

  @override
  String get leaderboardGlobal => 'विश्व';

  @override
  String get leaderboardFriends => 'साथी';

  @override
  String get leaderboardLeague => 'लिग';

  @override
  String get leaderboardDonors => 'दानकर्ता';

  @override
  String get leaderboardNoRank =>
      'अहिलेसम्म कुनो अंक छैन — लिडरबोर्डमा पर्न एउटा क्विज पूरा गर्नुहोस्।';

  @override
  String get leaderboardMyRank => 'मेरो अंक';

  @override
  String leaderboardRankIn(Object rank, Object scope) {
    return '$scope मा #$rank';
  }

  @override
  String leaderboardUnrankedIn(Object scope) {
    return '$scope मा अंक छैन';
  }

  @override
  String leaderboardScore(Object score) {
    return 'अंक: $score';
  }

  @override
  String get leaderboardNoEntries => 'अहिलेसम्म कुनै प्रविष्टि छैन';

  @override
  String get leaderboardBeFirst => 'पहिलो स्थान ओगट्ने पहिलो बन्नुहोस्!';

  @override
  String get leaderboardFriendsHint =>
      'प्रतिस्पर्धाका लागि साथी थप्नुहोस् — सर्भरले साथीहरू आफैँ छुट्याउँछ।';

  @override
  String get leaderboardLeagueHint =>
      'लिग मौसमिक हो — योग्य हुन कार्यक्रम/प्रतियोगितामा सामेल हुनुहोस्।';

  @override
  String get leaderboardNoEntriesShort => 'कुनै प्रविष्टि छैन';

  @override
  String get leaderboardCompeteToAppear => 'यहाँ देखिन प्रतिस्पर्धा गर्नुहोस्।';

  @override
  String get leaderboardNoDonors => 'अहिलेसम्म कुनै दानकर्ता छैन';

  @override
  String get leaderboardSupportToAppear =>
      'यहाँ देखिन प्लेटफर्म सहयोग गर्नुहोस्।';

  @override
  String leaderboardScoreAttempts(Object score, Object attempts) {
    return 'अंक $score • $attempts प्रयास';
  }

  @override
  String learningGoalLabel(Object number) {
    return 'लक्ष्य #$number';
  }

  @override
  String get learningToday => 'आज';

  @override
  String get learningGoalId => 'लक्ष्य ID';

  @override
  String get learningTrackId => 'ट्र्याक ID';

  @override
  String get learningTargetDate => 'लक्ष्य मिति';

  @override
  String get learningDailyMinutes => 'दैनिक मिनेट';

  @override
  String get learningIntensity => 'तीव्रता';

  @override
  String get learningPlacement => 'स्थान';

  @override
  String learningMastery(Object percent, Object topics) {
    return '$topics विषयमा $percent% दक्षता (MasteryService::computeReadiness)';
  }

  @override
  String learningReadinessValue(Object value) {
    return 'तयारी: $value';
  }

  @override
  String get learningDeleteGoalTitle => 'लक्ष्य मेटाउने?';

  @override
  String get learningDeleteGoalBody =>
      'यसले लक्ष्य स्थायी रूपमा मेटाउँछ। दैनिक योजनाहरू रहन्छन् तर नयाँ योजना बनाइँदैन।';

  @override
  String get learningGoalDeleted => 'लक्ष्य मेटाइयो';

  @override
  String get learningDeleting => 'मेटाउँदै…';

  @override
  String get learningDeleteGoal => 'लक्ष्य मेटाउनुहोस्';

  @override
  String get learningOpenTodayPlan => 'आजको योजना खोल्नुहोस्';

  @override
  String get learningBackToTracks => 'ट्र्याकमा फर्कनुहोस्';

  @override
  String get learningTodaysPlan => 'आजको योजना';

  @override
  String get learningNoActiveGoal => 'कुनै सक्रिय लक्ष्य छैन';

  @override
  String get learningNoActiveGoalBody =>
      'आजको योजना पाउन Tracks बाट सिकाइको लक्ष्य बनाउनुहोस्। पहिले नै भए यहाँ देखिन्छ।';

  @override
  String get learningBrowseTracks => 'ट्र्याकहरू हेर्नुहोस्';

  @override
  String learningPlanLabel(Object number) {
    return 'योजना #$number';
  }

  @override
  String learningPlanGoal(Object meta, Object number) {
    return '$meta • लक्ष्य #$number';
  }

  @override
  String learningCompletedCount(Object done, Object total) {
    return '$done/$total पूरा';
  }

  @override
  String learningMinBudget(Object minutes) {
    return '$minutes मिनेट बजट';
  }

  @override
  String get learningNoTasksBody =>
      'भोलि हेर्नुहोस् — दैनिक स्वचालनले दोहोराइ-पहिले + नयाँ विषय बनाउँछ।';

  @override
  String learningMinutes(Object minutes) {
    return '$minutes मिनेट';
  }

  @override
  String get learningItemCompleted => 'काम पूरा भयो';

  @override
  String get learningReviewsDue => 'दोहोराइ बाँकी';

  @override
  String get learningTitle => 'सिकाइ';

  @override
  String get learningReviewsCountFailed =>
      'तपाईंका दोहोराइको संख्या लोड गर्न सकिएन';

  @override
  String get learningTracks => 'ट्र्याक';

  @override
  String get learningNoTracks =>
      'अहिलेसम्म कुनै ट्र्याक छैन — हाम्रो टोलीले तयार भएपछि प्रकाशित गर्छ';

  @override
  String get learningAskAiTutor => 'AI ट्युटरलाई सोध्नुहोस्';

  @override
  String get learningStreamingNote =>
      'उत्तर एकैपटक होइन, बिस्तारै आउँछन्, त्यसैले तपाईं तुरुन्तै पढ्न सक्नुहुन्छ।';

  @override
  String get learningNoTasks => 'कुनै काम छैन — भोलि हेर्नुहोस्';

  @override
  String learningReviewsDueSrs(Object count) {
    return '$count दोहोराइ बाँकी (SRS)';
  }

  @override
  String get learningReviewAction => 'दोहोराउनुहोस्';

  @override
  String learningGoalCreatedForTrack(Object number) {
    return 'ट्र्याक #$number का लागि लक्ष्य बनाइयो';
  }

  @override
  String get learningTracksTitle => 'सिकाइका ट्र्याक';

  @override
  String get learningTodayPlan => 'आजको योजना';

  @override
  String learningNodesCount(Object count) {
    return '$count नोड';
  }

  @override
  String learningGoalsCount(Object count) {
    return '$count लक्ष्य';
  }

  @override
  String get learningCreating => 'बनाउँदै…';

  @override
  String get learningCreateGoal => 'लक्ष्य बनाउनुहोस्';

  @override
  String get learningReviewsDueTitle => 'दोहोराइ बाँकी';

  @override
  String get learningAllCaughtUp =>
      'तपाईं सबै पूरा गर्नुभयो! नयाँ कण सिकाएपछि FSRS ले अर्को दोहोराइ तोक्नेछ।';

  @override
  String learningReviewMeta(Object number, Object atom, Object state) {
    return 'दोहोराइ #$number • कण $atom • $state';
  }

  @override
  String learningInterval(Object index) {
    return 'I$index';
  }

  @override
  String learningDueDate(Object date) {
    return '$date सम्म';
  }

  @override
  String learningLapses(Object count) {
    return '$count पटक छुटे';
  }

  @override
  String get learningGradeAgain => 'फेरि';

  @override
  String get learningGradeHard => 'गाह्रो';

  @override
  String get learningGradeGood => 'राम्रो';

  @override
  String get learningGradeEasy => 'सजिलो';

  @override
  String get learningGradingNote =>
      'अंक सुरक्षित रूपमा दर्ता हुन्छ अनि अर्को दोहोराइको मिति तपाईंका लागि निकालिन्छ। दुई पटक थिचे पनि प्रगति हराइँदैन।';

  @override
  String get syllabusTitle => 'पाठ्यक्रम';

  @override
  String get syllabusNoNodes =>
      'यो पाठ्यक्रममा अहिलेसम्म कुनै नोड प्रकाशित छैन।';

  @override
  String get syllabusExaminable => 'परीक्षामा';

  @override
  String get syllabusQuestions => 'प्रश्न';

  @override
  String get syllabusPaperBlueprint => 'प्रश्नपत्रको ढाँचा';

  @override
  String syllabusPapersCount(Object count) {
    return '$count प्रश्नपत्र';
  }

  @override
  String syllabusMarksQuestions(Object marks, Object questions) {
    return '$marks अंक · $questions प्रश्न';
  }

  @override
  String syllabusNegativeMarking(Object mode) {
    return 'नकारात्मक अंक: $mode';
  }

  @override
  String syllabusMarks(Object marks) {
    return '$marks अंक';
  }

  @override
  String get syllabusBlueprintMismatch =>
      'खण्डका अंकहरू प्रश्नपत्रको कुलसँग बराबर छैनन्। यो ढाँचलाई प्रमाणित नमुनेर लिनुहोस्।';

  @override
  String syllabusCoversTopics(Object count) {
    return '$count पाठ्यक्रम विषय ओगट्छ';
  }

  @override
  String get syllabusSearchTopics => 'विषय खोज्नुहोस्';

  @override
  String get syllabusNoPublished =>
      'अहिलेसम्म कुनै पाठ्यक्रम प्रकाशित भएको छैन।';

  @override
  String syllabusTopicsCount(Object count) {
    return '$count विषय';
  }

  @override
  String get syllabusNotCurrent => 'हालकै होइन';

  @override
  String get booksTitle => 'पुस्तकहरू';

  @override
  String get booksSearch => 'पुस्तक खोज्नुहोस्';

  @override
  String get booksNonePublished => 'अहिलेसम्म कुनै पुस्तक प्रकाशित भएको छैन।';

  @override
  String booksNoMatch(Object query) {
    return '\"$query\" सँग मिल्ने कुनै पुस्तक छैन।';
  }

  @override
  String booksProgress(Object percent, Object page) {
    return '$percent% · पृष्ठ $page';
  }

  @override
  String get booksChapters => 'अध्यायहरू';

  @override
  String get booksNoChapters => 'अहिलेसम्म कुनै अध्याय प्रकाशित भएको छैन।';

  @override
  String get booksChapterTest => 'अध्यायको परीक्षा';

  @override
  String get booksReadChapter => 'अध्याय पढ्नुहोस्';

  @override
  String booksTakeTest(Object count) {
    return 'परीक्षा दिनुहोस् ($count)';
  }

  @override
  String get booksNoTopics =>
      'यो अध्यायमा अहिलेसम्म खोल्नुपर्ने कुनै विषय छैन।';

  @override
  String get downloadsClearTitle => 'अफलाइन सामग्री मेटाउने?';

  @override
  String get downloadsClearBody =>
      'यसले क्यास गरिएका सबै प्रश्न हटाउँछ। इन्टरनेट भएको बेला जुनसुकै बेला पुनः डाउनलोड गर्न सकिन्छ।';

  @override
  String get downloadsClear => 'हटाउनुहोस्';

  @override
  String get downloadsStorageUnreadable => 'अफलाइन भण्डारण पढ्न सकिएन';

  @override
  String get downloadsNothingReported =>
      'झुटो शून्य देखाउनेभन्दा केही पनि देखाइँदैन।';

  @override
  String downloadsCachedQuestions(Object count) {
    return '$count प्रश्न क्यास भयो';
  }

  @override
  String downloadsCacheSize(Object subjects, Object size) {
    return '$subjects विषय · ~$size KB';
  }

  @override
  String get downloadsLastCached => 'अन्तिम क्यास';

  @override
  String get downloadsAutoDownload => 'स्वतः डाउनलोड';

  @override
  String get downloadsPrefetchNow => 'दैनिक प्याक अहिले नै ल्याउनुहोस्';

  @override
  String get downloadsClearAction => 'अफलाइन सामग्री मेटाउनुहोस्';

  @override
  String get rewardsSpinWheel => 'चक्र घुमाउनुहोस्';

  @override
  String get rewardsCheckInUnavailable => 'चेक-इन उपलब्ध छैन';

  @override
  String get rewardsDailyCheckIn => 'दैनिक चेक-इन';

  @override
  String rewardsDayStreak(Object count) {
    return '$count दिन';
  }

  @override
  String get rewardsToday => 'आज';

  @override
  String get rewardsTomorrow => 'भोलि';

  @override
  String get rewardsClaimedToday => 'आज दावी गरियो';

  @override
  String rewardsCheckInFor(Object coins) {
    return '$coins क्विनका लागि चेक-इन गर्नुहोस्';
  }

  @override
  String get rewardsSpinUnavailable => 'चक्र उपलब्ध छैन';

  @override
  String get rewardsSpin => 'घुमाउनुहोस्';

  @override
  String get rewardsComeBackLater => 'पछि आउनुहोस्';

  @override
  String rewardsNextSpin(Object date) {
    return 'अर्को पटक $date';
  }

  @override
  String gameLevelLabel(Object number) {
    return 'तह $number';
  }

  @override
  String get gameBossLevel => 'बड तह';

  @override
  String get gameChapterLevel => 'अध्याय तह';

  @override
  String gameSecondsPerQuestion(Object seconds) {
    return 'प्रति प्रश्न ${seconds}s';
  }

  @override
  String get gameBestScore => 'उत्कृष्ट अंक';

  @override
  String get gameBestAccuracy => 'उत्कृष्ट शुद्धता';

  @override
  String get gameBestTime => 'उत्कृष्ट समय';

  @override
  String get gameStartLevel => 'तह सुरु गर्नुहोस्';

  @override
  String get gameNotPlayable => 'अहिले खेल्न मिल्दैन';

  @override
  String get gameWorldNoCourse =>
      'यो वर्ल्डसँग अहिलेसम्म कुनै क्विज कोर्स जोडिएको छैन, त्यसैले खेल्नुपर्ने केही छैन। प्रशासकलाई वर्ल्डको कोर्स सेट गर्न भन्नुहोस्।';

  @override
  String get gameWorldsTitle => 'वर्ल्डहरू';

  @override
  String get gameWorldsLoadFailed => 'वर्ल्डहरू लोड गर्न सकिएन';

  @override
  String get gameNoWorlds => 'अहिलेसम्म कुनै वर्ल्ड छैन';

  @override
  String get gameNoWorldsBody =>
      'सर्भरले अहिलेसम्म कुनै वर्ल्ड प्रकाशित गरेको छैन।';

  @override
  String get gameNeedsSubscription => 'सदस्यता योजना चाहिन्छ।';

  @override
  String get gameWorldNotFound => 'वर्ल्ड भेटिएन';

  @override
  String gameStarsProgress(Object earned, Object total) {
    return '$earned / $total स्टार';
  }

  @override
  String get gameWorldMapFailed => 'वर्ल्ड नक्सा लोड गर्न सकिएन';

  @override
  String get gameMissionsTitle => 'मिसन';

  @override
  String get gameMissionsFailed => 'मिसनहरू लोड गर्न सकिएन';

  @override
  String get gameNoMissions => 'अहिलेसम्म कुनै मिसन छैन';

  @override
  String get gameNoMissionsBody =>
      'सर्भरले तपाईंका लागि कुनै मिसन प्रकाशित गरेको छैन।';

  @override
  String get gameClaimAll => 'सबै दावी गर्नुहोस्';

  @override
  String gameClaimCoins(Object coins) {
    return '$coins क्विन दावी गर्नुहोस्';
  }

  @override
  String get gameClaimed => 'दावी गरियो';

  @override
  String get numericalsTitle => 'सङ्ख्यात्मक';

  @override
  String get numericalsNew => 'नयाँ सङ्ख्या';

  @override
  String get numericalsCheck => 'उत्तर जाँच्नुहोस्';

  @override
  String get numericalsShowSolution => 'चरणबद्ध समाधान हेर्नुहोस्';

  @override
  String numericalsCorrect(Object reason) {
    return 'सही$reason';
  }

  @override
  String get numericalsNotCorrect =>
      'गलत छ। फेरि प्रयास गर्नुहोस्, वा चरणबद्ध समाधान हेर्नुहोस्।';

  @override
  String get numericalsFlagged =>
      'सर्भरले यो प्रश्न पुनरावलोकनका लागि चिन्हित गरेको छ।';

  @override
  String get numericalsWorkedSolution => 'चरणबद्ध समाधान';

  @override
  String numericalsComputedBy(Object source) {
    return 'गणना गर्ने: $source';
  }

  @override
  String get numericalsFlaggedWarning =>
      'सर्भरले पुनरावलोकनका लागि चिन्हित गरेको छ — यो उत्तर सावधानीले हेर्नुहोस्।';

  @override
  String get numericalsOpenInCalculator => 'क्यालकुलेटरमा खोल्नुहोस्';

  @override
  String get storeEquipped => 'लगाइयो!';

  @override
  String get storeEquipFailed => 'त्यो वस्तु लगाउन सकिएन।';

  @override
  String get storeWardrobeTitle => 'वार्डरोब';

  @override
  String get storeEquippedLabel => 'लगाइएको';

  @override
  String get storeNothingEquipped => 'केही पनि लगाइएको छैन';

  @override
  String get storeNothingEquippedBody =>
      'प्रिमियम स्टोरबाट एसेट किन्नुहोस्, अनि यहाँ लगाउनुहोस्।';

  @override
  String get storeAvailableToEquip => 'लगाउन मिल्ने';

  @override
  String get storeEquipHint =>
      'लगाउन Equip थिच्नुहोस्। दुई पटक थिचे पनि दुई पटक लगाइँदैन।';

  @override
  String get storeNoAssets =>
      'अहिलेसम्म कुनै एसेट छैन — प्रिमियम स्टोर हेर्नुहोस्।';

  @override
  String storeClearSlot(Object slot) {
    return '$slot हटाउनुहोस्';
  }

  @override
  String get storeTitle => 'प्रिमियम स्टोर';

  @override
  String get storeAll => 'सबै';

  @override
  String storeAssetsCount(Object count) {
    return '$count एसेट';
  }

  @override
  String get storeNoAssetsInCategory => 'यस श्रेणीमा कुनै एसेट छैन।';

  @override
  String get storeTrading => 'व्यापार';

  @override
  String get storeTradingExplain =>
      'क्विनबाट स्रोत र बन्डल किन्नुहोस्, वा अब चाहिएको वस्तु बेच्नुहोस्।';

  @override
  String get storeCoinShop => 'क्विन शप';

  @override
  String get storeSellItems => 'वस्तु बेच्नुहोस्';

  @override
  String get storeOwnedBadge => 'आफूले भएको';

  @override
  String get storeOwned => 'आफ्नो';

  @override
  String get storeEmptyEquip => 'खाली — स्टोरबाट लगाउनुहोस्';

  @override
  String get eiceTitle => 'परीक्षा बुद्धि';

  @override
  String get eiceExplain =>
      'यहाँ भएको सबै कुरा तपाईंको वास्तविक उत्तर इतिहासबाट हाम्रो सर्भरमा निकालिन्छ, त्यसैले सत्य नभएसम्म केही देखाइँदैन।';

  @override
  String get eiceCoach => 'कोच — तपाईंको योजना';

  @override
  String get eiceSprint => 'स्प्रिन्ट — ७ दिनेको दोहोराइ क्यु';

  @override
  String get eiceWeeklyReport => 'साप्ताहिक प्रतिवेदन';

  @override
  String get eiceTriage => 'त्रायज — ओगट्ने वा छाड्ने';

  @override
  String get battleArena => 'ब्याटल रिङ';

  @override
  String get battleNoActiveMatch => 'कुनै सक्रिय म्याच छैन';

  @override
  String get battleFindMatch => 'म्याच खोज्नुहोस्';

  @override
  String get battleNoQuestions => 'यो म्याचमा कुनै प्रश्न छैन';

  @override
  String battleQuestionCounter(Object current, Object total) {
    return 'ब्याटल · प्रश्न$current/$total';
  }

  @override
  String get battleOpponentAnswered => 'प्रतिद्वन्द्वीले उत्तर दियो!';

  @override
  String get battleResultTitle => 'ब्याटल नतिजा';

  @override
  String get battleNoMatchToDisplay => 'देखाउनुपर्ने कुनै म्याच छैन';

  @override
  String get battleVs => 'विरुद्ध';

  @override
  String get battleRematch => 'पुनः भिडन्त';

  @override
  String get battleYou => 'तपाईं';

  @override
  String get liveEventsTitle => 'प्रत्यक्ष कार्यक्रम';

  @override
  String get liveEventsNone => 'कुनै प्रत्यक्ष कार्यक्रम छैन';

  @override
  String get liveEventsNoneBody =>
      'तोकिएका र प्रत्यक्ष कार्यक्रमहरू यहाँ देखिन्छन्।';

  @override
  String get notificationsTitle => 'सूचनाहरू';

  @override
  String get notificationsMarkAllRead => 'सबै पढियो भनी जनाउनुहोस्';

  @override
  String get notificationsNone => 'कुनै सूचना छैन';

  @override
  String get notificationsNoneBody => 'अहिले नयाँ केही छैन।';

  @override
  String get notificationsLoadFailed => 'सूचनाहरू लोड गर्न सकिएन';

  @override
  String get notificationsMarkFailed =>
      'त्यसलाई पढियो जनाउन सकिएन। फेरि प्रयास गर्नुहोस्।';

  @override
  String get notificationsMarkAllFailed => 'सबैलाई पढियो जनाउन सकिएन।';

  @override
  String get coursesLoadFailed => 'कोर्सहरू लोड गर्न सकिएन। जडान जाँच्नुहोस्।';

  @override
  String get coursesNone => 'कुनै कोर्स उपलब्ध छैन';

  @override
  String get coursesNoneBody =>
      'सिभिल इन्जिनियरिङका पाठ्यक्रम प्रकाशित भएपछि यहाँ देखिन्छन्।';

  @override
  String coursesTracksCount(Object count) {
    return '$count पाठ्यक्रम ट्र्याक';
  }

  @override
  String get coursesBrowseQuestions => 'प्रश्नहरू हेर्नुहोस्';

  @override
  String get pscTitle => 'PSC / लोकसेवा';

  @override
  String pscBlueprintsFailed(Object reason) {
    return 'PSC का ढाँचा लोड गर्न सकिएन।\n$reason';
  }

  @override
  String get pscNoBlueprints =>
      'अहिलेसम्म कुनै ढाँचा प्रकाशित छैन। तान्नुहोस् र फेरि प्रयास गर्नुहोस्।';

  @override
  String pscBlueprintMeta(Object id, Object questions) {
    return 'id: $id • $questions प्रश्न';
  }

  @override
  String get pscStartFailed => 'परीक्षा सुरु असफल (अफलाइन वा 404)';

  @override
  String pscStarted(Object id) {
    return 'परीक्षा सुरु भयो: $id';
  }

  @override
  String get achievementsBadges => 'ब्याज';

  @override
  String achievementsFailed(Object reason) {
    return 'उपलब्धि लोड गर्न सकिएन: $reason';
  }

  @override
  String get achievementsNone =>
      'अहिलेसम्म कुनै उपलब्धि छैन — क्विज खेल्न सुरु गर्नुहोस्!';

  @override
  String get searchTitle => 'खोज';

  @override
  String get searchHint => 'प्रश्न, क्यालकुलेटर, कोर्स खोज्नुहोस्…';

  @override
  String get searchTry => 'जस्तै: levelling, RCC, Bernoulli';

  @override
  String get searchNoResults => 'कुनै नतिजा छैन';

  @override
  String searchFailed(Object reason) {
    return 'खोज असफल: $reason';
  }

  @override
  String xpLevelLabel(Object level) {
    return 'तह $level';
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
    return 'अर्को तहसम्म $amount';
  }

  @override
  String xpDayStreak(Object count) {
    return '$count दिनको स्ट्रिक';
  }

  @override
  String get lottieOverlay => 'lottie-overlay';

  @override
  String get lottieTapToDismiss => 'हटाउन थिच्नुहोस्';

  @override
  String lifelineCost(Object name, Object coins) {
    return '$name lifeline, $coins क्विन';
  }

  @override
  String lifelineUnavailable(Object name, Object reason) {
    return '$name lifeline उपलब्ध छैन: $reason';
  }

  @override
  String get offlineCannotReach =>
      'हाम्रो सर्भरसम्म पुग्न सकिएन — जडान फर्केपछि प्रगति सिंक हुन्छ';

  @override
  String get offlineBackOnline =>
      'इन्टरनेट फर्कियो — तपाईंको कतारको गतिविधि सिंक हुँदैछ';

  @override
  String get learningNoResponse => 'कुनै जवाफ छैन (ट्युटर अफलाइन)।';

  @override
  String get socialApplyFailed => 'त्यो कोड लागू गर्न सकिएन';

  @override
  String get responseCached => 'ठीक छ (क्यास)';

  @override
  String battleTimer(Object seconds, Object current, Object total) {
    return '${seconds}s · $current/$total';
  }

  @override
  String get battleShareUnavailable => 'साझेदारी उपलब्ध छैन';

  @override
  String bookPageLabel(Object number) {
    return 'पृष्ठ $number';
  }

  @override
  String get bookMyHighlights => 'मेरा हाइलाइट';

  @override
  String get bookNoExtractableText =>
      'यो पृष्ठमा निकाल्न मिल्ने पाठ छैन। यो तस्बिर मात्र भएको स्क्यान हुन सक्छ।';

  @override
  String get bookPreviousPage => 'अघिल्लो पृष्ठ';

  @override
  String get bookNextPage => 'अर्को पृष्ठ';

  @override
  String get bookYourHighlights => 'तपाईंका हाइलाइट';

  @override
  String get bookNoHighlights => 'तपाईंले अझै केही हाइलाइट गर्नुभएको छैन।';

  @override
  String get bookImageNotText => 'तस्बिर वा रेखाचित्र (पाठको रूपमा उपलब्ध छैन)';

  @override
  String bookValueNotText(Object value) {
    return '$value (पाठको रूपमा उपलब्ध छैन)';
  }

  @override
  String get contestsNone => 'अहिलेसम्म कुनै प्रतियोगिता छैन';

  @override
  String get contestsNoneBody => 'सक्रिय र आउने प्रतियोगिताहरू यहाँ देखिन्छन्।';

  @override
  String get eiceNoData => 'अहिलेसम्म कुनै डाटा उपलब्ध छैन।';

  @override
  String get eiceNoDetails => 'अहिलेसम्म कुनै विवरण उपलब्ध छैन।';

  @override
  String get eiceNothingHere => 'यहाँ अहिलेसम्म केही छैन।';

  @override
  String eiceAndMore(Object count) {
    return 'र $count थप…';
  }

  @override
  String get gameNoRewardData =>
      'सर्भरले यो तहका लागि अझै पुरस्कारको डाटा पठायो छैन।';

  @override
  String gameMissionsReady(Object count) {
    return '$count मिसन दावी गर्न तयार';
  }

  @override
  String gameRewardsWaiting(Object count) {
    return '$count पुरस्कार बाँकी';
  }

  @override
  String get leaderboardFriendsTitle => 'साथीको लिडरबोर्ड';

  @override
  String get leaderboardLeagueTitle => 'लिगको लिडरबोर्ड';

  @override
  String leaderboardMonthsShort(Object months) {
    return '$months म.';
  }

  @override
  String get learningNoTracksTitle => 'अहिलेसम्म कुनै ट्र्याक छैन';

  @override
  String get learningTracksBody =>
      'ट्र्याकहरू प्रकाशित भएपछि यहाँ देखिन्छन्। छिट्टै फेरि जाँच्नुहोस्।';

  @override
  String learningGradedNextDue(Object grade, Object date) {
    return '$grade भएर अंकित — अर्को $date सम्म';
  }

  @override
  String get learningNoReviewsDue => 'कुनै दोहोराइ बाँकी छैन';

  @override
  String liveEventsActive(Object count, Object capacity) {
    return '$count$capacity सक्रिय';
  }

  @override
  String liveEventsQuestions(Object count) {
    return '$count प्रश्न';
  }

  @override
  String liveEventsSecondsPerQuestion(Object seconds) {
    return '${seconds}s / प्रश्न';
  }

  @override
  String liveEventsJoined(Object count, Object capacity) {
    return '$count$capacity सामेल';
  }

  @override
  String numericalsAnswer(Object value, Object unit) {
    return 'उत्तर: $value$unit';
  }

  @override
  String storeAssetMeta(Object rarity, Object slot, Object coins) {
    return '$rarity • $slot • $coins क्विन';
  }

  @override
  String syllabusNoTopicMatch(Object query) {
    return '\"$query\" सँग मिल्ने कुनै विषय छैन।';
  }

  @override
  String syllabusExaminableCount(Object count) {
    return '$count परीक्षामा';
  }

  @override
  String get forceUpdateUnsupportedLatest =>
      'यो CivilCal संस्करण अब समर्थित छैन। जारी राख्न कृपया नवीनतम संस्करणमा अद्यावधिक गर्नुहोस्।';

  @override
  String forceUpdateUnsupportedVersion(Object version) {
    return 'यो CivilCal संस्करण अब समर्थित छैन। जारी राख्न कृपया $version वा त्यसभन्दा पछिल्लो संस्करणमा अद्यावधिक गर्नुहोस्।';
  }

  @override
  String routeNotFound(Object path) {
    return 'मार्ग फेला परेन: $path';
  }
}
