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
add(
    "settingsAiUsageSub",
    "What AI used on your behalf, by feature",
    "तपाईंको तर्फमा AI ले के प्रयोग गर्यो, सुविधाअनुसार",
    "आपकी ओर से AI ने क्या इस्तेमाल किया, सुविधा के अनुसार",
)
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

# ── tutor ───────────────────────────────────────────────────────────────────
add("tutorStudyPlan", "Study Plan", "अध्ययन योजना", "अध्ययन योजना")
add("tutorChat", "Chat", "कुराकानी", "चैट")
add("tutorPlanTab", "Plan", "योजना", "योजना")
add("tutorInsights", "Insights", "विश्लेषण", "विश्लेषण")
add("tutorRevisions", "Revisions", "दोहोराइ", "दोहराव")
add("tutorWeekly", "Weekly", "साप्ताहिक", "साप्ताहिक")
add("tutorNoTasksToday", "No tasks today — check back tomorrow", "आज कुनै काम छैन — भोलि हेर्नुहोस्", "आज कोई काम नहीं — कल देखें")
add("tutorDone", "Done", "पूरा", "पूर्ण")
add("tutorTasksDone", "{done}/{total} tasks", "{done}/{total} काम", "{done}/{total} काम", ["done", "total"])
add("tutorDayCompleted", "Day completed — plan updated.", "दिन पूरा भयो — योजना अद्यावधिक भयो।", "दिन पूरा हुआ — योजना अपडेट हुई।")
add("tutorMarkDayComplete", "Mark day complete", "दिन पूरा भएको जनाउनुहोस्", "दिन पूरा चिह्नित करें")
add("tutorYourPlan", "Your plan — {title}", "तपाईंको योजना — {title}", "आपकी योजना — {title}", ["title"])
add("tutorPlanDays", "{days} days • current {current}", "{days} दिन • हालको {current}", "{days} दिन • वर्तमान {current}", ["days", "current"])
add("tutorPlanNoDays", "Plan has no days yet — onboarding will generate it.", "योजनामा अहिलेसम्म दिन छैनन् — अन onboarding ले बनाउनेछ।", "योजना में अभी तक दिन नहीं हैं — ऑनबोर्डिंग इसे बनाएगी।")
add("tutorMoreDays", "+ {count} more days", "+ {count} थप दिन", "+ {count} और दिन", ["count"])
add("tutorAdjustPlan", "Adjust plan", "योजना मिलाउनुहोस्", "योजना बदलें")
add("tutorNoPlanYet", "No plan yet", "अहिलेसम्म कुनै योजना छैन", "अभी तक कोई योजना नहीं")
add(
    "tutorOnboardingRequired",
    "Complete tutor onboarding to generate your personalized study plan.",
    "तपाईंको व्यक्तिगत अध्ययन योजना बनाउन ट्युटर onboarding पूरा गर्नुहोस्।",
    "आपकी व्यक्तिगत अध्ययन योजना बनाने के लिए ट्यूटर ऑनबोर्डिंग पूरा करें।",
)
add("tutorStartOnboarding", "Start onboarding", "Onboarding सुरु गर्नुहोस्", "ऑनबोर्डिंग शुरू करें")
add(
    "tutorAdjustExample",
    "e.g., \"I can do 3h/day\" or \"Focus more on soil mechanics\"",
    "जस्तै, \"म दिनमा ३ घण्टा गर्न सक्छु\" वा \"माटोको यान्त्रिकीमा बढी ध्यान दिन्छु\"",
    "जैसे, \"मैं रोज़ 3 घंटे कर सकता हूं\" या \"मिट्टी की यांत्रिकी पर अधिक ध्यान दें\"",
)
add("tutorAdjustPrompt", "How should we adjust?", "कसरी मिलाउने?", "कैसे बदलें?")
add("tutorAdjustRequested", "Plan adjustment requested.", "योजना मिलाउने अनुरोध भयो।", "योजना बदलने का अनुरोध भेजा गया।")
add("tutorSubmit", "Submit", "पेश गर्नुहोस्", "जमा करें")
add("tutorProjectedScore", "Projected score", "अनुमानित अंक", "अनुमानित अंक")
add("tutorConfidence", "Confidence {confidence}% • {trend}", "विश्वास {confidence}% • {trend}", "विश्वास {confidence}% • {trend}", ["confidence", "trend"])
add("tutorWeakAreas", "Weak areas", "कमजोर क्षेत्र", "कमजोर क्षेत्र")
add(
    "tutorNoWeakAreas",
    "No weak areas — great work! Keep practicing to stay sharp.",
    "कुनै कमजोर क्षेत्र छैन — उत्कृष्ट काम! तल्कुल तयार रहनुहोस्।",
    "कोई कमजोर क्षेत्र नहीं — बहुत बढ़िया! तेज़ रहने के लिए अभ्यास जारी रखें।",
)
add("tutorAccuracy", "Accuracy {accuracy}% • {attempts} attempts", "शुद्धता {accuracy}% • {attempts} प्रयास", "शुद्धता {accuracy}% • {attempts} प्रयास", ["accuracy", "attempts"])
add("tutorNoRevisionsDue", "No revisions due — you are on track.", "कुनै दोहोराइ बाँकी छैन — तपाईं कुशलमा हुनुहुन्छ।", "कोई दोहराव बाकी नहीं — आप सही रास्ते पर हैं।")
add("tutorDueLabel", "due {date}", "{date} सम्म", "{date} तक", ["date"])
add(
    "tutorTopicDue",
    "{topic} • due {date}",
    "{topic} • {date} सम्म",
    "{topic} • {date} तक",
    ["topic", "date"],
)
add("tutorCompleted", "Completed", "पूरा भयो", "पूरा हुआ")
add("tutorOverdue", "Overdue", "समय बित्यो", "समय बीत चुका")
add("tutorDue", "Due", "बाकी", "बाकी")
add("tutorWeekRange", "Week {start} → {end}", "हप्ता {start} → {end}", "सप्ताह {start} → {end}", ["start", "end"])
add("tutorAvgScore", "Avg score", "औसत अंक", "औसत अंक")
add("tutorHours", "Hours", "घण्टा", "घंटे")
add("tutorCompletion", "{percent}% completion", "{percent}% पूरा", "{percent}% पूरा", ["percent"])
add("tutorHighlights", "Highlights", "मुख्य कुराहरू", "मुख्य बातें")
add("tutorWeeklyReportPending", "Weekly report appears after a week of activity.", "हप्ताको गतिविधि पछि साप्ताहिक प्रतिवेदन देखिन्छ।", "एक सप्ताह की गतिविधि के बाद साप्ताहिक रिपोर्ट दिखेगी।")
add("tutorOnboardingSaved", "Onboarding saved — plan will generate shortly.", "Onboarding सुरक्षित भयो — योजना छिट्टै बनाइनेछ।", "ऑनबोर्डिंग सहेजी गई — योजना जल्द बनेगी।")
add("tutorOnboardingTitle", "Tutor Onboarding", "ट्युटर Onboarding", "ट्यूटर ऑनबोर्डिंग")
add("tutorPersonalised", "Personalized tutor", "व्यक्तिगत ट्युटर", "व्यक्तिगत ट्यूटर")
add(
    "tutorOnboardingExplain",
    "Tell us your goal — the server builds your plan. No user_id required (token-bound).",
    "आफ्नो लक्ष्य बताउनुहोस् — सर्भरले तपाईंको योजना बनाउँछ। user_id चाहिन्छैन (टोकनबाट)।",
    "अपना लक्ष्य बताएं — सर्वर आपकी योजना बनाएगा। user_id की ज़रूरत नहीं (टोकन से)।",
)
add("tutorSessionLabel", "Session: {session}", "सत्र: {session}", "सत्र: {session}", ["session"])
add("tutorYourGoal", "Your goal", "तपाईंको लक्ष्य", "आपका लक्ष्य")
add("tutorGoalExample", "e.g., Crack PSC Civil in 6 months", "जस्तै, ६ महिनामा PSC सिभिल क्र्याक गर्ने", "जैसे, 6 महीने में PSC सिविल क्रैक करना")
add("tutorCurrentLevel", "Current level", "हालको तह", "वर्तमान स्तर")
add("tutorLevelExample", "e.g., Final year B.E. Civil", "जस्तै: B.E. सिभिल अन्तिम वर्ष", "जैसे: B.E. सिविल अंतिम वर्ष")
add("tutorHoursPerDay", "Hours per day", "दिनमा घण्टा", "प्रतिदिन घंटे")
add("tutorHoursExample", "e.g., 2", "जस्तै: २", "जैसे: 2")
add("tutorOnboardingComplete", "Onboarding complete — your plan is ready.", "Onboarding पूरा भयो — तपाईंको योजना तयार छ।", "ऑनबोर्डिंग पूरा हुई — आपकी योजना तैयार है।")
add("tutorViewPlan", "View Plan", "योजना हेर्नुहोस्", "योजना देखें")
add("tutorCompleteOnboarding", "Complete onboarding", "Onboarding पूरा गर्नुहोस्", "ऑनबोर्डिंग पूरा करें")
add("tutorSkipToChat", "Skip → Chat with tutor", "छोड्नुहोस् → ट्युटरसँग कुराकानी", "छोड़ें → ट्यूटर से चैट")
add(
    "tutorSavedToAccount",
    "Saved to your account. Safe to retry if the connection drops.",
    "तपाईंको खातामा सुरक्षित भयो। जडान बिच्छ भने फेरि प्रयास गर्न सकिन्छ।",
    "आपके खाते में सहेजा गया। कनेक्शन टूटे तो फिर से कोशिश करना सुरक्षित है।",
)
add("tutorTitle", "AI Tutor", "AI ट्युटर", "AI ट्यूटर")
add("tutorClearChat", "Clear chat", "कुराकानी हटाउनुहोस्", "चैट साफ़ करें")
add(
    "tutorNotEnoughHistory",
    "Not enough history yet — complete a few quizzes to personalize.",
    "अहिलेसम्म पर्याप्त इतिहास छैन — व्यक्तिगत बनाउन केही क्विज पूरा गर्नुहोस्।",
    "अभी पर्याप्त इतिहास नहीं — व्यक्तिगत बनाने के लिए कुछ क्विज़ पूरे करें।",
)
add("tutorDismiss", "Dismiss", "हटाउनुहोस्", "खारिज करें")
add(
    "tutorWriting",
    "The tutor is writing its reply. It can take a moment on longer questions.",
    "ट्युटरले आफ्नो जवाफ लेख्दैछ। लामो प्रश्नमा केही समय लाग्न सक्छ।",
    "ट्यूटर अपना उत्तर लिख रहा है। लंबे प्रश्न में कुछ समय लग सकता है।",
)
add("tutorAskAnything", "Ask anything", "केही पनि सोध्नुहोस्", "कुछ भी पूछें")
add(
    "tutorChatExplain",
    "Exam concepts, beam deflection, soil mechanics — AI answers via Laravel gateway (never direct provider).",
    "परीक्षाका कन्सेप्ट, बिम डिफ्लेक्सन, माटोको यान्त्रिकी — AI उत्तर Laravel गेटवेबहरूबाट दिन्छ (कहिल्यै सिधै प्रोभाइडरबाट होइन)।",
    "परीक्षा के अवधारणाएं, बीम डिफ्लेक्शन, मिट्टी की यांत्रिकी — AI उत्तर Laravel गेटवे से देता है (कभी सीधे प्रोवाइडर से नहीं)।",
)
add("tutorExample1", "Explain proctor compaction", "प्रोक्टर कम्प्याक्सन बुझाउनुहोस्", "प्रोक्टर कम्पैक्शन समझाएं")
add("tutorExample2", "Weekly plan help", "साप्ताहिक योजनामा मद्दत", "साप्ताहिक योजना में मदद")
add("tutorExample3", "Weak areas?", "कमजोर क्षेत्रहरू?", "कमजोर क्षेत्र?")
add("tutorTyping", "Tutor is typing…", "ट्युटर लेख्दैछ…", "ट्यूटर लिख रहा है…")
add("tutorInputHint", "Ask tutor…", "ट्युटरलाई सोध्नुहोस्…", "ट्यूटर से पूछें…")

