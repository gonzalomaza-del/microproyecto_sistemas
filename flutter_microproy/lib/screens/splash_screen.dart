/// Pantalla de carga con el título animado del juego.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_microproy/screens/home_menu_screen.dart';

/// Splash inicial. Muestra el logo con fade-in y escalado y, tras unos
/// segundos o al pulsar "Saltar", abre el menú principal.
///
/// Es StatefulWidget porque maneja un AnimationController y un Timer.
class SplashScreen extends StatefulWidget {
  /// Crea el splash.
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 0.7,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

  Timer? _timer;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _timer = Timer(const Duration(milliseconds: 2500), _goToMenu);
  }

  /// Abre el menú una sola vez, ya sea por el Timer o por "Saltar".
  void _goToMenu() {
    if (_left || !mounted) return;
    _left = true;
    _timer?.cancel();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) {
          return const HomeMenuScreen();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 128,
                        height: 128,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.extension,
                          size: 72,
                          color: colors.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '15-Puzzle Flutter',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Desliza y ordena',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton.icon(
                  key: const Key('skip'),
                  onPressed: _goToMenu,
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Saltar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
