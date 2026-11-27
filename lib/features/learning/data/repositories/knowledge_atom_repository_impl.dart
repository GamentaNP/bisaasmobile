import '../../domain/entities/knowledge_atom.dart';
import '../../domain/repositories/knowledge_atom_repository.dart';
import '../datasources/knowledge_atom_remote_data_source.dart';

class KnowledgeAtomRepositoryImpl implements KnowledgeAtomRepository {
  const KnowledgeAtomRepositoryImpl(this._remote);

  final KnowledgeAtomRemoteDataSource _remote;

  @override
  Future<KnowledgeAtom> getAtom(String atomId) => _remote.getAtom(atomId);
}
