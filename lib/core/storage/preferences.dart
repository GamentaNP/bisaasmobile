import 'package:shared_preferences/shared_preferences.dart';

/// Small key-value prefs (non-sensitive only — tokens live in secure storage).
/// Initialized once by bootstrap(); access via [instance].
class Preferences {
  Preferences._(this._p);
  final SharedPreferences _p;

  static Preferences? _instance;
  static Preferences get instance =>
      _instance ?? (throw StateError('Preferences.init() not called — see bootstrap.dart'));

  static Future<Preferences> init() async {
    final p = await SharedPreferences.getInstance();
    return _instance ??= Preferences._(p);
  }

  bool get onboardingDone => _p.getBool('onboarding_done') ?? false;
  Future<void> setOnboardingDone(bool v) => _p.setBool('onboarding_done', v);

  String? get selectedExam => _p.getString('selected_exam');
  Future<void> setSelectedExam(String v) => _p.setString('selected_exam', v);

  int get dailyGoalMinutes => _p.getInt('daily_goal_minutes') ?? 20;
  Future<void> setDailyGoalMinutes(int v) => _p.setInt('daily_goal_minutes', v);

  String? get experienceLevel => _p.getString('experience_level');
  Future<void> setExperienceLevel(String v) => _p.setString('experience_level', v);

  String? get locale => _p.getString('locale');
  Future<void> setLocale(String v) => _p.setString('locale', v);

  bool get appLockEnabled => _p.getBool('app_lock_enabled') ?? false;
  Future<void> setAppLockEnabled(bool v) => _p.setBool('app_lock_enabled', v);
}
