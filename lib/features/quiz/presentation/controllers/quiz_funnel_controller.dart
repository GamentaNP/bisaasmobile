import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/quiz_funnel.dart';
import '../../data/datasources/quiz_remote_data_source.dart';

final quizFunnelRemoteDataSourceProvider = Provider<QuizRemoteDataSource>((ref) {
  return QuizRemoteDataSource(DioClient.instance.dio);
});

/// Which funnel to load.
///
/// The guest bundle (`GET /quiz/guest-funnel`) is public and works before
/// registration; the authenticated bundle (`GET /quiz/funnel`) is the same
/// shape with the caller's own tier.
enum QuizFunnelTier {
  guest,
  authenticated;

  String get endpoint => switch (this) {
        QuizFunnelTier.guest => '/quiz/guest-funnel',
        QuizFunnelTier.authenticated => '/quiz/funnel',
      };
}

class QuizFunnelState {
  const QuizFunnelState({
    this.funnel,
    this.isLoading = false,
    this.error,
    this.tier = QuizFunnelTier.guest,
  });

  final QuizFunnel? funnel;
  final bool isLoading;
  final String? error;
  final QuizFunnelTier tier;

  static const _sentinel = Object();

  QuizFunnelState copyWith({
    Object? funnel = _sentinel,
    bool? isLoading,
    Object? error = _sentinel,
    QuizFunnelTier? tier,
  }) {
    return QuizFunnelState(
      funnel: funnel == _sentinel ? this.funnel : funnel as QuizFunnel?,
      isLoading: isLoading ?? this.isLoading,
      error: error == _sentinel ? this.error : error as String?,
      tier: tier ?? this.tier,
    );
  }
}

class QuizFunnelController extends Notifier<QuizFunnelState> {
  @override
  QuizFunnelState build() => const QuizFunnelState();

  QuizRemoteDataSource get _remote =>
      ref.read(quizFunnelRemoteDataSourceProvider);

  String _msg(Object e) => e is ApiException ? e.message : e.toString();

  /// Loads the funnel bundle for [tier].
  ///
  /// A failure is surfaced as an error rather than an empty bundle: the user
  /// must be able to tell "there is no content" from "we could not reach the
  /// server".
  Future<void> load(QuizFunnelTier tier, {int itemLimit = 8}) async {
    state = state.copyWith(isLoading: true, error: null, tier: tier);
    try {
      final dto = switch (tier) {
        QuizFunnelTier.guest => await _remote.getGuestFunnel(itemLimit: itemLimit),
        QuizFunnelTier.authenticated =>
          await _remote.getFunnel(itemLimit: itemLimit),
      };
      state = state.copyWith(
        funnel: dto.toDomain(),
        isLoading: false,
        tier: tier,
      );
    } catch (e, st) {
      AppLogger.w('quiz funnel load (${tier.name}) failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isLoading: false, error: _msg(e));
    }
  }

  Future<void> refresh() => load(state.tier);
}

final quizFunnelControllerProvider =
    NotifierProvider<QuizFunnelController, QuizFunnelState>(
  QuizFunnelController.new,
);
