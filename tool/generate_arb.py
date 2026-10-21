# -*- coding: utf-8 -*-
"""Regenerates the three ARB files from one master table.

The app ships English, Nepali and Hindi. Hand-editing three JSON files in
lockstep is how they drift, so the copy lives here once — English, Nepali
and Hindi side by side — and this script writes the ARB files from it.

A key that is missing from any locale is a build error in `flutter gen-l10n`,
so the three files can never fall out of step.

    python tool/generate_arb.py
"""

import io
import json
import os

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
L10N = os.path.join(BASE, "lib", "l10n")

# key: (english, nepali, hindi, [placeholders])
T = {}


def add(key, en, ne, hi, placeholders=None):
    assert key not in T, "duplicate key: %s" % key
    T[key] = (en, ne, hi, placeholders or [])


# ── existing keys ────────────────────────────────────────────────────────────
add("appTitle", "CivilCal", "CivilCal", "CivilCal")
add("signIn", "Sign in", "साइन इन गर्नुहोस्", "साइन इन करें")
add("register", "Register", "दर्ता गर्नुहोस्", "रजिस्टर करें")
add("quiz", "Quiz", "क्विज", "क्विज़")
add("practice", "Practice", "अभ्यास", "अभ्यास")
add("calculators", "Calculators", "क्यालकुलेटर", "कैलकुलेटर")
add("courses", "Courses", "कोर्स", "कोर्स")
add("continueAsGuest", "Continue as guest", "अतिथिको रूपमा जारी राख्नुहोस्", "अतिथि के रूप में जारी रखें")
add("backend", "Backend", "ब्याकइन्ड", "बैकएंड")
add("env", "Env", "वातावरण", "एनवी")
add("home", "Home", "गृहपृष्ठ", "होम")
add("profile", "Profile", "प्रोफाइल", "प्रोफ़ाइल")
add("settings", "Settings", "सेटिङ", "सेटिंग")
add("offline", "Offline", "अफलाइन", "ऑफ़लाइन")
add("retry", "Retry", "फेरि प्रयास", "फिर से प्रयास करें")
add("error", "Something went wrong", "केही गडबड भयो", "कुछ गड़बड़ हो गई")
add("streakDays", "Streak: {days} days", "स्ट्रिक: {days} दिन", "स्ट्रीक: {days} दिन", ["days"])
add("coinsBalance", "{count} coins", "{count} क्विन", "{count} कॉइन", ["count"])
add("appLocked", "CivilCal is locked", "CivilCal लक छ", "CivilCal लॉक है")
add("unlock", "Unlock", "खोल्नुहोस्", "खोलें")
add("unlockCivilCal", "Unlock CivilCal", "CivilCal खोल्नुहोस्", "CivilCal खोलें")

# ── shared ───────────────────────────────────────────────────────────────────
add("commonCancel", "Cancel", "रद्द गर्नुहोस्", "रद्द करें")
add("commonSave", "Save", "सुरक्षित गर्नुहोस्", "सहेजें")
add("commonClose", "Close", "बन्द गर्नुहोस्", "बंद करें")
add("commonGoBack", "Go Back", "पछाडि जानुहोस्", "वापस जाएं")
add("commonStay", "Stay", "यहै रहनुहोस्", "यहीं रहें")
add("commonExit", "Exit", "बाहिर निस्कनुहोस्", "बाहर निकलें")
add("commonEmail", "Email", "इमेल", "ईमेल")
add("commonPassword", "Password", "पासवर्ड", "पासवर्ड")
add("commonContinueWithGoogle", "Continue with Google", "Google सँग जारी राख्नुहोस्", "Google के साथ जारी रखें")
add("commonContinueWithApple", "Continue with Apple", "Apple सँग जारी राख्नुहोस्", "Apple के साथ जारी रखें")
add("commonOr", "or", "वा", "या")
add("commonSkip", "Skip", "छोड्नुहोस्", "छोड़ें")
add("commonCheckAgain", "Check again", "फेरि जाँच्नुहोस्", "फिर से जांचें")
add("commonContactSupport", "Contact support", "सहायता सम्पर्क गर्नुहोस्", "सहायता से संपर्क करें")
add("commonShareResult", "Share Result", "नतिजा साझेदार गर्नुहोस्", "परिणाम साझा करें")
add("commonPoints", "{count} pts", "{count} अंक", "{count} अंक", ["count"])
add("commonPercent", "{value}%", "{value}%", "{value}%", ["value"])
add("commonXpGained", "+{amount} XP", "+{amount} XP", "+{amount} XP", ["amount"])

# ── auth ─────────────────────────────────────────────────────────────────────
add("authWelcomeBackTitle", "Welcome back", "पुनः स्वागत छ", "फिर से स्वागत है")
add(
    "authWelcomeBackSubtitle",
    "Sign in to access your quizzes, formulas, and ranking",
    "आफ्ना क्विज, सूत्र र अंक हेर्न साइन इन गर्नुहोस्",
    "अपने क्विज़, सूत्र और रैंक देखने के लिए साइन इन करें",
)
add("authForgotPasswordTitle", "Forgot Password?", "पासवर्ड बिर्सनुभयो?", "पासवर्ड भूल गए?")
add(
    "authForgotPasswordSubtitle",
    "Enter your registered email and we will send you instructions to reset your password.",
    "तपाईंको दर्ता गरिएको इमेल लेख्नुहोस्, हामी पासवर्ड रिसेट गर्ने निर्देश पठाउनेछौं।",
    "अपना पंजीकृत ईमेल दर्ज करें, हम आपको पासवर्ड रीसेट करने के निर्देश भेजेंगे।",
)
add("authEmailAddressLabel", "Email Address", "इमेल ठेगाना", "ईमेल पता")
add("authSendResetLink", "Send Reset Link", "रिसेट लिंक पठाउनुहोस्", "रीसेट लिंक भेजें")
add("authCheckEmailTitle", "Check your email", "आफ्नो इमेल हेर्नुहोस्", "अपना ईमेल देखें")
add(
    "authCheckEmailBody",
    "If an account exists with {email}, you will receive a password reset link shortly.",
    "{email} सँग खाता भए छुट्टै पासवर्ड रिसेट लिंक पठाइनेछौं।",
    "यदि {email} के साथ खाता मौजूद है, तो हम जल्द ही पासवर्ड रीसेट लिंक भेजेंगे।",
    ["email"],
)
add("authReturnToLogin", "Return to Login", "लगइनमा फर्कनुहोस्", "लॉगिन पर लौटें")
add("authJoinTitle", "Join CivilCal", "CivilCal मा सामेल हुनुहोस्", "CivilCal से जुड़ें")
add(
    "authJoinSubtitle",
    "Your companion for engineering exams and calculations",
    "इन्जिनियरिङ परीक्षा र गणितका लागि तपाईंको साथी",
    "इंजीनियरिंग परीक्षा और गणना के लिए आपका साथी",
)
add("authFullNameLabel", "Full Name", "पूरा नाम", "पूरा नाम")
add("authConfirmPasswordLabel", "Confirm Password", "पासवर्ड पुष्टि गर्नुहोस्", "पासवर्ड की पुष्टि करें")
add("authCreateAccount", "Create Account", "खाता खोल्नुहोस्", "खाता बनाएं")
add("authAlreadyHaveAccount", "Already have an account?", "पहिले नै खाता छ?", "पहले से खाता है?")
add("authNoAccount", "Don't have an account?", "खाता छैन?", "खाता नहीं है?")
add("authSetNewPasswordTitle", "Set a new password", "नयाँ पासवर्ड राख्नुहोस्", "नया पासवर्ड रखें")
add("authResetTitle", "Choose a new password", "नयाँ पासवर्ड छान्नुहोस्", "नया पासवर्ड चुनें")
add(
    "authResetSubtitle",
    "You will be signed out everywhere, including this device.",
    "तपाईं सबै यन्त्रमा, यस यन्त्रमा पनि, साइन आउट हुनुहुनेछ।",
    "आप हर जगह, इस डिवाइस सहित, साइन आउट हो जाएंगे।",
)
add(
    "authResetMissingToken",
    "This link is missing its reset token. Open the link from your email, or request a new one.",
    "यो लिंकमा रिसेट टोकन छैन। इमेलबाट पठाइएको लिंक खोल्नुहोस्, वा नयाँ लिंक माग्नुहोस्।",
    "इस लिंक में रीसेट टोकन नहीं है। ईमेल से भेजा गया लिंक खोलें, या नया लिंक मांगें।",
)
add("authRequestNewLink", "Request a new link", "नयाँ लिंक माग्नुहोस्", "नया लिंक मांगें")
add("authRequestNewLinkInstead", "Request a new link instead", "त्यसैले नयाँ लिंक माग्नुहोस्", "इसके बजाय नया लिंक मांगें")
add("authNewPasswordLabel", "New password", "नयाँ पासवर्ड", "नया पासवर्ड")
add("authConfirmNewPasswordLabel", "Confirm new password", "नयाँ पासवर्ड पुष्टि गर्नुहोस्", "नए पासवर्ड की पुष्टि करें")
add("authMinChars", "At least {count} characters", "कम्तीमा {count} अक्षर", "कम से कम {count} अक्षर", ["count"])
add("authVerifyEmailBanner", "Verify your email to unlock every feature.", "सबै सुविधा खोल्न आफ्नो इमेल प्रमाणित गर्नुहोस्।", "सभी सुविधाएं खोलने के लिए अपना ईमेल सत्यापित करें।")
add("authSplashTagline", "BiSaaS Engineering Learning Ecosystem", "बिसास इन्जिनियरिङ लर्निङ इकोसिस्टम", "बिसास इंजीनियरिंग लर्निंग इकोसिस्टम")
add("authInvalidEmail", "Enter a valid email", "मान्य इमेल लेख्नुहोस्", "मान्य ईमेल दर्ज करें")
add("authPasswordRequired", "Please enter your password", "कृपया आफ्नो पासवर्ड लेख्नुहोस्", "कृपया अपना पासवर्ड दर्ज करें")