# ── AI settings ─────────────────────────────────────────────────────────────
add("aiUsageTitle", "Your AI usage", "तपाईंको AI प्रयोग", "आपका AI का उपयोग")
add("aiUsageOverview", "Overview", "समग्र", "अवलोकन")
add("aiUsageRequests", "requests", "अनुरोध", "अनुरोध")
add("aiUsageTokens", "tokens", "टोकन", "टोकन")
add("aiUsageTutorChats", "tutor chats (all time)", "ट्युटर कुराकानी (सबै समय)", "ट्यूटर चैट (सभी समय)")
add("aiUsageNone", "No AI features were used in this period.", "यो अवधिमा कुनै AI सुविधा प्रयोग भएको छैन।", "इस अवधि में कोई AI सुविधा उपयोग नहीं हुई।")
add("aiUsageByFeature", "By feature", "सुविधाअनुसार", "सुविधा के अनुसार")
add("aiUsageTutorConversations", "Tutor conversations", "ट्युटर कुराकानीहरू", "ट्यूटर बातचीत")
add("aiUsageNoConversations", "No tutor conversations yet.", "अहिलेसम्म कुनै ट्युटर कुराकानी छैन।", "अभी तक कोई ट्यूटर बातचीत नहीं।")
add("aiUsageLoadMoreConversations", "Load more conversations", "थप कुराकानीहरू हेर्नुहोस्", "और बातचीत लोड करें")
add("aiUsageWeeklyReport", "Weekly report card", "साप्ताहिक प्रतिवेदन", "साप्ताहिक रिपोर्ट कार्ड")
add("aiUsageNoWeeks", "No weekly summaries stored yet.", "अहिलेसम्म कुनै साप्ताहिक सारांश सुरक्षित छैन।", "अभी तक कोई साप्ताहिक सारांश सहेजा नहीं गया।")
add("aiUsageLoadMoreWeeks", "Load more weeks", "थप हप्ता हेर्नुहोस्", "और सप्ताह लोड करें")
add("aiUsageConversationNumber", "Conversation #{number}", "कुराकानी #{number}", "बातचीत #{number}", ["number"])
add("aiUsageQuestionNumber", "Question {number}", "प्रश्न {number}", "प्रश्न {number}", ["number"])
add("aiUsageTurns", "{count} turns", "{count} पटक", "{count} बार", ["count"])
add("aiUsageWeekOf", "Week of {date}", "{date} को हप्ता", "{date} का सप्ताह", ["date"])
add(
    "aiUsageWeekSummary",
    "{accuracy}% accuracy • {xp} XP • {coins} coins • {streak} day streak",
    "{accuracy}% शुद्धता • {xp} XP • {coins} क्विन • {streak} दिन स्ट्रिक",
    "{accuracy}% शुद्धता • {xp} XP • {coins} कॉइन • {streak} दिन स्ट्रीक",
    ["accuracy", "xp", "coins", "streak"],
)
add("aiUsageHoursShort", "{hours}h", "{hours} घ", "{hours} घं", ["hours"])
add("aiKeysTitle", "Your AI keys", "तपाईंका AI कुञ्जीहरू", "आपकी AI कुंजियां")
add(
    "aiKeysExplain",
    "Your key is encrypted on our servers and never shown again. Only the last four characters are ever displayed.",
    "तपाईंको कुञ्जी हाम्रो सर्भरमा इन्क्रिप्टेड हुन्छ र पछि कहिल्यै देखाइँदैन। पछिल्लो चार अक्षर मात्र देखिन्छ।",
    "आपकी कुंजी हमारे सर्वर पर एन्क्रिप्ट होती है और कभी दोबारा नहीं दिखती। केवल अंतिम चार अक्षर दिखते हैं।",
)
add("aiKeysAddTitle", "Add a key", "कुञ्जी थप्नुहोस्", "कुंजी जोड़ें")
add("aiKeysNoneYet", "No keys yet", "अहिलेसम्म कुनै कुञ्जी छैन", "अभी तक कोई कुंजी नहीं")
add(
    "aiKeysNoneExplain",
    "Add a provider key to run AI features on your own quota instead of the shared one.",
    "साझा कोटामा होरुनेभन्दा आफ्नै कोटामा AI सुविधाहरू चलाउन प्रोभाइडर कुञ्जी थप्नुहोस्।",
    "साझा कोटे के बजाय अपने कोटे पर AI सुविधाएं चलाने के लिए प्रोवाइडर कुंजी जोड़ें।",
)
add("aiKeysStored", "Stored keys", "सुरक्षित कुञ्जीहरू", "सहेजी कुंजियां")
add("aiKeysTokensUsed", "{used} of {total} daily tokens used", "दैनिक {total} टोकनमध्ये {used} प्रयोग भयो", "{total} दैनिक टोकन में से {used} उपयोग", ["used", "total"])
add("aiKeysRevoke", "Revoke", "रद्द गर्नुहोस्", "रद्द करें")
add("aiKeysTooShort", "The key must be at least 8 characters", "कुञ्जी कम्तीमा ८ अक्षरको हुनुपर्छ", "कुंजी कम से कम 8 अक्षर की होनी चाहिए")
add("aiKeysAddProvider", "Add a provider key", "प्रोभाइडर कुञ्जी थप्नुहोस्", "प्रोवाइडर कुंजी जोड़ें")
add("aiKeysProvider", "Provider", "प्रोभाइडर", "प्रोवाइडर")
add("aiKeysApiKey", "API key", "API कुञ्जी", "API कुंजी")
add("aiKeysSentOnce", "Sent once and never shown again.", "एक पटक पठाइन्छ अनि कहिल्यै देखाइँदैन।", "एक बार भेजा जाता है और कभी दोबारा नहीं दिखता।")
add("aiKeysLabelOptional", "Label (optional)", "लेबल (वैकल्पिक)", "लेबल (वैकल्पिक)")
add("aiKeysSaveKey", "Save key", "कुञ्जी सुरक्षित गर्नुहोस्", "कुंजी सहेजें")
add("aiKeysSaved", "{name} saved. It is encrypted on our servers and never shown again.", "{name} सुरक्षित भयो। यो हाम्रो सर्भरमा इन्क्रिप्टेड हुन्छ अनि कहिल्यै देखाइँदैन।", "{name} सहेजी गई। यह हमारे सर्वर पर एन्क्रिप्ट है और कभी दोबारा नहीं दिखेगी।", ["name"])
add("aiKeysRevoked", "Key revoked.", "कुञ्जी रद्द गरियो।", "कुंजी रद्द कर दी गई।")

