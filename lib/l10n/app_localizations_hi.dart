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
  String streakDays(Object days) {
    return 'स्ट्रीक: $days दिन';
  }

  @override
  String coinsBalance(Object count) {
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
  String authMinChars(Object count) {
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
  String onboardingStepOf(Object current, Object total) {
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
  String quizAttemptCombo(Object count) {
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
  String quizResultCorrectOf(Object correct, Object total) {
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
  String quizFunnelShown(Object count) {
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
  String calcBrowserCount(Object count, Object domains) {
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
  String calcInputsCount(Object count) {
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
  String homeStars(Object earned, Object total) {
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
  String homeMissionsReady(Object count) {
    return '$count मिशन दावा करने के लिए तैयार';
  }

  @override
  String homeMissionsActive(Object count) {
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
  String get profileAvatarUploaded => 'अवतार अपलोड हो गया';

  @override
  String get profileAvatarUpdated => 'अवतार अपडेट हो गया';

  @override
  String profileUploadFailed(Object reason) {
    return 'अपलोड विफल: $reason';
  }

  @override
  String get profileEditName => 'नाम संपादित करें';

  @override
  String get profileDisplayName => 'प्रदर्शित नाम';

  @override
  String get profileUpdated => 'प्रोफ़ाइल अपडेट हो गया';

  @override
  String profileUpdateFailed(Object reason) {
    return 'अपडेट विफल: $reason';
  }

  @override
  String profileShareCardText(Object level) {
    return 'मेरा CivilCal प्रोफ़ाइल — स्तर $level इंजीनियर। https://bisaas.com';
  }

  @override
  String profileShareFailed(Object reason) {
    return 'साझा करना विफल: $reason';
  }

  @override
  String get profileShareCard => 'कार्ड साझा करें';

  @override
  String profileLevel(Object level) {
    return 'स्तर $level';
  }

  @override
  String get profileChangeAvatar => 'अवतार बदलें';

  @override
  String get profileEditAvatar => 'अवतार संपादित करें';

  @override
  String get profileStreak => 'स्ट्रीक';

  @override
  String get profileSkillRadar => 'स्किल रडार';

  @override
  String profileSkillsFailed(Object reason) {
    return 'स्किल लोड विफल: $reason';
  }

  @override
  String get profileAchievements => 'उपलब्धियां';

  @override
  String get profileAchievementsLoadFailed => 'उपलब्धियां लोड नहीं हो सकीं';

  @override
  String get profileNoBadges => 'अभी तक कोई बैज नहीं — क्विज़ पूरे करके कमाएं!';

  @override
  String get profileUnlocked => 'अनलॉक';

  @override
  String get profileSkillRadarEmpty =>
      'अपना स्किल रडार देखने के लिए क्विज़ खेलें।';

  @override
  String get profileSkillRadarEmptyHint =>
      'अपना स्किल रडार देखने के लिए अधिक श्रेणियों के प्रश्नों के उत्तर दें।';

  @override
  String get profileLearning => 'सीखना — ट्रैक और AI ट्यूटर';

  @override
  String get profileLearningSub => 'अध्ययन योजना • दोहराव • ट्यूटर';

  @override
  String get profileEice => 'परीक्षा बुद्धि (EICE)';

  @override
  String get profileEiceSub => 'कोच • ट्रायेज • स्प्रिंट';

  @override
  String get profilePsc => 'PSC / लोकसेवा';

  @override
  String get profilePscSub => 'परीक्षा ढांचा और पाठ्यक्रम';

  @override
  String get profilePracticeSub => 'बुकमार्क ड्रिल • कमजोर विषय';

  @override
  String get profileLeaderboardSub => 'विश्व • दोस्त • लीग';

  @override
  String get profileContests => 'प्रतियोगिताएं';

  @override
  String get profileContestsSub => 'लाइव क्विज़ और लीडरबोर्ड';

  @override
  String get profileLiveEvents => 'लाइव कार्यक्रम';

  @override
  String get profileLiveEventsSub => 'निर्धारित सत्र और चेक-इन';

  @override
  String get profileCoaching => 'कोचिंग';

  @override
  String get profileCoachingSub => 'कमजोर क्षेत्र • तैयारी • स्प्रिंट';

  @override
  String get profileSearch => 'खोजें';

  @override
  String get profileSearchSub => 'कोई भी प्रश्न खोजें';

  @override
  String get profileNotifications => 'सूचनाएं';

  @override
  String get profileNotificationsSub => 'गतिविधि और याद दिलाना';

  @override
  String get profileSocial => 'सोशल और रेफरल';

  @override
  String get profileSocialSub => 'साझा • स्ट्रीक • लीडरबोर्ड';

  @override
  String get profileWalletSub => 'कॉइन और बही';

  @override
  String get profileAchievementsSub => 'स्ट्रीक + बैज';

  @override
  String get profileOffline => 'ऑफ़लाइन सामग्री';

  @override
  String get profileOfflineSub => 'कैश किए गए पैक + प्रीफ़ेच';

  @override
  String get profileCalculatorsSub => 'सिविल फ़ॉर्मूला इंजन';

  @override
  String get profileSettingsSub => 'भाषा • बायोमेट्रिक • लॉगआउट';

  @override
  String get settingsSubscriptionActive =>
      'खाता मिटाने से पहले सदस्यता रद्द करनी होगी';

  @override
  String get settingsDeleteFailed =>
      'खाता मिटा नहीं सका — कृपया फिर से कोशिश करें';

  @override
  String get settingsAccountDeleted => 'आपका खाता मिटा दिया गया है';

  @override
  String get settingsNoBiometrics =>
      'इस डिवाइस पर कोई बायोमेट्रिक दर्ज नहीं है';

  @override
  String get settingsLanguageLocalOnly =>
      'भाषा केवल इस डिवाइस पर सहेजी गई — सर्वर तक नहीं पहुँच सके।';

  @override
  String get settingsSystemDefault => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get settingsAppLanguage => 'ऐप की भाषा';

  @override
  String get settingsBiometricLock => 'बायोमेट्रिक ऐप लॉक';

  @override
  String get settingsBiometricLockSub =>
      'बैकग्राउंड में 30 सेकंड बाद बायोमेट्रिक माँगें';

  @override
  String get settingsPrivacySub => 'विश्लेषण, कार्यक्षम और प्रचार की सहमति';

  @override
  String get settingsAiUsageSub =>
      'आपकी ओर से AI ने क्या इस्तेमाल किया, सुविधा के अनुसार';

  @override
  String get settingsAiKeysSub => 'AI सुविधाएं अपने प्रोवाइडर के कोटे पर चलाएं';

  @override
  String get settingsLogOut => 'लॉग आउट';

  @override
  String get settingsDeleteAccount => 'खाता मिटाएं';

  @override
  String get settingsDeleteAccountSub =>
      'आपका खाता, प्रयास और खरीद स्थायी रूप से मिटाएं';

  @override
  String get settingsDeleteAccountTitle => 'खाता मिटाएं?';

  @override
  String get settingsDeleteAccountBody =>
      'यह आपका खाता, क्विज़ इतिहास, कॉइन और खरीद स्थायी रूप से मिटा देता है। इसे पूर्ववत नहीं किया जा सकता।';

  @override
  String get settingsTypeDeleteToConfirm =>
      'पुष्टि करने के लिए \'DELETE\' लिखें';

  @override
  String get settingsDeleteConfirm => 'मिटाएं';

  @override
  String get streakRefresh => 'रिफ्रेश करें';

  @override
  String get streakNoneTitle => 'अभी तक कोई स्ट्रीक नहीं';

  @override
  String get streakNoneBody =>
      'अपनी स्ट्रीक शुरू करने के लिए एक क्विज़ पूरा करें।';

  @override
  String get streakCalendar => 'कैलेंडर';

  @override
  String get streakOnFire => 'आज आपकी स्ट्रीक जोश में है — ऐसे ही बनाए रखें!';

  @override
  String get streakProtect => 'अपनी स्ट्रीक बचाएं';

  @override
  String get streakFrozen => 'स्ट्रीक 30 दिन के लिए फ्रीज़ हो गई!';

  @override
  String get streakCurrent => 'वर्तमान स्ट्रीक';

  @override
  String get streakDaysUnit => 'दिन';

  @override
  String streakBest(Object count) {
    return 'सर्वश्रेष्ठ: $count दिन';
  }

  @override
  String get streakMultiplier => 'गुणक';

  @override
  String get streakMaxMultiplier => 'अधिकतम गुणक प्राप्त — किंवदंती!';

  @override
  String streakDaysToNextTier(Object current, Object total) {
    return 'अगले स्तर तक $current / $total दिन';
  }

  @override
  String get streakTiers =>
      '1–6 दिन → 1.0× • 7–29 दिन → 1.5× • 30–99 दिन → 2.0× • 100+ दिन → 3.0×';

  @override
  String get streakFreezeSection => 'स्ट्रीक फ्रीज़';

  @override
  String streakFreezeLeft(Object count) {
    return '$count बचे';
  }

  @override
  String streakFrozenUntil(Object date) {
    return '$date तक फ्रीज़';
  }

  @override
  String get streakFreezeHint =>
      'खेल न पाएँदा 30 दिनका लिए स्ट्रीक फ्रीज़ गर्न 50 कॉइन खर्च्नुहोस्। दानकर्ता बैज आवश्यक।';

  @override
  String get streakExtendFreeze => 'फ्रीज़ बढाउनुहोस्';

  @override
  String get streakFreezeAction => 'स्ट्रीक फ्रीज़ करें (50 कॉइन)';

  @override
  String get streakRepairTitle => 'छूटे दिन को मरम्मत करें';

  @override
  String get streakRepairAction => 'स्ट्रीक मरम्मत करें';

  @override
  String get streakInsurance => 'स्ट्रीक बीमा';

  @override
  String get streakInsuranceChecking => 'बीमा जांच रहे हैं…';

  @override
  String get streakBuy => 'खरीदें';

  @override
  String get streakUseNow => 'अभी उपयोग करें';

  @override
  String get streakWager => 'स्ट्रीक वेजर';

  @override
  String get streakWagerDescription =>
      'लक्ष्य स्ट्रीक तक पहुँचने के लिए कॉइन लगाएं। पहुँच गए तो ब्याज सहित पूरी जैसी वापस, नहीं पहुँचे तो कॉइन चले जाएंगे।';

  @override
  String streakWagerDay(Object current, Object total, Object reward) {
    return '$total में से $current दिन — $reward कॉइन जीतने के लिए खेलते रहें।';
  }

  @override
  String get streakWagerStart => 'वेजर शुरू करें';

  @override
  String get streakWagerInProgress => 'वेजर चल रहा है';

  @override
  String get streakWagerStartTitle => 'स्ट्रीक वेजर शुरू करें';

  @override
  String get streakWagerStartBody =>
      'दुगना जीतने के लिए लक्ष्य स्ट्रीक तक पहुँचें। नहीं पहुँचे तो लगाई गई रकम चली जाएगी।';

  @override
  String get streakWagerStake => 'लगाने वाले कॉइन';

  @override
  String get streakWagerDays => 'बनाए रखने वाले दिन';

  @override
  String streakXpMultiplier(Object value) {
    return '×$value XP';
  }

  @override
  String streakWagerProgress(Object percent) {
    return '$percent% पूरा';
  }

  @override
  String get streakFreezeDuration => '30 दिन';

  @override
  String streakWagerDaysCount(Object count) {
    return '$count दिन';
  }

  @override
  String streakWagerSummary(Object coins, Object days) {
    return '$days दिन के लिए $coins कॉइन का वेजर';
  }

  @override
  String get tutorStudyPlan => 'अध्ययन योजना';

  @override
  String get tutorChat => 'चैट';

  @override
  String get tutorPlanTab => 'योजना';

  @override
  String get tutorInsights => 'विश्लेषण';

  @override
  String get tutorRevisions => 'दोहराव';

  @override
  String get tutorWeekly => 'साप्ताहिक';

  @override
  String get tutorNoTasksToday => 'आज कोई काम नहीं — कल देखें';

  @override
  String get tutorDone => 'पूर्ण';

  @override
  String tutorTasksDone(Object done, Object total) {
    return '$done/$total काम';
  }

  @override
  String get tutorDayCompleted => 'दिन पूरा हुआ — योजना अपडेट हुई।';

  @override
  String get tutorMarkDayComplete => 'दिन पूरा चिह्नित करें';

  @override
  String tutorYourPlan(Object title) {
    return 'आपकी योजना — $title';
  }

  @override
  String tutorPlanDays(Object days, Object current) {
    return '$days दिन • वर्तमान $current';
  }

  @override
  String get tutorPlanNoDays =>
      'योजना में अभी तक दिन नहीं हैं — ऑनबोर्डिंग इसे बनाएगी।';

  @override
  String tutorMoreDays(Object count) {
    return '+ $count और दिन';
  }

  @override
  String get tutorAdjustPlan => 'योजना बदलें';

  @override
  String get tutorNoPlanYet => 'अभी तक कोई योजना नहीं';

  @override
  String get tutorOnboardingRequired =>
      'आपकी व्यक्तिगत अध्ययन योजना बनाने के लिए ट्यूटर ऑनबोर्डिंग पूरा करें।';

  @override
  String get tutorStartOnboarding => 'ऑनबोर्डिंग शुरू करें';

  @override
  String get tutorAdjustExample =>
      'जैसे, \"मैं रोज़ 3 घंटे कर सकता हूं\" या \"मिट्टी की यांत्रिकी पर अधिक ध्यान दें\"';

  @override
  String get tutorAdjustPrompt => 'कैसे बदलें?';

  @override
  String get tutorAdjustRequested => 'योजना बदलने का अनुरोध भेजा गया।';

  @override
  String get tutorSubmit => 'जमा करें';

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
      'कोई कमजोर क्षेत्र नहीं — बहुत बढ़िया! तेज़ रहने के लिए अभ्यास जारी रखें।';

  @override
  String tutorAccuracy(Object accuracy, Object attempts) {
    return 'शुद्धता $accuracy% • $attempts प्रयास';
  }

  @override
  String get tutorNoRevisionsDue =>
      'कोई दोहराव बाकी नहीं — आप सही रास्ते पर हैं।';

  @override
  String tutorDueLabel(Object date) {
    return '$date तक';
  }

  @override
  String tutorTopicDue(Object topic, Object date) {
    return '$topic • $date तक';
  }

  @override
  String get tutorCompleted => 'पूरा हुआ';

  @override
  String get tutorOverdue => 'समय बीत चुका';

  @override
  String get tutorDue => 'बाकी';

  @override
  String tutorWeekRange(Object start, Object end) {
    return 'सप्ताह $start → $end';
  }

  @override
  String get tutorAvgScore => 'औसत अंक';

  @override
  String get tutorHours => 'घंटे';

  @override
  String tutorCompletion(Object percent) {
    return '$percent% पूरा';
  }

  @override
  String get tutorHighlights => 'मुख्य बातें';

  @override
  String get tutorWeeklyReportPending =>
      'एक सप्ताह की गतिविधि के बाद साप्ताहिक रिपोर्ट दिखेगी।';

  @override
  String get tutorOnboardingSaved => 'ऑनबोर्डिंग सहेजी गई — योजना जल्द बनेगी।';

  @override
  String get tutorOnboardingTitle => 'ट्यूटर ऑनबोर्डिंग';

  @override
  String get tutorPersonalised => 'व्यक्तिगत ट्यूटर';

  @override
  String get tutorOnboardingExplain =>
      'अपना लक्ष्य बताएं — सर्वर आपकी योजना बनाएगा। user_id की ज़रूरत नहीं (टोकन से)।';

  @override
  String tutorSessionLabel(Object session) {
    return 'सत्र: $session';
  }

  @override
  String get tutorYourGoal => 'आपका लक्ष्य';

  @override
  String get tutorGoalExample => 'जैसे, 6 महीने में PSC सिविल क्रैक करना';

  @override
  String get tutorCurrentLevel => 'वर्तमान स्तर';

  @override
  String get tutorLevelExample => 'जैसे: B.E. सिविल अंतिम वर्ष';

  @override
  String get tutorHoursPerDay => 'प्रतिदिन घंटे';

  @override
  String get tutorHoursExample => 'जैसे: 2';

  @override
  String get tutorOnboardingComplete =>
      'ऑनबोर्डिंग पूरा हुई — आपकी योजना तैयार है।';

  @override
  String get tutorViewPlan => 'योजना देखें';

  @override
  String get tutorCompleteOnboarding => 'ऑनबोर्डिंग पूरा करें';

  @override
  String get tutorSkipToChat => 'छोड़ें → ट्यूटर से चैट';

  @override
  String get tutorSavedToAccount =>
      'आपके खाते में सहेजा गया। कनेक्शन टूटे तो फिर से कोशिश करना सुरक्षित है।';

  @override
  String get tutorTitle => 'AI ट्यूटर';

  @override
  String get tutorClearChat => 'चैट साफ़ करें';

  @override
  String get tutorNotEnoughHistory =>
      'अभी पर्याप्त इतिहास नहीं — व्यक्तिगत बनाने के लिए कुछ क्विज़ पूरे करें।';

  @override
  String get tutorDismiss => 'खारिज करें';

  @override
  String get tutorWriting =>
      'ट्यूटर अपना उत्तर लिख रहा है। लंबे प्रश्न में कुछ समय लग सकता है।';

  @override
  String get tutorAskAnything => 'कुछ भी पूछें';

  @override
  String get tutorChatExplain =>
      'परीक्षा के अवधारणाएं, बीम डिफ्लेक्शन, मिट्टी की यांत्रिकी — AI उत्तर Laravel गेटवे से देता है (कभी सीधे प्रोवाइडर से नहीं)।';

  @override
  String get tutorExample1 => 'प्रोक्टर कम्पैक्शन समझाएं';

  @override
  String get tutorExample2 => 'साप्ताहिक योजना में मदद';

  @override
  String get tutorExample3 => 'कमजोर क्षेत्र?';

  @override
  String get tutorTyping => 'ट्यूटर लिख रहा है…';

  @override
  String get tutorInputHint => 'ट्यूटर से पूछें…';

  @override
  String get aiUsageTitle => 'आपका AI का उपयोग';

  @override
  String get aiUsageOverview => 'अवलोकन';

  @override
  String get aiUsageRequests => 'अनुरोध';

  @override
  String get aiUsageTokens => 'टोकन';

  @override
  String get aiUsageTutorChats => 'ट्यूटर चैट (सभी समय)';

  @override
  String get aiUsageNone => 'इस अवधि में कोई AI सुविधा उपयोग नहीं हुई।';

  @override
  String get aiUsageByFeature => 'सुविधा के अनुसार';

  @override
  String get aiUsageTutorConversations => 'ट्यूटर बातचीत';

  @override
  String get aiUsageNoConversations => 'अभी तक कोई ट्यूटर बातचीत नहीं।';

  @override
  String get aiUsageLoadMoreConversations => 'और बातचीत लोड करें';

  @override
  String get aiUsageWeeklyReport => 'साप्ताहिक रिपोर्ट कार्ड';

  @override
  String get aiUsageNoWeeks => 'अभी तक कोई साप्ताहिक सारांश सहेजा नहीं गया।';

  @override
  String get aiUsageLoadMoreWeeks => 'और सप्ताह लोड करें';

  @override
  String aiUsageConversationNumber(Object number) {
    return 'बातचीत #$number';
  }

  @override
  String aiUsageQuestionNumber(Object number) {
    return 'प्रश्न $number';
  }

  @override
  String aiUsageTurns(Object count) {
    return '$count बार';
  }

  @override
  String aiUsageWeekOf(Object date) {
    return '$date का सप्ताह';
  }

  @override
  String aiUsageWeekSummary(
    Object accuracy,
    Object xp,
    Object coins,
    Object streak,
  ) {
    return '$accuracy% शुद्धता • $xp XP • $coins कॉइन • $streak दिन स्ट्रीक';
  }

  @override
  String aiUsageHoursShort(Object hours) {
    return '$hours घं';
  }

  @override
  String get aiKeysTitle => 'आपकी AI कुंजियां';

  @override
  String get aiKeysExplain =>
      'आपकी कुंजी हमारे सर्वर पर एन्क्रिप्ट होती है और कभी दोबारा नहीं दिखती। केवल अंतिम चार अक्षर दिखते हैं।';

  @override
  String get aiKeysAddTitle => 'कुंजी जोड़ें';

  @override
  String get aiKeysNoneYet => 'अभी तक कोई कुंजी नहीं';

  @override
  String get aiKeysNoneExplain =>
      'साझा कोटे के बजाय अपने कोटे पर AI सुविधाएं चलाने के लिए प्रोवाइडर कुंजी जोड़ें।';

  @override
  String get aiKeysStored => 'सहेजी कुंजियां';

  @override
  String aiKeysTokensUsed(Object used, Object total) {
    return '$total दैनिक टोकन में से $used उपयोग';
  }

  @override
  String get aiKeysRevoke => 'रद्द करें';

  @override
  String get aiKeysTooShort => 'कुंजी कम से कम 8 अक्षर की होनी चाहिए';

  @override
  String get aiKeysAddProvider => 'प्रोवाइडर कुंजी जोड़ें';

  @override
  String get aiKeysProvider => 'प्रोवाइडर';

  @override
  String get aiKeysApiKey => 'API कुंजी';

  @override
  String get aiKeysSentOnce => 'एक बार भेजा जाता है और कभी दोबारा नहीं दिखता।';

  @override
  String get aiKeysLabelOptional => 'लेबल (वैकल्पिक)';

  @override
  String get aiKeysSaveKey => 'कुंजी सहेजें';

  @override
  String aiKeysSaved(Object name) {
    return '$name सहेजी गई। यह हमारे सर्वर पर एन्क्रिप्ट है और कभी दोबारा नहीं दिखेगी।';
  }

  @override
  String get aiKeysRevoked => 'कुंजी रद्द कर दी गई।';

  @override
  String get practiceBookmarks => 'बुकमार्क';

  @override
  String get practiceWeakTopics => 'कमजोर विषय';

  @override
  String get practiceSelfChallenge => 'स्वयं चुनौती';

  @override
  String get practiceHistory => 'इतिहास';

  @override
  String get practiceNoBookmarks => 'अभ्यास के लिए कोई बुकमार्क नहीं';

  @override
  String get practiceBookmarkedPractice => 'बुकमार्क अभ्यास';

  @override
  String practiceBookmarksUnavailable(Object count, Object total) {
    return '$total में से $count बुकमार्क अभ्यास नहीं किए जा सके — सर्वर ने अभी तक उनके विकल्प प्रकाशित नहीं किए।';
  }

  @override
  String get practiceDrill => 'अभ्यास ड्रिल';

  @override
  String practiceDrillCount(Object count) {
    return 'ड्रिल: $count';
  }

  @override
  String get practiceNoBookmarksBody => 'कोई बुकमार्क नहीं';

  @override
  String get practiceNoBookmarksHint =>
      'क्विज़ खेलते समय प्रश्न बुकमार्क करें, बाद में वे यहाँ अभ्यास के लिए दिखेंगे।';

  @override
  String get practiceBrowseQuizzes => 'क्विज़ ब्राउज़ करें';

  @override
  String practiceBookmarkedCount(Object count) {
    return '$count बुकमार्क';
  }

  @override
  String get practiceAll => 'सभी का अभ्यास करें';

  @override
  String practiceQuestionNumber(Object number) {
    return 'प्रश्न #$number';
  }

  @override
  String practiceQuestionMeta(Object meta, Object difficulty, Object points) {
    return '$meta • कठिनाई $difficulty • $points अंक';
  }

  @override
  String get practiceBookmarked => 'बुकमार्क किया गया';

  @override
  String get practiceLoadMoreCursor => 'और लोड करें (cursor)';

  @override
  String get practiceWeakTopicsLoadFailed => 'आपके कमजोर विषय लोड नहीं हो सके';

  @override
  String get practiceWeakTopicsExplained =>
      'ये आपके अपने उत्तर इतिहास से निकाले गए हैं। जब तक सच न हो, कुछ नहीं दिखाया जाता।';

  @override
  String get practiceNoWeakTopics => 'अभी तक कोई कमजोर विषय नहीं';

  @override
  String get practiceWeakTopicsNeedsAttempts =>
      'कमजोर क्षेत्र पहचानने के लिए सर्वर को अंक वाले प्रयास चाहिए। Quiz टैब से एक क्विज़ खेलें और फिर देखें।';

  @override
  String get practiceWeakTopicsServerNote =>
      'कमजोर विषय हमारे सर्वर आपके उत्तर इतिहास से निकालते हैं, इसलिए यहाँ कुछ भी अनुमानित नहीं है।';

  @override
  String get practiceYourWeakTopics => 'आपके कमजोर विषय';

  @override
  String get practiceDrillAction => 'ड्रिल करें';

  @override
  String get practiceDrillTen =>
      '10 प्रश्न ड्रिल करें (अभ्यास मोड, समय-सीमित नहीं)';

  @override
  String get practiceUntimedNote =>
      'अभ्यास समय-सीमित नहीं है और इससे आपकी रैंक या कॉइन नहीं बदलते।';

  @override
  String get practiceSelfChallengeExplain =>
      'प्रश्नों की संख्या और कठिनाई चुनें — Elite Quiz के सेल्फ-चैलेंज जैसा, पर adaptive engine से।';

  @override
  String practiceQuestionCount(Object count) {
    return 'प्रश्न संख्या: $count';
  }

  @override
  String get practiceDifficulty => 'कठिनाई';

  @override
  String get practiceStarting => 'शुरू हो रहा है…';

  @override
  String practiceStartChallenge(Object count) {
    return 'चुनौती शुरू करें ($count प्रश्न)';
  }

  @override
  String get practiceResultsLabelled =>
      'परिणाम अभ्यास के रूप में चिह्नित होते हैं, इसलिए वे कभी आपकी रैंक में नहीं गिने जाते।';

  @override
  String get practiceNoHistory => 'कोई इतिहास नहीं';

  @override
  String get practiceNoHistoryBody => 'आपके पूरे हुए अभ्यास सत्र यहाँ दिखेंगे।';

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
  String get economyYourResources => 'आपके संसाधन';

  @override
  String economyResourceSummary(Object held, Object catalog, Object recent) {
    return '$held सहेजे • $catalog कैटलॉग • $recent हाल के';
  }

  @override
  String get economyNoResources => 'अभी तक कोई संसाधन नहीं';

  @override
  String get economyResourcesExplain =>
      'संसाधन शहर/अर्थव्यवस्था के प्रवाह और क्विज़ पुरस्कारों से मिलते हैं। उपलब्ध होने पर यहाँ दिखते हैं।';

  @override
  String get economyCatalog => 'कैटलॉग';

  @override
  String get economyCatalogEmpty =>
      'कैटलॉग खाली है — सर्वर सामग्री की सूची भरेगा।';

  @override
  String get economyRecentActivity => 'हाल की गतिविधि';

  @override
  String get economyNoRecentActivity => 'हाल में कोई गतिविधि नहीं।';

  @override
  String get economyDonations => 'दान';

  @override
  String get economyDonationsExplain =>
      'लाइव लीडरबोर्ड और फ़ीड। कॉइन से दानकर्ता की स्ट्रीक फ्रीज़ हो सकती है।';

  @override
  String economyLeaderboardFeed(Object status) {
    return 'लीडरबोर्ड/फ़ीड: $status';
  }

  @override
  String economyStreakMonths(Object name, Object months) {
    return '$name • $months महीने की स्ट्रीक';
  }

  @override
  String get economyLiveFeed => 'लाइव फ़ीड';

  @override
  String get economyDonationsEmpty => 'दान लीडरबोर्ड और फ़ीड खाली हैं।';

  @override
  String get economySyncing => 'सिंक हो रहा है…';

  @override
  String get economyLedger => 'बही';

  @override
  String get economyLedgerExplain =>
      'दिन के अनुसार समूहबद्ध। स्रोत लेबल credits.description से आते हैं (metadata.source से नहीं)।';

  @override
  String get economyWhereCoinsWent => 'आपके कॉइन कहाँ गए';

  @override
  String economyPeriodSummary(Object days, Object earned, Object spent) {
    return 'पिछले $days दिन • कमाए $earned • खर्च $spent';
  }

  @override
  String get economyNoActivity => 'इस अवधि में कोई कॉइन गतिविधि नहीं।';

  @override
  String get economyHowYouEarn => 'आप कैसे कमाते हैं';

  @override
  String get economyMintingExplain =>
      'कॉइन हर अंक वाले क्विज़ और सर्वर के दैनिक कार्यों के बाद जमा होते हैं। वे कभी आपके डिवाइस पर नहीं बनते, इसलिए आपका बैलेंस नहीं बिगड़ता।';

  @override
  String get economyNoTransactions => 'अभी तक कोई लेनदेन नहीं';

  @override
  String get economyNoTransactionsBody =>
      'कॉइन कमाने के लिए एक क्विज़ पूरा करें। हर जमा हमारे सर्वर पर दर्ज होता है।';

  @override
  String get economyTitle => 'अर्थव्यवस्था';

  @override
  String economyXpTotal(Object xp) {
    return 'कुल $xp XP';
  }

  @override
  String get economyLiveExplain =>
      'बैलेंस, बही, शॉप और स्टोर सब लाइव हैं। अंक वाला प्रयास पूरा होने पर कॉइन सर्वर पर बनते हैं।';

  @override
  String get economyWalletTile => 'वॉलेट - बैलेंस + दिन के अनुसार बही';

  @override
  String get economyWalletTileSub =>
      'बैलेंस, जीवनभर के कुल और आपका कॉइन इतिहास';

  @override
  String get economyShopTile => 'कॉइन शॉप - संसाधन और बंडल';

  @override
  String get economyShopTileSub => 'सामग्री और बंडल पर कॉइन खर्चें';

  @override
  String get economyInventoryTile => 'सामग्री - संसाधन + दान';

  @override
  String get economyInventoryTileSub =>
      '8 सामग्री + कैटलॉग + लाइव दान फ़ीड/लीडरबोर्ड';

  @override
  String get economyStoreTile => 'प्रीमियम स्टोर - एसेट और स्किन';

  @override
  String get economyStoreTileSub => 'फ़्रेम, थीम, बैज और अवतार खरीदें';

  @override
  String get economyWardrobeTile => 'वॉर्डरोब - लगाएं';

  @override
  String get economyWardrobeTileSub => 'अपने एसेट लगाएं या हटाएं';

  @override
  String get economyShopTitle => 'कॉइन शॉप';

  @override
  String get economyNothingForSale => 'अभी तक बिक्री के लिए कुछ नहीं';

  @override
  String get economyShopEmpty =>
      'सर्वर पर अभी शॉप की कोई वस्तु प्रकाशित नहीं है।';

  @override
  String get economyBundles => 'बंडल';

  @override
  String get economyMaterials => 'सामग्री';

  @override
  String get economyPurchaseSafe =>
      'खरीद सफल नहीं हुई तो फिर से कोशिश करना सुरक्षित है — दोबारा शुल्क नहीं लगेगा।';

  @override
  String economySellsBackFor(Object coins) {
    return '$coins में वापस बिकता है';
  }

  @override
  String economySave(Object coins) {
    return '$coins की बचत';
  }

  @override
  String libraryUnlockedCoins(Object coins) {
    return 'अनलॉक हो गया! खर्च किए गए कॉइन: $coins';
  }

  @override
  String get libraryDownloadStarted => 'डाउनलोड शुरू हुआ — ब्राउज़र खुल रहा है';

  @override
  String libraryDownloadUrl(Object url) {
    return 'डाउनलोड URL: $url';
  }

  @override
  String get libraryRatingRange => 'रेटिंग 1-5 के बीच होनी चाहिए';

  @override
  String get libraryReviewSubmitted => 'समीक्षा जमा हुई';

  @override
  String get libraryAbout => 'परिचय';

  @override
  String get libraryReviews => 'समीक्षाएं';

  @override
  String get libraryNoReviews =>
      'अभी तक कोई समीक्षा नहीं — अनलॉक करने के बाद पहली समीक्षा करें!';

  @override
  String get libraryLoadMoreReviews => 'और समीक्षाएं लोड करें';

  @override
  String get librarySignedUrls =>
      'डाउनलोड URL हस्ताक्षरित और अल्पकालिक होते हैं। डाउनलोड विफल हो तो फिर से Download दबाएं। library-api-download की सीमा मानें।';

  @override
  String get libraryFree => 'मुफ़्त';

  @override
  String libraryCoinsLabel(Object count) {
    return '$count कॉइन';
  }

  @override
  String get libraryFeatured => 'विशेष';

  @override
  String libraryByUploader(Object name) {
    return '$name द्वारा';
  }

  @override
  String libraryUnlockedFor(Object coins) {
    return 'अनलॉक • $coins कॉइन';
  }

  @override
  String get libraryUnlocking => 'अनलॉक हो रहा है…';

  @override
  String get libraryGettingLink => 'लिंक ला रहे हैं…';

  @override
  String get libraryDownload => 'डाउनलोड';

  @override
  String get libraryUnlockNote =>
      'अनलॉक करने पर आपके कॉइन बैलेंस से एक बार ही कटौती होती है, पहली बार टैप न हो तो भी। डाउनलोड से पहले फ़ाइल अनलॉक करनी होगी।';

  @override
  String libraryReviewsCount(Object count) {
    return '$count समीक्षाएं';
  }

  @override
  String get libraryDownloads => 'डाउनलोड';

  @override
  String get libraryAccess => 'पहुँच';

  @override
  String get libraryWriteReview => 'समीक्षा लिखें (पहले अनलॉक करना होगा)';

  @override
  String get libraryCommentOptional => 'टिप्पणी (वैकल्पिक)';

  @override
  String get librarySubmitting => 'जमा हो रहा है…';

  @override
  String get librarySubmitReview => 'समीक्षा जमा करें';

  @override
  String get libraryReviewVerified =>
      'आपने फ़ाइल डाउनलोड/अनलॉक की है तो समीक्षा सत्यापित होती है।';

  @override
  String get libraryVerified => 'सत्यापित';

  @override
  String get librarySearchHint => 'फ़ाइल, श्रेणी खोजें…';

  @override
  String libraryTrendingFailed(Object reason) {
    return 'ट्रेंडिंग फ़ाइलें लोड नहीं हो सकीं।\n$reason';
  }

  @override
  String get libraryTrending => 'ट्रेंडिंग';

  @override
  String libraryRecommendedFailed(Object reason) {
    return 'आपके सुझाव लोड नहीं हो सके।\n$reason';
  }

  @override
  String get libraryRecommendedForYou => 'आपके लिए सुझाव';

  @override
  String get libraryFiles => 'फ़ाइलें';

  @override
  String libraryTotalCount(Object count) {
    return 'कुल $count';
  }

  @override
  String get libraryNoFiles => 'अभी तक कोई फ़ाइल नहीं';

  @override
  String libraryNoResults(Object query) {
    return '\"$query\" का कोई परिणाम नहीं';
  }

  @override
  String get libraryNoFilesBody =>
      'सर्वर पर प्रकाशित और स्वीकृत होने के बाद लाइब्रेरी की फ़ाइलें यहाँ दिखेंगी।';

  @override
  String get libraryTryDifferentSearch =>
      'कोई दूसरा शब्द खोजें या फ़िल्टर हटाएं।';

  @override
  String get libraryClearSearch => 'खोज साफ़ करें';

  @override
  String get libraryNoCategories => 'कोई श्रेणी प्रकाशित नहीं';

  @override
  String get commonLoadMore => 'और लोड करें';

  @override
  String get commonLeaderboard => 'लीडरबोर्ड';

  @override
  String get commonWallet => 'वॉलेट';

  @override
  String get commonLibrary => 'लाइब्रेरी';

  @override
  String get practiceDrillComplete => 'ड्रिल पूरा हुआ';

  @override
  String get practiceDoesNotAffect =>
      'अभ्यास — रैंक, XP या स्ट्रीक को प्रभावित नहीं करता';

  @override
  String practiceQuestionsCount(Object count) {
    return '$count प्रश्न';
  }

  @override
  String practiceAnsweredSkipped(Object answered, Object skipped) {
    return '$answered उत्तर दिए • $skipped छोड़े';
  }

  @override
  String practiceScore(Object score) {
    return 'अंक $score';
  }

  @override
  String get practiceGradedByServer => 'सर्वर द्वारा अंकित';

  @override
  String practiceCorrectWrongSkipped(
    Object correct,
    Object wrong,
    Object skipped,
  ) {
    return '$correct सही • $wrong गलत • $skipped छोड़े';
  }

  @override
  String practiceGradingFailed(Object reason) {
    return 'सर्वर यह ड्रिल अंकित नहीं कर सका: $reason';
  }

  @override
  String get practiceReviewPassNote =>
      'यह एक दोहराव था। कोई प्रयास नहीं बनाया गया, इसलिए दिखाने कोई अंक नहीं है।';

  @override
  String get practiceNoQuestionsInSet => 'इस सेट में कोई प्रश्न नहीं';

  @override
  String practiceQuestionCounter(Object current, Object total) {
    return 'प्रश्न $current/$total';
  }

  @override
  String get practiceUntimedPractice => 'समय-सीमित नहीं • अभ्यास';

  @override
  String practiceDifficultyLabel(Object difficulty) {
    return 'कठिनाई: $difficulty';
  }

  @override
  String get practiceNoOptionsNotice =>
      'सर्वर ने यह प्रश्न विकल्पों के बिना भेजा, इसलिए यहाँ ड्रिल नहीं किया जा सकता। अंक वाला Quiz टैब आज़माएं, जो पूरा सत्र लोड करता है।';

  @override
  String get practiceAnswerSentNotice =>
      'उत्तर सर्वर को भेजा गया। सर्वर प्रयास को अंकित करता है — यह स्क्रीन कभी अंक का अनुमान नहीं लगाती।';

  @override
  String get practicePrev => 'पिछला';

  @override
  String get practiceGrading => 'अंक लगा रहे हैं…';

  @override
  String get practiceNoEffectNote =>
      'अभ्यास समय-सीमित नहीं है और इसका अंक, XP, कॉइन या स्ट्रीक पर कोई प्रभाव नहीं पड़ता।';

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
