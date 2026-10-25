import 'package:flutter/material.dart';

import '../core/navigation.dart';
import '../core/strings.dart';
import '../services/api_client.dart';
import '../services/local_store.dart';
import '../widgets/async_body.dart';
import '../widgets/busy_icon.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _api = ApiClient();
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController(text: S.guardian);
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  bool _isRegister = false;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final email = _email.text.trim();
      final data = _isRegister
          ? await _api.register(
              name: _name.text.trim(),
              email: email,
              password: _password.text,
              phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
            )
          : await _api.login(email: email, password: _password.text);
      final user = Map<String, dynamic>.from(data['user'] as Map? ?? const {});
      await LocalStore.saveSession(
        token: data['token'].toString(),
        name: (user['name'] ?? '').toString(),
        email: (user['email'] ?? email).toString(),
      );
      if (!mounted) return;
      context.replaceWith(const DashboardScreen());
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(S.appName),
        actions: [
          IconButton(
            tooltip: S.serverSettings,
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.push(const SettingsScreen()),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 20),
            Icon(Icons.health_and_safety_rounded, size: 64, color: scheme.primary),
            const SizedBox(height: 12),
            Text(
              _isRegister ? S.registerTitle : S.signInTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(S.serverMustRun, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: AutofillGroup(
                child: Column(
                  children: [
                    if (_isRegister) ...[
                      TextFormField(
                        controller: _name,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(labelText: S.name),
                        validator: (v) => v == null || v.trim().isEmpty ? S.nameRequired : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(labelText: S.phone),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(labelText: S.email),
                      validator: (v) => v == null || !v.contains('@') ? S.emailRequired : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _busy ? null : _submit(),
                      decoration: InputDecoration(labelText: S.password),
                      validator: (v) => v == null || v.length < 6 ? S.passwordTooShort : null,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _busy ? null : _submit,
                      icon: BusyIcon(busy: _busy, icon: Icons.login_rounded),
                      label: Text(_isRegister ? S.register : S.signIn),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy ? null : () => setState(() => _isRegister = !_isRegister),
              child: Text(_isRegister ? S.haveAccount : S.noAccount),
            ),
          ],
        ),
      ),
    );
  }
}
