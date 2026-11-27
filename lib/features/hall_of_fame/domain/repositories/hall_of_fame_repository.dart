import '../entities/hall_of_fame.dart';

/// Read boundary for the Hall of Fame snapshot.
// ignore: one_member_abstracts — repository boundary per Clean Arch.
abstract class HallOfFameRepository {
  Future<HallOfFameSnapshot> getSnapshot({
    required String recordType,
    required String period,
    String? search,
  });
}
