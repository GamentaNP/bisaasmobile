import 'package:dio/dio.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/envelope.dart';
import '../../../../core/network/pagination.dart';
import '../models/store_dto.dart';

/// Premium asset store — server routes (`routes/api/v1.php` store group):
/// - GET    /store/assets                → cursor-paginated catalogue
/// - GET    /store/assets/{slug}         → single asset + is_owned
/// - POST   /store/assets/{slug}/purchase→ buy with coins (Idempotency-Key)
/// - GET    /store/wardrobe              → slots with the equipped asset
/// - PUT    /store/wardrobe/equipment    → equip (Idempotency-Key)
/// - DELETE /store/wardrobe/equipment    → unequip (Idempotency-Key)
///
/// Dio baseUrl already ends with /api/v1.
///
/// **A failure is never an empty catalogue.** The previous version of this file
/// caught every error and returned `[]`, so a server error, a contract drift
/// and a genuinely empty catalogue all rendered as the same "0 assets" empty
/// state. Now a failure throws and the UI shows an error with a retry.
class StoreRemoteDataSource {
  const StoreRemoteDataSource(this._dio);
  final Dio _dio;

  /// The server's canonical wardrobe slots, in its own order.
  ///
  /// `StoreController::WARDROBE_SLOTS` = avatar_frame, avatar, quiz_theme,
  /// sound_pack, mascot. The client previously invented a `frame` slot that
  /// the server rejects, so equipping from the UI was a guaranteed 422.
  static const wardrobeSlots = <String>[
    'avatar_frame',
    'avatar',
    'quiz_theme',
    'sound_pack',
    'mascot',
  ];

  Future<List<StoreAssetDto>> getAssets() async {
    final res = await _dio.get<Map<String, dynamic>>('/store/assets');
    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty store catalogue response',
        endpoint: '/store/assets',
      );
    }
    final page = parsePage<StoreAssetDto>(
      body,
      StoreAssetDto.fromJson,
      endpoint: '/store/assets',
    );
    return page.items;
  }

  Future<StoreAssetDto?> getAsset(String slug) async {
    final res = await _dio.get<Map<String, dynamic>>('/store/assets/$slug');
    final body = res.data;
    if (body == null) {
      throw ContractViolation(
        'Empty asset response',
        endpoint: '/store/assets/$slug',
      );
    }
    final data = requireDataMap(body, endpoint: '/store/assets/$slug');
    // The asset may be the payload itself or nested one level.
    if (data.containsKey('id') || data.containsKey('slug')) {
      return StoreAssetDto.fromJson(data);
    }
    final inner = data['asset'] ?? data['data'];
    if (inner is Map<String, dynamic>) return StoreAssetDto.fromJson(inner);
    throw ContractViolation(
      'Asset payload not found in the response',
      endpoint: '/store/assets/$slug',
    );
  }

  Future<StorePurchaseResultDto> purchaseAsset(
    String slug, {
    String? idempotencyKey,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/store/assets/$slug/purchase',
      data: {},
      options: Options(headers: idempotencyHeader(idempotencyKey)),
    );
    final body = res.data;
    if (body == null) {
      throw ContractViolation(
        'Empty purchase response',
        endpoint: '/store/assets/$slug/purchase',
      );
    }
    final data = requireDataMap(
      body,
      endpoint: '/store/assets/$slug/purchase',
    );
    if (data.containsKey('success') ||
        data.containsKey('purchased') ||
        data.containsKey('coins_spent')) {
      return StorePurchaseResultDto.fromJson(data);
    }
    // Envelope-wrapped: the envelope itself carries the verdict.
    return StorePurchaseResultDto(
      success: body['success'] as bool? ?? false,
      message: body['message'] as String?,
      assetId: slug,
    );
  }

  Future<WardrobeDto> getWardrobe() async {
    final res = await _dio.get<Map<String, dynamic>>('/store/wardrobe');
    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty wardrobe response',
        endpoint: '/store/wardrobe',
      );
    }
    final data = requireDataMap(body, endpoint: '/store/wardrobe');
    return WardrobeDto.fromJson(data);
  }

  /// `DELETE /api/v1/store/wardrobe/equipment` with `{slot}`.
  ///
  /// The server exposes this (`routes/api/v1.php` store group) so a slot can
  /// actually be emptied. The wardrobe UI previously had a visible "clear"
  /// affordance wired to `() {}`, so nothing happened.
  Future<bool> unequip(String slot, {String? idempotencyKey}) async {
    final res = await _dio.delete<Map<String, dynamic>>(
      '/store/wardrobe/equipment',
      data: {'slot': slot},
      options: Options(headers: idempotencyHeader(idempotencyKey)),
    );
    final body = res.data;
    if (body == null) return false;
    if (body['success'] as bool? ?? false) return true;
    final data = _extractMapData(body);
    if (data != null && (data['unequipped'] == true || data['success'] == true)) {
      return true;
    }
    return false;
  }

  Future<bool> equip(String slot, String assetId, {String? idempotencyKey}) async {
    final res = await _dio.put<Map<String, dynamic>>(
      // Canonical resource form is PUT /wardrobe/equipment; POST /wardrobe/equip
      // is the additive alias (routes/api/v1.php).
      '/store/wardrobe/equipment',
      data: {'slot': slot, 'asset_id': int.tryParse(assetId) ?? assetId},
      options: Options(headers: idempotencyHeader(idempotencyKey)),
    );
    final body = res.data;
    if (body == null) return false;
    final success = body['success'] as bool? ?? false;
    if (success) return true;
    final data = _extractMapData(body);
    if (data != null && (data['equipped'] == true || data['success'] == true)) {
      return true;
    }
    return false;
  }

  Map<String, dynamic>? _extractMapData(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    return null;
  }
}
