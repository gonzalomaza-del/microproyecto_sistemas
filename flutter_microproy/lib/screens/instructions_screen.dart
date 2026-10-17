/// Reglas del 15-Puzzle: cómo se juega, cómo se gana y cómo se pierde.
library;

import 'package:flutter/material.dart';

/// Pantalla de instrucciones. Es StatelessWidget porque su contenido no cambia.
class InstructionsScreen extends StatelessWidget {
  /// Crea la pantalla de instrucciones.
  const InstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cómo jugar')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: const [
                _RuleCard(
                  icon: Icons.swipe_outlined,
                  title: 'Objetivo',
                  text:
                      'Ordena las piezas en orden numérico usando el espacio '
                      'vacío para deslizar las piezas que están a su lado.',
                ),
                _RuleCard(
                  icon: Icons.touch_app_outlined,
                  title: 'Cómo mover',
                  text:
                      'Toca una pieza que esté justo arriba, abajo, a la '
                      'izquierda o a la derecha del espacio vacío. Las demás '
                      'piezas no se pueden mover.',
                ),
                _RuleCard(
                  icon: Icons.emoji_events_outlined,
                  title: 'Cómo ganar',
                  text:
                      'Ganas cuando todas las piezas están en orden de '
                      'izquierda a derecha y de arriba hacia abajo, con el '
                      'espacio vacío en la última casilla.',
                ),
                _RuleCard(
                  icon: Icons.timer_outlined,
                  title: 'Cómo perder',
                  text:
                      'El tiempo empieza con tu primer movimiento. Pierdes si '
                      'se acaba: 3 minutos en Fácil, 5 en Medio y 8 en '
                      'Difícil. También pierdes si eliges Rendirse.',
                ),
                _RuleCard(
                  icon: Icons.leaderboard_outlined,
                  title: 'Récords',
                  text:
                      'Al ganar se guarda tu partida si es la mejor de esa '
                      'dificultad: gana quien usó menos movimientos y, si '
                      'empatan, quien tardó menos.',
                ),
                _RuleCard(
                  icon: Icons.grid_view_outlined,
                  title: 'Dificultades',
                  text:
                      'Fácil: 3×3 (8 piezas). Medio: 4×4 (15 piezas, el '
                      'clásico). Difícil: 5×5 (24 piezas). Todos los tableros '
                      'se mezclan de forma que siempre tienen solución.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta con un ícono, un título y la explicación de una regla.
class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(text, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
