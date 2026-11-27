/// Pure Dart models for the two past-paper reads (§9.5).
///
/// The list is cursor-walked; the detail is a bounded snapshot of question text
/// and (only when redistribution is allowed) scanned page URLs. No answer key
/// is ever part of these models — answer keys stay server-authoritative.
library;

class PastPaperCourse {
  const PastPaperCourse({required this.id, required this.name});

  final int id;
  final String name;
}

class PastPaperListItem {
  const PastPaperListItem({
    required this.id,
    required this.label,
    this.country,
    this.province,
    this.post,
    this.board,
    this.yearBs,
    this.yearAd,
    this.paperNumber,
    this.totalQuestions = 0,
    this.totalMarks = 0,
    this.durationMinutes = 0,
    this.verified = false,
    this.hasKey = false,
    this.redistributionAllowed = false,
    this.sourceUrl,
    this.examName,
    this.authority,
    this.detailUrl,
  });

  final int id;
  final String label;
  final String? country;
  final String? province;
  final String? post;
  final String? board;
  final int? yearBs;
  final int? yearAd;
  final int? paperNumber;
  final int totalQuestions;
  final int totalMarks;
  final int durationMinutes;
  final bool verified;
  final bool hasKey;
  final bool redistributionAllowed;
  final String? sourceUrl;
  final String? examName;
  final String? authority;
  final String? detailUrl;
}

class PastPaperCatalog {
  const PastPaperCatalog({
    required this.items,
    required this.filters,
    required this.facets,
    required this.courses,
  });

  final List<PastPaperListItem> items;
  final Map<String, dynamic> filters;
  final Map<String, dynamic> facets;
  final List<PastPaperCourse> courses;
}

class PastPaperCatalogPage {
  const PastPaperCatalogPage({
    required this.items,
    required this.filters,
    required this.facets,
    required this.courses,
    this.nextCursor,
    this.hasMore = false,
  });

  final List<PastPaperListItem> items;
  final Map<String, dynamic> filters;
  final Map<String, dynamic> facets;
  final List<PastPaperCourse> courses;
  final String? nextCursor;
  final bool hasMore;
}

class PastPaperQuestion {
  const PastPaperQuestion({
    required this.id,
    required this.text,
    this.number,
    this.marks,
  });

  final int id;
  final String text;
  final String? number;
  final String? marks;
}

class PastPaperPage {
  const PastPaperPage({
    required this.pageNumber,
    required this.url,
    this.hasQuestionText = false,
    this.hasAnswerKey = false,
  });

  final int pageNumber;
  final String url;
  final bool hasQuestionText;
  final bool hasAnswerKey;
}

class PastPaperDetail {
  const PastPaperDetail({
    required this.label,
    required this.pages,
    required this.questions,
    this.canShowScans = false,
    this.country,
    this.province,
    this.post,
    this.board,
    this.yearBs,
    this.yearAd,
    this.totalQuestions = 0,
    this.totalMarks = 0,
    this.durationMinutes = 0,
    this.verified = false,
    this.authority,
    this.syllabusVersion,
  });

  final String label;
  final List<PastPaperPage> pages;
  final List<PastPaperQuestion> questions;
  final bool canShowScans;
  final String? country;
  final String? province;
  final String? post;
  final String? board;
  final int? yearBs;
  final int? yearAd;
  final int totalQuestions;
  final int totalMarks;
  final int durationMinutes;
  final bool verified;
  final String? authority;
  final String? syllabusVersion;
}
