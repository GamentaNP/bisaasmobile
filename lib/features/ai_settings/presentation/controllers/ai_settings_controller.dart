import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/ai_settings_remote_data_source.dart';

import '../../data/repositories/ai_settings_repository_impl.dart';
import '../../domain/entities/ai_settings.dart';
import '../../domain/repositories/ai_settings_repository.dart';

final aiSettingsRemoteDataSourceProvider =
    Provider<AiSettingsRemoteDataSource>((ref) {
  return AiSettingsRemoteDataSource(DioClient.instance.dio);
});

final aiSettingsRepositoryProvider = Provider<AiSettingsRepository>((ref) {
  return AiSettingsRepositoryImpl(ref.watch(aiSettingsRemoteDataSourceProvider));
});

/// The periods the server accepts.
enum AiUsagePeriod {
  sevenDays('7d', '7 days'),
  thirtyDays('30d', '30 days'),
  ninetyDays('90d', '90 days');

  const AiUsagePeriod(this.wireValue, this.label);

  /// The value the server validates against.
  final String wireValue;
  final String label;
}

class AiSettingsState {
  const AiSettingsState({
    this.keys = const [],
    this.isKeysLoading = false,
    this.keysError,
    this.keysHasMore = false,
    this.keysCursor,
    this.isSavingKey = false,
    this.saveKeyError,
    this.saveKeyMessage,
    this.usage,
    this.isUsageLoading = false,
    this.usageError,
    this.usagePeriod = AiUsagePeriod.thirtyDays,
    this.tutorSessions = const [],
    this.isSessionsLoading = false,
    this.sessionsError,
    this.reportCard = const [],
    this.isReportCardLoading = false,
    this.reportCardError,
  });

  final List<AiKey> keys;
  final bool isKeysLoading;
  final String? keysError;
  final bool keysHasMore;
  final String? keysCursor;

  final bool isSavingKey;
  final String? saveKeyError;
  final String? saveKeyMessage;

  final AiUsageSummary? usage;
  final bool isUsageLoading;
  final String? usageError;
  final AiUsagePeriod usagePeriod;

  final List<TutorSession> tutorSessions;
  final bool isSessionsLoading;
  final String? sessionsError;

  final List<ReportCardWeek> reportCard;
  final bool isReportCardLoading;
  final String? reportCardError;

  static const _sentinel = Object();

  AiSettingsState copyWith({
    List<AiKey>? keys,
    bool? isKeysLoading,
    Object? keysError = _sentinel,
    bool? keysHasMore,
    Object? keysCursor = _sentinel,
    bool? isSavingKey,
    Object? saveKeyError = _sentinel,
    Object? saveKeyMessage = _sentinel,
    Object? usage = _sentinel,
    bool? isUsageLoading,
    Object? usageError = _sentinel,
    AiUsagePeriod? usagePeriod,
    List<TutorSession>? tutorSessions,
    bool? isSessionsLoading,
    Object? sessionsError = _sentinel,
    List<ReportCardWeek>? reportCard,
    bool? isReportCardLoading,
    Object? reportCardError = _sentinel,
  }) {
    return AiSettingsState(
      keys: keys ?? this.keys,
      isKeysLoading: isKeysLoading ?? this.isKeysLoading,
      keysError: keysError == _sentinel ? this.keysError : keysError as String?,
      keysHasMore: keysHasMore ?? this.keysHasMore,
      keysCursor: keysCursor == _sentinel ? this.keysCursor : keysCursor as String?,
      isSavingKey: isSavingKey ?? this.isSavingKey,
      saveKeyError:
          saveKeyError == _sentinel ? this.saveKeyError : saveKeyError as String?,
      saveKeyMessage: saveKeyMessage == _sentinel
          ? this.saveKeyMessage
          : saveKeyMessage as String?,
      usage: usage == _sentinel ? this.usage : usage as AiUsageSummary?,
      isUsageLoading: isUsageLoading ?? this.isUsageLoading,
      usageError: usageError == _sentinel ? this.usageError : usageError as String?,
      usagePeriod: usagePeriod ?? this.usagePeriod,
      tutorSessions: tutorSessions ?? this.tutorSessions,
      isSessionsLoading: isSessionsLoading ?? this.isSessionsLoading,
      sessionsError:
          sessionsError == _sentinel ? this.sessionsError : sessionsError as String?,
      reportCard: reportCard ?? this.reportCard,
      isReportCardLoading: isReportCardLoading ?? this.isReportCardLoading,
      reportCardError: reportCardError == _sentinel
          ? this.reportCardError
          : reportCardError as String?,
    );
  }
}

