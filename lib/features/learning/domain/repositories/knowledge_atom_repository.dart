import '../entities/knowledge_atom.dart';

/// Read boundary for the single knowledge-atom popover payload.
// ignore: one_member_abstracts — repository boundary per Clean Arch.
abstract class KnowledgeAtomRepository {
  Future<KnowledgeAtom> getAtom(String atomId);
}