# ── onboarding ───────────────────────────────────────────────────────────────
add("onboardingStepOf", "Step {current} of {total}", "चरण {current} / {total}", "चरण {current} / {total}", ["current", "total"])
add("onboardingTargetExamTitle", "Target Examination", "लक्षित परीक्षा", "लक्षित परीक्षा")
add(
    "onboardingTargetExamBody",
    "Sets the syllabus this account studies towards.",
    "यो खाताले कुन पाठ्यक्रमतर्फ अध्ययन गर्छ तो तोक्न्छ।",
    "यह तय करता है कि यह खाता किस पाठ्यक्रम की ओर पढ़ेगा।",
)
add("onboardingDailyGoalTitle", "Daily Practice Goal", "दैनिक अभ्यासको लक्ष्य", "दैनिक अभ्यास का लक्ष्य")
add(
    "onboardingDailyGoalBody",
    "How much time would you like to dedicate each day? You can change this anytime.",
    "तपाईं दैनिक कति समय दिन चाहनुहुन्छ? जुनसुकै बेला परिवर्तन गर्न सकिन्छ।",
    "आप रोज़ाना कितना समय देना चाहेंगे? आप कभी भी बदल सकते हैं।",
)
add("onboardingMinutesPerDay", "{minutes} mins / day — {label}", "दिनमा {minutes} मिनेट — {label}", "{minutes} मिनट / दिन — {label}", ["minutes", "label"])
add("onboardingCurrentLevelTitle", "Your Current Level", "तपाईंको हालको तह", "आपका वर्तमान स्तर")
add(
    "onboardingCurrentLevelBody",
    "Sets where your streak and revision queue start from.",
    "तपाईंको स्ट्रिक र दोहोराइ कतामा सुरु हुन्छ तो तोक्न्छ।",
    "यह तय करता है कि आपकी स्ट्रीक और दोहराव कहाँ से शुरू होगी।",
)

# ── quiz ─────────────────────────────────────────────────────────────────────
add("quizHomeTitle", "Practice & Quiz", "अभ्यास र क्विज", "अभ्यास और क्विज़")
add("quizHomeLoadError", "Could not load quiz", "क्विज लोड गर्न सकिएन", "क्विज़ लोड नहीं हो सका")
add("quizHomeEmptyTitle", "No quizzes yet", "अहिलेसम्म कुनै क्विज छैन", "अभी तक कोई क्विज़ नहीं")
add(
    "quizHomeEmptyBody",
    "Question sets for your exam are being prepared. Check back soon.",
    "तपाईंको परीक्षाका प्रश्न संग्रह तयार हुँदैछ। छिट्टै फेरि जाँच्नुहोस्।",
    "आपकी परीक्षा के प्रश्न तैयार किए जा रहे हैं। जल्द ही फिर देखें।",
)
add("quizPlayWorlds", "Play Worlds", "वर्ल्डहरू खेल्नुहोस्", "वर्ल्ड खेलें")
add("quizPlayWorldsSubtitle", "Chapters, levels and bosses — earn stars as you go", "अध्याय, तह र बड — अघि बढ्दै स्टार कमाउनुहोस्", "अध्याय, स्तर और बॉस — आगे बढ़ते सितारे कमाएं")
add("quizPracticeDrill", "Practice drill", "अभ्यास ड्रिल", "अभ्यास ड्रिल")
add(
    "quizPracticeDrillSubtitle",
    "Drill your bookmarks and weak topics — untimed, no rank effect",
    "आफ्ना बुकमार्क र कमजोर विषय दोहोराउनुहोस् — समयसीमा छैन, अंकमा असर छैन",
    "अपने बुकमार्क और कमजोर विषय दोहराएं — समय-सीमित नहीं, रैंक पर असर नहीं",
)
add("quizIntroDetailsTitle", "Quiz Details", "क्विजको विवरण", "क्विज़ का विवरण")
add("quizIntroLoadFailed", "Failed to load quiz: {reason}", "क्विज लोड गर्न सकिएन: {reason}", "क्विज़ लोड नहीं हो सका: {reason}", ["reason"])
add("quizIntroQuestions", "Questions", "प्रश्नहरू", "प्रश्न")
add("quizIntroMinutes", "min", "मिनेट", "मिनट")
add("quizIntroStart", "Start Quiz", "क्विज सुरु गर्नुहोस्", "क्विज़ शुरू करें")
add("quizIntroHowItWorks", "How it works", "यसरी काम गर्छ", "यह कैसे काम करता है")
add("quizAttemptLoadError", "Could not load quiz", "क्विज लोड गर्न सकिएन", "क्विज़ लोड नहीं हो सका")
add(
    "quizAttemptOfflineNotice",
    "Offline practice — not official. XP/coins will reconcile when back online.",
    "अफलाइन अभ्यास — आधिकारिक होइन। इन्टरनेट फर्केपछि XP/क्विन मिलाइनेछन्।",
    "ऑफ़लाइन अभ्यास — आधिकारिक नहीं। इंटरनेट लौटने पर XP/कॉइन मिला दिए जाएंगे।",
)
add(
    "quizAttemptUnsupportedEffect",
    "{effect} used — the server returned an effect this app cannot show yet.",
    "{effect} प्रयोग भयो — सर्भरले यस्तो इफेक्ट फर्कायो जुन यो एपले अहिले देखाउन सक्दैन।",
    "{effect} उपयोग हुआ — सर्वर ने ऐसा इफ़ेक्ट लौटाया जिसे यह ऐप अभी नहीं दिखा सकता।",
    ["effect"],
)
add("quizAttemptCombo", "×{count} Combo!", "×{count} कम्बो!", "×{count} कॉम्बो!", ["count"])
add("quizAttemptExitTitle", "Exit Quiz?", "क्विजबाट निस्कने?", "क्विज़ से बाहर निकलें?")
add(
    "quizAttemptExitBody",
    "Your current progress will be lost. Are you sure you want to exit?",
    "तपाईंको हालको प्रगति हराउनेछ। निस्कनेमा पक्का हुनुहुन्छ?",
    "आपकी अभी की प्रगति चली जाएगी। क्या आप वाकई बाहर निकलना चाहते हैं?",
)
add("quizResultTitle", "Quiz Complete!", "क्विज पूरा भयो!", "क्विज़ पूरा हुआ!")
add("quizResultAccuracy", "Accuracy", "शुद्धता", "शुद्धता")
add("quizResultCorrectOf", "{correct} of {total} correct", "{total} मध्ये {correct} सही", "{total} में से {correct} सही", ["correct", "total"])
add("quizResultCorrect", "Correct", "सही", "सही")
add("quizResultXpEarned", "XP Earned", "कमाइएको XP", "अर्जित XP")
add("quizResultCoins", "Coins", "क्विन", "कॉइन")
add("quizResultAnswerReview", "Answer Review", "उत्तर पुनरावलोकन", "उत्तर समीक्षा")
add("quizResultBackToHome", "Back to Home", "गृहपृष्ठमा फर्कनुहोस्", "होम पर लौटें")
add("quizResultReviewAll", "Review All Answers", "सबै उत्तर हेर्नुहोस्", "सभी उत्तर देखें")
add("quizResultMorePractice", "More Practice", "थप अभ्यास", "और अभ्यास")
add("quizResultShareFailed", "Share unavailable: {reason}", "साझेदारी उपलब्ध छैन: {reason}", "साझा करना उपलब्ध नहीं: {reason}", ["reason"])
add("quizReviewTitle", "Review Answers", "उत्तरहरू हेर्नुहोस्", "उत्तर देखें")
add("quizReviewLoadFailed", "Failed to load review: {reason}", "पुनरावलोकन लोड गर्न सकिएन: {reason}", "समीक्षा लोड नहीं हो सकी: {reason}", ["reason"])
add("quizReviewEmpty", "No answers to review", "हेर्नुपर्ने कुनै उत्तर छैन", "देखने के लिए कोई उत्तर नहीं")
add("quizReviewYourAnswer", "Your answer", "तपाईंको उत्तर", "आपका उत्तर")
add("quizReviewNotAnswered", "Not answered", "उत्तर दिइएको छैन", "उत्तर नहीं दिया गया")
add("quizReviewQuestionNumber", "Q{number}", "प्रश्न {number}", "प्रश्न {number}", ["number"])
add("quizFunnelTryItOut", "Try it out", "आजमाएर हेर्नुहोस्", "आजमाकर देखें")
add("quizFunnelSampleTitle", "Sample questions", "नमुना प्रश्नहरू", "नमूना प्रश्न")
add("quizFunnelShown", "{count} shown", "{count} देखाइएको", "{count} दिखाए गए", ["count"])
add("quizFunnelEmptyTitle", "No sample questions yet", "अहिलेसम्म कुनै नमुना प्रश्न छैन", "अभी तक कोई नमूना प्रश्न नहीं")
add(
    "quizFunnelEmptyBody",
    "The catalogue has no public questions published right now. Sign up and you will see everything.",
    "अहिले सङ्ग्रहमा सार्वजनिक प्रश्न छैनन्। खाता खोल्नुहोस्, सबै कुरा देख्नुहुन्छ।",
    "इस समय कैटलॉग में कोई सार्वजनिक प्रश्न नहीं है। साइन अप करें, आप सब कुछ देखेंगे।",
)
add("quizFunnelCreateAccount", "Create a free account to play", "खेल्न निःशुल्क खाता खोल्नुहोस्", "खेलने के लिए मुफ़्त खाता बनाएं")
add("quizFunnelPlayGraded", "Play a graded quiz", "मूल्याङ्कनसहितको क्विज खेल्नुहोस्", "अंक वाला क्विज़ खेलें")
add("quizFunnelPracticeNote", "Practice mode never affects rank, XP or streak.", "अभ्यास मोडले अंक, XP वा स्ट्रिकलाई कहिल्यै असर गर्दैन।", "अभ्यास मोड कभी रैंक, XP या स्ट्रीक को प्रभावित नहीं करता।")
add("quizOfflinePractice", "Offline Practice — {subject}", "अफलाइन अभ्यास — {subject}", "ऑफ़लाइन अभ्यास — {subject}", ["subject"])
add("quizFinishFailed", "Could not finish the quiz. Please try again.", "क्विज समाप्त गर्न सकिएन। कृपया फेरि प्रयास गर्नुहोस्।", "क्विज़ पूरा नहीं हो सका। कृपया फिर से कोशिश करें।")
add("quizCountUnavailable", "Count unavailable", "संख्या उपलब्ध छैन", "संख्या उपलब्ध नहीं")

