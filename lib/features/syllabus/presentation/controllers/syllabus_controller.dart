import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/syllabus_remote_data_source.dart';
import '../../data/repositories/syllabus_repository_impl.dart';
import '../../domain/entities/syllabus.dart';
import '../../domain/repositories/syllabus_repository.dart';

final syllabusRemoteDataSourceProvider = Provider<SyllabusRemoteDataSource>(
  (ref) => SyllabusRemoteDataSource(DioClient.instance.dio),
);

final syllabusRepositoryProvider = Provider<SyllabusRepository>(
  (ref) => SyllabusRepositoryImpl(ref.watch(syllabusRemoteDataSourceProvider)),
);

/// State for the version list — the entry point of the syllabus feature.
class SyllabusVersionsState {
  const SyllabusVersionsState({this.isLoading = false, this.versions = const [], this.error});

  final bool isLoading;
  final List<SyllabusVersion> versions;
  final String? error;

  /// True only once a completed load produced nothing. A list still loading is
  /// not "empty", and the screen must not flash a "no syllabus" message for it.
  bool get isEmpty => !isLoading && error == null && versions.isEmpty;

  /// Versions currently in force. Falls back to the full list, because a closed
  /// effective window is not a reason to tell the user there is no syllabus.
  List<SyllabusVersion> get effective {
    final live = versions.where((v) => v.isEffectiveNow).toList();
    return live.isEmpty ? versions : live;
  }

  SyllabusVersionsState copyWith({
    bool? isLoading,
    List<SyllabusVersion>? versions,
    String? error,
    bool clearError = false,
  }) {
    return SyllabusVersionsState(
      isLoading: isLoading ?? this.isLoading,
      versions: versions ?? this.versions,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// State for one version's tree.
class SyllabusTreeState {
  const SyllabusTreeState({this.isLoading = false, this.tree, this.error, this.depth = 2});

  final bool isLoading;
  final SyllabusTree? tree;
  final String? error;

  /// Depth currently loaded, so "show more levels" widens the request instead of
  /// refetching blind.
  final int depth;

  bool get isEmpty => tree != null && tree!.isEmpty;

  SyllabusTreeState copyWith({
    bool? isLoading,
    SyllabusTree? tree,
    String? error,
    bool clearError = false,
    int? depth,
  }) {
    return SyllabusTreeState(
      isLoading: isLoading ?? this.isLoading,
      tree: tree ?? this.tree,
      error: clearError ? null : (error ?? this.error),
      depth: depth ?? this.depth,
    );
  }
}

class SyllabusVersionsController extends Notifier<SyllabusVersionsState> {
  @override
  SyllabusVersionsState build() {
    // Starts in the loading state rather than an empty one. The screen branches
    // on `isEmpty`, which is `!isLoading && error == null && versions.isEmpty`,
    // so starting empty-but-not-loading made the first frame render "No syllabus
    // has been published yet" before the request had even been made. The load is
    // still kicked off here so the screen does not have to remember to call it.
    Future.microtask(load);
    return const SyllabusVersionsState(isLoading: true);
  }

  SyllabusRepository get _repo => ref.read(syllabusRepositoryProvider);

  String _msg(Object e) => e is ApiException ? e.message : 'Could not load syllabus versions';

  /// True while a request is genuinely in flight.
  ///
  /// This cannot be read from `state.isLoading`, because `build()` starts in the
  /// loading state to avoid an empty first frame — so the flag would read true
  /// before any request had been made and the initial load would refuse to run.
  bool _inFlight = false;

  Future<void> load({bool force = false}) async {
    if (_inFlight) return;
    if (state.versions.isNotEmpty && !force) return;
    _inFlight = true;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final versions = await _repo.getVersions();
      state = state.copyWith(isLoading: false, versions: versions);
    } catch (e, st) {
      AppLogger.w('syllabus versions failed: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isLoading: false, error: _msg(e));
    } finally {
      // Released in `finally` so a thrown error cannot wedge the controller into
      // a permanently-loading state with no way to retry.
      _inFlight = false;
    }
  }

  Future<void> refresh() => load(force: true);
}

class SyllabusTreeController extends Notifier<SyllabusTreeState> {
  SyllabusTreeController(this.publicId);

  /// The version's `public_id`, which is what the route binds on.
  final String publicId;

  String? _loadedFor;

  @override
  SyllabusTreeState build() {
    // Starts loading rather than empty, for the same reason as the version list:
    // an empty-but-not-loading first frame renders "This syllabus has no
    // published nodes yet" before the request has been made.
    Future.microtask(() => load(publicId));
    return const SyllabusTreeState(isLoading: true);
  }

  SyllabusRepository get _repo => ref.read(syllabusRepositoryProvider);

  /// Fetches the tree for [publicId].
  ///
  /// The `_loadedFor` guard matters: the server caches this payload for 24h
  /// keyed on `structure_hash` and it is large, so re-entering the screen must
  /// not refetch what is already held. A different [publicId] does refetch.
  /// True while a request is genuinely in flight. See the note on the version
  /// list controller: it cannot be read from `state.isLoading`, because `build()`
  /// starts loading and the guard would then block the initial load itself.
  bool _inFlight = false;

  Future<void> load(String publicId, {int? depth, bool force = false}) async {
    if (_inFlight) return;
    if (!force && _loadedFor == publicId && state.tree != null) return;
    _inFlight = true;
    state = state.copyWith(isLoading: true, clearError: true, depth: depth ?? state.depth);
    try {
      final tree = await _repo.getTree(publicId, depth: depth);
      _loadedFor = publicId;
      state = state.copyWith(isLoading: false, tree: tree);
    } catch (e, st) {
      AppLogger.w('syllabus tree failed for $publicId: $e');
      if (!const bool.fromEnvironment('dart.vm.product')) AppLogger.d(st);
      state = state.copyWith(isLoading: false, error: 'Could not load the syllabus');
    } finally {
      _inFlight = false;
    }
  }

  Future<void> refresh() => load(publicId, force: true);
}

final syllabusVersionsControllerProvider =
    NotifierProvider<SyllabusVersionsController, SyllabusVersionsState>(
  SyllabusVersionsController.new,
);

/// Family keyed on the version's `public_id`, which is what the route binds on.
final syllabusTreeControllerProvider =
    NotifierProvider.family<SyllabusTreeController, SyllabusTreeState, String>(
  SyllabusTreeController.new,
);

/// The learner's own plans. Kept apart from the catalog because a signed-out
/// user can still browse the public syllabus and must not trigger a 401.
final mySyllabusPlansProvider = FutureProvider<List<UserSyllabusPlan>>(
  (ref) => ref.watch(syllabusRepositoryProvider).getMyPlans(),
);
