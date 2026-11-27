import '../entities/resource_hub.dart';

/// Read boundary for the resource hub snapshot.
// ignore: one_member_abstracts — repository boundary per Clean Arch.
abstract class ResourceHubRepository {
  Future<ResourceHub> getHub();
}