# ── calculator ───────────────────────────────────────────────────────────────
add("calcBrowserEmpty", "No calculators published", "कुनै क्यालकुलेटर प्रकाशित छैन", "कोई कैलकुलेटर प्रकाशित नहीं")
add("calcBrowserCount", "{count} calculators • {domains} domains", "{count} क्यालकुलेटर • {domains} क्षेत्र", "{count} कैलकुलेटर • {domains} क्षेत्र", ["count", "domains"])
add("calcBrowserLoadError", "Could not load calculators", "क्यालकुलेटर लोड गर्न सकिएन", "कैलकुलेटर लोड नहीं हो सके")
add("calcShareFailed", "Could not share this result: {reason}", "यो नतिजा साझेदार गर्न सकिएन: {reason}", "यह परिणाम साझा नहीं हो सका: {reason}", ["reason"])
add("calcNoInputNamed", "No input named \"{name}\" on this calculator", "यस क्यालकुलेटरमा \"{name}\" नामको इनपुट छैन", "इस कैलकुलेटर में \"{name}\" नाम का इनपुट नहीं है", ["name"])
add("calcAddInput", "Add at least one input", "कम्तीमा एउटा इनपुट थप्नुहोस्", "कम से कम एक इनपुट जोड़ें")
add("calcInputsLabel", "Inputs · {label}", "इनपुट · {label}", "इनपुट · {label}", ["label"])
add("calcInputsLegacy", "Inputs (legacy)", "इनपुट (पुरानो)", "इनपुट (पुराना)")
add("calcKeyLabel", "key", "कुञ्जी", "कुंजी")
add("calcKeyExample", "e.g. length", "जस्तै: लम्बाइ", "जैसे: लंबाई")
add("calcValueLabel", "value", "मान", "मान")
add("calcValueExample", "e.g. 12.5", "जस्तै: 12.5", "जैसे: 12.5")
add("calcAssistantTitle", "Ask the assistant", "सहायकलाई सोध्नुहोस्", "सहायक से पूछें")
add("calcAssistantExample", "e.g. a 3 m wide, 4 m deep slab for a 25 MPa mix", "जस्तै: २५ MPa मिक्सका लागि ३ म चौडाइ, ४ म गहराइको स्ल्याब", "जैसे: 25 MPa मिक्स के लिए 3 मीटर चौड़ा, 4 मीटर गहरा स्लैब")
add("calcAssistantSuggested", "Suggested values", "सुझाव दिइएका मान", "सुझाए गए मान")
add("calcAssistantAlso", "You could also ask", "तपाईं यो पनि सोध्न सक्नुहुन्छ", "आप यह भी पूछ सकते हैं")
add("calcHistoryTitle", "{subject} · history", "{subject} · इतिहास", "{subject} · इतिहास", ["subject"])
add("calcHistoryEmpty", "No saved calculations yet", "अहिलेसम्म कुनै गणित सुरक्षित गरिएको छैन", "अभी तक कोई गणना सहेजी नहीं गई")
add("calcStepByStep", "Step-by-step", "चरणबद्ध", "चरणबद्ध")
add("calcShareResult", "Share result", "नतिजा साझेदार गर्नुहोस्", "परिणाम साझा करें")
add("calcPracticeRelated", "Practice related questions", "सम्बन्धित प्रश्न अभ्यास गर्नुहोस्", "संबंधित प्रश्न अभ्यास करें")
add("calcViewHistory", "View history", "इतिहास हेर्नुहोस्", "इतिहास देखें")
add(
    "calcNoSchema",
    "Server did not return a field schema. Falling back to generic key/value editor.",
    "सर्भरले फाँटको स्किमा दिएन। सामान्य कुञ्जी/मान सम्पादकमा प्रयोग गरिन्छ।",
    "सर्वर ने फ़ील्ड स्कीमा नहीं दी। सामान्य कुंजी/मान संपादक पर वापस जा रहे हैं।",
)
add("calcAddField", "Add field", "फाँट थप्नुहोस्", "फ़ील्ड जोड़ें")
add("calcInputsCount", "inputs: {count}", "इनपुट: {count}", "इनपुट: {count}", ["count"])
add("calcAsk", "Ask", "सोध्नुहोस्", "पूछें")
add("calcApply", "Apply", "प्रयोग गर्नुहोस्", "लागू करें")
add(
    "calcAssistantDisclaimer",
    "The assistant suggests; you decide. Calculations are always performed by the server.",
    "सहायकले सुझाव दिन्छ, निर्णय तपाईंको। गणित सधैँ सर्भरले गर्छ।",
    "सहायक सुझाव देता है, निर्णय आपका है। गणना हमेशा सर्वर करता है।",
)

