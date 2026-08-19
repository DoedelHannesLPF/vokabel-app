import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import 'web_viewport_fix.dart';
import '../data/app_storage.dart';
import '../state/app_controller.dart';
import '../ui/bottom_nav_shell.dart';
import '../ui/login_page.dart';

class VokabelRoot extends StatefulWidget {
  const VokabelRoot({super.key});

  @override
  State<VokabelRoot> createState() => _VokabelRootState();
}

class _VokabelRootState extends State<VokabelRoot> {
  AppStorage? _storage;
  AppController? _controller;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final storage = await AppStorage.create();
    final current = storage.currentUser;
    final controller = AppController(storage: storage);

    setState(() {
      _storage = storage;
      _controller = controller;
    });

    if (current != null && current.isNotEmpty) {
      await controller.loadForUser(current);
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = _storage;
    final controller = _controller;

    if (storage == null || controller == null) {
      return MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return ChangeNotifierProvider.value(
      value: controller,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        builder: (context, child) {
          final content = child ?? const SizedBox.shrink();
          if (kIsWeb) return WebTouchCalibrationGate(child: content);
          return SafeArea(child: content);
        },
        home: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            if (controller.loading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final showLogin = _shouldShowLogin(controller: controller);
            return WebViewportResync(
              key: ValueKey(showLogin ? 'login' : controller.profile?.username),
              child: showLogin
                  ? LoginPage(
                      onAuth: (username, password, isRegister) async {
                        if (isRegister) {
                          final ok =
                              await storage.register(username, password);
                          if (!ok) {
                            return 'Benutzername bereits vergeben.';
                          }
                        } else {
                          if (!storage.userExists(username)) {
                            return 'Kein Konto mit diesem Benutzernamen gefunden.';
                          }
                          if (!storage.checkPassword(username, password)) {
                            return 'Falsches Passwort.';
                          }
                        }
                        await storage.setCurrentUser(username);
                        await controller.loadForUser(username);
                        return null;
                      },
                    )
                  : const BottomNavShell(),
            );
          },
        ),
      ),
    );
  }

  bool _shouldShowLogin({required AppController controller}) {
    return controller.profile == null;
  }
}

