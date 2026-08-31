// ignore_for_file: avoid_dynamic_calls
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_response.dart';
import '../models/store_dto.dart';

/// Server routes — all WO-3 (not shipped): GET /store/assets, GET /store/assets/{s}, POST /store/assets/{s}/purchase, GET /store/wardrobe, POST /store/wardrobe/equip
/// Per law 11 additive parsing: never crash on new field, always degrade gracefully (beta placeholder, isDegraded flag).
/// Dio baseUrl already ends with /api/v1.
class StoreRemoteDataSource {
  const StoreRemoteDataSource(this._dio);
  final Dio _dio;
  static const _uuid = Uuid();

  Future<List<StoreAssetDto>> getAssets() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/store/assets');
      final body = res.data;
      if (body == null) return [];
      final data = body['data'];
      if (data is List) return data.whereType<Map<String, dynamic>>().map(StoreAssetDto.fromJson).toList();
      if (data is Map<String, dynamic>) {
        final items = data['assets'] ?? data['items'] ?? data['data'];
        if (items is List) return items.whereType<Map<String, dynamic>>().map(StoreAssetDto.fromJson).toList();
      }
      final envData = _extractMapData(body);
      if (envData != null) {
        final items = envData['assets'] ?? envData['items'];
        if (items is List) return items.whereType<Map<String, dynamic>>().map(StoreAssetDto.fromJson).toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        AppLogger.w('store getAssets: 404 — WO-3 not shipped, degraded placeholder');
        return [];
      }
      AppLogger.w('store getAssets failed: ${e.response?.statusCode} ${e.message}');
      return [];
    } catch (e) {
      AppLogger.w('store getAssets unexpected: $e');
      return [];
    }
  }

  Future<StoreAssetDto?> getAsset(String slug) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/store/assets/$slug');
      final body = res.data;
      if (body == null) return null;
      final data = _extractMapData(body) ?? (body['data'] is Map<String, dynamic> ? body['data'] as Map<String, dynamic> : null);
      if (data == null) return null;
      // If data is the asset itself or wrapped
      if (data.containsKey('id') || data.containsKey('slug')) return StoreAssetDto.fromJson(data);
      final inner = data['asset'] ?? data['data'];
      if (inner is Map<String, dynamic>) return StoreAssetDto.fromJson(inner);
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        AppLogger.w('store getAsset $slug: 404 degraded');
        return null;
      }
      AppLogger.w('store getAsset $slug failed: ${e.response?.statusCode} ${e.message}');
      return null;
    } catch (e) {
      AppLogger.w('store getAsset $slug unexpected: $e');
      return null;
    }
  }

  Future<StorePurchaseResultDto> purchaseAsset(String slug, {String? idempotencyKey}) async {
    final key = idempotencyKey ?? _uuid.v4();
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/store/assets/$slug/purchase',
        data: {},
        options: Options(headers: {'Idempotency-Key': key}),
      );
      final body = res.data;
      if (body == null) return const StorePurchaseResultDto(success: false, message: 'Empty response');
      final data = _extractMapData(body);
      if (data != null) {
        if (data.containsKey('success') || data.containsKey('purchased') || data.containsKey('coins_spent')) {
          return StorePurchaseResultDto.fromJson(data);
        }
        // envelope wrapped
        final success = body['success'] as bool? ?? false;
        return StorePurchaseResultDto(success: success, message: body['message'] as String?, assetId: slug);
      }
      return StorePurchaseResultDto(success: body['success'] as bool? ?? false, message: body['message'] as String?, assetId: slug);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        AppLogger.w('store purchaseAsset $slug: 404 — WO-3 not shipped, graceful degrade');
        return const StorePurchaseResultDto(success: false, message: 'Store not available yet (beta)', isDegraded: true);
      }
      final msg = _dioErrorMessage(e);
      AppLogger.w('store purchaseAsset $slug failed: ${e.response?.statusCode} $msg');
      return StorePurchaseResultDto(success: false, message: msg);
    } catch (e) {
      AppLogger.w('store purchaseAsset $slug unexpected: $e');
      return StorePurchaseResultDto(success: false, message: e.toString());
    }
  }

  Future<WardrobeDto> getWardrobe() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/store/wardrobe');
      final body = res.data;
      if (body == null) return WardrobeDto(slots: [], isDegraded: true);
      final data = _extractMapData(body);
      if (data != null) {
        // WardrobeDto handles both list and map shapes additively
        return WardrobeDto.fromJson(data);
      }
      // data might be list directly
      final raw = body['data'];
      if (raw is List) {
        return WardrobeDto(slots: raw.whereType<Map<String, dynamic>>().map(WardrobeSlotDto.fromJson).toList());
      }
      return WardrobeDto(slots: [], isDegraded: true);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        AppLogger.w('store getWardrobe: 404 — WO-3 not shipped, degraded placeholder');
        return WardrobeDto.localMockDegraded();
      }
      AppLogger.w('store getWardrobe failed: ${e.response?.statusCode} ${e.message}');
      return WardrobeDto(slots: [], isDegraded: true);
    } catch (e) {
      AppLogger.w('store getWardrobe unexpected: $e');
      return WardrobeDto(slots: [], isDegraded: true);
    }
  }

  Future<bool> equip(String slot, String assetId, {String? idempotencyKey}) async {
    final key = idempotencyKey ?? _uuid.v4();
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/store/wardrobe/equip',
        data: {'slot': slot, 'asset_id': int.tryParse(assetId) ?? assetId},
        options: Options(headers: {'Idempotency-Key': key}),
      );
      final body = res.data;
      if (body == null) return false;
      final success = body['success'] as bool? ?? false;
      // Some APIs return 200 with success true even without envelope
      if (success) return true;
      final data = _extractMapData(body);
      if (data != null && (data['equipped'] == true || data['success'] == true)) return true;
      return success;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        AppLogger.w('store equip $slot/$assetId: 404 degraded');
        return false;
      }
      AppLogger.w('store equip failed: ${e.response?.statusCode} ${e.message}');
      return false;
    } catch (e) {
      AppLogger.w('store equip unexpected: $e');
      return false;
    }
  }

  Future<List<MarketListingDto>> getMarket() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/store/market');
      final body = res.data;
      if (body == null) return [];
      final data = body['data'];
      if (data is List) return data.whereType<Map<String, dynamic>>().map(MarketListingDto.fromJson).toList();
      if (data is Map<String, dynamic>) {
        final items = data['market'] ?? data['listings'] ?? data['items'];
        if (items is List) return items.whereType<Map<String, dynamic>>().map(MarketListingDto.fromJson).toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        AppLogger.w('store getMarket: 404 — not shipped, empty');
        return [];
      }
      AppLogger.w('store getMarket failed: ${e.response?.statusCode} ${e.message}');
      return [];
    } catch (e) {
      AppLogger.w('store getMarket unexpected: $e');
      return [];
    }
  }

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
    final d = e.response?.data;
    if (d is Map<String, dynamic>) {
      final m = d['message'] as String?;
      if (m != null && m.isNotEmpty) return m;
      final err = d['error'] is Map ? (d['error'] as Map)['message'] as String? : null;
      if (err != null && err.isNotEmpty) return err;
    }
    return e.message ?? 'Request failed';
  }
}