# ── home ─────────────────────────────────────────────────────────────────────
add("homeGreeting", "Hi, {name} 👋", "नमस्ते, {name} 👋", "नमस्ते, {name} 👋", ["name"])
add("homeLevel", "Level {level} • {xp} XP", "तह {level} • {xp} XP", "स्तर {level} • {xp} XP", ["level", "xp"])
add("homeDaily", "Daily", "दैनिक", "दैनिक")
add("homeBattle", "Battle", "ब्याटल", "बैटल")
add("homeBrowse", "Browse", "हेर्नुहोस्", "ब्राउज़ करें")
add("homeExplore", "Explore", "घुम्नुहोस्", "एक्सप्लोर करें")
add("homeCurrentCourse", "CURRENT COURSE", "हालको कोर्स", "वर्तमान कोर्स")
add("homePercentDone", "{percent}% Done", "{percent}% पूरा", "{percent}% पूरा", ["percent"])
add("homeMissionsUnavailable", "Missions unavailable", "मिसन उपलब्ध छैन", "मिशन उपलब्ध नहीं")
add("homeWorldsLoadError", "Could not load your worlds", "तपाईंका वर्ल्ड लोड गर्न सकिएन", "आपके वर्ल्ड लोड नहीं हो सके")
add("homeWorldsEmpty", "No worlds published yet — browse topics to keep practising.", "अहिलेसम्म कुनै वर्ल्ड प्रकाशित छैन — अभ्यास जारी राख्न विषय हेर्नुहोस्।", "अभी तक कोई वर्ल्ड प्रकाशित नहीं — अभ्यास जारी रखने के लिए विषय देखें।")
add("homeYourWorlds", "Your worlds", "तपाईंका वर्ल्ड", "आपके वर्ल्ड")
add("homeStars", "{earned} / {total} ⭐", "{earned} / {total} ⭐", "{earned} / {total} ⭐", ["earned", "total"])
add("homeContinue", "Continue: {title}", "जारी राख्नुहोस्: {title}", "जारी रखें: {title}", ["title"])
add("homeDashboardLoadError", "Could not load your dashboard", "तपाईंको ड्यासबोर्ड लोड गर्न सकिएन", "आपका डैशबोर्ड लोड नहीं हो सका")
add(
    "homeDashboardEmpty",
    "Nothing is shown rather than guessing. Pull to refresh, or retry below.",
    "अनुमान गर्नुको सट्टा केही देखाइएको छैन। तान्नुहोस्, वा तल फेरि प्रयास गर्नुहोस्।",
    "अनुमान लगाने के बजाय कुछ नहीं दिखाया गया। खींचें, या नीचे फिर से प्रयास करें।",
)
add(
    "homeDashboardUnreachable",
    "Could not reach the server, so the dashboard cannot be shown.",
    "सर्भरसम्म पुग्न सकिएन, त्यसैले ड्यासबोर्ड देखाउन सकिएन।",
    "सर्वर तक नहीं पहुँच सके, इसलिए डैशबोर्ड नहीं दिखाया जा सका।",
)

# ── consent ──────────────────────────────────────────────────────────────────
add("consentTitle", "Privacy choices", "गोपनीयता विकल्प", "गोपनीयता विकल्प")
add(
    "consentIntro",
    "Your account and quiz progress are stored on our servers so you can sign in on any device. To make that work and to keep the app stable we also send a device identifier, a push-notification token, crash reports and a device security check. With your permission we also send anonymous usage events. You can change this at any time in Settings → Privacy.",
    "तपाईंको खाता र क्विजको प्रगति हाम्रो सर्भरमा राखिन्छ, जसले तपाईं जुनसुकै यन्त्रमा साइन इन गर्न सक्नुहुन्छ। यसले काम गर्न र एप स्थिर रहनका लागि हामी यन्त्र पहिचान, पुश सूचना टोकन, क्र्यास रिपोर्ट र यन्त्र सुरक्षा जाँच पनि पठाउँछौं। तपाईंको अनुमति भए हामी प्रयोग सम्बन्धी घटना पनि पठाउँछौं। Settings → Privacy मा गएर जुनसुकै बेला परिवर्तन गर्न सकिन्छ।",
    "आपका खाते और क्विज़ की प्रगति हमारे सर्वर पर रखी जाती है, ताकि आप किसी भी डिवाइस में साइन इन कर सकें। इसके काम करने और ऐप को स्थिर रखने के लिए हम डिवाइस पहचान, पुश नोटिफिकेशन टोकन, क्रैश रिपोर्ट और डिवाइस सुरक्षा जाँच भी भेजते हैं। आपकी अनुमति से हम उपयोग घटनाएं भी भेजते हैं। आप Settings → Privacy में जाकर कभी भी इसे बदल सकते हैं।",
)
add("consentNecessary", "Necessary", "आवश्यक", "आवश्यक")
add(
    "consentNecessaryBody",
    "Sign-in and your saved work, your push-notification token, crash reports, and a device security check. Required for the app to work.",
    "साइन इन र तपाईंको सुरक्षित काम, पुश सूचना टोकन, क्र्यास रिपोर्ट र यन्त्र सुरक्षा जाँच। एप चल्नका लागि आवश्यक।",
    "साइन इन और आपका सहेजा काम, आपका पुश नोटिफिकेशन टोकन, क्रैश रिपोर्ट और डिवाइस सुरक्षा जाँच। ऐप चलने के लिए आवश्यक।",
)
add("consentFunctional", "Functional", "कार्यक्षम", "कार्यक्षम")
add(
    "consentFunctionalBody",
    "Remember settings such as your language and filters on this device.",
    "तपाईंको भाषा र फिल्टरजस्ता सेटिङ यस यन्त्रमा सम्झनुहोस्।",
    "आपकी भाषा और फ़िल्टर जैसे सेटिंग इस डिवाइस पर याद रखें।",
)
add("consentAnalytics", "Analytics", "विश्लेषण", "विश्लेषण")
add(
    "consentAnalyticsBody",
    "Usage events that tell us which features are useful. They are tied to a device identifier rather than to your account. No question content is ever included.",
    "प्रयोग सम्बन्धी घटना जुन सुविधाहरू उपयोगी छन् भनी देखाउँछ। तिनीहरू तपाईंको खातासँग होइन, यन्त्र पहिचानसँग जोडिन्छन्। प्रश्नको सामग्री कहिल्यै समावेश हुँदैन।",
    "उपयोग घटनाएं जो बताती हैं कि कौन-सी सुविधाएं उपयोगी हैं। वे आपके खाते से नहीं, डिवाइस पहचान से जुड़ी होती हैं। प्रश्न का सामग्री कभी शामिल नहीं होता।",
)
add("consentMarketing", "Marketing", "प्रचार", "प्रचार")
add(
    "consentMarketingBody",
    "Offers and promotions. Off unless you ask for it.",
    "अफर र प्रचार। तपाईं नभाएसम्म बन्द।",
    "ऑफ़र और प्रचार। जब तक आप न कहें, बंद रहता है।",
)
add("consentSaveChoices", "Save choices", "विकल्प सुरक्षित गर्नुहोस्", "विकल्प सहेजें")
add("consentNecessaryOnly", "Continue with necessary only", "आवश्यक मात्र राखेर जारी राख्नुहोस्", "केवल आवश्यक के साथ जारी रखें")
add("consentLoadError", "Could not load your choices", "तपाईंका विकल्प लोड गर्न सकिएन", "आपके विकल्प लोड नहीं हो सके")
add(
    "consentNecessaryAlwaysOn",
    "Always on. Your account, saved work, push token, crash reports and device security check.",
    "सधैं सक्रिय। तपाईंको खाता, सुरक्षित काम, पुश टोकन, क्र्यास रिपोर्ट र यन्त्र सुरक्षा जाँच।",
    "हमेशा चालू। आपका खाता, सहेजा काम, पुश टोकन, क्रैश रिपोर्ट और डिवाइस सुरक्षा जाँच।",
)
add("consentDataStored", "Data stored about this device", "यस यन्त्रबारे सुरक्षित डाटा", "इस डिवाइस के बारे में सहेजा डेटा")
add("consentDataStoredSubtitle", "View, and erase, the anonymous profile", "अनाम प्रोफाइल हेर्नुहोस् र मेटाउनुहोस्", "अनाम प्रोफ़ाइल देखें और मिटाएं")
add(
    "consentFootnote",
    "Turning off a category stops that collection from that moment. It does not delete data already collected — for that, use the link above or contact privacy@bisaas.com.",
    "कुनै श्रेणी बन्द गर्दा त्यस संग्रह त्यस क्षणबाट रोकिन्छ। पहिले संग्रह भएको डाटा भने महिल्न्छ — त्यसका लागि माथिको लिंक प्रयोग गर्नुहोस् वा privacy@bisaas.com मा सम्पर्क गर्नुहोस्।",
    "कोई श्रेणी बंद करने से उस संग्रह उस क्षण से रुक जाता है। पहले संग्रह किया गया डेटा नहीं मिटता — इसके लिए ऊपर दिए लिंक का उपयोग करें या privacy@bisaas.com पर संपर्क करें।",
)

