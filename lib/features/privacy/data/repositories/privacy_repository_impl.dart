import '../../domain/entities/visitor_data.dart';
import '../../domain/repositories/privacy_repository.dart';
import '../datasources/privacy_remote_data_source.dart';

/// Thin repository over the existing anonymous-profile data source.
///
/// Identity stays in the server's signed cookie; this layer passes through
/// the existing methods without adding an id parameter or changing how a
/// missing/invalid payload is reported.
class PrivacyRepositoryImpl implements PrivacyRepository {
  const PrivacyRepositoryImpl(this._remote);

  final PrivacyRemoteDataSource _remote;

  @override
  Future<VisitorData?> getVisitorData() => _remote.getVisitorData();

  @override
  Future<VisitorConsentMode> setVisitorConsent({required bool analytics}) =>
      _remote.setVisitorConsent(analytics: analytics);

  @override
  Future<void> eraseVisitorData() => _remote.eraseVisitorData();

  @override
  Future<bool> recordVisitorEvent({
    required String event,
    String? subject,
    int? subjectId,
  }) =>
      _remote.recordVisitorEvent(
        event: event,
        subject: subject,
        subjectId: subjectId,
      );
}
