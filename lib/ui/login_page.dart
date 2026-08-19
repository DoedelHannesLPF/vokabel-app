import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef AuthCallback = Future<String?> Function(
    String username, String password, bool isRegister);

class LoginPage extends StatefulWidget {
  /// Called when the user taps Login or Registrieren.
  /// Returns an error message string on failure, or null on success.
  final AuthCallback onAuth;

  const LoginPage({super.key, required this.onAuth});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _loginUsernameCtrl = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();
  final _regUsernameCtrl = TextEditingController();
  final _regPasswordCtrl = TextEditingController();
  final _regPasswordConfirmCtrl = TextEditingController();

  bool _loginPasswordVisible = false;
  bool _regPasswordVisible = false;
  bool _regPasswordConfirmVisible = false;
  bool _busy = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() => setState(() => _errorMessage = null));
  }

  @override
  void dispose() {
    _tabs.dispose();
    _loginUsernameCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _regUsernameCtrl.dispose();
    _regPasswordCtrl.dispose();
    _regPasswordConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _errorMessage = null;
      _busy = true;
    });

    final isRegister = _tabs.index == 1;
    String username;
    String password;

    if (isRegister) {
      username = _regUsernameCtrl.text.trim();
      password = _regPasswordCtrl.text;
      final confirm = _regPasswordConfirmCtrl.text;

      if (username.isEmpty || password.isEmpty) {
        setState(() {
          _errorMessage = 'Bitte alle Felder ausfüllen.';
          _busy = false;
        });
        return;
      }
      if (password != confirm) {
        setState(() {
          _errorMessage = 'Passwörter stimmen nicht überein.';
          _busy = false;
        });
        return;
      }
      if (password.length < 4) {
        setState(() {
          _errorMessage = 'Passwort muss mindestens 4 Zeichen haben.';
          _busy = false;
        });
        return;
      }
    } else {
      username = _loginUsernameCtrl.text.trim();
      password = _loginPasswordCtrl.text;

      if (username.isEmpty || password.isEmpty) {
        setState(() {
          _errorMessage = 'Bitte Benutzername und Passwort eingeben.';
          _busy = false;
        });
        return;
      }
    }

    final error = await widget.onAuth(username, password, isRegister);
    if (mounted) {
      setState(() {
        _errorMessage = error;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                48 + (kIsWeb ? MediaQuery.viewPaddingOf(context).top : 0),
                24,
                48,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App icon / title
                  Icon(Icons.menu_book_outlined, size: 64, color: cs.primary),
                  const SizedBox(height: 12),
                  Text(
                    'VokabelApp',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Englisch ↔ Spanisch lernen',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),

                  // Card with tabs
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          TabBar(
                            controller: _tabs,
                            tabs: const [
                              Tab(text: 'Anmelden'),
                              Tab(text: 'Registrieren'),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: _tabs.index == 0 ? 180 : 270,
                            child: TabBarView(
                              controller: _tabs,
                              children: [
                                _buildLoginForm(),
                                _buildRegisterForm(),
                              ],
                            ),
                          ),

                          // Error banner
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: cs.errorContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline,
                                      color: cs.onErrorContainer, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(
                                          color: cs.onErrorContainer),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _busy ? null : _submit,
                              child: _busy
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: cs.onPrimary),
                                    )
                                  : Text(_tabs.index == 0
                                      ? 'Anmelden'
                                      : 'Konto erstellen'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Daten werden lokal auf diesem Gerät gespeichert.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        TextField(
          controller: _loginUsernameCtrl,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Benutzername',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _loginPasswordCtrl,
          obscureText: !_loginPasswordVisible,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: 'Passwort',
            prefixIcon: const Icon(Icons.lock_outline),
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(_loginPasswordVisible
                  ? Icons.visibility_off
                  : Icons.visibility),
              onPressed: () => setState(
                  () => _loginPasswordVisible = !_loginPasswordVisible),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      children: [
        TextField(
          controller: _regUsernameCtrl,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Benutzername',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _regPasswordCtrl,
          obscureText: !_regPasswordVisible,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Passwort',
            prefixIcon: const Icon(Icons.lock_outline),
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(_regPasswordVisible
                  ? Icons.visibility_off
                  : Icons.visibility),
              onPressed: () =>
                  setState(() => _regPasswordVisible = !_regPasswordVisible),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _regPasswordConfirmCtrl,
          obscureText: !_regPasswordConfirmVisible,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: 'Passwort bestätigen',
            prefixIcon: const Icon(Icons.lock_outline),
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(_regPasswordConfirmVisible
                  ? Icons.visibility_off
                  : Icons.visibility),
              onPressed: () => setState(() =>
                  _regPasswordConfirmVisible = !_regPasswordConfirmVisible),
            ),
          ),
        ),
      ],
    );
  }
}
