/// Data source for `GET /quiz/knowledge-atoms/{atom}` (§9.5).
///
/// A single authenticated read; no query keys are sent and no cursor applies.
library;

import 'package:dio/dio.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/envelope.dart';
import '../../domain/entities/knowledge_atom.dart';
import '../models/knowledge_atom_dto.dart';

class KnowledgeAtomRemoteDataSource {
  const KnowledgeAtomRemoteDataSource(this._dio);

  final Dio _dio;

  static const endpoint = '/quiz/knowledge-atoms';

  Future<KnowledgeAtom> getAtom(String atomId) async {
    if (int.tryParse(atomId) == null) {
      throw ContractViolation(
        'A knowledge atom id must be numeric',
        endpoint: endpoint,
      );
    }
    final path = '$endpoint/$atomId';
    final res = await _dio.get<Map<String, dynamic>>(path);
    final body = res.data;
    if (body == null) {
      throw ContractViolation('Empty response body', endpoint: path);
    }
    return KnowledgeAtomDto.fromJson(
      requireDataMap(body, endpoint: path),
      endpoint: path,
    ).toDomain(endpoint: path);
  }
}
