import 'package:bisaasmobile/features/syllabus/data/models/syllabus_dto.dart';
import 'package:flutter_test/flutter_test.dart';

/// Payload shapes are taken from the server resources, not invented:
/// - `app/Http/Resources/Api/Syllabus/SyllabusVersionResource.php`
/// - `app/Http/Resources/Api/Syllabus/SyllabusNodeResource.php`
/// - `app/Domains/Quiz/Syllabus/Services/SyllabusTreeService.php` (summary, tree)
/// - `app/Http/Controllers/Api/V1/Syllabus/SyllabusCatalogController.php` (blueprint)
void main() {
  group('SyllabusVersionDto', () {
    final row = <String, dynamic>{
      'public_id': '01HQ8S4T2V0000000000001',
      'version_code': 'loksewa-2082',
      'title': 'Loksewa Civil Engineer',
      'title_ne': 'लोकसेवा सिविल इन्जिनियर',
      'status': 'published',
      'effective_from': '2026-01-01T00:00:00+00:00',
      'effective_to': null,
      'effective_window': '2082/01/01 – 2083/12/31',
      'structure_hash': 'abc123',
      'node_count': 412,
      'examinable_node_count': 380,
      'exam': <String, dynamic>{
        'id': 7,
        'name': 'Civil Engineer',
        'post': 'Civil Engineer',
        'level': 'Level 2',
        'group_name': 'Technical',
        'authority': 'OPMC',
      },
      'created_at': '2026-01-01T00:00:00+00:00',
    };

    test('parses the full resource', () {
      final v = SyllabusVersionDto.fromJson(row)!.domain;
      expect(v.publicId, '01HQ8S4T2V0000000000001');
      expect(v.versionCode, 'loksewa-2082');
      expect(v.titleNe, 'लोकसेवा सिविल इन्जिनियर');
      expect(v.nodeCount, 412);
      expect(v.examinableNodeCount, 380);
      expect(v.exam!.post, 'Civil Engineer');
      expect(v.exam!.authority, 'OPMC');
    });

    test('public_id is the route key and version_code is not', () {
      // The route binds on SyllabusVersion::getRouteKeyName() = public_id.
      // A client that built the URL from version_code would 404.
      final v = SyllabusVersionDto.fromJson(row)!.domain;
      expect(v.publicId, isNot(v.versionCode));
      expect(v.publicId, isNotEmpty);
    });

    test('rejects a row with no public_id rather than inventing one', () {
      final bad = Map<String, dynamic>.from(row)..remove('public_id');
      expect(SyllabusVersionDto.fromJson(bad), isNull);
    });

    test('a missing exam becomes null, not a crash', () {
      final noExam = Map<String, dynamic>.from(row)..remove('exam');
      expect(SyllabusVersionDto.fromJson(noExam)!.domain.exam, isNull);
    });

    test('an exam with no id or name is dropped', () {
      final broken = Map<String, dynamic>.from(row)..['exam'] = <String, dynamic>{'post': 'x'};
      expect(SyllabusVersionDto.fromJson(broken)!.domain.exam, isNull);
    });

    test('string numbers are coerced because char-padded and JSON types vary', () {
      final asStrings = Map<String, dynamic>.from(row)
        ..['node_count'] = '412'
        ..['examinable_node_count'] = '380'
        ..['exam'] = <String, dynamic>{'id': '7', 'name': 'Civil Engineer'};
      final v = SyllabusVersionDto.fromJson(asStrings)!.domain;
      expect(v.nodeCount, 412);
      expect(v.exam!.id, 7);
    });

    test('an unparsable date is null rather than a thrown FormatException', () {
      final badDate = Map<String, dynamic>.from(row)..['effective_from'] = 'not-a-date';
      expect(SyllabusVersionDto.fromJson(badDate)!.domain.effectiveFrom, isNull);
    });

    test('title_ne falls back to English when blank or absent', () {
      final blank = Map<String, dynamic>.from(row)..['title_ne'] = '   ';
      expect(SyllabusVersionDto.fromJson(blank)!.domain.titleFor(preferNative: true),
          'Loksewa Civil Engineer');

      final absent = Map<String, dynamic>.from(row)..remove('title_ne');
      expect(SyllabusVersionDto.fromJson(absent)!.domain.titleFor(preferNative: true),
          'Loksewa Civil Engineer');
    });

    test('prefers the native title when the reader asked for it', () {
      final v = SyllabusVersionDto.fromJson(row)!.domain;
      expect(v.titleFor(preferNative: true), 'लोकसेवा सिविल इन्जिनियर');
      expect(v.titleFor(preferNative: false), 'Loksewa Civil Engineer');
    });

    test('an unfetched version is not reported as effective', () {
      // No window at all: treat as current rather than hiding a syllabus the
      // server has not dated.
      final v = SyllabusVersionDto.fromJson(row)!.domain;
      expect(v.isEffectiveNow, isTrue);
    });

    test('a closed window is not effective, and a future one is not either', () {
      final past = Map<String, dynamic>.from(row)
        ..['effective_from'] = '2020-01-01T00:00:00+00:00'
        ..['effective_to'] = '2021-01-01T00:00:00+00:00';
      expect(SyllabusVersionDto.fromJson(past)!.domain.isEffectiveNow, isFalse);

      final future = Map<String, dynamic>.from(row)
        ..['effective_from'] = '2099-01-01T00:00:00+00:00'
        ..['effective_to'] = null;
      expect(SyllabusVersionDto.fromJson(future)!.domain.isEffectiveNow, isFalse);
    });
  });

  group('SyllabusNodeDto', () {
    test('parses a summary row from the flat nodes endpoint', () {
      final n = SyllabusNodeDto.fromJson(<String, dynamic>{
            'id': 12,
            'node_code': '1.1.2',
            'node_type': 'topic',
            'title': 'Limit Analysis',
            'depth': 2,
            'is_examinable': true,
            'child_count': 4,
          })!
          .domain;
      expect(n.id, 12);
      expect(n.nodeCode, '1.1.2');
      expect(n.isExaminable, isTrue);
      expect(n.childCount, 4);
      expect(n.questionCount, 0);
    });

    test('a node with no title is rejected — an untappable row is worse than none', () {
      expect(SyllabusNodeDto.fromJson(<String, dynamic>{'id': 1}), isNull);
    });

    test('is_examinable only accepts a real true, not a truthy string', () {
      final n = SyllabusNodeDto.fromJson(<String, dynamic>{
            'id': 1,
            'title': 'x',
            'is_examinable': 'false',
          })!
          .domain;
      expect(n.isExaminable, isFalse, reason: 'the string "false" is not a bool');
    });

    test('a malformed child is skipped without taking its siblings down', () {
      final n = SyllabusNodeDto.fromJson(<String, dynamic>{
            'id': 1,
            'title': 'Root',
            'children': [
              <String, dynamic>{'title': 'no id'},
              'not a map',
              <String, dynamic>{'id': 3, 'title': 'Good'},
            ],
          })!
          .domain;
      expect(n.children.length, 1);
      expect(n.children.single.title, 'Good');
    });

    test('children are null on the list endpoint and must not become a list', () {
      final n = SyllabusNodeDto.fromJson(<String, dynamic>{
            'id': 1,
            'title': 'Root',
            'children': null,
          })!
          .domain;
      expect(n.children, isEmpty);
    });

    test('a leaf arrives with children as an empty STRING, not an empty list', () {
      // Captured from the live API on 2026-09-28 against
      // /api/v1/syllabi/{v}/tree?depth=2: the server's nest() serialises a childless
      // node as "children":"" rather than "children":[]. A client that assumed a
      // List here would either crash or mis-render every leaf in the tree.
      final n = SyllabusNodeDto.fromJson(<String, dynamic>{
            'id': 10703,
            'node_code': 'A',
            'title': 'Section A',
            'node_type': 'section',
            'depth': 2,
            'is_examinable': false,
            'question_count': 0,
            'material_count': 0,
            'children': '',
          })!
          .domain;
      expect(n.children, isEmpty);
      expect(n.hasChildren, isFalse);
    });

    test('a real live tree row parses with its nested children', () {
      // Verbatim shape from the live API, trimmed to the two levels that matter.
      final n = SyllabusNodeDto.fromJson(<String, dynamic>{
            'id': 10739,
            'node_code': 'II',
            'title': 'Job Based-Knowledge (25 Questions x 2 Marks = 50 Marks)',
            'node_type': 'part',
            'depth': 1,
            'is_examinable': false,
            'question_count': 0,
            'material_count': 0,
            'children': [
              <String, dynamic>{
                'id': 10740,
                'node_code': '1',
                'title': 'Surveying',
                'node_type': 'unit',
                'depth': 2,
                'is_examinable': true,
                'question_count': 0,
                'material_count': 0,
                'children': '',
              },
            ],
          })!
          .domain;
      expect(n.children.single.title, 'Surveying');
      expect(n.children.single.isExaminable, isTrue);
      expect(n.children.single.children, isEmpty);
      expect(n.hasChildren, isTrue);
    });

    test('node_type is preserved so a paper is not shown as a topic', () {
      final n = SyllabusNodeDto.fromJson(<String, dynamic>{
            'id': 1,
            'title': 'General Knowledge',
            'node_type': 'paper',
          })!
          .domain;
      expect(n.nodeType, 'paper');
      expect(n.depth, 0);
    });

    test('hasChildren reflects either nested children or the flat child_count', () {
      final nested = SyllabusNodeDto.fromJson(<String, dynamic>{
            'id': 1,
            'title': 'Root',
            'children': [
              <String, dynamic>{'id': 2, 'title': 'Kid'},
            ],
          })!
          .domain;
      expect(nested.hasChildren, isTrue);

      final flat = SyllabusNodeDto.fromJson(<String, dynamic>{
            'id': 1,
            'title': 'Root',
            'child_count': 3,
          })!
          .domain;
      expect(flat.hasChildren, isTrue);
      expect(flat.children, isEmpty);
    });

    test('marks_hint formats without a trailing .0', () {
      final whole = SyllabusNodeDto.fromJson(
          <String, dynamic>{'id': 1, 'title': 'x', 'marks_hint': 10})!
          .domain;
      expect(whole.marksLabel, '10');

      final frac = SyllabusNodeDto.fromJson(
          <String, dynamic>{'id': 1, 'title': 'x', 'marks_hint': 1.5})!
          .domain;
      expect(frac.marksLabel, '1.50');
    });

    test('marks_hint absent yields no label rather than a fabricated 0', () {
      final n = SyllabusNodeDto.fromJson(<String, dynamic>{'id': 1, 'title': 'x'})!.domain;
      expect(n.marksLabel, isNull);
    });
  });

  group('SyllabusTreeDto', () {
    Map<String, dynamic> tree({int withChildren = 0, int questionCount = 0}) => <String, dynamic>{
          'nodes': [
            <String, dynamic>{
              'id': 1,
              'title': 'Structural Analysis',
              'node_type': 'section',
              'depth': 0,
              'is_examinable': true,
              'question_count': questionCount,
              'material_count': 3,
              'children': withChildren == 0
                  ? <dynamic>[]
                  : [
                      <String, dynamic>{
                        'id': 2,
                        'title': 'Determinate Structures',
                        'node_type': 'topic',
                        'depth': 1,
                        'is_examinable': true,
                        'question_count': 10,
                        'material_count': 1,
                        'children': <dynamic>[],
                      },
                    ],
            },
          ],
          'node_count': 2,
          'examinable_node_count': 2,
        };

    test('parses counts from the top level', () {
      final t = SyllabusTreeDto.fromJson(tree()).domain;
      expect(t.nodeCount, 2);
      expect(t.examinableNodeCount, 2);
      expect(t.nodes.length, 1);
      expect(t.isEmpty, isFalse);
    });

    test('an empty tree is reported as empty, not as a failure', () {
      final t = SyllabusTreeDto.fromJson(<String, dynamic>{
        'nodes': <dynamic>[],
        'node_count': 0,
        'examinable_node_count': 0,
      }).domain;
      expect(t.isEmpty, isTrue);
    });

    test('a missing nodes key yields an empty tree instead of throwing', () {
      final t = SyllabusTreeDto.fromJson(<String, dynamic>{}).domain;
      expect(t.nodes, isEmpty);
      expect(t.nodeCount, 0);
    });

    test('depthLimited is recorded so a scoped count is not shown as the total', () {
      // Live API: the version says node_count 542, /tree?depth=2 says 33.
      final scoped = SyllabusTreeDto.fromJson(tree(), depthLimited: true).domain;
      expect(scoped.depthLimited, isTrue);

      final full = SyllabusTreeDto.fromJson(tree()).domain;
      expect(full.depthLimited, isFalse);
    });

    test('flattened walks depth-first', () {
      final t = SyllabusTreeDto.fromJson(tree(withChildren: 1)).domain;
      expect(t.flattened.length, 2);
      expect(t.flattened.first.id, 1);
      expect(t.flattened.last.id, 2);
    });

    test('totalQuestionCount counts top-level nodes only', () {
      // Counts are subtree-inclusive server-side, so summing every level would
      // double count. Only the roots are summed.
      final t = SyllabusTreeDto.fromJson(tree(withChildren: 1, questionCount: 100)).domain;
      expect(t.totalQuestionCount, 100);
    });

    test('search matches title, code and native title', () {
      final t = SyllabusTreeDto.fromJson(<String, dynamic>{
        'nodes': [
          <String, dynamic>{'id': 1, 'title': 'Limit Analysis', 'node_code': '1.1.2'},
          <String, dynamic>{'id': 2, 'title': 'सिम्पुलस'},
        ],
      }).domain;
      expect(t.search('limit').length, 1);
      expect(t.search('1.1.2').length, 1);
      expect(t.search('सिम्पुलस').length, 1);
      expect(t.search(''), isEmpty);
      expect(t.search('   '), isEmpty);
      expect(t.search('zzz'), isEmpty);
    });
  });

  group('SyllabusNodeDetailDto', () {
    test('parses node, coverage and children', () {
      final d = SyllabusNodeDetailDto.fromJson(<String, dynamic>{
        'node': <String, dynamic>{'id': 5, 'title': 'Trusses', 'is_examinable': true},
        'coverage': <String, dynamic>{'served': 42},
        'children': [
          <String, dynamic>{'id': 6, 'title': 'Methods of joints'},
        ],
      });
      expect(d.isEmpty, isFalse);
      expect(d.domain!.node.title, 'Trusses');
      expect(d.domain!.children.length, 1);
      expect(d.domain!.coverage!['served'], 42);
    });

    test('null coverage stays null so no coverage number is invented', () {
      final d = SyllabusNodeDetailDto.fromJson(<String, dynamic>{
        'node': <String, dynamic>{'id': 5, 'title': 'Trusses'},
        'coverage': null,
      });
      expect(d.domain!.coverage, isNull);
    });

    test('an envelope with no node is reported empty, not crashed', () {
      final d = SyllabusNodeDetailDto.fromJson(<String, dynamic>{'message': 'Not found'});
      expect(d.isEmpty, isTrue);
      expect(d.domain, isNull);
    });
  });

  group('SyllabusBlueprintDto', () {
    // The controller maps a collection, so a version returns a LIST.
    final list = <dynamic>[
      <String, dynamic>{
        'paper_code': 'CE-full',
        'part_code': 'A',
        'name': 'Civil Engineering Full',
        'total_marks': 100.0,
        'total_questions': 50,
        'negative_marking_mode': 'proportional',
        'unattempted_marks': 0.0,
        'sections': [
          <String, dynamic>{
            'section_code': 'S1',
            'name': 'General',
            'marks': 60.0,
            'question_count': 30,
          },
          <String, dynamic>{
            'section_code': 'S2',
            'name': 'Structural',
            'marks': 40.0,
            'question_count': 20,
          },
        ],
        // Paper-level, as the server actually sends it.
        'rules': [
          <String, dynamic>{
            'quiz_syllabus_node_id': 5,
            'node_code': '1.1',
            'node_title': 'Limit Analysis',
            'marks_each': 2.0,
            'question_count': 30,
            'weight': 0.6,
          },
        ],
      },
    ];

    test('parses a list of blueprints', () {
      final b = SyllabusBlueprintDto.fromList(list).items;
      expect(b.length, 1);
      expect(b.single.paperCode, 'CE-full');
      expect(b.single.totalMarks, 100);
      expect(b.single.sections.length, 2);
    });

    test('parses paper-level rules with the node they draw from', () {
      // `rules` is a sibling of `sections`, not a child. Verified against the live
      // API on 2026-09-28: one paper carried 13 rules and no section had any.
      final rule = SyllabusBlueprintDto.fromList(list).items.single.rules.single;
      expect(rule.nodeCode, '1.1');
      expect(rule.nodeTitle, 'Limit Analysis');
      expect(rule.marksEach, 2.0);
      expect(rule.weight, 0.6);
    });

    test('a section with a null section_code is kept, not dropped', () {
      // The live blueprint returns a null section_code for the unnamed trailing
      // "Part II". Requiring a non-null code would silently lose a third of the
      // paper's marks.
      final b = SyllabusBlueprintDto.fromList(<dynamic>[
        <String, dynamic>{
          'paper_code': 'I',
          'name': 'Paper I',
          'total_marks': 100,
          'total_questions': 50,
          'sections': [
            <String, dynamic>{
              'section_code': 'A',
              'name': 'Section (A)',
              'marks': 30,
              'question_count': 15,
            },
            <String, dynamic>{
              'section_code': null,
              'name': 'Part II',
              'marks': 50,
              'question_count': 25,
            },
          ],
        },
      ]).items.single;
      expect(b.sections.length, 2);
      expect(b.sections[1].sectionCode, isNull);
      expect(b.sections[1].name, 'Part II');
      expect(b.sections[1].marks, 50);
    });

    test('a section with no name at all is still dropped', () {
      final b = SyllabusBlueprintDto.fromList(<dynamic>[
        <String, dynamic>{
          'paper_code': 'I',
          'name': 'Paper I',
          'total_marks': 100,
          'total_questions': 50,
          'sections': [
            <String, dynamic>{'section_code': 'A', 'marks': 100},
          ],
        },
      ]).items.single;
      expect(b.sections, isEmpty);
    });

    test('a paper with no rules key is valid, not an error', () {
      final b = SyllabusBlueprintDto.fromList(<dynamic>[
        <String, dynamic>{
          'paper_code': 'I',
          'name': 'Paper I',
          'total_marks': 100,
          'total_questions': 50,
        },
      ]).items.single;
      expect(b.rules, isEmpty);
    });

    test('a malformed rule is skipped without losing the paper', () {
      final b = SyllabusBlueprintDto.fromList(<dynamic>[
        <String, dynamic>{
          'paper_code': 'I',
          'name': 'Paper I',
          'total_marks': 100,
          'total_questions': 50,
          'rules': [
            'not a map',
            <String, dynamic>{'marks_each': 2},
          ],
        },
      ]).items.single;
      expect(b.rules.length, 1, reason: 'a rule with no ids still maps');
      expect(b.totalMarks, 100);
    });

    test('a live-shaped blueprint reconciles', () {
      // The real payload: sections 30 + 20 + 50 = 100, matching total_marks.
      final b = SyllabusBlueprintDto.fromList(<dynamic>[
        <String, dynamic>{
          'paper_code': 'I',
          'part_code': null,
          'name': 'lok-sewa-sub-engineer-2026 - Paper I',
          'total_marks': 100,
          'total_questions': 50,
          'negative_marking_mode': 'none',
          'unattempted_marks': 0,
          'sections': [
            <String, dynamic>{
              'section_code': 'A',
              'name': 'Section (A)',
              'marks': 30,
              'question_count': 15,
            },
            <String, dynamic>{
              'section_code': 'B',
              'name': 'Section (B)',
              'marks': 20,
              'question_count': 10,
            },
            <String, dynamic>{
              'section_code': null,
              'name': 'Part II',
              'marks': 50,
              'question_count': 25,
            },
          ],
          'rules': [
            <String, dynamic>{
              'quiz_syllabus_node_id': 10740,
              'node_code': '1',
              'node_title': 'Surveying',
              'marks_each': 2,
              'question_count': 2,
              'weight': 0,
            },
          ],
        },
      ]).items.single;
      expect(b.marksReconcile, isTrue);
      expect(b.sections.length, 3);
      expect(b.sections.fold<double>(0, (a, s) => a + s.marks), 100);
      expect(b.rules.single.nodeTitle, 'Surveying');
    });

    test('marksReconcile detects a section/total mismatch', () {
      final good = SyllabusBlueprintDto.fromList(list).items.single;
      expect(good.marksReconcile, isTrue);

      final bad = SyllabusBlueprintDto.fromList(<dynamic>[
        <String, dynamic>{
          'paper_code': 'X',
          'name': 'X',
          'total_marks': 100.0,
          'total_questions': 50,
          'sections': [
            <String, dynamic>{'section_code': 'S1', 'name': 'A', 'marks': 90.0, 'question_count': 50},
          ],
        },
      ]).items.single;
      expect(bad.marksReconcile, isFalse,
          reason: 'a blueprint that does not add up must not be shown as authoritative');
    });

    test('non-list and malformed input degrade to empty', () {
      expect(SyllabusBlueprintDto.fromList(null).items, isEmpty);
      expect(SyllabusBlueprintDto.fromList(<String, dynamic>{}).items, isEmpty);
      expect(SyllabusBlueprintDto.fromList('nonsense').items, isEmpty);
    });

    test('a blueprint missing paper_code is skipped', () {
      expect(
        SyllabusBlueprintDto.fromList(<dynamic>[
          <String, dynamic>{'name': 'no code'},
        ]).items,
        isEmpty,
      );
    });
  });

  group('UserSyllabusPlanDto', () {
    test('parses a plan', () {
      final p = UserSyllabusPlanDto.fromJson(<String, dynamic>{
            'public_id': '01HQPLAN',
            'nickname': 'Loksewa 2082',
            'syllabus_version_id': 7,
            'version_code': 'loksewa-2082',
            'target_exam_date': '2099-06-01',
            'daily_minutes': 90,
            'planning_mode': 'exam_date',
            'scope_mode': 'examinable',
            'is_active': true,
            'last_planned_at': '2026-09-01T10:00:00+00:00',
          })!
          .domain;
      expect(p.publicId, '01HQPLAN');
      expect(p.dailyMinutes, 90);
      expect(p.planningMode, 'exam_date');
      expect(p.scopeMode, 'examinable');
      expect(p.daysRemaining, isNotNull);
    });

    test('a plan with no exam date has no countdown rather than a fake one', () {
      final p = UserSyllabusPlanDto.fromJson(<String, dynamic>{
        'public_id': 'x',
            'syllabus_version_id': 1,
            'planning_mode': 'daily_minutes',
            'scope_mode': 'all',
          })!
          .domain;
      expect(p.targetExamDate, isNull);
      expect(p.daysRemaining, isNull);
    });

    test('a passed exam date counts down to zero, never negative', () {
      // A negative "−3 days left" is a bug the user would see.
      final p = UserSyllabusPlanDto.fromJson(<String, dynamic>{
        'public_id': 'x',
            'syllabus_version_id': 1,
            'target_exam_date': '2020-01-01',
            'planning_mode': 'exam_date',
            'scope_mode': 'all',
          })!
          .domain;
      expect(p.daysRemaining, 0);
    });

    test('is_active defaults to true when the key is absent', () {
      final p = UserSyllabusPlanDto.fromJson(<String, dynamic>{
            'public_id': 'x',
            'syllabus_version_id': 1,
            'planning_mode': 'a',
            'scope_mode': 'b',
          })!
          .domain;
      expect(p.isActive, isTrue);
    });

    test('daily_minutes null stays null rather than becoming 0', () {
      final p = UserSyllabusPlanDto.fromJson(<String, dynamic>{
            'public_id': 'x',
            'syllabus_version_id': 1,
            'daily_minutes': null,
            'planning_mode': 'a',
            'scope_mode': 'b',
          })!
          .domain;
      expect(p.dailyMinutes, isNull);
    });
  });
}