# ── privacy ──────────────────────────────────────────────────────────────────
add("privacyTitle", "Your data", "तपाईंको डाटा", "आपका डेटा")
add("privacyAnonymousProfile", "Anonymous profile", "अनाम प्रोफाइल", "अनाम प्रोफ़ाइल")
add("privacyReference", "Reference {reference}", "सन्दर्भ {reference}", "संदर्भ {reference}", ["reference"])
add("privacyEraseData", "Erase stored data", "सुरक्षित डाटा मेटाउनुहोस्", "सहेजा डेटा मिटाएं")
add("privacyLocalChoices", "Local choices", "यस यन्त्रका विकल्प", "इस डिवाइस के विकल्प")
add("privacyEraseTitle", "Erase stored data?", "सुरक्षित डाटा मेटाउने?", "सहेजा डेटा मिटाएं?")
add(
    "privacyEraseBody",
    "This deletes the anonymous profile and every intent event stored for this device. It cannot be undone.",
    "यसले अनाम प्रोफाइल र यस यन्त्रका लागि सुरक्षित भएका सबै इन्टेन्ट घटना मेटाउँछ। यो पूर्ववत् हुँदैन।",
    "यह अनाम प्रोफ़ाइल और इस डिवाइस के लिए सहेजे गए सभी इंटेंट घटनाएं मिटा देता है। इसे पूर्ववत नहीं किया जा सकता।",
)
add("privacyErased", "Stored data erased", "सुरक्षित डाटा मेटाइयो", "सहेजा डेटा मिटा दिया गया")
add("privacyEraseFailed", "Could not erase your data. Try again.", "डाटा मेटाउन सकिएन। फेरि प्रयास गर्नुहोस्।", "डेटा मिटा नहीं सका। फिर से कोशिश करें।")
add("privacyEraseConfirm", "Erase", "मेटाउनुहोस्", "मिटाएं")
add("privacyMenu", "Privacy", "गोपनीयता", "गोपनीयता")

# ── notifications ────────────────────────────────────────────────────────────
add("notificationDailyTitle", "Daily Sprint ready ⚡", "दैनिक स्प्रिन्ट तयार छ ⚡", "दैनिक स्प्रिंट तैयार है ⚡")
add(
    "notificationDailyBody",
    "Your daily MCQs are waiting — keep the streak alive!",
    "तपाईंका दैनिक बहुविकल्पीय प्रश्न तयार छन् — स्ट्रिक जोगाउनुहोस्!",
    "आपके दैनिक बहुविकल्पीय प्रश्न तैयार हैं — स्ट्रीक जारी रखें!",
)

# ── app-level ────────────────────────────────────────────────────────────────
add("forceUpdateTitle", "Update required", "अद्यावधिक आवश्यक", "अपडेट आवश्यक")
add("forceUpdateYourVersion", "Your version: {version}", "तपाईंको संस्करण: {version}", "आपका संस्करण: {version}", ["version"])
add("forceUpdateNow", "Update now", "अहिले अद्यावधिक गर्नुहोस्", "अभी अपडेट करें")
add(
    "forceUpdateReassurance",
    "Your account and progress are safe — nothing is lost by updating.",
    "तपाईंको खाता र प्रगति सुरक्षित छ — अद्यावधिकले केही गुमाउँदैन।",
    "आपका खाता और प्रगति सुरक्षित है — अपडेट करने से कुछ नहीं खोता।",
)
add("forceUpdateStoreFailed", "Could not open the store. Visit {url}", "स्टोर खोल्न सकिएन। {url} मा जानुहोस्", "स्टोर नहीं खुल सका। {url} पर जाएं", ["url"])
add("maintenanceTitle", "We'll be right back", "हामी छिट्टै फर्कन्छौं", "हम जल्द ही वापस आ रहे हैं")
add(
    "maintenanceBody",
    "CivilCal is down for a short maintenance. Your account, coins and progress are safe — nothing has been lost.",
    "CivilCal सँक्षिप्त मर्मतका लागि बन्द छ। तपाईंको खाता, क्विन र प्रगति सुरक्षित छ — केही गुमेको छैन।",
    "CivilCal संक्षिप्त रखरखाव के लिए बंद है। आपका खाता, कॉइन और प्रगति सुरक्षित है — कुछ नहीं खोया गया है।",
)
add("versionUnsupported", "This app version is no longer supported.", "यो एप संस्करण अब समर्थित छैन।", "यह ऐप संस्करण अब समर्थित नहीं है।")

# ── second pass: the strings the conditional-branch scan surfaced ───────────
add("authUpdating", "Updating…", "अद्यावधिक हुँदैछ…", "अपडेट हो रहा है…")
add("authUpdatePassword", "Update password", "पासवर्ड अद्यावधिक गर्नुहोस्", "पासवर्ड अपडेट करें")
add(
    "authVerificationResentBody",
    "If that address still needs verifying, a new link is on its way. Check your inbox and spam folder.",
    "यो ठेगाना अझै प्रमाणित हुनुपर्ने छ भने नयाँ लिंक पठाइदैछौं। आफ्नो इनबक्स र स्प्याम फोल्डर हेर्नुहोस्।",
    "यदि वह पता अभी सत्यापित करना है, तो नया लिंक भेजा जा रहा है। अपना इनबॉक्स और स्पैम फ़ोल्डर देखें।",
)
add(
    "authVerificationResentHint",
    "We send a one-tap verification link to the address on your account.",
    "हामी तपाईंको खाताको ठेगानामा एक ट्यापको प्रमाणीकरण लिंक पठाउँछौं।",
    "हम आपके खाते के पते पर एक टैप का सत्यापन लिंक भेजते हैं।",
)
add("authVerificationSent", "Verification sent", "प्रमाणीकरण पठाइयो", "सत्यापन भेजा गया")
add("authResendVerification", "Resend verification email", "प्रमाणीकरण इमेल पुनः पठाउनुहोस्", "सत्यापन ईमेल फिर से भेजें")
add("calcSearchInDomain", "Search {scope} calculators…", "{scope} क्यालकुलेटर खोज्नुहोस्…", "{scope} कैलकुलेटर खोजें…", ["scope"])
add("calcSearchPlaceholder", "Search calculators…", "क्यालकुलेटर खोज्नुहोस्…", "कैलकुलेटर खोजें…")
add("calcCalculating", "Calculating…", "गणना हुँदैछ…", "गणना हो रही है…")
add("calcCalculateServer", "Calculate (server)", "गणना गर्नुहोस् (सर्भर)", "गणना करें (सर्वर)")
add("calcVia", "via {source}", "{source} मार्फत", "{source} के ज़रिए", ["source"])
add("homeMissionsReady", "{count} missions ready to claim", "{count} मिसन दावी गर्न तयार", "{count} मिशन दावा करने के लिए तैयार", ["count"])
add("homeMissionsActive", "Missions — {count} active", "मिसन — {count} सक्रिय", "मिशन — {count} सक्रिय", ["count"])
add("onboardingStartLearning", "Start Learning", "सिकाइ सुरु गर्नुहोस्", "सीखना शुरू करें")
add("onboardingContinue", "Continue", "जारी राख्नुहोस्", "जारी रखें")
add(
    "privacyLinkedToAccount",
    "This profile is linked to your account. Delete the account to erase everything.",
    "यो प्रोफाइल तपाईंको खातासँग जोडिएको छ। सबै मेटाउन खाता नै हटाउनुहोस्।",
    "यह प्रोफ़ाइल आपके खाते से जुड़ा है। सब कुछ मिटाने के लिए खाता ही हटाएं।",
)
add("quizSeeResults", "See Results", "नतिजा हेर्नुहोस्", "परिणाम देखें")
add("quizNextQuestion", "Next Question", "अर्को प्रश्न", "अगला प्रश्न")
add("quizAnswerSubmitted", "Answer submitted", "उत्तर पठाइयो", "उत्तर जमा हुआ")
add("quizBrowseQuizzes", "Browse Quizzes", "क्विजहरू हेर्नुहोस्", "क्विज़ ब्राउज़ करें")
add("quizPickTopic", "Pick a Topic", "विषय छान्नुहोस्", "विषय चुनें")
add("quizSearchCourses", "Search courses…", "कोर्स खोज्नुहोस्…", "कोर्स खोजें…")
add("quizSearchTopics", "Search topics…", "विषय खोज्नुहोस्…", "विषय खोजें…")
add("quizNoCoursesYet", "No courses yet", "अहिलेसम्म कुनै कोर्स छैन", "अभी तक कोई कोर्स नहीं")
add("quizNoMatches", "No matches", "कुनै मिलान छैन", "कोई मिलान नहीं")
add(
    "quizSetsBeingPrepared",
    "Question sets for your exam are being prepared.",
    "तपाईंको परीक्षाका प्रश्न संग्रह तयार हुँदैछ।",
    "आपकी परीक्षा के प्रश्न तैयार किए जा रहे हैं।",
)
add("quizTryDifferentSearch", "Try a different search", "अर्को खोजी प्रयास गर्नुहोस्", "कोई दूसरी खोज आज़माएं")
add("quizNoTopicsYet", "No topics yet", "अहिलेसम्म कुनै विषय छैन", "अभी तक कोई विषय नहीं")
add("quizCourseNoActiveTopics", "This course has no active topics yet.", "यो कोर्समा अहिलेसम्म कुनै सक्रिय विषय छैन।", "इस कोर्स में अभी तक कोई सक्रिय विषय नहीं है।")
add(
    "quizFunnelSampleBody",
    "Sample questions from our catalogue. Open the Quiz tab to play a full graded session.",
    "हाम्रो सङ्ग्रहबाट नमुना प्रश्नहरू। पूर्ण अंकयुक्त सत्र खेल्न Quiz ट्याब खोल्नुहोस्।",
    "हमारे कैटलॉग से नमूना प्रश्न। पूर्ण अंक वाला सत्र खेलने के लिए Quiz टैब खोलें।",
)
add(
    "quizFunnelPublicBody",
    "Public questions from our catalogue. Answers unlock when you create a free account.",
    "हाम्रो सङ्ग्रहबाट सार्वजनिक प्रश्नहरू। निःशुल्क खाता बनाएपछि उत्तरहरू खुल्छन्।",
    "हमारे कैटलॉग से सार्वजनिक प्रश्न। मुफ़्त खाता बनाने पर उत्तर खुलते हैं।",
)
add("quizFreshQuestions", "Fresh questions were added recently.", "हालै नयाँ प्रश्नहरू थपिएका छन्।", "हाल ही में नए प्रश्न जोड़े गए हैं।")
add("quizNewIn", "New in {scope}", "{scope} मा नयाँ", "{scope} में नया", ["scope"])
add("quizNoQuestionText", "This question has no text on the server.", "यो प्रश्नको सर्भरमा कुनै पाठ छैन।", "इस प्रश्न का सर्वर पर कोई टेक्स्ट नहीं है।")
add("quizGraded", "Graded", "अंकयुक्त", "अंक वाला")
add("quizXp", "XP", "XP", "XP")
add("quizByServer", "by server", "सर्भरद्वारा", "सर्वर द्वारा")

