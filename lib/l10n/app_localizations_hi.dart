// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'CivilCal';

  @override
  String get signIn => 'साइन इन करें';

  @override
  String get register => 'रजिस्टर करें';

  @override
  String get quiz => 'क्विज़';

  @override
  String get practice => 'अभ्यास';

  @override
  String get calculators => 'कैलकुलेटर';

  @override
  String get courses => 'कोर्स';

  @override
  String get continueAsGuest => 'अतिथि के रूप में जारी रखें';

  @override
  String get backend => 'बैकएंड';

  @override
  String get env => 'एनवी';

  @override
  String get home => 'होम';

  @override
  String get profile => 'प्रोफ़ाइल';

  @override
  String get settings => 'सेटिंग';

  @override
  String get offline => 'ऑफ़लाइन';

  @override
  String get retry => 'फिर से प्रयास करें';

  @override
  String get error => 'कुछ गड़बड़ हो गई';

  @override
  String streakDays(int days) {
    return 'स्ट्रीक: $days दिन';
  }

  @override
  String coinsBalance(int count) {
    return '$count कॉइन';
  }

  @override
  String get appLocked => 'CivilCal लॉक है';

  @override
  String get unlock => 'खोलें';

  @override
  String get unlockCivilCal => 'CivilCal खोलें';

  @override
  String get commonCancel => 'रद्द करें';

  @override
  String get commonSave => 'सहेजें';

  @override
  String get commonClose => 'बंद करें';

  @override
  String get commonGoBack => 'वापस जाएं';

  @override
  String get commonStay => 'यहीं रहें';

  @override
  String get commonExit => 'बाहर निकलें';

  @override
  String get commonEmail => 'ईमेल';

  @override
  String get commonPassword => 'पासवर्ड';

  @override
  String get commonContinueWithGoogle => 'Google के साथ जारी रखें';

  @override
  String get commonContinueWithApple => 'Apple के साथ जारी रखें';

  @override
  String get commonOr => 'या';

  @override
  String get commonSkip => 'छोड़ें';

  @override
  String get commonCheckAgain => 'फिर से जांचें';

  @override
  String get commonContactSupport => 'सहायता से संपर्क करें';

  @override
  String get commonShareResult => 'परिणाम साझा करें';

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
  String get authWelcomeBackTitle => 'फिर से स्वागत है';

  @override
  String get authWelcomeBackSubtitle =>
      'अपने क्विज़, सूत्र और रैंक देखने के लिए साइन इन करें';

  @override
  String get authForgotPasswordTitle => 'पासवर्ड भूल गए?';

  @override
  String get authForgotPasswordSubtitle =>
      'अपना पंजीकृत ईमेल दर्ज करें, हम आपको पासवर्ड रीसेट करने के निर्देश भेजेंगे।';

  @override
  String get authEmailAddressLabel => 'ईमेल पता';

  @override
  String get authSendResetLink => 'रीसेट लिंक भेजें';

  @override
  String get authCheckEmailTitle => 'अपना ईमेल देखें';

  @override
  String authCheckEmailBody(Object email) {
    return 'यदि $email के साथ खाता मौजूद है, तो हम जल्द ही पासवर्ड रीसेट लिंक भेजेंगे।';
  }

  @override
  String get authReturnToLogin => 'लॉगिन पर लौटें';

  @override
  String get authJoinTitle => 'CivilCal से जुड़ें';

  @override
  String get authJoinSubtitle => 'इंजीनियरिंग परीक्षा और गणना के लिए आपका साथी';

  @override
  String get authFullNameLabel => 'पूरा नाम';

  @override
  String get authConfirmPasswordLabel => 'पासवर्ड की पुष्टि करें';

  @override
  String get authCreateAccount => 'खाता बनाएं';

  @override
  String get authAlreadyHaveAccount => 'पहले से खाता है?';

  @override
  String get authNoAccount => 'खाता नहीं है?';

  @override
  String get authSetNewPasswordTitle => 'नया पासवर्ड रखें';

  @override
  String get authResetTitle => 'नया पासवर्ड चुनें';

  @override
  String get authResetSubtitle =>
      'आप हर जगह, इस डिवाइस सहित, साइन आउट हो जाएंगे।';

  @override
  String get authResetMissingToken =>
      'इस लिंक में रीसेट टोकन नहीं है। ईमेल से भेजा गया लिंक खोलें, या नया लिंक मांगें।';

  @override
  String get authRequestNewLink => 'नया लिंक मांगें';

  @override
  String get authRequestNewLinkInstead => 'इसके बजाय नया लिंक मांगें';

  @override
  String get authNewPasswordLabel => 'नया पासवर्ड';

  @override
  String get authConfirmNewPasswordLabel => 'नए पासवर्ड की पुष्टि करें';

  @override
  String authMinChars(int count) {
    return 'कम से कम $count अक्षर';
  }

  @override
  String get authVerifyEmailBanner =>
      'सभी सुविधाएं खोलने के लिए अपना ईमेल सत्यापित करें।';

  @override
  String get authSplashTagline => 'बिसास इंजीनियरिंग लर्निंग इकोसिस्टम';

  @override
  String get authInvalidEmail => 'मान्य ईमेल दर्ज करें';

  @override
  String get authPasswordRequired => 'कृपया अपना पासवर्ड दर्ज करें';

  @override
  String onboardingStepOf(int current, int total) {
    return 'चरण $current / $total';
  }

  @override
  String get onboardingTargetExamTitle => 'लक्षित परीक्षा';

  @override
  String get onboardingTargetExamBody =>
      'यह तय करता है कि यह खाता किस पाठ्यक्रम की ओर पढ़ेगा।';

  @override
  String get onboardingDailyGoalTitle => 'दैनिक अभ्यास का लक्ष्य';

  @override
  String get onboardingDailyGoalBody =>
      'आप रोज़ाना कितना समय देना चाहेंगे? आप कभी भी बदल सकते हैं।';

  @override
  String onboardingMinutesPerDay(Object minutes, Object label) {
    return '$minutes मिनट / दिन — $label';
  }

  @override
  String get onboardingCurrentLevelTitle => 'आपका वर्तमान स्तर';

  @override
  String get onboardingCurrentLevelBody =>
      'यह तय करता है कि आपकी स्ट्रीक और दोहराव कहाँ से शुरू होगी।';

  @override
  String get quizHomeTitle => 'अभ्यास और क्विज़';

  @override
  String get quizHomeLoadError => 'क्विज़ लोड नहीं हो सका';

  @override
  String get quizHomeEmptyTitle => 'अभी तक कोई क्विज़ नहीं';

  @override
  String get quizHomeEmptyBody =>
      'आपकी परीक्षा के प्रश्न तैयार किए जा रहे हैं। जल्द ही फिर देखें।';

  @override
  String get quizPlayWorlds => 'वर्ल्ड खेलें';

  @override
  String get quizPlayWorldsSubtitle =>
      'अध्याय, स्तर और बॉस — आगे बढ़ते सितारे कमाएं';

  @override
  String get quizPracticeDrill => 'अभ्यास ड्रिल';

  @override
  String get quizPracticeDrillSubtitle =>
      'अपने बुकमार्क और कमजोर विषय दोहराएं — समय-सीमित नहीं, रैंक पर असर नहीं';

  @override
  String get quizIntroDetailsTitle => 'क्विज़ का विवरण';

  @override
  String quizIntroLoadFailed(Object reason) {
    return 'क्विज़ लोड नहीं हो सका: $reason';
  }

  @override
  String get quizIntroQuestions => 'प्रश्न';

  @override
  String get quizIntroMinutes => 'मिनट';

  @override
  String get quizIntroStart => 'क्विज़ शुरू करें';

  @override
  String get quizIntroHowItWorks => 'यह कैसे काम करता है';

  @override
  String get quizAttemptLoadError => 'क्विज़ लोड नहीं हो सका';

  @override
  String get quizAttemptOfflineNotice =>
      'ऑफ़लाइन अभ्यास — आधिकारिक नहीं। इंटरनेट लौटने पर XP/कॉइन मिला दिए जाएंगे।';

  @override
  String quizAttemptUnsupportedEffect(Object effect) {
    return '$effect उपयोग हुआ — सर्वर ने ऐसा इफ़ेक्ट लौटाया जिसे यह ऐप अभी नहीं दिखा सकता।';
  }

  @override
  String quizAttemptCombo(int count) {
    return '×$count कॉम्बो!';
  }

  @override
  String get quizAttemptExitTitle => 'क्विज़ से बाहर निकलें?';

  @override
  String get quizAttemptExitBody =>
      'आपकी अभी की प्रगति चली जाएगी। क्या आप वाकई बाहर निकलना चाहते हैं?';

  @override
  String get quizResultTitle => 'क्विज़ पूरा हुआ!';

  @override
  String get quizResultAccuracy => 'शुद्धता';

  @override
  String quizResultCorrectOf(Object correct, int total) {
    return '$total में से $correct सही';
  }

  @override
  String get quizResultCorrect => 'सही';

  @override
  String get quizResultXpEarned => 'अर्जित XP';

  @override
  String get quizResultCoins => 'कॉइन';

  @override
  String get quizResultAnswerReview => 'उत्तर समीक्षा';

  @override
  String get quizResultBackToHome => 'होम पर लौटें';

  @override
  String get quizResultReviewAll => 'सभी उत्तर देखें';

  @override
  String get quizResultMorePractice => 'और अभ्यास';

  @override
  String quizResultShareFailed(Object reason) {
    return 'साझा करना उपलब्ध नहीं: $reason';
  }

  @override
  String get quizReviewTitle => 'उत्तर देखें';

  @override
  String quizReviewLoadFailed(Object reason) {
    return 'समीक्षा लोड नहीं हो सकी: $reason';
  }

  @override
  String get quizReviewEmpty => 'देखने के लिए कोई उत्तर नहीं';

  @override
  String get quizReviewYourAnswer => 'आपका उत्तर';

  @override
  String get quizReviewNotAnswered => 'उत्तर नहीं दिया गया';

  @override
  String quizReviewQuestionNumber(Object number) {
    return 'प्रश्न $number';
  }

  @override
  String get quizFunnelTryItOut => 'आजमाकर देखें';

  @override
  String get quizFunnelSampleTitle => 'नमूना प्रश्न';

  @override
  String quizFunnelShown(int count) {
    return '$count दिखाए गए';
  }

  @override
  String get quizFunnelEmptyTitle => 'अभी तक कोई नमूना प्रश्न नहीं';

  @override
  String get quizFunnelEmptyBody =>
      'इस समय कैटलॉग में कोई सार्वजनिक प्रश्न नहीं है। साइन अप करें, आप सब कुछ देखेंगे।';

  @override
  String get quizFunnelCreateAccount => 'खेलने के लिए मुफ़्त खाता बनाएं';

  @override
  String get quizFunnelPlayGraded => 'अंक वाला क्विज़ खेलें';

  @override
  String get quizFunnelPracticeNote =>
      'अभ्यास मोड कभी रैंक, XP या स्ट्रीक को प्रभावित नहीं करता।';

  @override
  String quizOfflinePractice(Object subject) {
    return 'ऑफ़लाइन अभ्यास — $subject';
  }

  @override
  String get quizFinishFailed =>
      'क्विज़ पूरा नहीं हो सका। कृपया फिर से कोशिश करें।';

  @override
  String get quizCountUnavailable => 'संख्या उपलब्ध नहीं';

  @override
  String get calcBrowserEmpty => 'कोई कैलकुलेटर प्रकाशित नहीं';

  @override
  String calcBrowserCount(int count, Object domains) {
    return '$count कैलकुलेटर • $domains क्षेत्र';
  }

  @override
  String get calcBrowserLoadError => 'कैलकुलेटर लोड नहीं हो सके';

  @override
  String calcShareFailed(Object reason) {
    return 'यह परिणाम साझा नहीं हो सका: $reason';
  }

  @override
  String calcNoInputNamed(Object name) {
    return 'इस कैलकुलेटर में \"$name\" नाम का इनपुट नहीं है';
  }

  @override
  String get calcAddInput => 'कम से कम एक इनपुट जोड़ें';

  @override
  String calcInputsLabel(Object label) {
    return 'इनपुट · $label';
  }

  @override
  String get calcInputsLegacy => 'इनपुट (पुराना)';

  @override
  String get calcKeyLabel => 'कुंजी';

  @override
  String get calcKeyExample => 'जैसे: लंबाई';

  @override
  String get calcValueLabel => 'मान';

  @override
  String get calcValueExample => 'जैसे: 12.5';

  @override
  String get calcAssistantTitle => 'सहायक से पूछें';

  @override
  String get calcAssistantExample =>
      'जैसे: 25 MPa मिक्स के लिए 3 मीटर चौड़ा, 4 मीटर गहरा स्लैब';

  @override
  String get calcAssistantSuggested => 'सुझाए गए मान';

  @override
  String get calcAssistantAlso => 'आप यह भी पूछ सकते हैं';

  @override
  String calcHistoryTitle(Object subject) {
    return '$subject · इतिहास';
  }

  @override
  String get calcHistoryEmpty => 'अभी तक कोई गणना सहेजी नहीं गई';

  @override
  String get calcStepByStep => 'चरणबद्ध';

  @override
  String get calcShareResult => 'परिणाम साझा करें';

  @override
  String get calcPracticeRelated => 'संबंधित प्रश्न अभ्यास करें';

  @override
  String get calcViewHistory => 'इतिहास देखें';

  @override
  String get calcNoSchema =>
      'सर्वर ने फ़ील्ड स्कीमा नहीं दी। सामान्य कुंजी/मान संपादक पर वापस जा रहे हैं।';

  @override
  String get calcAddField => 'फ़ील्ड जोड़ें';

  @override
  String calcInputsCount(int count) {
    return 'इनपुट: $count';
  }

  @override
  String get calcAsk => 'पूछें';

  @override
  String get calcApply => 'लागू करें';

  @override
  String get calcAssistantDisclaimer =>
      'सहायक सुझाव देता है, निर्णय आपका है। गणना हमेशा सर्वर करता है।';

  @override
  String homeGreeting(Object name) {
    return 'नमस्ते, $name 👋';
  }

  @override
  String homeLevel(Object level, Object xp) {
    return 'स्तर $level • $xp XP';
  }

  @override
  String get homeDaily => 'दैनिक';

  @override
  String get homeBattle => 'बैटल';

  @override
  String get homeBrowse => 'ब्राउज़ करें';

  @override
  String get homeExplore => 'एक्सप्लोर करें';

  @override
  String get homeCurrentCourse => 'वर्तमान कोर्स';

  @override
  String homePercentDone(Object percent) {
    return '$percent% पूरा';
  }

  @override
  String get homeMissionsUnavailable => 'मिशन उपलब्ध नहीं';

  @override
  String get homeWorldsLoadError => 'आपके वर्ल्ड लोड नहीं हो सके';

  @override
  String get homeWorldsEmpty =>
      'अभी तक कोई वर्ल्ड प्रकाशित नहीं — अभ्यास जारी रखने के लिए विषय देखें।';

  @override
  String get homeYourWorlds => 'आपके वर्ल्ड';

  @override
  String homeStars(Object earned, int total) {
    return '$earned / $total ⭐';
  }

  @override
  String homeContinue(Object title) {
    return 'जारी रखें: $title';
  }

  @override
  String get homeDashboardLoadError => 'आपका डैशबोर्ड लोड नहीं हो सका';

  @override
  String get homeDashboardEmpty =>
      'अनुमान लगाने के बजाय कुछ नहीं दिखाया गया। खींचें, या नीचे फिर से प्रयास करें।';

  @override
  String get homeDashboardUnreachable =>
      'सर्वर तक नहीं पहुँच सके, इसलिए डैशबोर्ड नहीं दिखाया जा सका।';

  @override
  String get consentTitle => 'गोपनीयता विकल्प';

  @override
  String get consentIntro =>
      'आपका खाते और क्विज़ की प्रगति हमारे सर्वर पर रखी जाती है, ताकि आप किसी भी डिवाइस में साइन इन कर सकें। इसके काम करने और ऐप को स्थिर रखने के लिए हम डिवाइस पहचान, पुश नोटिफिकेशन टोकन, क्रैश रिपोर्ट और डिवाइस सुरक्षा जाँच भी भेजते हैं। आपकी अनुमति से हम उपयोग घटनाएं भी भेजते हैं। आप Settings → Privacy में जाकर कभी भी इसे बदल सकते हैं।';

  @override
  String get consentNecessary => 'आवश्यक';

  @override
  String get consentNecessaryBody =>
      'साइन इन और आपका सहेजा काम, आपका पुश नोटिफिकेशन टोकन, क्रैश रिपोर्ट और डिवाइस सुरक्षा जाँच। ऐप चलने के लिए आवश्यक।';

  @override
  String get consentFunctional => 'कार्यक्षम';

  @override
  String get consentFunctionalBody =>
      'आपकी भाषा और फ़िल्टर जैसे सेटिंग इस डिवाइस पर याद रखें।';

  @override
  String get consentAnalytics => 'विश्लेषण';

  @override
  String get consentAnalyticsBody =>
      'उपयोग घटनाएं जो बताती हैं कि कौन-सी सुविधाएं उपयोगी हैं। वे आपके खाते से नहीं, डिवाइस पहचान से जुड़ी होती हैं। प्रश्न का सामग्री कभी शामिल नहीं होता।';

  @override
  String get consentMarketing => 'प्रचार';

  @override
  String get consentMarketingBody =>
      'ऑफ़र और प्रचार। जब तक आप न कहें, बंद रहता है।';

  @override
  String get consentSaveChoices => 'विकल्प सहेजें';

  @override
  String get consentNecessaryOnly => 'केवल आवश्यक के साथ जारी रखें';

  @override
  String get consentLoadError => 'आपके विकल्प लोड नहीं हो सके';

  @override
  String get consentNecessaryAlwaysOn =>
      'हमेशा चालू। आपका खाता, सहेजा काम, पुश टोकन, क्रैश रिपोर्ट और डिवाइस सुरक्षा जाँच।';

  @override
  String get consentDataStored => 'इस डिवाइस के बारे में सहेजा डेटा';

  @override
  String get consentDataStoredSubtitle => 'अनाम प्रोफ़ाइल देखें और मिटाएं';

  @override
  String get consentFootnote =>
      'कोई श्रेणी बंद करने से उस संग्रह उस क्षण से रुक जाता है। पहले संग्रह किया गया डेटा नहीं मिटता — इसके लिए ऊपर दिए लिंक का उपयोग करें या privacy@bisaas.com पर संपर्क करें।';

  @override
  String get privacyTitle => 'आपका डेटा';

  @override
  String get privacyAnonymousProfile => 'अनाम प्रोफ़ाइल';

  @override
  String privacyReference(Object reference) {
    return 'संदर्भ $reference';
  }

  @override
  String get privacyEraseData => 'सहेजा डेटा मिटाएं';

  @override
  String get privacyLocalChoices => 'इस डिवाइस के विकल्प';

  @override
  String get privacyEraseTitle => 'सहेजा डेटा मिटाएं?';

  @override
  String get privacyEraseBody =>
      'यह अनाम प्रोफ़ाइल और इस डिवाइस के लिए सहेजे गए सभी इंटेंट घटनाएं मिटा देता है। इसे पूर्ववत नहीं किया जा सकता।';

  @override
  String get privacyErased => 'सहेजा डेटा मिटा दिया गया';

  @override
  String get privacyEraseFailed => 'डेटा मिटा नहीं सका। फिर से कोशिश करें।';

  @override
  String get privacyEraseConfirm => 'मिटाएं';

  @override
  String get privacyMenu => 'गोपनीयता';

  @override
  String get notificationDailyTitle => 'दैनिक स्प्रिंट तैयार है ⚡';

  @override
  String get notificationDailyBody =>
      'आपके दैनिक बहुविकल्पीय प्रश्न तैयार हैं — स्ट्रीक जारी रखें!';

  @override
  String get forceUpdateTitle => 'अपडेट आवश्यक';

  @override
  String forceUpdateYourVersion(Object version) {
    return 'आपका संस्करण: $version';
  }

  @override
  String get forceUpdateNow => 'अभी अपडेट करें';

  @override
  String get forceUpdateReassurance =>
      'आपका खाता और प्रगति सुरक्षित है — अपडेट करने से कुछ नहीं खोता।';

  @override
  String forceUpdateStoreFailed(Object url) {
    return 'स्टोर नहीं खुल सका। $url पर जाएं';
  }

  @override
  String get maintenanceTitle => 'हम जल्द ही वापस आ रहे हैं';

  @override
  String get maintenanceBody =>
      'CivilCal संक्षिप्त रखरखाव के लिए बंद है। आपका खाता, कॉइन और प्रगति सुरक्षित है — कुछ नहीं खोया गया है।';

  @override
  String get versionUnsupported => 'यह ऐप संस्करण अब समर्थित नहीं है।';

  @override
  String get authUpdating => 'अपडेट हो रहा है…';

  @override
  String get authUpdatePassword => 'पासवर्ड अपडेट करें';

  @override
  String get authVerificationResentBody =>
      'यदि वह पता अभी सत्यापित करना है, तो नया लिंक भेजा जा रहा है। अपना इनबॉक्स और स्पैम फ़ोल्डर देखें।';

  @override
  String get authVerificationResentHint =>
      'हम आपके खाते के पते पर एक टैप का सत्यापन लिंक भेजते हैं।';

  @override
  String get authVerificationSent => 'सत्यापन भेजा गया';

  @override
  String get authResendVerification => 'सत्यापन ईमेल फिर से भेजें';

  @override
  String calcSearchInDomain(Object scope) {
    return '$scope कैलकुलेटर खोजें…';
  }

  @override
  String get calcSearchPlaceholder => 'कैलकुलेटर खोजें…';

  @override
  String get calcCalculating => 'गणना हो रही है…';

  @override
  String get calcCalculateServer => 'गणना करें (सर्वर)';

  @override
  String calcVia(Object source) {
    return '$source के ज़रिए';
  }

  @override
  String homeMissionsReady(int count) {
    return '$count मिशन दावा करने के लिए तैयार';
  }

  @override
  String homeMissionsActive(int count) {
    return 'मिशन — $count सक्रिय';
  }

  @override
  String get onboardingStartLearning => 'सीखना शुरू करें';

  @override
  String get onboardingContinue => 'जारी रखें';

  @override
  String get privacyLinkedToAccount =>
      'यह प्रोफ़ाइल आपके खाते से जुड़ा है। सब कुछ मिटाने के लिए खाता ही हटाएं।';

  @override
  String get quizSeeResults => 'परिणाम देखें';

  @override
  String get quizNextQuestion => 'अगला प्रश्न';

  @override
  String get quizAnswerSubmitted => 'उत्तर जमा हुआ';

  @override
  String get quizBrowseQuizzes => 'क्विज़ ब्राउज़ करें';

  @override
  String get quizPickTopic => 'विषय चुनें';

  @override
  String get quizSearchCourses => 'कोर्स खोजें…';

  @override
  String get quizSearchTopics => 'विषय खोजें…';

  @override
  String get quizNoCoursesYet => 'अभी तक कोई कोर्स नहीं';

  @override
  String get quizNoMatches => 'कोई मिलान नहीं';

  @override
  String get quizSetsBeingPrepared =>
      'आपकी परीक्षा के प्रश्न तैयार किए जा रहे हैं।';

  @override
  String get quizTryDifferentSearch => 'कोई दूसरी खोज आज़माएं';

  @override
  String get quizNoTopicsYet => 'अभी तक कोई विषय नहीं';

  @override
  String get quizCourseNoActiveTopics =>
      'इस कोर्स में अभी तक कोई सक्रिय विषय नहीं है।';

  @override
  String get quizFunnelSampleBody =>
      'हमारे कैटलॉग से नमूना प्रश्न। पूर्ण अंक वाला सत्र खेलने के लिए Quiz टैब खोलें।';

  @override
  String get quizFunnelPublicBody =>
      'हमारे कैटलॉग से सार्वजनिक प्रश्न। मुफ़्त खाता बनाने पर उत्तर खुलते हैं।';

  @override
  String get quizFreshQuestions => 'हाल ही में नए प्रश्न जोड़े गए हैं।';

  @override
  String quizNewIn(Object scope) {
    return '$scope में नया';
  }

  @override
  String get quizNoQuestionText => 'इस प्रश्न का सर्वर पर कोई टेक्स्ट नहीं है।';

  @override
  String get quizGraded => 'अंक वाला';

  @override
  String get quizXp => 'XP';

  @override
  String get quizByServer => 'सर्वर द्वारा';

  @override
  String get forceUpdateUnsupportedLatest =>
      'यह CivilCal संस्करण अब समर्थित नहीं है। जारी रखने के लिए कृपया नवीनतम संस्करण पर अपडेट करें।';

  @override
  String forceUpdateUnsupportedVersion(Object version) {
    return 'यह CivilCal संस्करण अब समर्थित नहीं है। जारी रखने के लिए कृपया $version या उससे नए संस्करण पर अपडेट करें।';
  }

  @override
  String routeNotFound(Object path) {
    return 'रूट नहीं मिला: $path';
  }
}
