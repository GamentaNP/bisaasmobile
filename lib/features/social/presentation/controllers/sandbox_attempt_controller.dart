/// Provider for the authenticated guest-sandbox result read (§9.5).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../data/datasources/sandbox_attempt_remote_data_source.dart';
import '../../data/repositories/sandbox_attempt_repository_impl.dart';
import '../../domain/entities/sandbox_attempt.dart';
import '../../domain/repositories/sandbox_attempt_repository.dart';

/// Both proofs travel in the family key: the credential is supplied by the
/// data source's Dio, the session binding as the only allowed query key.
typedef SandboxAttemptKey = ({String attemptId, String guestSessionId});

/// The credential proof is a provider seam: tests override it with a stub,
/// production reads the same bearer token the auth interceptor attaches.
final sandboxCredentialProvider = Provider<Future<bool> Function()>((ref) {
  return SandboxAttemptRemoteDataSource.storedTokenGuard;
});

final sandboxAttemptRemoteDataSourceProvider =
    Provider<SandboxAttemptRemoteDataSource>((ref) {
  return SandboxAttemptRemoteDataSource(
    ref.watch(dioProvider),
    hasCredential: ref.watch(sandboxCredentialProvider),
  );
});

final sandboxAttemptRepositoryProvider = Provider<SandboxAttemptRepository>((ref) {
  return SandboxAttemptRepositoryImpl(
    ref.watch(sandboxAttemptRemoteDataSourceProvider),
  );
});

final sandboxAttemptProvider = FutureProvider.family<
    SandboxAttemptResults, SandboxAttemptKey>((ref, key) {
  return ref.watch(sandboxAttemptRepositoryProvider).getAttempt(
        attemptId: key.attemptId,
        guestSessionId: key.guestSessionId,
      );
});