# ── profile ──────────────────────────────────────────────────────────────────
add("profileAvatarUploaded", "Avatar uploaded", "अवतार अपलोड भयो", "अवतार अपलोड हो गया")
add("profileAvatarUpdated", "Avatar updated", "अवतार अद्यावधिक भयो", "अवतार अपडेट हो गया")
add("profileUploadFailed", "Upload failed: {reason}", "अपलोड असफल: {reason}", "अपलोड विफल: {reason}", ["reason"])
add("profileEditName", "Edit name", "नाम सम्पादन गर्नुहोस्", "नाम संपादित करें")
add("profileDisplayName", "Display name", "प्रदर्शित नाम", "प्रदर्शित नाम")
add("profileUpdated", "Profile updated", "प्रोफाइल अद्यावधिक भयो", "प्रोफ़ाइल अपडेट हो गया")
add("profileUpdateFailed", "Update failed: {reason}", "अद्यावधिक असफल: {reason}", "अपडेट विफल: {reason}", ["reason"])
add(
    "profileShareCardText",
    "My CivilCal profile — Level {level} Engineer. https://bisaas.com",
    "मेरो CivilCal प्रोफाइल — तह {level} इन्जिनियर। https://bisaas.com",
    "मेरा CivilCal प्रोफ़ाइल — स्तर {level} इंजीनियर। https://bisaas.com",
    ["level"],
)
add("profileShareFailed", "Share failed: {reason}", "साझेदारी असफल: {reason}", "साझा करना विफल: {reason}", ["reason"])
add("profileShareCard", "Share card", "कार्ड साझेदार गर्नुहोस्", "कार्ड साझा करें")
add("profileLevel", "Lv {level}", "तह {level}", "स्तर {level}", ["level"])
add("profileChangeAvatar", "Change avatar", "अवतार परिवर्तन गर्नुहोस्", "अवतार बदलें")
add("profileEditAvatar", "Edit avatar", "अवतार सम्पादन गर्नुहोस्", "अवतार संपादित करें")
add("profileStreak", "Streak", "स्ट्रिक", "स्ट्रीक")
add("profileSkillRadar", "Skill Radar", "सीप रेडार", "स्किल रडार")
add("profileSkillsFailed", "Skills failed: {reason}", "सीप लोड असफल: {reason}", "स्किल लोड विफल: {reason}", ["reason"])
add("profileAchievements", "Achievements", "उपलब्धि", "उपलब्धियां")
add("profileAchievementsLoadFailed", "Could not load achievements", "उपलब्धि लोड गर्न सकिएन", "उपलब्धियां लोड नहीं हो सकीं")
add(
    "profileNoBadges",
    "No badges yet — complete quizzes to earn them!",
    "अहिलेसम्म कुनै ब्याज छैन — क्विज पूरा गरेर कमाउनुहोस्!",
    "अभी तक कोई बैज नहीं — क्विज़ पूरे करके कमाएं!",
)
add("profileUnlocked", "Unlocked", "खुला", "अनलॉक")
add(
    "profileSkillRadarEmpty",
    "Take quizzes to reveal your skill radar.",
    "आफ्नो सीप रेडार देख्न क्विज खेल्नुहोस्।",
    "अपना स्किल रडार देखने के लिए क्विज़ खेलें।",
)
add(
    "profileSkillRadarEmptyHint",
    "Answer more categories to reveal your skill radar.",
    "आफ्नो सीप रेडार देख्न थप श्रेणीहरूमा उत्तर दिनुहोस्।",
    "अपना स्किल रडार देखने के लिए अधिक श्रेणियों के प्रश्नों के उत्तर दें।",
)
add("profileLearning", "Learning — tracks & AI tutor", "सिकाइ — ट्र्याक र AI ट्युटर", "सीखना — ट्रैक और AI ट्यूटर")
add("profileLearningSub", "study plans • revisions • tutor", "अध्ययन योजना • दोहोराइ • ट्युटर", "अध्ययन योजना • दोहराव • ट्यूटर")
add("profileEice", "Exam Intelligence (EICE)", "परीक्षा बुद्धि (EICE)", "परीक्षा बुद्धि (EICE)")
add("profileEiceSub", "coach • triage • sprint", "कोच • त्रायज • स्प्रिन्ट", "कोच • ट्रायेज • स्प्रिंट")
add("profilePsc", "PSC / Loksewa", "PSC / लोकसेवा", "PSC / लोकसेवा")
add("profilePscSub", "exam blueprints & syllabus", "परीक्षा ढाँचा र पाठ्यक्रम", "परीक्षा ढांचा और पाठ्यक्रम")
add("profilePracticeSub", "drill bookmarks • weak topics", "बुकमार्क ड्रिल • कमजोर विषय", "बुकमार्क ड्रिल • कमजोर विषय")
add("profileLeaderboard", "Leaderboard", "लिडरबोर्ड", "लीडरबोर्ड")
add("profileLeaderboardSub", "global • friends • league", "विश्व • साथी • लिग", "विश्व • दोस्त • लीग")
add("profileContests", "Contests", "प्रतियोगिता", "प्रतियोगिताएं")
add("profileContestsSub", "live quizzes & leaderboards", "प्रत्यक्ष क्विज र लिडरबोर्ड", "लाइव क्विज़ और लीडरबोर्ड")
add("profileLiveEvents", "Live events", "प्रत्यक्ष कार्यक्रम", "लाइव कार्यक्रम")
add("profileLiveEventsSub", "scheduled sessions & check-in", "तोकिएका सत्र र चेक-इन", "निर्धारित सत्र और चेक-इन")
add("profileCoaching", "Coaching", "कोचिङ", "कोचिंग")
add("profileCoachingSub", "weak areas • readiness • sprint", "कमजोर क्षेत्र • तयारी • स्प्रिन्ट", "कमजोर क्षेत्र • तैयारी • स्प्रिंट")
add("profileSearch", "Search", "खोज्नुहोस्", "खोजें")
add("profileSearchSub", "find any question", "कुनै पनि प्रश्न खोज्नुहोस्", "कोई भी प्रश्न खोजें")
add("profileNotifications", "Notifications", "सूचनाहरू", "सूचनाएं")
add("profileNotificationsSub", "activity & reminders", "गतिविधि र सम्झना", "गतिविधि और याद दिलाना")
add("profileSocial", "Social & Referral", "सामाजिक र रेफरल", "सोशल और रेफरल")
add("profileSocialSub", "share • streak • leaderboard", "साझेदारी • स्ट्रिक • लिडरबोर्ड", "साझा • स्ट्रीक • लीडरबोर्ड")
add("profileWallet", "Wallet", "वालेट", "वॉलेट")
add("profileWalletSub", "coins & ledger", "क्विन र खाता", "कॉइन और बही")
add("profileAchievementsSub", "streak + badges", "स्ट्रिक + ब्याज", "स्ट्रीक + बैज")
add("profileOffline", "Offline content", "अफलाइन सामग्री", "ऑफ़लाइन सामग्री")
add("profileOfflineSub", "cached packs + prefetch", "क्यास गरिएका प्याक + प्रीफेच", "कैश किए गए पैक + प्रीफ़ेच")
add("profileCalculatorsSub", "Civil formula engines", "सिभिल सूत्र इन्जिन", "सिविल फ़ॉर्मूला इंजन")
add("profileSettingsSub", "language • biometrics • logout", "भाषा • बायोमेट्रिक • लगआउट", "भाषा • बायोमेट्रिक • लॉगआउट")

