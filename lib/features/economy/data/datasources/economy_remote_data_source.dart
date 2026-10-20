import 'package:dio/dio.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/envelope.dart';
import '../../../../core/network/pagination.dart';
import '../../domain/entities/economy.dart';
import '../models/economy_dto.dart';

/// Server-verified routes (`php artisan route:list --path=api/v1` in C:\laragon\www\bisaas):
/// - GET  /economy/resources/inventory
/// - GET  /economy/wallet
/// - GET  /economy/wallet/ledger        (cursor-paginated)
/// - GET  /economy/wallet/categories    (own coin spending by source category)
/// - GET  /economy/shop                 (resources + bundles, priced in coins)
/// - POST /economy/shop/purchase        ({type, key, quantity}, Idempotency-Key)
/// - GET  /donations/leaderboard, GET /donations/feed, POST /donations/freeze-streak
///
/// Dio baseUrl already ends with /api/v1 — never add prefix.
/// All POSTs that spend coins carry Idempotency-Key even when the endpoint
/// answers 404 — caller retries must reuse the same key (RetryInterceptor
/// guards non-idempotent POSTs).
///
/// **A failure is never an empty list.** Every method here throws on a
/// transport error, a non-2xx status or a body that does not match the
/// contract, so the UI can distinguish "you have nothing" from "the shop is
/// down". The previous version of this file caught everything and returned
/// `[]`, which made a server error indistinguishable from an empty account
/// and hid a real catalogue behind a "No packs yet" empty state.
class EconomyRemoteDataSource {
  const EconomyRemoteDataSource(this._dio);
  final Dio _dio;

  // ── Verified live: resource inventory ───────────────────────────────────────

