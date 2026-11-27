import '../../../../core/network/api_failure.dart';
import '../../domain/entities/past_paper.dart';

/// Wire DTOs for `/quiz/past-papers` and `/quiz/past-papers/{paper}`.
///
/// The server's keys are snake_case and additive; every key the UI reads is
/// checked here. A missing or wrongly typed section is contract drift, not an
/// empty catalogue.
abstract final class _Parse {
  static Map<String, dynamic> map(Object? value, String key, String endpoint) {
    if (value is Map<String, dynamic>) return value;
    throw ContractViolation('Expected $key to be an object', endpoint: endpoint);
  }

  static List<Map<String, dynamic>> list(Object? value, String key, String endpoint) {
    if (value is List) return value.whereType<Map<String, dynamic>>().toList();
    throw ContractViolation('Expected $key to be a list', endpoint: endpoint);
  }

  static int intOf(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? nullableInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static String? nullableString(Object? value) => value?.toString();

  static String requiredString(Object? value, String key, String endpoint) {
    final text = value?.toString() ?? '';
    if (text.isEmpty) {
      throw ContractViolation('A past paper has no $key', endpoint: endpoint);
    }
    return text;
  }
}

class PastPaperListItemDto {
  const PastPaperListItemDto._(this._j);
  final Map<String, dynamic> _j;

  factory PastPaperListItemDto.fromJson(
    Map<String, dynamic> j, {
    String endpoint = '/quiz/past-papers',
  }) {
    // `id` and `label` are the two non-nullable identity fields of the row.
    _Parse.intOf(j['id']);
    _Parse.requiredString(j['label'], 'label', endpoint);
    return PastPaperListItemDto._(j);
  }

  PastPaperListItem toDomain() => PastPaperListItem(
        id: _Parse.intOf(_j['id']),
        label: _Parse.requiredString(_j['label'], 'label', '/quiz/past-papers'),
        country: _Parse.nullableString(_j['country']),
        province: _Parse.nullableString(_j['province']),
        post: _Parse.nullableString(_j['post']),
        board: _Parse.nullableString(_j['board']),
        yearBs: _Parse.nullableInt(_j['year_bs']),
        yearAd: _Parse.nullableInt(_j['year_ad']),
        paperNumber: _Parse.nullableInt(_j['paper_number']),
        totalQuestions: _Parse.intOf(_j['total_questions']),
        totalMarks: _Parse.intOf(_j['total_marks']),
        durationMinutes: _Parse.intOf(_j['duration_minutes']),
        verified: _j['verified'] == true,
        hasKey: _j['has_key'] == true,
        redistributionAllowed: _j['redistribution_allowed'] == true,
        sourceUrl: _Parse.nullableString(_j['source_url']),
        examName: _Parse.nullableString(_j['exam_name']),
        authority: _Parse.nullableString(_j['authority']),
        detailUrl: _Parse.nullableString(_j['detail_url']),
      );
}

class PastPaperCatalogDto {
  const PastPaperCatalogDto({required this.data});
  final Map<String, dynamic> data;

  factory PastPaperCatalogDto.fromJson(
    Map<String, dynamic> data, {
    String endpoint = '/quiz/past-papers',
  }) {
    _Parse.list(data['items'], 'items', endpoint);
    _Parse.map(data['filters'], 'filters', endpoint);
    _Parse.map(data['facets'], 'facets', endpoint);
    _Parse.list(data['courses'], 'courses', endpoint);
    return PastPaperCatalogDto(data: data);
  }

  PastPaperCatalog toDomain({String endpoint = '/quiz/past-papers'}) =>
      PastPaperCatalog(
        items: _Parse.list(_data('items'), 'items', endpoint)
            .map((j) => PastPaperListItemDto.fromJson(j, endpoint: endpoint).toDomain())
            .toList(),
        filters: _Parse.map(_data('filters'), 'filters', endpoint),
        facets: _Parse.map(_data('facets'), 'facets', endpoint),
        courses: _Parse.list(_data('courses'), 'courses', endpoint).map((j) {
          return PastPaperCourse(
            id: _Parse.intOf(j['id']),
            name: _Parse.requiredString(j['name'], 'name', endpoint),
          );
        }).toList(),
      );

  Object? _data(String key) => data[key];
}

class PastPaperDetailDto {
  const PastPaperDetailDto({required this.data});
  final Map<String, dynamic> data;

  factory PastPaperDetailDto.fromJson(
    Map<String, dynamic> data, {
    String endpoint = '/quiz/past-papers/{paper}',
  }) {
    _Parse.map(data['paper'], 'paper', endpoint);
    _Parse.list(data['pages'], 'pages', endpoint);
    _Parse.list(data['questions'], 'questions', endpoint);
    return PastPaperDetailDto(data: data);
  }

  PastPaperDetail toDomain({String endpoint = '/quiz/past-papers/{paper}'}) {
    final paper = _Parse.map(data['paper'], 'paper', endpoint);
    final canShowScans = paper['can_show_scans'] == true;
    final publishedPages = _Parse.list(data['pages'], 'pages', endpoint);

    return PastPaperDetail(
      label: _Parse.requiredString(paper['label'], 'label', endpoint),
      canShowScans: canShowScans,
      // The server only publishes a URL when redistribution is allowed. Never
      // render an answer-key scan even in that case.
      pages: !canShowScans
          ? const <PastPaperPage>[]
          : publishedPages
              .where((page) => page['has_answer_key'] != true)
              .map((page) => PastPaperPage(
                    pageNumber: _Parse.intOf(page['page_number']),
                    url: _Parse.requiredString(page['url'], 'url', endpoint),
                    hasQuestionText: page['has_question_text'] == true,
                    hasAnswerKey: page['has_answer_key'] == true,
                  ))
              .toList(),
      questions: _Parse.list(data['questions'], 'questions', endpoint).map((q) {
        return PastPaperQuestion(
          id: _Parse.intOf(q['id']),
          text: _Parse.requiredString(q['text'], 'text', endpoint),
          number: _Parse.nullableString(q['number']),
          marks: _Parse.nullableString(q['marks']),
        );
      }).toList(),
      country: _Parse.nullableString(paper['country']),
      province: _Parse.nullableString(paper['province']),
      post: _Parse.nullableString(paper['post']),
      board: _Parse.nullableString(paper['board']),
      yearBs: _Parse.nullableInt(paper['year_bs']),
      yearAd: _Parse.nullableInt(paper['year_ad']),
      totalQuestions: _Parse.intOf(paper['total_questions']),
      totalMarks: _Parse.intOf(paper['total_marks']),
      durationMinutes: _Parse.intOf(paper['duration_minutes']),
      verified: paper['verified'] == true,
      authority: _Parse.nullableString(paper['authority']),
      syllabusVersion: _Parse.nullableString(paper['syllabus_version']),
    );
  }
}
