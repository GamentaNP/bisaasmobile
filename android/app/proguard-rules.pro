# ProGuard / R8 rules for the release build (security plan W2.1).
#
# Context: R8 only sees the JVM (Kotlin/Java) host side — the Dart side is
# obfuscated separately by `--obfuscate --split-debug-info` (set on every
# release invocation in ci.yml, deploy_android.yml and the Fastfiles).
# Most Flutter plugins ship their own consumer rules inside their AARs, so
# only the ones that reach into reflection or JNI without consumer rules are
# kept here. Redundant keeps are worse than missing ones: they pin names and
# defeat the shrinking this file exists to enable.

# --- Crash de-obfuscation ---------------------------------------------------
# Keep line numbers so Play/ Crashlytics can retrace stack traces with the
# mapping.txt produced alongside the build (uploaded as a private CI artifact).
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# --- freeRASP (Talsec, com.aheaditec.freerasp) ------------------------------
# Threat detection is wired through JNI callbacks into the native SDK. Its
# AAR does not ship consumer rules for every entry point, and a stripped
# callback class silently disables RASP — fail loud instead.
-keep class com.aheaditec.freerasp.** { *; }
-dontwarn com.aheaditec.freerasp.**

# --- Firebase (auth / messaging / database / analytics / crashlytics) -------
# flutterfire's plugins ship consumer rules; these cover only the reflection
# entry points the Flutter engine reaches directly. Keep the messaging service
# registrable (manifest-declared services are kept by AAPT, their
# constructors by the rules below).
-keep class io.flutter.plugins.firebase.** { *; }
-dontwarn com.google.firebase.**

# --- google_sign_in / local_auth -------------------------------------------
# Platform-channel handlers resolved by name at runtime.
-keep class io.flutter.plugins.googlesignin.** { *; }
-keep class io.flutter.plugins.localauth.** { *; }

# --- Drift (sqlite3_flutter_libs) -------------------------------------------
# Drift runs Dart-side; the only JVM surface is the bundled sqlite3 JNI
# library, which is loaded by System.loadLibrary (name-based, kept by AAPT).
# No keep rules needed — deliberately none, so R8 can strip the rest.

# --- Dio --------------------------------------------------------------------
# Pure Dart (package:dio + dart:io HttpClient); no JVM surface exists.
# The certificate pins live in Dart string constants, unreachable by R8.
# No keep rules needed — deliberately none.