class AiSettingsController extends Notifier<AiSettingsState> {
  @override
  AiSettingsState build() => const AiSettingsState();

  AiSettingsRepository get _repo => ref.read(aiSettingsRepositoryProvider);

  String _msg(Object e) => e is ApiException ? e.message : e.toString();

  // ── BYOK ───────────────────────────────────────────────────────────────────

  /// Loads the caller's keys.
  ///
  /// A failure throws out of the data source, so the UI shows an error with a
  /// retry rather than an empty key list that looks like "you have no keys".
  Future<void> fetchKeys({String? cursor, bool append = false}) async {
    state = state.copyWith(isKeysLoading: true, keysError: null);
    try {
      final page = await _repo.getKeys(cursor: cursor);
      state = state.copyWith(
        keys: append ? [...state.keys, ...page.items] : page.items,
        isKeysLoading: false,
        keysHasMore: page.hasMore,
        keysCursor: page.nextCursor,
      );
    } catch (e, st) {
      AppLogger.w('ai settings fetchKeys failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isKeysLoading: false, keysError: _msg(e));
    }
  }

  /// Stores a key.
  ///
  /// The secret is sent once and never read back — the server returns only a
  /// masked preview.
  Future<bool> storeKey({
    required AiProvider provider,
    required String secret,
    String? label,
    int? dailyTokenLimit,
  }) async {
    state = state.copyWith(
      isSavingKey: true,
      saveKeyError: null,
      saveKeyMessage: null,
    );
    try {
      final key = await _repo.storeKey(
        provider: provider,
        secret: secret,
        label: label,
        dailyTokenLimit: dailyTokenLimit,
      );
      state = state.copyWith(
        isSavingKey: false,
        saveKeyMessage:
            '${key.displayName} saved. It is encrypted on our servers and never shown again.',
      );
      await fetchKeys();
      return true;
    } catch (e, st) {
      AppLogger.w('ai settings storeKey failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isSavingKey: false, saveKeyError: _msg(e));
      return false;
    }
  }

  /// Revokes a key.
  Future<bool> revokeKey(int keyId) async {
    state = state.copyWith(isSavingKey: true, saveKeyError: null);
    try {
      await _repo.revokeKey(keyId);
      state = state.copyWith(
        isSavingKey: false,
        saveKeyMessage: 'Key revoked.',
      );
      await fetchKeys();
      return true;
    } catch (e, st) {
      AppLogger.w('ai settings revokeKey $keyId failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isSavingKey: false, saveKeyError: _msg(e));
      return false;
    }
  }

  void clearSaveMessages() => state = state.copyWith(
        saveKeyError: null,
        saveKeyMessage: null,
      );

  // ── Own usage ──────────────────────────────────────────────────────────────

  Future<void> fetchUsage({AiUsagePeriod? period}) async {
    final selected = period ?? state.usagePeriod;
    state = state.copyWith(
      isUsageLoading: true,
      usageError: null,
      usagePeriod: selected,
    );
    try {
      final usage = await _repo.getUsageSummary(period: selected.wireValue);
      state = state.copyWith(isUsageLoading: false, usage: usage);
    } catch (e, st) {
      AppLogger.w('ai settings fetchUsage failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isUsageLoading: false, usageError: _msg(e));
    }
  }

  Future<void> fetchTutorSessions({String? cursor, bool append = false}) async {
    state = state.copyWith(isSessionsLoading: true, sessionsError: null);
    try {
      final page = await _repo.getTutorSessions(cursor: cursor);
      state = state.copyWith(
        tutorSessions:
            append ? [...state.tutorSessions, ...page.items] : page.items,
        isSessionsLoading: false,
      );
    } catch (e, st) {
      AppLogger.w('ai settings fetchTutorSessions failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isSessionsLoading: false, sessionsError: _msg(e));
    }
  }

  Future<void> fetchReportCardHistory({String? cursor, bool append = false}) async {
    state = state.copyWith(isReportCardLoading: true, reportCardError: null);
    try {
      final page = await _repo.getReportCardHistory(cursor: cursor);
      state = state.copyWith(
        reportCard:
            append ? [...state.reportCard, ...page.items] : page.items,
        isReportCardLoading: false,
      );
    } catch (e, st) {
      AppLogger.w('ai settings fetchReportCardHistory failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isReportCardLoading: false, reportCardError: _msg(e));
    }
  }
}

final aiSettingsControllerProvider =
    NotifierProvider<AiSettingsController, AiSettingsState>(
  AiSettingsController.new,
);

