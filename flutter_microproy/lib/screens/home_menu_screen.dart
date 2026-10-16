/// Menú principal: entrada a jugar, marcadores, historial, ajustes y reglas.
library;

import 'package:flutter/material.dart';

import 'package:flutter_microproy/screens/high_scores_screen.dart';
import 'package:flutter_microproy/screens/history_screen.dart';
import 'package:flutter_microproy/screens/instructions_screen.dart';
import 'package:flutter_microproy/screens/settings_screen.dart';
import 'package:flutter_microproy/screens/username_screen.dart';
import 'package:flutter_microproy/state/app_scope.dart';

/// Menú principal. Es StatelessWidget: no guarda datos propios, solo
/// lee si las animaciones están activas y abre las demás pantallas.
class HomeMenuScreen extends StatelessWidget {
  /// Crea el menú principal.
  const HomeMenuScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final animate = AppScope.of(context).settings.animationsEnabled;

    const items = [
      _MenuItem(
        buttonKey: Key('play'),
        icon: Icons.play_arrow_rounded,
        label: 'Jugar',
        screen: UsernameScreen(),
        primary: true,
      ),
      _MenuItem(
        buttonKey: Key('high-scores'),
        icon: Icons.leaderboard_outlined,
        label: 'Marcadores',
        screen: HighScoresScreen(),
      ),
      _MenuItem(
        buttonKey: Key('history'),
        icon: Icons.history,
        label: 'Historial',
        screen: HistoryScreen(),
      ),
      _MenuItem(
        buttonKey: Key('settings'),
        icon: Icons.settings_outlined,
        label: 'Configuración',
        screen: SettingsScreen(),
      ),
      _MenuItem(
        buttonKey: Key('instructions'),
        icon: Icons.help_outline,
        label: 'Cómo jugar',
        screen: InstructionsScreen(),
      ),
    ];

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.primaryContainer, colors.surface],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Entrance(
                      animate: animate,
                      index: 0,
                      child: _Logo(colors: colors),
                    ),
                    const SizedBox(height: 24),
                    _Entrance(
                      animate: animate,
                      index: 1,
                      child: Text(
                        '15-Puzzle Flutter',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _Entrance(
                      animate: animate,
                      index: 1,
                      child: Text(
                        'Desliza, ordena y bate tus récords.',
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),
                    for (var i = 0; i < items.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _Entrance(
                          animate: animate,
                          index: i + 2,
                          child: _MenuButton(
                            item: items[i],
                            animate: animate,
                            onPressed: () => _open(context, items[i].screen),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Datos de un botón del menú.
class _MenuItem {
  const _MenuItem({
    required this.buttonKey,
    required this.icon,
    required this.label,
    required this.screen,
    this.primary = false,
  });

  final Key buttonKey;
  final IconData icon;
  final String label;
  final Widget screen;

  /// El botón principal (Jugar) se dibuja con el color más fuerte.
  final bool primary;
}

/// Logo circular del juego.
class _Logo extends StatelessWidget {
  const _Logo({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
      child: Icon(Icons.extension, size: 64, color: colors.onPrimary),
    );
  }
}

/// Hace aparecer a su hijo con un desvanecido y un deslizamiento hacia arriba.
/// [index] retrasa la entrada para que los elementos aparezcan en cascada.
class _Entrance extends StatelessWidget {
  const _Entrance({
    required this.animate,
    required this.index,
    required this.child,
  });

  final bool animate;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!animate) return child;
    const stepMs = 90;
    const lengthMs = 400;
    final delayMs = index * stepMs;
    final totalMs = delayMs + lengthMs;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: totalMs),
      curve: Interval(delayMs / totalMs, 1, curve: Curves.easeOutCubic),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Botón grande que se encoge al presionarlo.
///
/// Es StatefulWidget porque recuerda si el dedo está encima (_pressed).
class _MenuButton extends StatefulWidget {
  const _MenuButton({
    required this.item,
    required this.animate,
    required this.onPressed,
  });

  final _MenuItem item;
  final bool animate;
  final VoidCallback onPressed;

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final icon = Icon(item.icon);
    final label = Text(item.label);
    final button = item.primary
        ? FilledButton.icon(
            key: item.buttonKey,
            onPressed: widget.onPressed,
            icon: icon,
            label: label,
          )
        : FilledButton.tonalIcon(
            key: item.buttonKey,
            onPressed: widget.onPressed,
            icon: icon,
            label: label,
          );
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1,
        duration: widget.animate
            ? const Duration(milliseconds: 120)
            : Duration.zero,
        curve: Curves.easeOut,
        child: SizedBox(width: double.infinity, child: button),
      ),
    );
  }
}
