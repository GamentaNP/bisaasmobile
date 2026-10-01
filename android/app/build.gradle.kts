import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Firebase google-services plugin (declared in settings.gradle.kts). Applied
// ONLY when google-services.json exists so dev builds work before Firebase
// console setup. Adding the JSON next to this file activates FCM,
// Crashlytics, Analytics and Remote Config automatically.
// See docs/FIREBASE_SETUP.md.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

// Release signing — android/key.properties (gitignored). A release build MUST
// be signed with the upload key; the debug fallback is opt-in and loud, because
// a silently debug-signed AAB cannot be published or updated later.
// Escape hatch for local smoke builds: -Pallow-debug-signing=true
val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) FileInputStream(f).use { load(it) }
}

val allowDebugSigning = (project.findProperty("allow-debug-signing") as String?) == "true"

android {
    namespace = "com.bisaas.bisaasmobile"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.bisaas.bisaasmobile"
        // Master plan 1.3 named Android 10 (API 29) as the floor. Security plan
        // W2.6 then *raised* it to 29 and retired the CPH1909 (API 27) device.
        //
        // REVISED 2026-09-27: floor lowered back to API 28 (Android 9) on the
        // founder's decision. Rationale — distribution, not capability:
        //   * The Loksewa / PSC candidate base in Nepal skews hard to budget
        //     handsets. The Redmi 6A (Android 9, API 28) is the single most
        //     common device class in that market, and API 28 still covers the
        //     overwhelming majority of active Android installs. API 29 buys no
        //     capability this app uses: the runtime surface we rely on
        //     (notification channels, scoped storage via the plugin layer,
        //     FCM) is satisfied at 28, and Google Play accepts a 28 floor.
        //   * Real-device QA is now possible on the connected test phone,
        //     which is API 28. Keeping 29 meant the team's only physical
        //     device could never install the app, so no on-device verification
        //     could happen at all.
        // Trade-off accepted: API 28 is out of support and receives no OS
        // security patches. Nothing in the client depends on a 29-only API, and
        // the app performs no local grading or key storage that the platform
        // would harden for us — grading is server-authoritative and the PAT
        // lives in flutter_secure_storage's EncryptedSharedPreferences.
        // Revisit to 29 once Play Console's own target-API deadline forces it
        // or once the QA device is retired.
        minSdk = 28
        targetSdk = 36
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            if (keystoreProperties.isNotEmpty()) {
                signingConfig = signingConfigs.create("upload") {
                    keyAlias = keystoreProperties["keyAlias"] as String
                    keyPassword = keystoreProperties["keyPassword"] as String
                    storeFile = file(keystoreProperties["storeFile"] as String)
                    storePassword = keystoreProperties["storePassword"] as String
                }
            } else if (allowDebugSigning) {
                logger.warn(
                    "WARNING: release build is DEBUG-SIGNED (allow-debug-signing=true). " +
                        "This artifact must never be published or distributed."
                )
                signingConfig = signingConfigs.getByName("debug")
            } else {
                throw GradleException(
                    "Release build requires android/key.properties (keyAlias, keyPassword, " +
                        "storeFile, storePassword). In CI, materialise it from the " +
                        "ANDROID_KEYSTORE_BASE64 secret. For a throwaway local smoke build only, " +
                        "pass -Pallow-debug-signing=true."
                )
            }

            // Security plan W2.1: R8 shrinking + resource shrinking on every
            // release artifact. Keep rules in proguard-rules.pro (freeRASP JNI,
            // firebase reflection points); the Dart side is obfuscated by the
            // --obfuscate flag on the flutter build invocation, never here.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

flutter {
    source = "../.."
}
