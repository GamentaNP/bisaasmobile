# Android SDK Setup on Windows (Bisaasmobile / CivilCal)

> **Goal:** Get `flutter doctor` to all green so we can `flutter run` on an emulator and on a physical Redmi Note 12 (or similar).

## 1. Prerequisites

- Windows 11 (Laragon stack already running)
- ~10 GB free disk for Android Studio + SDK + emulator
- Hardware virtualization enabled in BIOS (Intel VT-x / AMD-V)

## 2. Install JDK 17 (Temurin)

```powershell
winget install --id EclipseAdoptium.Temurin.17.JDK -e --accept-package-agreements
# restart terminal
java -version
# openjdk 17.x.x
```

If `winget` is missing (older Windows), download the MSI from https://adoptium.net/.

## 3. Install Android Studio

```powershell
winget install --id Google.AndroidStudio -e --accept-package-agreements
```

After install, open Android Studio and let the wizard install:
- Android SDK Platform 34 (Android 14)
- Build-Tools 34.0.0
- Platform-Tools
- Android Emulator
- (Optional) Intel HAXM for emulator acceleration

## 4. Environment Variables

System Properties → Environment Variables → System variables:

| Variable | Value |
|---|---|
| `ANDROID_HOME` | `%LOCALAPPDATA%\Android\Sdk` |
| `ANDROID_SDK_ROOT` | `%LOCALAPPDATA%\Android\Sdk` |

User `PATH` (prepend):
```
%ANDROID_HOME%\platform-tools
%ANDROID_HOME%\tools
%ANDROID_HOME%\tools\bin
%ANDROID_HOME%\emulator
```

Restart terminal.

## 5. Accept Licenses

```bash
flutter doctor --android-licenses
# type y for each prompt
```

## 6. Verify

```bash
flutter doctor -v
# Expected: [✓] Flutter, [✓] Android toolchain, [✓] Android Studio, [✓] Connected device (after AVD)
```

## 7. Create AVD

Android Studio → Tools → Device Manager → Create Device:
- Phone → Pixel 6
- System Image: API 34 (Android 14) x86_64
- AVD Name: `Pixel_6_API_34`

## 8. Run App on Emulator

```bash
cd C:\laragon\www\bisaasmobile
flutter run --dart-define=ENV=dev --dart-define=API_HOST=http://10.0.2.2 -d emulator-5554
```

> **Note:** Use `http://10.0.2.2` (not `bisaas.test`) so the Android emulator can reach the Laragon dev server on the Windows host.

## 9. Physical Device (Redmi Note 12 or any Android)

1. Phone → Settings → About phone → tap **Build number 7 times** to enable Developer Options.
2. Developer Options → enable **USB debugging**.
3. Connect via USB.
4. On phone, accept the RSA fingerprint prompt.
5. `flutter devices` should now list the phone.
6. `flutter run --dart-define=ENV=dev -d <device-id>`.

For wireless debugging (Android 11+):
- Developer Options → Wireless debugging → Pair device with pairing code
- `adb pair <ip>:<port>` then `adb connect <ip>:<port>`

## 10. Profile Mode Performance Check

```bash
flutter run --profile -d <device-id>
# Open DevTools from the printed URL, or VS Code → Flutter → Open DevTools
# Use the Performance tab while navigating through quiz attempts
# Target: every frame < 16ms; timer rebuild < 8ms
```

## 11. Common Pitfalls

| Symptom | Fix |
|---|---|
| `cmdline-tools` missing | SDK Manager → SDK Tools → check "Android SDK Command-line Tools (latest)" |
| Emulator won't boot (HAXM) | SDK Manager → SDK Tools → check "Intel x86 Emulator Accelerator (HAXM installer)" |
| `adb: device offline` | Toggle USB debugging off/on; re-plug |
| `flutter run` can't find device | `adb kill-server && adb start-server` |
| App stuck on white screen | Check Firebase bootstrap log — if google-services.json is template, push will no-op (expected), but the app should still render login. Check `lib/app/bootstrap.dart` for exceptions. |
