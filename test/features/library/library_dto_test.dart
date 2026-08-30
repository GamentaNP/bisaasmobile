import 'package:bisaasmobile/features/library/data/models/library_dto.dart';
import 'package:bisaasmobile/features/library/domain/entities/library.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LibraryCategoryDto', () {
    test('fromJson tolerant — minimal', () {
      final dto = LibraryCategoryDto.fromJson({'id': 1, 'name': 'Civil', 'slug': 'civil'});
      expect(dto.id, 1);
      expect(dto.name, 'Civil');
      expect(dto.slug, 'civil');
      expect(dto.children, isEmpty);
      expect(dto.fileCount, isNull);
      expect(dto.toDomain(), isA<LibraryCategory>());
    });

    test('fromJson with children and file_count tolerant', () {
      final dto = LibraryCategoryDto.fromJson({
        'id': 10,
        'name': 'Structural',
        'slug': 'structural',
        'description': 'Beams',
        'icon': 'beam',
        'file_count': 12,
        'children': [
          {'id': 11, 'name': 'RCC', 'slug': 'rcc', 'file_count': 5},
          {'id': 12, 'name': 'Steel', 'slug': 'steel'},
        ],
        'extra_unknown_field': 'ignored',
      });
      expect(dto.fileCount, 12);
      expect(dto.children.length, 2);
      expect(dto.children.first.name, 'RCC');
      expect(dto.children.first.fileCount, 5);
      expect(dto.children.last.fileCount, isNull);
      expect(dto.toDomain().children.length, 2);
    });

    test('fromJson additive — unknown fields do not throw', () {
      final dto = LibraryCategoryDto.fromJson({
        'id': 99,
        'name': 'X',
        'slug': 'x',
        'new_server_field': {'nested': true},
        'another': 123,
      });
      expect(dto.id, 99);
    });

    test('handles string id gracefully', () {
      final dto = LibraryCategoryDto.fromJson({'id': '5', 'name': 'N', 'slug': 'n'});
      expect(dto.id, 5);
    });
  });

  group('LibraryFileDto', () {
    test('fromJson snake_case tolerant minimal', () {
      final dto = LibraryFileDto.fromJson({
        'id': 42,
        'title': 'Beam Design Notes',
        'slug': 'beam-design-notes',
        'file_type': 'pdf',
        'visibility': 'public',
        'coin_price': 10,
        'average_rating': 4.5,
        'review_count': 23,
        'download_count': 100,
        'is_featured': true,
        'tags': ['rcc', 'beam'],
        'created_at': '2026-08-20T10:00:00Z',
        'category': {'id': 1, 'name': 'Civil', 'slug': 'civil'},
        'uploader': {'id': 2, 'name': 'Admin'},
      });
      expect(dto.title, 'Beam Design Notes');
      expect(dto.fileType, 'pdf');
      expect(dto.coinPrice, 10);
      expect(dto.averageRating, 4.5);
      expect(dto.isFeatured, true);
      expect(dto.tags, ['rcc', 'beam']);
      expect(dto.createdAt, isNotNull);
      expect(dto.category?.name, 'Civil');
      expect(dto.uploader?.name, 'Admin');
      expect(dto.toDomain(), isA<LibraryFile>());
      expect(dto.toDomain().isFree, isFalse);
    });

    test('fromJson handles coin_price as string and missing tags', () {
      final dto = LibraryFileDto.fromJson({
        'id': 1,
        'title': 'Free File',
        'slug': 'free-file',
        'file_type': 'pdf',
        'coin_price': '0',
        'average_rating': '3.7',
      });
      expect(dto.coinPrice, 0);
      expect(dto.averageRating, 3.7);
      expect(dto.tags, isEmpty);
      expect(dto.toDomain().isFree, isTrue);
      expect(dto.visibility, 'public'); // default
    });

    test('additive tolerant — ignores unknown server fields', () {
      final dto = LibraryFileDto.fromJson({
        'id': 7,
        'title': 'T',
        'slug': 't',
        'file_type': 'zip',
        'coin_price': 5,
        'metadata': {'pages': 12},
        'license': 'CC',
        'view_count': 999,
        'extra': 'ignored',
      });
      expect(dto.id, 7);
      expect(dto.fileType, 'zip');
    });

    test('handles is_unlocked future field additive', () {
      final dto = LibraryFileDto.fromJson({
        'id': 1,
        'title': 'x',
        'slug': 'x',
        'file_type': 'pdf',
        'is_unlocked': true,
      });
      expect(dto.isUnlocked, true);
      final dto2 = LibraryFileDto.fromJson({'id': 1, 'title': 'x', 'slug': 'x', 'file_type': 'pdf', 'is_unlocked': 0});
      expect(dto2.isUnlocked, false);
    });

    test('fallback for missing required defaults', () {
      final dto = LibraryFileDto.fromJson({});
      expect(dto.title, '');
      expect(dto.slug, '');
      expect(dto.fileType, 'unknown');
      expect(dto.coinPrice, 0);
      expect(dto.reviewCount, 0);
      expect(dto.isFeatured, false);
    });
  });

  group('LibraryReviewDto', () {
    test('fromJson minimal', () {
      final dto = LibraryReviewDto.fromJson({'id': 5, 'rating': 4, 'comment': 'Great!', 'is_verified_download': true, 'user': {'id': 1, 'name': 'Ram'}, 'created_at': '2026-08-21T00:00:00Z'});
      expect(dto.rating, 4);
      expect(dto.comment, 'Great!');
      expect(dto.isVerifiedDownload, true);
      expect(dto.user?.name, 'Ram');
      expect(dto.toDomain(), isA<LibraryReview>());
    });

    test('fromJson tolerant without user/comment', () {
      final dto = LibraryReviewDto.fromJson({'id': 6, 'rating': 5});
      expect(dto.rating, 5);
      expect(dto.comment, isNull);
      expect(dto.user, isNull);
      expect(dto.isVerifiedDownload, isFalse);
    });

    test('additive ignores new fields', () {
      final dto = LibraryReviewDto.fromJson({'id': 1, 'rating': 3, 'new_field': 'x', 'another': 123});
      expect(dto.rating, 3);
    });
  });

  group('LibraryUnlockDto & UnlockItemDto', () {
    test('unlock fromJson', () {
      final dto = LibraryUnlockDto.fromJson({'unlocked': true, 'coins_spent': 10, 'unlocked_at': '2026-08-30T00:00:00Z'});
      expect(dto.coinsSpent, 10);
      expect(dto.unlocked, true);
      expect(dto.toDomain().coinsSpent, 10);
    });

    test('unlockItem fromJson nested file', () {
      final dto = LibraryUnlockItemDto.fromJson({
        'file': {'id': 1, 'title': 'F', 'slug': 'f', 'file_type': 'pdf'},
        'coins_spent': 5,
        'unlocked_at': '2026-08-30T00:00:00Z',
      });
      expect(dto.file.title, 'F');
      expect(dto.coinsSpent, 5);
      expect(dto.toDomain().file.title, 'F');
    });
  });
}
