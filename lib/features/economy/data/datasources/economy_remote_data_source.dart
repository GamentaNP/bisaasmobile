// ignore_for_file: avoid_dynamic_calls, cast_nullable_to_non_nullable, use_null_aware_elements, unnecessary_cast
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_response.dart';
import '../models/economy_dto.dart';

/// Server-verified routes (php artisan route:list --path=api/v1 in C:\laragon\www\bisaas):
/// - GET /economy/resources/inventory (live)
/// - GET /donations/leaderboard, GET /donations/feed, POST /donations/freeze-streak (live)
/// - GET /economy/wallet, GET /economy/wallet/ledger, GET /economy/shop, POST /economy/shop/purchase (WO-1/WO-2 — no API yet)
///
/// Dio baseUrl already ends with /api/v1 — never add prefix.
/// All POSTs that spend coins carry Idempotency-Key even when endpoint returns 404
/// — caller retries must reuse the same key (RetryInterceptor guards non-idempotent POSTs).
class EconomyRemoteDataSource {
  const EconomyRemoteDataSource(this._dio);
  final Dio _dio;
  static const _uuid = Uuid();

  // ── Verified live: resource inventory ───────────────────────────────────────

  Future<EconomyInventoryBundleDto> getInventory({int activityLimit = 10}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/economy/resources/inventory',
      queryParameters: {'activity_limit': activityLimit},
    );
    final body = res.data;
    if (body == null) return const EconomyInventoryBundleDto(inventory: [], catalog: [], recentActivity: []);
    // Envelope: {success, data: {inventory, catalog, recent_activity}, message, ...}
    Map<String, dynamic>? data;
    if (body['data'] is Map<String, dynamic>) {
      data = body['data'] as Map<String, dynamic>;
    } else {
      // Tolerant fallback via ApiResponse
      try {
        final env = ApiResponse.fromJson(
          body,
          (json) => json as Map<String, dynamic>?,
        );
        data = env.data;
      } catch (_) {
        data = null;
      }
    }
    if (data == null) return const EconomyInventoryBundleDto(inventory: [], catalog: [], recentActivity: []);
    return EconomyInventoryBundleDto.fromJson(data);
  }

  // ── Verified live: donations ────────────────────────────────────────────────

  Future<List<DonorLeaderboardEntryDto>> getDonationLeaderboard() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/donations/leaderboard');
      final body = res.data;
      if (body == null) return [];
      final data = _extractMapData(body);
      if (data == null) return [];
      final raw = data['topDonors'] ?? data['top_donors'] ?? data['leaderboard'] ?? data['data'];
      if (raw is List) {
        return raw.whereType<Map<String, dynamic>>().map(DonorLeaderboardEntryDto.fromJson).toList();
      }
      // Sometimes envelope data is directly list
      final direct = body['data'];
      if (direct is List) {
        return direct.whereType<Map<String, dynamic>>().map(DonorLeaderboardEntryDto.fromJson).toList();
      }
      return [];
    } on DioException catch (e) {
      AppLogger.w('economy getDonationLeaderboard failed: ${e.response?.statusCode} ${e.message}');
      return [];
    } catch (e) {
      AppLogger.w('economy getDonationLeaderboard unexpected: $e');
      return [];
    }
  }

  Future<List<DonationFeedEntryDto>> getDonationFeed() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/donations/feed');
      final body = res.data;
      if (body == null) return [];
      final data = _extractMapData(body);
      if (data == null) return [];
      final raw = data['feed'] ?? data['data'] ?? data['items'];
      if (raw is List) {
        return raw.whereType<Map<String, dynamic>>().map(DonationFeedEntryDto.fromJson).toList();
      }
      final direct = body['data'];
      if (direct is List) {
        return direct.whereType<Map<String, dynamic>>().map(DonationFeedEntryDto.fromJson).toList();
      }
      return [];
    } on DioException catch (e) {
      AppLogger.w('economy getDonationFeed failed: ${e.response?.statusCode} ${e.message}');
      return [];
    } catch (e) {
      AppLogger.w('economy getDonationFeed unexpected: $e');
      return [];
    }
  }

  Future<FreezeStreakResultDto> freezeStreak({String? idempotencyKey}) async {
    final key = idempotencyKey ?? _uuid.v4();
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/donations/freeze-streak',
        data: {},
        options: Options(headers: {'Idempotency-Key': key}),
      );
      final body = res.data;
      if (body == null) return const FreezeStreakResultDto(frozen: false, message: 'Empty response');
      final data = _extractMapData(body) ?? body['data'] as Map<String, dynamic>?;
      if (data != null && data.containsKey('frozen')) {
        return FreezeStreakResultDto.fromJson(data);
      }
      // Success path: envelope itself indicates frozen
      final success = body['success'] as bool? ?? true;
      if (success) {
        final inner = (body['data'] is Map<String, dynamic>) ? body['data'] as Map<String, dynamic> : <String, dynamic>{};
        if (inner.containsKey('frozen')) return FreezeStreakResultDto.fromJson(inner);
        // If server returns {success:true, message:...} without frozen, treat as success
        return FreezeStreakResultDto(frozen: true, message: body['message'] as String?);
      }
      return FreezeStreakResultDto(frozen: false, message: body['message'] as String?);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final msg = _dioErrorMessage(e);
      AppLogger.w('economy freezeStreak failed: $status $msg');
      // 402/422 = insufficient coins or no streak — not degraded, just business rule
      // 404 = route missing? treat as degraded
      if (status == 404) {
        return FreezeStreakResultDto(frozen: false, message: msg, isDegraded: true);
      }
      return FreezeStreakResultDto(frozen: false, message: msg);
    } catch (e) {
      AppLogger.w('economy freezeStreak unexpected: $e');
      return FreezeStreakResultDto(frozen: false, message: e.toString());
    }
  }

  // ── Missing APIs (WO-1/WO-2) — tolerant degraded fallback ───────────────────

  Future<WalletDto?> getWallet() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/economy/wallet');
      final body = res.data;
      if (body == null) return null;
      final data = _extractMapData(body);
      if (data == null) return null;
      return WalletDto.fromJson(data);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404) {
        AppLogger.w('economy getWallet: 404 — WO-1 not shipped, degraded placeholder');
        return null;
      }
      AppLogger.w('economy getWallet failed: $status ${e.message}');
      return null;
    } catch (e) {
      AppLogger.w('economy getWallet unexpected: $e');
      return null;
    }
  }

  Future<List<LedgerEntryDto>> getLedger({int page = 1, int perPage = 20}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/economy/wallet/ledger',
        queryParameters: {'page': page, 'per_page': perPage},
      );
      final body = res.data;
      if (body == null) return [];
      // Try cursor/offset envelope: data.items or data directly list
      final data = body['data'];
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().map(LedgerEntryDto.fromJson).toList();
      }
      if (data is Map<String, dynamic> && data['items'] is List) {
        return (data['items'] as List).whereType<Map<String, dynamic>>().map((e) => LedgerEntryDto.fromJson(e as Map<String, dynamic>)).toList();
      }
      final mapData = _extractMapData(body);
      if (mapData != null) {
        final items = mapData['items'] ?? mapData['ledger'] ?? mapData['entries'];
        if (items is List) {
          return items.whereType<Map<String, dynamic>>().map(LedgerEntryDto.fromJson).toList();
        }
        if (mapData.containsKey('amount') || mapData.containsKey('description')) {
          return [LedgerEntryDto.fromJson(mapData)];
        }
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        AppLogger.w('economy getLedger: 404 — WO-1 not shipped, empty ledger');
        return [];
      }
      AppLogger.w('economy getLedger failed: ${e.response?.statusCode} ${e.message}');
      return [];
    } catch (e) {
      AppLogger.w('economy getLedger unexpected: $e');
      return [];
    }
  }

  Future<List<CoinPackDto>> getShopPacks() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/economy/shop');
      final body = res.data;
      if (body == null) return [];
      final data = body['data'];
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().map(CoinPackDto.fromJson).toList();
      }
      if (data is Map<String, dynamic>) {
        final packs = data['packs'] ?? data['shop'] ?? data['items'];
        if (packs is List) return packs.whereType<Map<String, dynamic>>().map(CoinPackDto.fromJson).toList();
      }
      final mapData = _extractMapData(body);
      if (mapData != null) {
        final packs = mapData['packs'] ?? mapData['items'];
        if (packs is List) return packs.whereType<Map<String, dynamic>>().map(CoinPackDto.fromJson).toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        AppLogger.w('economy getShopPacks: 404 — WO-2 not shipped, empty packs');
        return [];
      }
      AppLogger.w('economy getShopPacks failed: ${e.response?.statusCode} ${e.message}');
      return [];
    } catch (e) {
      AppLogger.w('economy getShopPacks unexpected: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> purchasePack(String packId, {String? idempotencyKey}) async {
    final key = idempotencyKey ?? _uuid.v4();
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/economy/shop/purchase',
        data: {'pack_id': packId, 'packId': packId},
        options: Options(headers: {'Idempotency-Key': key}),
      );
      final body = res.data;
      if (body == null) return {'success': false, 'is_degraded': false};
      return body;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        AppLogger.w('economy purchasePack $packId: 404 — WO-2 not shipped, graceful degrade');
        return {'success': false, 'is_degraded': true, 'message': 'Shop not available yet (beta)'};
      }
      final msg = _dioErrorMessage(e);
      AppLogger.w('economy purchasePack $packId failed: ${e.response?.statusCode} $msg');
      return {'success': false, 'message': msg, 'is_degraded': false};
    } catch (e) {
      AppLogger.w('economy purchasePack $packId unexpected: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── helpers ─────────────────────────────────────────────────────────────────

  Map<String, dynamic>? _extractMapData(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    try {
      final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
      return env.data;
    } catch (_) {
      return null;
    }
  }

  String _dioErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final msg = data['message'] as String?;
      if (msg != null && msg.isNotEmpty) return msg;
      final err = data['error'] is Map ? (data['error'] as Map)['message'] as String? : null;
      if (err != null && err.isNotEmpty) return err;
    }
    return e.message ?? 'Request failed';
  }
}
