import '../entities/achievements.dart';

// ignore: one_member_abstracts
abstract class AchievementsRepository {
  Future<AchievementsData> getAchievements();
}
