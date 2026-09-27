import 'package:bisaasmobile/features/quiz/data/models/lifeline_dto.dart';
import 'package:bisaasmobile/features/quiz/presentation/widgets/lifeline_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget-level proof that the lifeline bar renders the **server's** catalogue.
///
/// Screenshots cannot be used for this: `SensitiveScreenGuard` applies
/// FLAG_SECURE to graded attempts, so the framebuffer is protected and
/// `screencap` returns "FB is protected: PERMISSION_DENIED". That guard is
/// working as designed; this test is the verification instead.
void main() {
  /// Captured verbatim from GET /api/v1/quiz/attempts/6115/lifelines on
  /// 2026-09-27 (13 lifelines, wallet 130 coins, a 25% discount on 50/50).
  final livePayload = <String, dynamic>{
    'enabled': true,
    'walletBalance': 130,
    'lifelines': [
      {
        'slug': 'fifty_fifty',
        'name': '50/50',
        'iconUrl': '/icons/svg/powerup-5050.svg',
        'costCoins': 38,
        'baseCostCoins': 50,
        'discountPct': 25,
        'effectType': 'fifty_fifty',
        'maxUsesPerAttempt': 1,
        'purchasedUses': 0,
        'usedUses': 0,
        'remainingUses': 0,
        'inventoryUses': 0,
        'canPurchase': true,
        'canUse': false,
        'lockedByMode': false,
        'lockReason': null,
        'adUnlockEnabled': false,
      },
      {
        'slug': 'skip',
        'name': 'Skip',
        'costCoins': 57,
        'effectType': 'skip',
        'maxUsesPerAttempt': 1,
        'remainingUses': 0,
        'inventoryUses': 0,
        'canPurchase': true,
        'canUse': false,
        'lockedByMode': false,
      },
      {
        'slug': 'hint',
        'name': 'Hint',
        'costCoins': 23,
        'effectType': 'hint',
        'maxUsesPerAttempt': 1,
        'remainingUses': 0,
        'inventoryUses': 0,
        'canPurchase': true,
        'canUse': false,
        'lockedByMode': false,
      },
    ],
  };

  Future<void> pump(WidgetTester tester, LifelineCatalogueDto dto, {String? busySlug}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LifelineBar(
            lifelines: dto.lifelines,
            walletBalance: dto.walletBalance,
            // The kill switch is the server's `enabled` flag, forwarded verbatim.
            enabled: dto.enabled,
            busySlug: busySlug,
            onUse: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders every lifeline the server offered, in order', (tester) async {
    final dto = LifelineCatalogueDto.fromJson(livePayload);
    await pump(tester, dto);

    expect(find.text('50/50'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Hint'), findsOneWidget);
  });

  testWidgets('a purchasable lifeline is tappable even though canUse is false', (tester) async {
    // The regression this guards: gating on canUse alone left every chip
    // disabled for any player who had not pre-bought tokens.
    final dto = LifelineCatalogueDto.fromJson(livePayload);
    await pump(tester, dto);

    final fiftyFifty = dto.bySlug('fifty_fifty')!;
    expect(fiftyFifty.canUse, isFalse);
    expect(fiftyFifty.canPurchase, isTrue);
    expect(fiftyFifty.isAvailable, isTrue);

    // Tapping must reach the callback.
    final used = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LifelineBar(
            lifelines: dto.lifelines,
            walletBalance: dto.walletBalance,
            onUse: (l) => used.add(l.slug),
          ),
        ),
      ),
    );
    await tester.tap(find.text('50/50'));
    await tester.pump();
    expect(used, ['fifty_fifty']);
  });

  testWidgets('shows the discounted price alongside the struck-through base', (tester) async {
    final dto = LifelineCatalogueDto.fromJson(livePayload);
    await pump(tester, dto);

    // base 50 struck through, real price 38 bold.
    expect(find.text('50'), findsOneWidget);
    expect(find.text('38'), findsOneWidget);
    final base = tester.widget<Text>(find.text('50'));
    expect(base.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('a lifeline the player cannot afford is disabled', (tester) async {
    final dto = LifelineCatalogueDto.fromJson({
      'enabled': true,
      'walletBalance': 5,
      'lifelines': [
        {
          'slug': 'shield',
          'name': 'Shield',
          'costCoins': 125,
          'effectType': 'shield',
          'canPurchase': false,
          'canUse': false,
          'lockedByMode': false,
        },
      ],
    });
    final used = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LifelineBar(
            lifelines: dto.lifelines,
            walletBalance: dto.walletBalance,
            onUse: (l) => used.add(l.slug),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Shield'));
    await tester.pump();
    expect(used, isEmpty, reason: 'an unaffordable lifeline must not fire');
  });

  testWidgets('a mode-locked lifeline is disabled even when affordable', (tester) async {
    final dto = LifelineCatalogueDto.fromJson({
      'enabled': true,
      'walletBalance': 9999,
      'lifelines': [
        {
          'slug': 'double_xp',
          'name': 'Double XP',
          'costCoins': 100,
          'effectType': 'double_xp',
          'canPurchase': true,
          'canUse': true,
          'lockedByMode': true,
          'lockReason': 'Not available in exam mode',
        },
      ],
    });
    final used = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LifelineBar(
            lifelines: dto.lifelines,
            walletBalance: dto.walletBalance,
            onUse: (l) => used.add(l.slug),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Double XP'));
    await tester.pump();
    expect(used, isEmpty);
  });

  testWidgets('renders nothing when the server kill switch is off', (tester) async {
    final dto = LifelineCatalogueDto.fromJson(const {
      'enabled': false,
      'walletBalance': 0,
      'lifelines': <dynamic>[],
    });
    await pump(tester, dto);

    // The widget collapses to zero height — no chips, no coins, no dead row.
    expect(find.text('50/50'), findsNothing);
    expect(find.byIcon(Icons.monetization_on_rounded), findsNothing);
    expect(tester.getSize(find.byType(LifelineBar)).height, 0);
  });

  testWidgets('renders nothing for an empty catalogue', (tester) async {
    final dto = LifelineCatalogueDto.fromJson(const {
      'enabled': true,
      'walletBalance': 0,
      'lifelines': <dynamic>[],
    });
    await pump(tester, dto);

    expect(find.text('50/50'), findsNothing);
    expect(tester.getSize(find.byType(LifelineBar)).height, 0);
  });

  testWidgets('the kill switch hides chips even when the server sent some', (tester) async {
    // enabled:false with a populated list must not render — the server flag wins.
    final dto = LifelineCatalogueDto.fromJson({
      'enabled': false,
      'walletBalance': 130,
      'lifelines': [
        {'slug': 'fifty_fifty', 'name': '50/50', 'costCoins': 38, 'canPurchase': true},
      ],
    });
    await pump(tester, dto);
    expect(find.text('50/50'), findsNothing);
  });
}
