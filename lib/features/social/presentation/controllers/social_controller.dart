import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/social_remote_data_source.dart';
import '../../data/repositories/social_repository_impl.dart';
import '../../domain/entities/social.dart';
import '../../domain/repositories/social_repository.dart';

final socialRemoteDataSourceProvider = Provider<SocialRemoteDataSource>(
  (ref) => SocialRemoteDataSource(DioClient.instance.dio),
);

final socialRepositoryProvider = Provider<SocialRepository>(
  (ref) => SocialRepositoryImpl(ref.watch(socialRemoteDataSourceProvider)),
);

class SocialState {
  const SocialState({
    this.isLoading = false,
    this.dashboard,
    this.moments = const [],
    this.error,
    this.claimInFlight = false,
    this.claimMessage,
  });

  final bool isLoading;
  final ReferralDashboard? dashboard;
  final List<ShareMoment> moments;
  final String? error;
  final bool claimInFlight;
  final String? claimMessage;

  /// Distinguishes "loaded and you have no referrals" from "not loaded", which
  /// are very different things to show a user.
  bool get hasLoaded => dashboard != null;

  SocialState copyWith({
    bool? isLoading,
    ReferralDashboard? dashboard,
    List<ShareMoment>? moments,
    String? error,
    bool clearError = false,
    bool? claimInFlight,
    String? claimMessage,
    bool clearClaimMessage = false,
  }) {
    return SocialState(
      isLoading: isLoading ?? this.isLoading,
      dashboard: dashboard ?? this.dashboard,
      moments: moments ?? this.moments,
      error: clearError ? null : (error ?? this.error),
      claimInFlight: claimInFlight ?? this.claimInFlight,
      claimMessage: clearClaimMessage ? null : (claimMessage ?? this.claimMessage),
    );
  }
}

class SocialController extends Notifier<SocialState> {
  @override
  SocialState build() {
    Future.microtask(load);
    return const SocialState();
  }

  SocialRepository get _repo => ref.read(socialRepositoryProvider);

  String _msg(Object e) => e is ApiException ? e.message : 'Could not load referrals';

  Future<void> load({bool force = false}) async {
    if (state.isLoading) return;
    if (state.hasLoaded && !force) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // The dashboard is the point of the screen; moments are supplementary, so
      // a moments failure must not blank the whole thing.
      final dashboard = await _repo.getReferralDashboard();
      var moments = <ShareMoment>[];
      try {
        moments = await _repo.getActiveMoments();
      } catch (e) {
        AppLogger.w('social moments failed: $e');
      }
      state = state.copyWith(isLoading: false, dashboard: dashboard, moments: moments);
    } catch (e, st) {
      AppLogger.w('social dashboard failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isLoading: false, error: _msg(e));
    }
  }

  Future<void> refresh() => load(force: true);

  /// Claims a code a friend gave the user after signup.
  ///
  /// The server is the judge: it returns 422 for an invalid code or for a second,
  /// different code once already attributed, and that message is surfaced
  /// verbatim rather than replaced with a generic failure.
  Future<void> claimCode(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) return;
    if (state.claimInFlight) return;
    state = state.copyWith(claimInFlight: true, clearClaimMessage: true);
    try {
      final result = await _repo.claimReferralCode(code);
      final message = result.claimed
          ? 'Referral code applied.'
          : 'That code could not be applied. It may already have been used.';
      state = state.copyWith(claimInFlight: false, claimMessage: message);
      // The reward may have changed the wallet, so re-read the dashboard.
      if (result.claimed) await load(force: true);
    } catch (e) {
      AppLogger.w('referral claim failed: $e');
      state = state.copyWith(
        claimInFlight: false,
        claimMessage: e is ApiException ? e.message : 'Could not apply that code',
      );
    }
  }

  void clearClaimMessage() => state = state.copyWith(clearClaimMessage: true);

  Future<void> dismiss(ShareMoment moment) async {
    // Remove it locally first: the user should not see it reappear while the
    // request is in flight.
    state = state.copyWith(
      moments: state.moments.where((m) => m.id != moment.id).toList(),
    );
    try {
      await _repo.dismissMoment(moment.id);
    } catch (e) {
      AppLogger.w('dismiss moment failed: $e');
    }
  }
}

final socialControllerProvider = NotifierProvider<SocialController, SocialState>(
  SocialController.new,
);