# ── settings ────────────────────────────────────────────────────────────────
add(
    "settingsSubscriptionActive",
    "Subscription must be cancelled before deletion",
    "खाता मेटाउनुअघि सदस्यता रद्द गर्नुपर्छ",
    "खाता मिटाने से पहले सदस्यता रद्द करनी होगी",
)
add(
    "settingsDeleteFailed",
    "Could not delete account — please try again",
    "खाता मेटाउन सकिएन — कृपया फेरि प्रयास गर्नुहोस्",
    "खाता मिटा नहीं सका — कृपया फिर से कोशिश करें",
)
add("settingsAccountDeleted", "Your account has been deleted", "तपाईंको खाता मेटाइएको छ", "आपका खाता मिटा दिया गया है")
add(
    "settingsNoBiometrics",
    "No biometrics enrolled on this device",
    "यस यन्त्रमा कुनै बायोमेट्रिक दर्ता छैन",
    "इस डिवाइस पर कोई बायोमेट्रिक दर्ज नहीं है",
)
add(
    "settingsLanguageLocalOnly",
    "Language saved on this device only — could not reach the server.",
    "भाषा यस यन्त्रमा मात्र सुरक्षित भयो — सर्भरसम्म पुग्न सकिएन।",
    "भाषा केवल इस डिवाइस पर सहेजी गई — सर्वर तक नहीं पहुँच सके।",
)
add("settingsSystemDefault", "System default", "प्रणालीको सान्दर्भ", "सिस्टम डिफ़ॉल्ट")
add("settingsAppLanguage", "App language", "एपको भाषा", "ऐप की भाषा")
add("settingsBiometricLock", "Biometric app lock", "बायोमेट्रिक एप लक", "बायोमेट्रिक ऐप लॉक")
add(
    "settingsBiometricLockSub",
    "Require biometrics after 30s in background",
    "पृष्ठभूमिमा ३० सेकेन्डपछि बायोमेट्रिक माग्नुहोस्",
    "बैकग्राउंड में 30 सेकंड बाद बायोमेट्रिक माँगें",
)
add(
    "settingsPrivacySub",
    "Analytics, functional and marketing consent",
    "विश्लेषण, कार्यक्षम र प्रचारको सहमति",
    "विश्लेषण, कार्यक्षम और प्रचार की सहमति",
)
add("settingsAiUsage", "Your AI usage", "तपाईंको AI प्रयोग", "आपका AI का उपयोग")
add(
    "settingsAiUsageSub",
    "What AI used on your behalf, by feature",
    "तपाईंको तर्फमा AI ले के प्रयोग गर्यो, सुविधाअनुसार",
    "आपकी ओर से AI ने क्या इस्तेमाल किया, सुविधा के अनुसार",
)
add("settingsAiKeys", "Your AI keys", "तपाईंका AI कुञ्जीहरू", "आपकी AI कुंजियां")
add(
    "settingsAiKeysSub",
    "Run AI features on your own provider quota",
    "AI सुविधाहरू आफ्नै प्रोभाइडरको कोटामा चलाउनुहोस्",
    "AI सुविधाएं अपने प्रोवाइडर के कोटे पर चलाएं",
)
add("settingsLogOut", "Log out", "लगआउट", "लॉग आउट")
add("settingsDeleteAccount", "Delete account", "खाता मेटाउनुहोस्", "खाता मिटाएं")
add(
    "settingsDeleteAccountSub",
    "Permanently erase your account, attempts and purchases",
    "तपाईंको खाता, प्रयास र खरोद स्थायी रूपमा मेटाउनुहोस्",
    "आपका खाता, प्रयास और खरीद स्थायी रूप से मिटाएं",
)
add("settingsDeleteAccountTitle", "Delete account?", "खाता मेटाउने?", "खाता मिटाएं?")
add(
    "settingsDeleteAccountBody",
    "This permanently deletes your account, quiz history, coins and purchases. This cannot be undone.",
    "यसले तपाईंको खाता, क्विज इतिहास, क्विन र खरोद स्थायी रूपमा मेटाउँछ। यो पूर्ववत् हुँदैन।",
    "यह आपका खाता, क्विज़ इतिहास, कॉइन और खरीद स्थायी रूप से मिटा देता है। इसे पूर्ववत नहीं किया जा सकता।",
)
add(
    "settingsTypeDeleteToConfirm",
    "Type 'DELETE' to confirm",
    "पुष्टि गर्न 'DELETE' लेख्नुहोस्",
    "पुष्टि करने के लिए 'DELETE' लिखें",
)
add("settingsDeleteConfirm", "Delete", "मेटाउनुहोस्", "मिटाएं")

