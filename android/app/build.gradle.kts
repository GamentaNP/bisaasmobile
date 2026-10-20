import java.util.Properties
import java.util.Base64
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
//
// FAIL CLOSED. A release build is refused when the signing configuration is
// missing *or incomplete*. The previous version only checked that
// `key.properties` was non-empty, so a file with three of the four keys got
// past the guard and then died inside the Kotlin DSL with a bare
// "null cannot be cast to non-null type" — which reads like a toolchain bug
// and sends the release engineer down the wrong path.
val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) FileInputStream(f).use { load(it) }
}

val allowDebugSigning = (project.findProperty("allow-debug-signing") as String?) == "true"

// The four keys the upload signing config needs, and the human-readable
// reason each one is required.
val requiredSigningKeys = listOf(
    "keyAlias" to "the alias of the upload key inside the keystore",
    "keyPassword" to "the private key password",
    "storeFile" to "the path to the .jks/.keystore file",
    "storePassword" to "the keystore password",
)

val missingSigningKeys = requiredSigningKeys
    .filter { (key, _) -> keystoreProperties.getProperty(key).isNullOrBlank() }
    .map { (key, reason) -> "$key ($reason)" }

// The keystore file has to exist too — a present-but-wrong `storeFile` is the
// same failure as a missing key, and it is caught here with a message that
// says what to do about it.
val configuredStoreFile = keystoreProperties.getProperty("storeFile")
val storeFileMissing = configuredStoreFile != null &&
    configuredStoreFile.isNotBlank() &&
    !file(configuredStoreFile).exists()

val signingReady = missingSigningKeys.isEmpty() && !storeFileMissing

// Whether this invocation is actually building a release variant.
//
// The guard below MUST NOT fire for a debug build: `buildTypes { release { … } }`
// is evaluated during *configuration*, for every build, so a throw in there
// would make `flutter run` and `flutter build apk --debug` impossible on a
// machine that has no upload keystore — which is every developer machine and
// every CI runner that is not building a release.
//
// The task names are the reliable signal: Flutter invokes Gradle with
// `assembleRelease` / `bundleRelease` for a release build and
// `assembleDebug` for a debug one.
val buildingRelease = gradle.startParameter.taskNames.any { taskName ->
    taskName.contains("Release", ignoreCase = true)
}

// Certificate pins, read from the dart-defines the Flutter tool passes to
// Gradle.
//
// The Flutter tool encodes the defines as a comma-separated list of
// individually base64-encoded `KEY=VALUE` strings (`encodeDartDefines`), so
// they can be decoded here.
//
// The runtime guard in `lib/core/network/certificate_pinning.dart` refuses to
// start a production build without a usable pin. That is the right behaviour
// for the device, but it means the failure is discovered on a user's phone
// rather than in CI. Checking the same thing here fails the *build* instead,
// which is where it can be fixed.
val dartDefines: Map<String, String> =
    (project.findProperty("dart-defines") as String? ?: "")
        .split(",")
        .filter { it.isNotBlank() }
        .mapNotNull { encoded ->
            runCatching {
                String(Base64.getDecoder().decode(encoded), Charsets.UTF_8)
            }.getOrNull()
        }
        .mapNotNull { define ->
            val separator = define.indexOf('=')
            if (separator <= 0) null else define.substring(0, separator) to
                define.substring(separator + 1)
        }
        .toMap()

/**
 * A pin that is still a deployment placeholder is not a pin: it can never
 * match a real certificate, and treating it as configured would let a
 * release ship with pinning that is silently dead.
 */
fun isUsablePin(value: String?): Boolean {
    if (value.isNullOrBlank()) return false
    val upper = value.uppercase()
    return !upper.contains("REPLACE") &&
        !upper.contains("PLACEHOLDER") &&
        !upper.contains("TODO") &&
        !upper.contains("XXXX")
}

val productionEnv = dartDefines["ENV"] ?: ""
val usablePins = listOf("CERT_PIN_1", "CERT_PIN_2", "CERT_PIN_3")
    .mapNotNull { dartDefines[it] }
    .filter { isUsablePin(it) }

val pinsMissing = when {
    productionEnv != "prod" -> emptyList()
    usablePins.isEmpty() -> listOf(
        "no usable certificate pin was passed. Pass at least CERT_PIN_1 " +
            "via --dart-define-from-file=dart_defines/production.json."
    )
    else -> emptyList()
}

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
            if (signingReady) {
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
            } else if (buildingRelease) {
                // Fail closed, with a message that says exactly what is wrong.
                val problems = buildList {
                    if (missingSigningKeys.isNotEmpty()) {
                        add("android/key.properties is missing or incomplete:\n" +
                            missingSigningKeys.joinToString("\n") { "  - $it" })
                    }
                    if (storeFileMissing) {
                        add("android/key.properties points storeFile at " +
                            "\"$configuredStoreFile\", which does not exist.")
                    }
                }.joinToString("\n")

                throw GradleException(
                    "Release signing is not configured, so the release build is refused.\n" +
                        "$problems\n\n" +
                        "Create android/key.properties (gitignored) with:\n" +
                        "  keyAlias=...\n  keyPassword=...\n  storeFile=../upload-keystore.jks\n" +
                        "  storePassword=...\n" +
                        "In CI, materialise it from the ANDROID_KEYSTORE_BASE64 secret.\n" +
                        "For a throwaway local smoke build only, pass -Pallow-debug-signing=true."
                )
            }
            // When the signing configuration is absent and this invocation is
            // not building a release, the release variant simply carries no
            // signing config. A later release build re-evaluates this script
            // and refuses — so the failure is still closed, it just happens at
            // the point where it matters.

            // Certificate pins are mandatory for a production release, and
            // the check belongs here rather than only at app start: a release
            // that ships without pinning has to be caught in CI, not on a
            // user's phone.
            if (buildingRelease && pinsMissing.isNotEmpty()) {
                throw GradleException(
                    "Certificate pinning is not configured for this production " +
                        "release, so the build is refused.\n" +
                        pinsMissing.joinToString("\n") { "  - $it" } +
                        "\n\nThe runtime guard in " +
                        "lib/core/network/certificate_pinning.dart would " +
                        "refuse to start the app anyway; failing the build " +
                        "here means the mistake is caught before it ships."
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
