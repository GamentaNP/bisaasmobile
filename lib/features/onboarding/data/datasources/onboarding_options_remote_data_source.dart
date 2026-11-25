library;

import 'package:dio/dio.dart';

import '../../../../core/network/api_failure.dart';
import '../../domain/entities/onboarding_options.dart';
import '../models/onboarding_options_dto.dart';

/// Reads the server-owned onboarding option catalogue.
///
/// Auth is required; the injected [Dio] carries the bearer token through the
/// shared interceptor chain. A transport failure or non-2xx becomes an
/// `ApiException`; an unreadable 2xx body becomes a [ContractViolation]. Neither
/// is ever collapsed into an empty option list.
class OnboardingOptionsRemoteDataSource {
  const OnboardingOptionsRemoteDataSource(this._dio);

  final Dio _dio;

  static const endpoint = OnboardingOptionsDto.endpoint;

  Future<OnboardingOptions> fetchOptions() async {
    final res = await _dio.get<Map<String, dynamic>>(endpoint);
    final body = res.data;
    if (body == null) {
      throw const ContractViolation('Empty onboarding options response',
          endpoint: endpoint);
    }
    return OnboardingOptionsDto.fromEnvelope(body, endpoint: endpoint).toDomain();
  }
}
