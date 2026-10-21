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
  String get profilePsc => 'PSC / लोकसेवा';

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
  String get profileSearch => 'खोज्नुहोस्';

  @override
  String get profileSearchSub => 'कुनै पनि प्रश्न खोज्नुहोस्';

  @override
  String get profileNotifications => 'सूचनाहरू';

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