# ── practice ────────────────────────────────────────────────────────────────
add("practiceBookmarks", "Bookmarks", "बुकमार्क", "बुकमार्क")
add("practiceWeakTopics", "Weak Topics", "कमजोर विषय", "कमजोर विषय")
add("practiceSelfChallenge", "Self Challenge", "आफैँ चुनौती", "स्वयं चुनौती")
add("practiceHistory", "History", "इतिहास", "इतिहास")
add("practiceNoBookmarks", "No bookmarks to practice", "अभ्यास गर्न कुनै बुकमार्क छैन", "अभ्यास के लिए कोई बुकमार्क नहीं")
add("practiceBookmarkedPractice", "Bookmarked Practice", "बुकमार्क अभ्यास", "बुकमार्क अभ्यास")
add(
    "practiceBookmarksUnavailable",
    "{count} of {total} bookmarks could not be drilled — the server does not publish their answer options yet.",
    "{total} मध्ये {count} बुकमार्क अभ्यास गर्न सकिएन — सर्भरले तिनका विकल्प अझै प्रकाशित गरेको छैन।",
    "{total} में से {count} बुकमार्क अभ्यास नहीं किए जा सके — सर्वर ने अभी तक उनके विकल्प प्रकाशित नहीं किए।",
    ["count", "total"],
)
add("practiceDrill", "Practice Drill", "अभ्यास ड्रिल", "अभ्यास ड्रिल")
add("practiceDrillCount", "Drill: {count}", "ड्रिल: {count}", "ड्रिल: {count}", ["count"])
add("practiceNoBookmarksBody", "No bookmarks", "कुनै बुकमार्क छैन", "कोई बुकमार्क नहीं")
add(
    "practiceNoBookmarksHint",
    "Bookmark questions while you take a quiz and they will show up here for drilling later.",
    "क्विज खेल्दा प्रश्न बुकमार्क गर्नुहोस्, पछि तिनीहरू यहाँ ड्रिलका लागि देखिन्छन्।",
    "क्विज़ खेलते समय प्रश्न बुकमार्क करें, बाद में वे यहाँ अभ्यास के लिए दिखेंगे।",
)
add("practiceBrowseQuizzes", "Browse quizzes", "क्विजहरू हेर्नुहोस्", "क्विज़ ब्राउज़ करें")
add("practiceBookmarkedCount", "{count} bookmarked", "{count} बुकमार्क", "{count} बुकमार्क", ["count"])
add("practiceAll", "Practice all", "सबै अभ्यास गर्नुहोस्", "सभी का अभ्यास करें")
add("practiceQuestionNumber", "Question #{number}", "प्रश्न #{number}", "प्रश्न #{number}", ["number"])
add("practiceQuestionMeta", "{meta} • difficulty {difficulty} • {points} pts", "{meta} • कठिनाई {difficulty} • {points} अंक", "{meta} • कठिनाई {difficulty} • {points} अंक", ["meta", "difficulty", "points"])
add("practiceBookmarked", "Bookmarked", "बुकमार्क गरिएको", "बुकमार्क किया गया")
add("practiceLoadMoreCursor", "Load more (cursor)", "थप हेर्नुहोस् (cursor)", "और लोड करें (cursor)")
add("practiceWeakTopicsLoadFailed", "Could not load your weak topics", "तपाईंका कमजोर विषय लोड गर्न सकिएन", "आपके कमजोर विषय लोड नहीं हो सके")
add(
    "practiceWeakTopicsExplained",
    "These are worked out from your own answer history. Nothing is shown unless it is real.",
    "यी तपाईंको आफ्नै उत्तर इतिहासबाट निकालिएका हुन्। सत्य नभएसम्म केही देखाइँदैन।",
    "ये आपके अपने उत्तर इतिहास से निकाले गए हैं। जब तक सच न हो, कुछ नहीं दिखाया जाता।",
)
add("practiceNoWeakTopics", "No weak topics yet", "अहिलेसम्म कुनै कमजोर विषय छैन", "अभी तक कोई कमजोर विषय नहीं")
add(
    "practiceWeakTopicsNeedsAttempts",
    "The server needs graded attempts before it can spot weak areas. Take a quiz from the Quiz tab and check back.",
    "कमजोर क्षेत्र पहिचान्न सर्भरलाई अंकयुक्त प्रयास चाहिन्छ। Quiz ट्याबबाट एउटा क्विज खेल्नुहोस् र फेरि हेर्नुहोस्।",
    "कमजोर क्षेत्र पहचानने के लिए सर्वर को अंक वाले प्रयास चाहिए। Quiz टैब से एक क्विज़ खेलें और फिर देखें।",
)
add(
    "practiceWeakTopicsServerNote",
    "Weak topics are worked out on our servers from your answer history, so nothing here is guessed.",
    "कमजोर विषयहरू हाम्रो सर्भरले तपाईंको उत्तर इतिहासबाट निकाल्छ, त्यसैले यहाँ केही अनुमान गरिएको हुँदैन।",
    "कमजोर विषय हमारे सर्वर आपके उत्तर इतिहास से निकालते हैं, इसलिए यहाँ कुछ भी अनुमानित नहीं है।",
)
add("practiceYourWeakTopics", "Your weak topics", "तपाईंका कमजोर विषय", "आपके कमजोर विषय")
add("practiceDrillAction", "Drill", "ड्रिल गर्नुहोस्", "ड्रिल करें")
add("practiceDrillTen", "Drill 10 questions (practice mode, untimed)", "१० प्रश्न ड्रिल गर्नुहोस् (अभ्यास मोड, समयसीमा छैन)", "10 प्रश्न ड्रिल करें (अभ्यास मोड, समय-सीमित नहीं)")
add(
    "practiceUntimedNote",
    "Practice is untimed and does not affect your rank or coin balance.",
    "अभ्यासमा समयसीमा छैन र यसले तपाईंको अंक वा क्विन बदल्दैन।",
    "अभ्यास समय-सीमित नहीं है और इससे आपकी रैंक या कॉइन नहीं बदलते।",
)
add(
    "practiceSelfChallengeExplain",
    "Pick question count & difficulty — mirrors Elite Quiz self-challenge but sourced from adaptive engine.",
    "प्रश्न संख्या र कठिनाई छान्नुहोस् — Elite Quiz को आफैँ चुनौतीजस्तै, तर अनुकूली इन्जिनबाट।",
    "प्रश्नों की संख्या और कठिनाई चुनें — Elite Quiz के सेल्फ-चैलेंज जैसा, पर adaptive engine से।",
)
add("practiceQuestionCount", "Question count: {count}", "प्रश्न संख्या: {count}", "प्रश्न संख्या: {count}", ["count"])
add("practiceDifficulty", "Difficulty", "कठिनाई", "कठिनाई")
add("practiceStarting", "Starting…", "सुरु हुँदैछ…", "शुरू हो रहा है…")
add("practiceStartChallenge", "Start challenge ({count} Qs)", "चुनौती सुरु गर्नुहोस् ({count} प्रश्न)", "चुनौती शुरू करें ({count} प्रश्न)", ["count"])
add(
    "practiceResultsLabelled",
    "Results are labelled as practice, so they never count towards your rank.",
    "नतिजालाई अभ्यासका रूपमा चिन्हित गरिन्छ, त्यसैले तिनले कहिल्यै अंकमा गनिन्छन्।",
    "परिणाम अभ्यास के रूप में चिह्नित होते हैं, इसलिए वे कभी आपकी रैंक में नहीं गिने जाते।",
)
add("practiceNoHistory", "No history", "कुनै इतिहास छैन", "कोई इतिहास नहीं")
add("practiceNoHistoryBody", "Your completed practice sessions will appear here.", "तपाईंका पूरा भएका अभ्यास सत्रहरू यहाँ देखिन्छन्।", "आपके पूरे हुए अभ्यास सत्र यहाँ दिखेंगे।")
add("practiceAttemptMeta", "Attempt #{number} • {mode}", "प्रयास #{number} • {mode}", "प्रयास #{number} • {mode}", ["number", "mode"])
add(
    "practiceAttemptSummary",
    "{meta} • score {score} • {correct}✓ {wrong}✗ {skipped}– • {questions} Qs",
    "{meta} • अंक {score} • {correct}✓ {wrong}✗ {skipped}– • {questions} प्रश्न",
    "{meta} • अंक {score} • {correct}✓ {wrong}✗ {skipped}– • {questions} प्रश्न",
    ["meta", "score", "correct", "wrong", "skipped", "questions"],
)

