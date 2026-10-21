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
  String streakDays(int days) {
    return 'स्ट्रिक: $days दिन';
  }

  @override
  String coinsBalance(int count) {
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
  String commonPoints(int count) {
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
  String authMinChars(int count) {
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
  String onboardingStepOf(int current, int total) {
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
  String quizAttemptCombo(int count) {
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
  String quizResultCorrectOf(Object correct, int total) {
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
  String quizFunnelShown(int count) {
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
  String calcBrowserCount(int count, Object domains) {
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
  String calcInputsCount(int count) {
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
  String homeStars(Object earned, int total) {
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
  String homeMissionsReady(int count) {
    return '$count मिसन दावी गर्न तयार';
  }

  @override
  String homeMissionsActive(int count) {
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
