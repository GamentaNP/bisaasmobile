library;
import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  Preferences(this._p);
  final SharedPreferences _p;

  static Future<Preferences> init() async => Preferences(await SharedPreferences.getInstance());

  bool get onboardingDone => _p.getBool('onboarding_done') ?? false;
  Future<void> setOnboardingDone(bool v) => _p.setBool('onboarding_done', v);

  String? get locale => _p.getString('locale');
  Future<void> setLocale(String v) => _p.setString('locale', v);
}