# ── economy ─────────────────────────────────────────────────────────────────
add("economyInventory", "Inventory", "सामग्री", "सामग्री")
add("economyYourResources", "Your resources", "तपाईंका स्रोतहरू", "आपके संसाधन")
add(
    "economyResourceSummary",
    "{held} held • {catalog} catalog • {recent} recent",
    "{held} सुरक्षित • {catalog} सङ्ग्रह • {recent} हालैका",
    "{held} सहेजे • {catalog} कैटलॉग • {recent} हाल के",
    ["held", "catalog", "recent"],
)
add("economyNoResources", "No resources yet", "अहिलेसम्म कुनै स्रोत छैन", "अभी तक कोई संसाधन नहीं")
add(
    "economyResourcesExplain",
    "Resources are earned via city / economy flows and quiz rewards. They appear here when available.",
    "स्रोतहरू सिटी/अर्थव्यवस्थाको प्रवाह र क्विज पुरस्कारबाट कमाइन्छन्। उपलब्ध भएपछि यहाँ देखिन्छन्।",
    "संसाधन शहर/अर्थव्यवस्था के प्रवाह और क्विज़ पुरस्कारों से मिलते हैं। उपलब्ध होने पर यहाँ दिखते हैं।",
)
add("economyCatalog", "Catalog", "सङ्ग्रह", "कैटलॉग")
add("economyCatalogEmpty", "Catalog empty — server will populate material list.", "सङ्ग्रह खाली छ — सर्भरले सामग्रीको सूची भर्नेछ।", "कैटलॉग खाली है — सर्वर सामग्री की सूची भरेगा।")
add("economyRecentActivity", "Recent activity", "हालैका गतिविधि", "हाल की गतिविधि")
add("economyNoRecentActivity", "No recent activity.", "हालै कुनै गतिविधि छैन।", "हाल में कोई गतिविधि नहीं।")
add("economyDonations", "Donations", "दान", "दान")
add(
    "economyDonationsExplain",
    "Live leaderboard and feed. Coins can freeze a donor streak.",
    "प्रत्यक्ष लिडरबोर्ड र फिड। क्विनले दानकर्ताको स्ट्रिक फ्रिज गर्न सक्छ।",
    "लाइव लीडरबोर्ड और फ़ीड। कॉइन से दानकर्ता की स्ट्रीक फ्रीज़ हो सकती है।",
)
add("economyLeaderboardFeed", "Leaderboard/feed: {status}", "लिडरबोर्ड/फिड: {status}", "लीडरबोर्ड/फ़ीड: {status}", ["status"])
add("economyStreakMonths", "{name} • {months} mo streak", "{name} • {months} महिनाको स्ट्रिक", "{name} • {months} महीने की स्ट्रीक", ["name", "months"])
add("economyLiveFeed", "Live feed", "प्रत्यक्ष फिड", "लाइव फ़ीड")
add("economyDonationsEmpty", "Donation leaderboard and feed are empty.", "दानको लिडरबोर्ड र फिड खाली छन्।", "दान लीडरबोर्ड और फ़ीड खाली हैं।")
add("economySyncing", "Syncing…", "सिंक हुँदैछ…", "सिंक हो रहा है…")
add("economyLedger", "Ledger", "खाता", "बही")
add(
    "economyLedgerExplain",
    "Grouped by day. Source labels come from credits.description (not metadata.source).",
    "दिनअनुसार समूहबद्ध। स्रोतका लेबल credits.description बाट आउँछन् (metadata.source बाट होइन)।",
    "दिन के अनुसार समूहबद्ध। स्रोत लेबल credits.description से आते हैं (metadata.source से नहीं)।",
)
add("economyWhereCoinsWent", "Where your coins went", "तपाईंका क्विन कहाँ गए", "आपके कॉइन कहाँ गए")
add(
    "economyPeriodSummary",
    "Last {days} days • earned {earned} • spent {spent}",
    "गत {days} दिन • कमाइ {earned} • खर्च {spent}",
    "पिछले {days} दिन • कमाए {earned} • खर्च {spent}",
    ["days", "earned", "spent"],
)
add("economyNoActivity", "No coin activity in this period.", "यो अवधिमा कुनै क्विन गतिविधि छैन।", "इस अवधि में कोई कॉइन गतिविधि नहीं।")
add("economyHowYouEarn", "How you earn", "तपाईं कसरी कमाउनुहुन्छ", "आप कैसे कमाते हैं")
add(
    "economyMintingExplain",
    "Coins are credited after each graded quiz and server-side daily actions. They are never minted on your device, so your balance cannot drift.",
    "क्विन हरेक अंकयुक्त क्विज र सर्भरका दैनिक कार्यपछि जम्मा हुन्छन्। तिनीहरू यन्त्रमा कहिल्यै बन्दैनन्, त्यसैले तपाईंको ब्यालेन्स बिग्रिँदैन।",
    "कॉइन हर अंक वाले क्विज़ और सर्वर के दैनिक कार्यों के बाद जमा होते हैं। वे कभी आपके डिवाइस पर नहीं बनते, इसलिए आपका बैलेंस नहीं बिगड़ता।",
)
add("economyNoTransactions", "No transactions yet", "अहिलेसम्म कुनै कारोबार छैन", "अभी तक कोई लेनदेन नहीं")
add(
    "economyNoTransactionsBody",
    "Complete a quiz to earn coins. Every credit is recorded on our servers.",
    "क्विन कमाउन एउटा क्विज पूरा गर्नुहोस्। हरेक जम्मा हाम्रो सर्भरमा दर्ज हुन्छ।",
    "कॉइन कमाने के लिए एक क्विज़ पूरा करें। हर जमा हमारे सर्वर पर दर्ज होता है।",
)
add("economyTitle", "Economy", "अर्थव्यवस्था", "अर्थव्यवस्था")
add("economyXpTotal", "{xp} XP total", "जम्मा {xp} XP", "कुल {xp} XP", ["xp"])
add(
    "economyLiveExplain",
    "Balance, ledger, shop and store are all live. Coins are minted server-side when a graded attempt completes.",
    "ब्यालेन्स, खाता, शप र स्टोर सबै प्रत्यक्ष छन्। अंकयुक्त प्रयास पूरा भएपछि क्विन सर्भरमा बन्दैनन्।",
    "बैलेंस, बही, शॉप और स्टोर सब लाइव हैं। अंक वाला प्रयास पूरा होने पर कॉइन सर्वर पर बनते हैं।",
)
add("economyWalletTile", "Wallet - balance + ledger by day", "वालेट - ब्यालेन्स + दिनअनुसार खाता", "वॉलेट - बैलेंस + दिन के अनुसार बही")
add("economyWalletTileSub", "Balance, lifetime totals and your coin history", "ब्यालेन्स, जीवनभरका जम्मा र तपाईंको क्विन इतिहास", "बैलेंस, जीवनभर के कुल और आपका कॉइन इतिहास")
add("economyShopTile", "Coin Shop - resources & bundles", "क्विन शप - स्रोत र बन्डल", "कॉइन शॉप - संसाधन और बंडल")
add("economyShopTileSub", "Spend coins on materials and bundles", "सामग्री र बन्डलमा क्विन खर्च्नुहोस्", "सामग्री और बंडल पर कॉइन खर्चें")
add("economyInventoryTile", "Inventory — resources + donations", "सामग्री - स्रोत + दान", "सामग्री - संसाधन + दान")
add("economyInventoryTileSub", "8 materials + catalog + live donations feed/leaderboard", "८ सामग्री + सङ्ग्रह + प्रत्यक्ष दान फिड/लिडरबोर्ड", "8 सामग्री + कैटलॉग + लाइव दान फ़ीड/लीडरबोर्ड")
add("economyStoreTile", "Premium Store - assets & skins", "प्रिमियम स्टोर - एसेट र स्किन", "प्रीमियम स्टोर - एसेट और स्किन")
add("economyStoreTileSub", "Buy frames, themes, badges and avatars", "फ्रेम, थिम, ब्याज र अवतार किन्नुहोस्", "फ़्रेम, थीम, बैज और अवतार खरीदें")
add("economyWardrobeTile", "Wardrobe - equip", "वार्डरोब - लगाउनुहोस्", "वॉर्डरोब - लगाएं")
add("economyWardrobeTileSub", "Equip or clear the assets you own", "आफूले भएका एसेट लगाउनुहोस् वा हटाउनुहोस्", "अपने एसेट लगाएं या हटाएं")
add("economyShopTitle", "Coin Shop", "क्विन शप", "कॉइन शॉप")
add("economyNothingForSale", "Nothing for sale yet", "अहिलेसम्म बिक्रीका लागि केही छैन", "अभी तक बिक्री के लिए कुछ नहीं")
add(
    "economyShopEmpty",
    "The shop has no items published on the server right now.",
    "सर्भरमा अहिले शपका कुनै वस्तु प्रकाशित छैनन्।",
    "सर्वर पर अभी शॉप की कोई वस्तु प्रकाशित नहीं है।",
)
add("economyBundles", "Bundles", "बन्डल", "बंडल")
add("economyMaterials", "Materials", "सामग्री", "सामग्री")
add(
    "economyPurchaseSafe",
    "If a purchase does not go through, retrying is safe — you are never charged twice.",
    "खरिद नभए पुनः प्रयास गर्न सुरक्षित छ — दुब्बे तिरोस् हुँदैन।",
    "खरीद सफल नहीं हुई तो फिर से कोशिश करना सुरक्षित है — दोबारा शुल्क नहीं लगेगा।",
)
add("economySellsBackFor", "sells back for {coins}", "{coins} मा फिर्ता बिक्छ", "{coins} में वापस बिकता है", ["coins"])
add("economySave", "save {coins}", "{coins} बचत", "{coins} की बचत", ["coins"])