  Future<EconomyInventoryBundleDto> getInventory({int activityLimit = 10}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/economy/resources/inventory',
      queryParameters: {'activity_limit': activityLimit},
    );
    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty inventory response',
        endpoint: '/economy/resources/inventory',
      );
    }
    // Envelope: {success, data: {inventory, catalog, recent_activity}, message, ...}
    final data = requireDataMap(
      body,
      endpoint: '/economy/resources/inventory',
    );
    return EconomyInventoryBundleDto.fromJson(data);
  }

  // ── Verified live: donations ────────────────────────────────────────────────

  Future<List<DonorLeaderboardEntryDto>> getDonationLeaderboard() async {
    final res = await _dio.get<Map<String, dynamic>>('/donations/leaderboard');
    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty donation leaderboard response',
        endpoint: '/donations/leaderboard',
      );
    }
    final data = requireDataMap(body, endpoint: '/donations/leaderboard');
    final raw = data['topDonors'] ?? data['top_donors'] ?? data['leaderboard'] ?? data['data'];
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().map(DonorLeaderboardEntryDto.fromJson).toList();
    }
    // Sometimes the envelope data is directly a list.
    final direct = body['data'];
    if (direct is List) {
      return direct.whereType<Map<String, dynamic>>().map(DonorLeaderboardEntryDto.fromJson).toList();
    }
    return const [];
  }

  Future<List<DonationFeedEntryDto>> getDonationFeed() async {
    final res = await _dio.get<Map<String, dynamic>>('/donations/feed');
    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty donation feed response',
        endpoint: '/donations/feed',
      );
    }
    final data = requireDataMap(body, endpoint: '/donations/feed');
    final raw = data['feed'] ?? data['data'] ?? data['items'];
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().map(DonationFeedEntryDto.fromJson).toList();
    }
    final direct = body['data'];
    if (direct is List) {
      return direct.whereType<Map<String, dynamic>>().map(DonationFeedEntryDto.fromJson).toList();
    }
    return const [];
  }

  /// Freezes the streak with coins.
  ///
  /// A 402/422 is a business rule ("not enough coins", "no streak"), not a
  /// failure of the app — the message from the server is shown as-is.
  Future<FreezeStreakResultDto> freezeStreak({String? idempotencyKey}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/donations/freeze-streak',
      data: {},
      options: Options(headers: idempotencyHeader(idempotencyKey)),
    );
    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty freeze-streak response',
        endpoint: '/donations/freeze-streak',
      );
    }
    final data = body['data'];
    if (data is Map<String, dynamic> && data.containsKey('frozen')) {
      return FreezeStreakResultDto.fromJson(data);
    }
    // Success path: the envelope itself indicates the freeze.
    final success = body['success'] as bool? ?? true;
    if (success) {
      return FreezeStreakResultDto(frozen: true, message: body['message'] as String?);
    }
    return FreezeStreakResultDto(frozen: false, message: body['message'] as String?);
  }

  // ── Wallet / ledger / shop ─────────────────────────────────────────────────

  Future<WalletDto> getWallet() async {
    final res = await _dio.get<Map<String, dynamic>>('/economy/wallet');
    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty wallet response',
        endpoint: '/economy/wallet',
      );
    }
    final data = requireDataMap(body, endpoint: '/economy/wallet');
    return WalletDto.fromJson(data);
  }

  /// The coin ledger.
  ///
  /// `GET /economy/wallet/ledger` is cursor-paginated: the `cursor` parameter
  /// is the id of the last-seen entry and the canonical pagination block is
  /// published at the top level of the envelope
  /// (`ApiResponse::rawCursorList`). Sending `?page=2` would return page one
  /// forever, so this never sends `page`.
  Future<LedgerPageDto> getLedger({
    String? cursor,
    int perPage = 20,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/economy/wallet/ledger',
      queryParameters: cursorQuery(cursor: cursor, perPage: perPage),
    );
    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty ledger response',
        endpoint: '/economy/wallet/ledger',
      );
    }
    final page = parsePage<LedgerEntryDto>(
      body,
      LedgerEntryDto.fromJson,
      rowKeys: const ['items', 'entries', 'ledger'],
      endpoint: '/economy/wallet/ledger',
    );
    return LedgerPageDto(entries: page.items, pagination: page.pagination);
  }

  /// Own coin spending grouped by source category.
  ///
  /// `GET /economy/wallet/categories?period=7d|30d|90d` — an object-shaped
  /// aggregate, not a list, so it has no pagination.
  Future<WalletCategoriesDto> getWalletCategories({
    String period = '30d',
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/economy/wallet/categories',
      queryParameters: {'period': period},
    );
    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty wallet categories response',
        endpoint: '/economy/wallet/categories',
      );
    }
    final data = requireDataMap(body, endpoint: '/economy/wallet/categories');
    return WalletCategoriesDto.fromJson(data);
  }

  /// The coin shop catalogue.
  ///
  /// The server publishes `data.resources` (materials, priced with
  /// `base_price_coins`) and `data.bundles` (priced with `price_coins`), plus
  /// a merged `data.packs` alias. The split keys are read because the merged
  /// alias drops the `type` that `POST /economy/shop/purchase` validates.
  Future<List<ShopItemDto>> getShopItems() async {
    final res = await _dio.get<Map<String, dynamic>>('/economy/shop');
    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty shop response',
        endpoint: '/economy/shop',
      );
    }
    final data = requireDataMap(body, endpoint: '/economy/shop');

    final items = <ShopItemDto>[];

    final resources = data['resources'];
    if (resources is List) {
      items.addAll(
        resources
            .whereType<Map<String, dynamic>>()
            .map((j) => ShopItemDto.fromJson(j, type: ShopItemType.resource)),
      );
    }

    final bundles = data['bundles'];
    if (bundles is List) {
      items.addAll(
        bundles
            .whereType<Map<String, dynamic>>()
            .map((j) => ShopItemDto.fromJson(j, type: ShopItemType.bundle)),
      );
    }

    if (items.isEmpty) {
      // Fall back to the merged alias. The type is unknown there, so it is
      // inferred from the pricing fields the server used for each kind.
      final packs = data['packs'] ?? data['items'];
      if (packs is List) {
        items.addAll(
          packs.whereType<Map<String, dynamic>>().map((j) {
            final type = j.containsKey('price_coins') || j.containsKey('contents')
                ? ShopItemType.bundle
                : ShopItemType.resource;
            return ShopItemDto.fromJson(j, type: type);
          }),
        );
      }
    }

    return items;
  }

  /// Buys a resource or bundle with coins.
  ///
  /// The server validates `{type, key, quantity}` — the previous client sent
  /// `{pack_id, packId}`, which is a 422 on every single purchase.
  ///
  /// Idempotency-Key is required by the server; a retry with the same key
  /// replays the original response instead of charging twice.
  Future<ShopPurchaseResultDto> purchaseShopItem({
    required ShopItemType type,
    required String key,
    int quantity = 1,
    String? idempotencyKey,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/economy/shop/purchase',
      data: <String, dynamic>{
        'type': type.wireValue,
        'key': key,
        'quantity': quantity,
      },
      options: Options(headers: idempotencyHeader(idempotencyKey)),
    );
    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty purchase response',
        endpoint: '/economy/shop/purchase',
      );
    }
    final data = requireDataMap(body, endpoint: '/economy/shop/purchase');
    return ShopPurchaseResultDto.fromJson(data);
  }

  /// Sells a material resource back for coins.
  ///
  /// `POST /economy/market/sells` — the coin credit is irreversible, so the
  /// Idempotency-Key is mandatory.
  Future<void> sellResource({
    required String resource,
    int quantity = 1,
    String? idempotencyKey,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/economy/market/sells',
      data: <String, dynamic>{
        'resource': resource,
        'quantity': quantity,
      },
      options: Options(headers: idempotencyHeader(idempotencyKey)),
    );
  }
}
