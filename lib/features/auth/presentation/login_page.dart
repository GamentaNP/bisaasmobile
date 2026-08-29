library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dio/dio.dart';

import '../../../app/config/api_config.dart';
import '../../../app/config/env.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/security/token_manager.dart';
import '../data/auth_repository.dart';

final tokenManagerProvider = Provider((_) => TokenManager());

final dioProvider = Provider<Dio>((ref) {
  if (!DioClient.isInitialized) throw StateError('DioClient not init — see bootstrap.dart');
  return DioClient.instance.dio;
});

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginState();
}

class _LoginState extends ConsumerState<LoginPage> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  String? _err;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final tokens = ref.read(tokenManagerProvider);
      final dio = ref.read(dioProvider);
      final repo = AuthRepository(dio);
      final deviceName = await tokens.readDeviceName() ?? 'android-${DateTime.now().millisecondsSinceEpoch}';
      await tokens.setDeviceName(deviceName);
      final data = await repo.login(
        email: _email.text.trim(),
        password: _pass.text,
        deviceName: deviceName,
      );
      await tokens.persist(
        token: data['token'] as String,
        expiresAt: data['expires_at'] as String?,
      );
      if (!mounted) return;
      context.go('/quiz');
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final env = currentEnv();
    return Scaffold(
      appBar: AppBar(title: const Text('CivilCal — Sign in')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Backend: ${ApiConfig.baseUrl}', style: Theme.of(context).textTheme.labelSmall),
          Text('Env: ${env.name} (${env.host})', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 24),
          TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 12),
          TextField(controller: _pass, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
          const SizedBox(height: 20),
          if (_err != null) Text(_err!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          FilledButton(onPressed: _loading ? null : _login, child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Sign in')),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: () => context.go('/quiz'), child: const Text('Continue as guest → Quiz')),
          const SizedBox(height: 24),
          const Text('Server-authoritative: quiz grading, coins, leaderboards all live at C:\\laragon\\www\\bisaas (/api/v1). This client never duplicates that logic.',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
