import '../entities/public_profile.dart';

/// Read boundary for public profiles and their comparison.
abstract class PublicProfileRepository {
  Future<PublicProfileSnapshot> getProfile(String username);

  Future<ProfileComparison> compare(String username);
}
