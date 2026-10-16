/// Selección de dificultad después de ingresar el nombre.
library;

import 'package:flutter/material.dart';

import 'package:flutter_microproy/models/models.dart';
import 'package:flutter_microproy/screens/game_screen.dart';

/// Elige Fácil, Medio o Difícil y abre la partida con [playerName].
class DifficultySelectionScreen extends StatelessWidget {
  /// Crea la selección para el jugador ya identificado.
  const DifficultySelectionScreen({required this.playerName, super.key});

  /// Nombre ya validado. No se vuelve a recortar aquí.
  final String playerName;

  void _start(BuildContext context, Difficulty difficulty) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(
          settings: GameSettings(difficulty: difficulty),
          playerName: playerName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Dificultad')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Hola, $playerName',
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Elige el tamaño del tablero.',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _Choice(
                    label: 'Fácil · 3×3',
                    buttonKey: const Key('play-easy'),
                    onPressed: () => _start(context, Difficulty.easy),
                  ),
                  const SizedBox(height: 12),
                  _Choice(
                    label: 'Medio · 4×4',
                    buttonKey: const Key('play-medium'),
                    onPressed: () => _start(context, Difficulty.medium),
                  ),
                  const SizedBox(height: 12),
                  _Choice(
                    label: 'Difícil · 5×5',
                    buttonKey: const Key('play-hard'),
                    onPressed: () => _start(context, Difficulty.hard),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.buttonKey,
    required this.onPressed,
  });

  final String label;
  final Key buttonKey;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        key: buttonKey,
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