# ── library ─────────────────────────────────────────────────────────────────
add("libraryUnlockedCoins", "Unlocked! Coins spent: {coins}", "खुल्यो! खर्च भएको क्विन: {coins}", "अनलॉक हो गया! खर्च किए गए कॉइन: {coins}", ["coins"])
add("libraryDownloadStarted", "Download started — opening browser", "डाउनलोड सुरु भयो — ब्राउजर खुल्दै", "डाउनलोड शुरू हुआ — ब्राउज़र खुल रहा है")
add("libraryDownloadUrl", "Download URL: {url}", "डाउनलोड URL: {url}", "डाउनलोड URL: {url}", ["url"])
add("libraryRatingRange", "Rating must be 1-5", "रेटिङ १-५ बीच हुनुपर्छ", "रेटिंग 1-5 के बीच होनी चाहिए")
add("libraryReviewSubmitted", "Review submitted", "समीक्षा पेश भयो", "समीक्षा जमा हुई")
add("libraryAbout", "About", "बारेमा", "परिचय")
add("libraryReviews", "Reviews", "समीक्षाहरू", "समीक्षाएं")
add(
    "libraryNoReviews",
    "No reviews yet — be the first to review after unlocking!",
    "अहिलेसम्म कुनै समीक्षा छैन — अनलोक गरेपछि पहिलो समीक्षा गर्नुहोस्!",
    "अभी तक कोई समीक्षा नहीं — अनलॉक करने के बाद पहली समीक्षा करें!",
)
add("libraryLoadMoreReviews", "Load more reviews", "थप समीक्षा हेर्नुहोस्", "और समीक्षाएं लोड करें")
add(
    "librarySignedUrls",
    "Download URLs are signed and short-lived. If a download fails, tap Download again to get a fresh URL. Respect library-api-download throttle.",
    "डाउनलोड URL हस्ताक्षरित र छोटो अवधिका हुन्छन्। डाउनलोड असफल भए फेरि Download थिच्नुहोस्। library-api-download को throttle मान्नुहोस्।",
    "डाउनलोड URL हस्ताक्षरित और अल्पकालिक होते हैं। डाउनलोड विफल हो तो फिर से Download दबाएं। library-api-download की सीमा मानें।",
)
add("libraryFree", "FREE", "निःशुल्क", "मुफ़्त")
add("libraryCoinsLabel", "{count} COINS", "{count} क्विन", "{count} कॉइन", ["count"])
add("libraryFeatured", "Featured", "विशेष", "विशेष")
add("libraryByUploader", "by {name}", "{name} द्वारा", "{name} द्वारा", ["name"])
add("libraryUnlockedFor", "Unlocked • {coins} coins", "खुल्यो • {coins} क्विन", "अनलॉक • {coins} कॉइन", ["coins"])
add("libraryUnlocking", "Unlocking…", "खोल्दै…", "अनलॉक हो रहा है…")
add("libraryGettingLink", "Getting link…", "लिंक खोज्दै…", "लिंक ला रहे हैं…")
add("libraryDownload", "Download", "डाउनलोड", "डाउनलोड")
add(
    "libraryUnlockNote",
    "Unlocking is charged to your coin balance once, even if the tap does not register the first time. You need to unlock a file before you can download it.",
    "अनलोक गर्दा तपाईंको क्विन ब्यालेन्सबाट एक पटक मात्र काटिन्छ, पहिलो थिचाइ नभए पनि। डाउनलोड गर्नुअघि फाइल अनलोक गर्नुपर्छ।",
    "अनलॉक करने पर आपके कॉइन बैलेंस से एक बार ही कटौती होती है, पहली बार टैप न हो तो भी। डाउनलोड से पहले फ़ाइल अनलॉक करनी होगी।",
)
add("libraryReviewsCount", "{count} reviews", "{count} समीक्षा", "{count} समीक्षाएं", ["count"])
add("libraryDownloads", "downloads", "डाउनलोड", "डाउनलोड")
add("libraryAccess", "access", "पहुँच", "पहुँच")
add("libraryWriteReview", "Write a review (must unlock first)", "समीक्षा लेख्नुहोस् (पहिले अनलोक गर्नुपर्छ)", "समीक्षा लिखें (पहले अनलॉक करना होगा)")
add("libraryCommentOptional", "Comment (optional)", "टिप्पणी (वैकल्पिक)", "टिप्पणी (वैकल्पिक)")
add("librarySubmitting", "Submitting…", "पेश गर्दै…", "जमा हो रहा है…")
add("librarySubmitReview", "Submit review", "समीक्षा पेश गर्नुहोस्", "समीक्षा जमा करें")
add(
    "libraryReviewVerified",
    "Reviews are verified if you have downloaded/unlocked the file.",
    "तपाईंले फाइल डाउनलोड/अनलोक गरेको भए समीक्षा प्रमाणित हुन्छ।",
    "आपने फ़ाइल डाउनलोड/अनलॉक की है तो समीक्षा सत्यापित होती है।",
)
add("libraryVerified", "verified", "प्रमाणित", "सत्यापित")
add("librarySearchHint", "Search files, categories…", "फाइल, श्रेणी खोज्नुहोस्…", "फ़ाइल, श्रेणी खोजें…")
add(
    "libraryTrendingFailed",
    "Could not load the trending files.\n{reason}",
    "प्रचलित फाइलहरू लोड गर्न सकिएन।\n{reason}",
    "ट्रेंडिंग फ़ाइलें लोड नहीं हो सकीं।\n{reason}",
    ["reason"],
)
add("libraryTrending", "Trending", "प्रचलित", "ट्रेंडिंग")
add(
    "libraryRecommendedFailed",
    "Could not load your recommendations.\n{reason}",
    "तपाईंका सुझावहरू लोड गर्न सकिएन।\n{reason}",
    "आपके सुझाव लोड नहीं हो सके।\n{reason}",
    ["reason"],
)
add("libraryRecommendedForYou", "Recommended for you", "तपाईंका लागि सुझाव", "आपके लिए सुझाव")
add("libraryFiles", "Files", "फाइलहरू", "फ़ाइलें")
add("libraryTotalCount", "{count} total", "जम्मा {count}", "कुल {count}", ["count"])
add("libraryNoFiles", "No files yet", "अहिलेसम्म कुनै फाइल छैन", "अभी तक कोई फ़ाइल नहीं")
add("libraryNoResults", "No results for \"{query}\"", "\"{query}\" का कुनै नतिजा छैन", "\"{query}\" का कोई परिणाम नहीं", ["query"])
add(
    "libraryNoFilesBody",
    "Library files will appear here once published and approved on the server.",
    "सर्भरमा प्रकाशित र स्वीकृत भएपछि लाइब्रेरीका फाइलहरू यहाँ देखिन्छन्।",
    "सर्वर पर प्रकाशित और स्वीकृत होने के बाद लाइब्रेरी की फ़ाइलें यहाँ दिखेंगी।",
)
add("libraryTryDifferentSearch", "Try a different search term or clear filters.", "अर्को शब्द खोज्नुहोस् वा फिल्टर हटाउनुहोस्।", "कोई दूसरा शब्द खोजें या फ़िल्टर हटाएं।")
add("libraryClearSearch", "Clear search", "खोजी हटाउनुहोस्", "खोज साफ़ करें")
add("libraryNoCategories", "No categories published", "कुनै श्रेणी प्रकाशित छैन", "कोई श्रेणी प्रकाशित नहीं")

