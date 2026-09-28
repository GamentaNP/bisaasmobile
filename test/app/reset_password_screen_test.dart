import 'package:bisaasmobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:bisaasmobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:bisaasmobile/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

/// The screen must reach the server with the token, not merely display fields.
///
/// This is the behaviour that was missing entirely: no screen consumed the
/// token, so the flow could not complete even in principle. Overrides
/// `authRepositoryProvider` — the same seam the existing AuthNotifier test uses
/// — so these exercise the real notifier.
void main() {
  late MockAuthRepository repo;
  late List<_ResetCall> calls;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    repo = MockAuthRepository();
    calls = [];
  });

  void stubSuccess() {
    when(() => repo.resetPassword(
          token: any(named: 'token'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          passwordConfirmation: any(named: 'passwordConfirmation'),
        )).thenAnswer((invocation) async {
      calls.add(_ResetCall(
        token: invocation.namedArguments[#token] as String,
        email: invocation.namedArguments[#email] as String,
        password: invocation.namedArguments[#password] as String,
        passwordConfirmation:
            invocation.namedArguments[#passwordConfirmation] as String,
      ));
    });
  }

  void stubFailure(String message) {
    when(() => repo.resetPassword(
          token: any(named: 'token'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          passwordConfirmation: any(named: 'passwordConfirmation'),
        )).thenThrow(StateError(message));
  }

  Widget host({String? token, String? email}) => ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(home: ResetPasswordScreen(token: token, email: email)),
      );

  Future<void> submitWith(WidgetTester tester, String pass, String confirm) async {
    await tester.enterText(find.byType(TextFormField).at(0), pass);
    await tester.enterText(find.byType(TextFormField).at(1), confirm);
    // GradientButton upper-cases its label, so match what is actually painted.
    await tester.tap(find.text('UPDATE PASSWORD'));
    await tester.pumpAndSettle();
  }

  testWidgets('submits the token and email to the server', (tester) async {
    stubSuccess();
    await tester.pumpWidget(host(token: 'tok-123', email: 'a@b.com'));
    await submitWith(tester, 'abcd1234', 'abcd1234');

    expect(calls, hasLength(1));
    expect(calls.single.token, 'tok-123');
    expect(calls.single.email, 'a@b.com');
    expect(calls.single.password, 'abcd1234');
    expect(calls.single.passwordConfirmation, 'abcd1234');
  });

  testWidgets('blocks a too-short password client-side', (tester) async {
    stubSuccess();
    await tester.pumpWidget(host(token: 'tok-123', email: 'a@b.com'));
    await submitWith(tester, 'abc', 'abc');

    // No network call: the server would reject it anyway, and an unnecessary
    // round-trip is worse than a clear inline message.
    expect(calls, isEmpty);
    expect(find.textContaining('at least'), findsOneWidget);
  });

  testWidgets('blocks a mismatched confirmation client-side', (tester) async {
    stubSuccess();
    await tester.pumpWidget(host(token: 'tok-123', email: 'a@b.com'));
    await submitWith(tester, 'abcd1234', 'zzzz9999');

    expect(calls, isEmpty);
    expect(find.textContaining('do not match'), findsOneWidget);
  });

  testWidgets('a link with no token explains itself and offers a new one', (
    tester,
  ) async {
    stubSuccess();
    await tester.pumpWidget(host());

    expect(find.textContaining('missing its reset token'), findsOneWidget);
    expect(find.text('Request a new link'), findsOneWidget);
    // Crucially it does NOT offer a form that would post an empty token.
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('an email without a token is treated as incomplete', (tester) async {
    stubSuccess();
    await tester.pumpWidget(host(email: 'a@b.com'));
    expect(find.textContaining('missing its reset token'), findsOneWidget);
  });

  testWidgets('surfaces a server rejection and keeps the form usable', (
    tester,
  ) async {
    stubFailure('This password reset token is invalid.');
    await tester.pumpWidget(host(token: 'bad', email: 'a@b.com'));
    await submitWith(tester, 'abcd1234', 'abcd1234');

    expect(calls, isEmpty);
    expect(find.textContaining('invalid'), findsWidgets);
    expect(find.text('UPDATE PASSWORD'), findsOneWidget);
  });
}

class _ResetCall {
  const _ResetCall({
    required this.token,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
  });

  final String token;
  final String email;
  final String password;
  final String passwordConfirmation;
}
