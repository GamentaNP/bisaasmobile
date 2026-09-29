import 'package:bisaasmobile/app/localization/app_languages.dart';
import 'package:bisaasmobile/app/theme/script_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The language picker overflowed its sheet by 308px on a 1440px-tall Redmi 6A,
/// found only by running the app on the device. A `Column` sized to its children
/// cannot work for a list whose length comes from the server, so the regression
/// is pinned here against the shortest screen worth supporting.
void main() {
  /// A deliberately small viewport: 1440 logical px tall is the Redmi 6A the bug
  /// was found on, and a 480px one is shorter still.
  Future<void> pumpPicker(WidgetTester tester, {Size size = const Size(720, 1440)}) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          onGenerateRoute: (settings) => MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => showModalBottomSheet<Locale?>(
                      context: context,
                      showDragHandle: true,
                      isScrollControlled: true,
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.7,
                      ),
                      builder: (context) => SafeArea(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const ListTile(title: Text('System default')),
                              for (final lang in AppLanguages.all)
                                ListTile(
                                  title: Text(
                                    lang.displayLabel,
                                    style: ScriptFonts.forText(
                                      Theme.of(context).textTheme.bodyLarge!,
                                      lang.displayLabel,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('the picker does not overflow on a 1440px screen', (tester) async {
    await pumpPicker(tester);
    expect(tester.takeException(), isNull,
        reason: 'this is the exact device the 308px overflow was seen on');
  });

  testWidgets('the picker does not overflow on a very short screen', (tester) async {
    await pumpPicker(tester, size: const Size(720, 900));
    expect(tester.takeException(), isNull);
  });

  testWidgets('every language is reachable, which requires the sheet to scroll',
      (tester) async {
    // If the sheet cannot scroll, a language below the fold is unreachable,
    // which is a worse bug than the overflow: a user whose language is listed
    // but not visible cannot select it at all.
    await pumpPicker(tester, size: const Size(720, 900));
    final last = AppLanguages.all.last;

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -800));
    await tester.pumpAndSettle();

    expect(find.text(last.displayLabel), findsOneWidget);
  });

  testWidgets('a grown registry still renders without overflowing', (tester) async {
    // The registry is server-driven, so more languages is the expected direction
    // of travel. This asserts the layout survives 30 of them.
    AppLanguages.adopt([
      for (var i = 0; i < 30; i++)
        AppLanguage(code: 'l$i', labelEn: 'Lang $i', nativeName: 'भाषा $i'),
    ]);
    addTearDown(AppLanguages.reset);

    await pumpPicker(tester, size: const Size(720, 1440));
    expect(tester.takeException(), isNull);
  });
}
