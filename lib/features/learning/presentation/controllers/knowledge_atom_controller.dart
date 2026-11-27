/// Provider for the knowledge-atom detail read (§9.5).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../data/datasources/knowledge_atom_remote_data_source.dart';
import '../../data/repositories/knowledge_atom_repository_impl.dart';
import '../../domain/entities/knowledge_atom.dart';
import '../../domain/repositories/knowledge_atom_repository.dart';

final knowledgeAtomRemoteDataSourceProvider =
    Provider<KnowledgeAtomRemoteDataSource>((ref) {
  return KnowledgeAtomRemoteDataSource(ref.watch(dioProvider));
});

final knowledgeAtomRepositoryProvider = Provider<KnowledgeAtomRepository>((ref) {
  return KnowledgeAtomRepositoryImpl(ref.watch(knowledgeAtomRemoteDataSourceProvider));
});

final knowledgeAtomProvider =
    FutureProvider.family<KnowledgeAtom, String>((ref, atomId) {
  return ref.watch(knowledgeAtomRepositoryProvider).getAtom(atomId);
});