# ── streak ──────────────────────────────────────────────────────────────────
add("streakRefresh", "Refresh", "ताजा गर्नुहोस्", "रिफ्रेश करें")
add("streakNoneTitle", "No streak yet", "अहिलेसम्म कुनै स्ट्रिक छैन", "अभी तक कोई स्ट्रीक नहीं")
add(
    "streakNoneBody",
    "Complete a quiz to start your fire streak.",
    "आफ्नो स्ट्रिक सुरु गर्न एउटा क्विज पूरा गर्नुहोस्।",
    "अपनी स्ट्रीक शुरू करने के लिए एक क्विज़ पूरा करें।",
)
add("streakCalendar", "Calendar", "पात्रो", "कैलेंडर")
add(
    "streakOnFire",
    "You are on fire today — keep it up!",
    "आज तपाईंको स्ट्रिक उत्कर्ष छ — यसै गरिरहनुहोस्!",
    "आज आपकी स्ट्रीक जोश में है — ऐसे ही बनाए रखें!",
)
add("streakProtect", "Protect your streak", "आफ्नो स्ट्रिक जोगाउनुहोस्", "अपनी स्ट्रीक बचाएं")
add("streakFrozen", "Streak frozen for 30 days!", "स्ट्रिक ३० दिनका लागि फ्रिज गरियो!", "स्ट्रीक 30 दिन के लिए फ्रीज़ हो गई!")
add("streakCurrent", "Current streak", "हालको स्ट्रिक", "वर्तमान स्ट्रीक")
add("streakDaysUnit", "days", "दिन", "दिन")
add("streakBest", "Best: {count} days", "उत्कृष्ट: {count} दिन", "सर्वश्रेष्ठ: {count} दिन", ["count"])
add("streakMultiplier", "multiplier", "गुणक", "गुणक")
add(
    "streakMaxMultiplier",
    "Max multiplier reached — legendary!",
    "अधिकतम गुणक प्राप्त — किंवदन्ती!",
    "अधिकतम गुणक प्राप्त — किंवदंती!",
)
add(
    "streakDaysToNextTier",
    "{current} / {total} days to next tier",
    "अर्को तहसम्म {current} / {total} दिन",
    "अगले स्तर तक {current} / {total} दिन",
    ["current", "total"],
)
add(
    "streakTiers",
    "1–6d → 1.0× • 7–29d → 1.5× • 30–99d → 2.0× • 100+d → 3.0×",
    "१–६ दिन → १.०× • ७–२९ दिन → १.५× • ३०–९९ दिन → २.०× • १००+ दिन → ३.०×",
    "1–6 दिन → 1.0× • 7–29 दिन → 1.5× • 30–99 दिन → 2.0× • 100+ दिन → 3.0×",
)
add("streakFreezeSection", "Streak freeze", "स्ट्रिक फ्रिज", "स्ट्रीक फ्रीज़")
add("streakFreezeLeft", "{count} left", "{count} बाँकी", "{count} बचे", ["count"])
add("streakFrozenUntil", "Frozen until {date}", "{date} सम्म फ्रिज", "{date} तक फ्रीज़", ["date"])
add(
    "streakFreezeHint",
    "Spend 50 coins to freeze streak for 30 days when you cannot play. Donor badge required.",
    "खेल्न नसक्दा ३० दिनका लागि स्ट्रिक फ्रिज गर्न ५० क्विन खर्च्नुहोस्। दानकार ब्याज आवश्यक।",
    "खेल न पाएँदा 30 दिनका लिए स्ट्रीक फ्रीज़ गर्न 50 कॉइन खर्च्नुहोस्। दानकर्ता बैज आवश्यक।",
)
add("streakExtendFreeze", "Extend freeze", "फ्रिज थप्नुहोस्", "फ्रीज़ बढाउनुहोस्")
add(
    "streakFreezeAction",
    "Freeze streak (50 coins)",
    "स्ट्रिक फ्रिज गर्नुहोस् (५० क्विन)",
    "स्ट्रीक फ्रीज़ करें (50 कॉइन)",
)
add("streakRepairTitle", "Repair a missed day", "छुटेको दिन मर्मत गर्नुहोस्", "छूटे दिन को मरम्मत करें")
add("streakRepairAction", "Repair streak", "स्ट्रिक मर्मत गर्नुहोस्", "स्ट्रीक मरम्मत करें")
add("streakInsurance", "Streak insurance", "स्ट्रिक बीमा", "स्ट्रीक बीमा")
add("streakInsuranceChecking", "Checking insurance…", "बीमा जाँच्दै…", "बीमा जांच रहे हैं…")
add("streakBuy", "Buy", "किन्नुहोस्", "खरीदें")
add("streakUseNow", "Use now", "अहिले प्रयोग गर्नुहोस्", "अभी उपयोग करें")
add("streakWager", "Streak wager", "स्ट्रिक वागर", "स्ट्रीक वेजर")
add(
    "streakWagerDescription",
    "Stake coins on hitting a target streak. Meet it and you win the pot back with interest — miss and the coins are gone.",
    "लक्ष्य स्ट्रिक पुग्न क्विन लगाउनुहोस्। पुगेमा ब्याजसहित पुरोट फर्कन्छ, नपुगे क्विन गुम्छ।",
    "लक्ष्य स्ट्रीक तक पहुँचने के लिए कॉइन लगाएं। पहुँच गए तो ब्याज सहित पूरी जैसी वापस, नहीं पहुँचे तो कॉइन चले जाएंगे।",
)
add(
    "streakWagerDay",
    "Day {current} of {total} — keep playing to win {reward} coins.",
    "{total} मध्येको {current} दिन — {reward} क्विन जित्न खेलिरहनुहोस्।",
    "{total} में से {current} दिन — {reward} कॉइन जीतने के लिए खेलते रहें।",
    ["current", "total", "reward"],
)
add("streakWagerStart", "Start a wager", "वागर सुरु गर्नुहोस्", "वेजर शुरू करें")
add("streakWagerInProgress", "Wager in progress", "वागर चलिरहेको छ", "वेजर चल रहा है")
add("streakWagerStartTitle", "Start a streak wager", "स्ट्रिक वागर सुरु गर्नुहोस्", "स्ट्रीक वेजर शुरू करें")
add(
    "streakWagerStartBody",
    "Hit the target streak to win double. Miss it and the stake is gone.",
    "दुब्बे जित्न लक्ष्य स्ट्रिक पुग्नुहोस्। नपुगे लगाइएको क्विन गुम्छ।",
    "दुगना जीतने के लिए लक्ष्य स्ट्रीक तक पहुँचें। नहीं पहुँचे तो लगाई गई रकम चली जाएगी।",
)
add("streakWagerStake", "Stake (coins)", "लगाउने क्विन", "लगाने वाले कॉइन")
add("streakWagerDays", "Days to sustain", "कायम राख्ने दिन", "बनाए रखने वाले दिन")
add("streakXpMultiplier", "×{value} XP", "×{value} XP", "×{value} XP", ["value"])
add("streakWagerProgress", "{percent}% complete", "{percent}% पूरा", "{percent}% पूरा", ["percent"])
add("streakFreezeDuration", "30 days", "३० दिन", "30 दिन")
add("streakWagerDaysCount", "{count} days", "{count} दिन", "{count} दिन", ["count"])
add(
    "streakWagerSummary",
    "Wager {coins} coins for {days} days",
    "{days} दिनका लागि {coins} क्विनको वागर",
    "{days} दिन के लिए {coins} कॉइन का वेजर",
    ["coins", "days"],
)
add(
    "forceUpdateUnsupportedLatest",
    "This version of CivilCal is no longer supported. Please update to the latest version to continue.",
    "यो CivilCal संस्करण अब समर्थित छैन। जारी राख्न कृपया नवीनतम संस्करणमा अद्यावधिक गर्नुहोस्।",
    "यह CivilCal संस्करण अब समर्थित नहीं है। जारी रखने के लिए कृपया नवीनतम संस्करण पर अपडेट करें।",
)
add(
    "forceUpdateUnsupportedVersion",
    "This version of CivilCal is no longer supported. Please update to version {version} or later to continue.",
    "यो CivilCal संस्करण अब समर्थित छैन। जारी राख्न कृपया {version} वा त्यसभन्दा पछिल्लो संस्करणमा अद्यावधिक गर्नुहोस्।",
    "यह CivilCal संस्करण अब समर्थित नहीं है। जारी रखने के लिए कृपया {version} या उससे नए संस्करण पर अपडेट करें।",
    ["version"],
)
add("routeNotFound", "Route not found: {path}", "मार्ग फेला परेन: {path}", "रूट नहीं मिला: {path}", ["path"])

# ── write ────────────────────────────────────────────────────────────────────
# The placeholder types decide the signature gen-l10n generates. `Object`
# accepts whatever the caller has — an int, a double, a nullable String that
# was already coalesced — and gen-l10n stringifies it. Only the counters that
# are unambiguously whole numbers keep the `int` type.
PLACEHOLDER_TYPES = {
    "days": "int",
    "count": "int",
    "current": "int",
    "total": "int",
}


def build(locale_index, locale):
    out = {"@@locale": locale}
    for key, values in T.items():
        out[key] = values[locale_index]
        names = values[3]
        if names:
            meta = {"placeholders": {}}
            for name in names:
                meta["placeholders"][name] = {
                    "type": PLACEHOLDER_TYPES.get(name, "Object")
                }
            out["@" + key] = meta
    return out


def write(locale_index, locale):
    data = build(locale_index, locale)
    path = os.path.join(L10N, "app_%s.arb" % locale)
    with io.open(path, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(json.dumps(data, ensure_ascii=False, indent=2))
        fh.write("\n")
    print("wrote %s (%d keys)" % (os.path.relpath(path, BASE), len(data) - 1))


write(0, "en")
write(1, "ne")
write(2, "hi")
print("master table: %d keys" % len(T))
