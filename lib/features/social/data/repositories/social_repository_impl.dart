import '../../domain/entities/social.dart';
import '../../domain/repositories/social_repository.dart';
import '../datasources/social_remote_data_source.dart';

class SocialRepositoryImpl implements SocialRepository {
  const SocialRepositoryImpl(this._remote);
  final SocialRemoteDataSource _remote;

  @override
  Future<ReferralDashboard?> getReferralDashboard() => _remote.getReferralDashboard();

  @override
  Future<ReferralClaim> claimReferralCode(String code) => _remote.claimReferralCode(code);

  @override
  Future<List<ShareMoment>> getActiveMoments() => _remote.getActiveMoments();

  @override
  Future<void> dismissMoment(String momentId) => _remote.dismissMoment(momentId);

  @override
  Future<void> recordShare({String? subject, int? subjectId, String? channel}) =>
      _remote.recordShare(subject: subject, subjectId: subjectId, channel: channel);

  @override
  Future<SocialProof?> getProof({required String subject, required int id}) =>
      _remote.getProof(subject: subject, id: id);

  @override
  Future<String?> createShareLink({String? subject, int? subjectId}) =>
      _remote.createShareLink(subject: subject, subjectId: subjectId);
}
