import '../entities/creator_application.dart';

/// Read boundary for the current creator-application snapshot.
// ignore: one_member_abstracts — repository boundary per Clean Arch.
abstract class CreatorApplicationRepository {
  Future<CreatorApplicationStatus> getCurrent();
}