# ── shared ──────────────────────────────────────────────────────────────────
# One key per English string, however many screens say it. The rewrite
# matches on the text, so a second key with the same text would be
# ambiguous.
add("commonLoadMore", "Load more", "थप हेर्नुहोस्", "और लोड करें")
add("commonLeaderboard", "Leaderboard", "लिडरबोर्ड", "लीडरबोर्ड")
add("commonWallet", "Wallet", "वालेट", "वॉलेट")
add("commonLibrary", "Library", "लाइब्रेरी", "लाइब्रेरी")

# ── the practice session ────────────────────────────────────────────────────
add("practiceDrillComplete", "Drill complete", "ड्रिल पूरा भयो", "ड्रिल पूरा हुआ")
add(
    "practiceDoesNotAffect",
    "Practice — does not affect rank, XP or streak",
    "अभ्यास — अंक, XP वा स्ट्रिकलाई असर गर्दैन",
    "अभ्यास — रैंक, XP या स्ट्रीक को प्रभावित नहीं करता",
)
add("practiceQuestionsCount", "{count} questions", "{count} प्रश्न", "{count} प्रश्न", ["count"])
add(
    "practiceAnsweredSkipped",
    "{answered} answered • {skipped} skipped",
    "{answered} उत्तर दिइयो • {skipped} छाडियो",
    "{answered} उत्तर दिए • {skipped} छोड़े",
    ["answered", "skipped"],
)
add("practiceScore", "Score {score}", "अंक {score}", "अंक {score}", ["score"])
add("practiceGradedByServer", "Graded by the server", "सर्भरद्वारा अंकित", "सर्वर द्वारा अंकित")
add(
    "practiceCorrectWrongSkipped",
    "{correct} correct • {wrong} wrong • {skipped} skipped",
    "{correct} सही • {wrong} गलत • {skipped} छाडिएको",
    "{correct} सही • {wrong} गलत • {skipped} छोड़े",
    ["correct", "wrong", "skipped"],
)
add(
    "practiceGradingFailed",
    "The server could not grade this drill: {reason}",
    "सर्भरले यो ड्रिल अंकित गर्न सकेन: {reason}",
    "सर्वर यह ड्रिल अंकित नहीं कर सका: {reason}",
    ["reason"],
)
add(
    "practiceReviewPassNote",
    "This was a review pass. No attempt was created, so there is no score to show.",
    "यो पुनरावलोकन थियो। कुनै प्रयास बनाइएको छैन, त्यसैले देखाउनुपर्ने अंक छैन।",
    "यह एक दोहराव था। कोई प्रयास नहीं बनाया गया, इसलिए दिखाने कोई अंक नहीं है।",
)
add("practiceNoQuestionsInSet", "No questions in this set", "यस सेटमा कुनै प्रश्न छैन", "इस सेट में कोई प्रश्न नहीं")
add("practiceQuestionCounter", "Q {current}/{total}", "प्रश्न {current}/{total}", "प्रश्न {current}/{total}", ["current", "total"])
add("practiceUntimedPractice", "Untimed • Practice", "समयसीमा छैन • अभ्यास", "समय-सीमित नहीं • अभ्यास")
add("practiceDifficultyLabel", "Difficulty: {difficulty}", "कठिनाई: {difficulty}", "कठिनाई: {difficulty}", ["difficulty"])
add(
    "practiceNoOptionsNotice",
    "The server sent this question without answer options, so it cannot be drilled here. Try the graded Quiz tab, which loads a full session.",
    "सर्भरले यो प्रश्न विकल्पबिना पठायो, त्यसैले यहाँ ड्रिल गर्न सकिँदैन। अंकयुक्त Quiz ट्याब प्रयास गर्नुहोस्, जसले पूरै सत्र लोड गर्छ।",
    "सर्वर ने यह प्रश्न विकल्पों के बिना भेजा, इसलिए यहाँ ड्रिल नहीं किया जा सकता। अंक वाला Quiz टैब आज़माएं, जो पूरा सत्र लोड करता है।",
)
add(
    "practiceAnswerSentNotice",
    "Answer sent to the server. It grades the attempt — this screen never guesses a score.",
    "उत्तर सर्भरमा पठाइयो। सर्भरले प्रयास अंकित गर्छ — यो स्क्रिनले कहिल्यै अंक अनुमान गर्दैन।",
    "उत्तर सर्वर को भेजा गया। सर्वर प्रयास को अंकित करता है — यह स्क्रीन कभी अंक का अनुमान नहीं लगाती।",
)
add("practicePrev", "Prev", "अघिल्लो", "पिछला")
add("practiceGrading", "Grading…", "अंक गरिँदै…", "अंक लगा रहे हैं…")
add(
    "practiceNoEffectNote",
    "Practice is untimed and carries no score, XP, coins or streak effect.",
    "अभ्यासमा समयसीमा छैन र यसले अंक, XP, क्विन वा स्ट्रिकमा कुनै असर गर्दैन।",
    "अभ्यास समय-सीमित नहीं है और इसका अंक, XP, कॉइन या स्ट्रीक पर कोई प्रभाव नहीं पड़ता।",
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
# The placeholder types decide the signature gen-l10n generates.
#
# `Object` accepts whatever the caller has — an int, a double, a String, an
# enum's `name` — and gen-l10n stringifies it. A narrower type (`int`,
# `String`) makes the *client* the place where a mismatch is found, and the
# mismatch is a compile error in a screen that was correct the moment the
# server changed a field from a count to a label.
#
# The one thing `Object` does not accept is `null`, so a nullable value has
# to be coalesced at the call site. That is the right place for it: the
# screen knows what to show when the server sent nothing.
PLACEHOLDER_TYPES = {}


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
