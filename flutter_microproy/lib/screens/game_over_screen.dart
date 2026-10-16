/// Resultado de una partida.
library;

import 'package:flutter/material.dart';

import 'package:flutter_microproy/models/models.dart';
import 'package:flutter_microproy/screens/game_screen.dart';

/// Cómo terminó la partida, además de [GameOverScreen.isWin].
enum GameResult {
  /// El tablero quedó en orden.
  victory,

  /// Se alcanzó el límite de tiempo.
  timeUp,

  /// El jugador confirmó que se rinde.
  surrendered,
}

/// Pantalla de fin de partida. Muestra el resultado y permite continuar.
class GameOverScreen extends StatelessWidget {
  /// Crea el resultado. [settings] conserva el estilo al repetir la partida.
  const GameOverScreen({
    required this.isWin,
    required this.moves,
    required this.timeInSeconds,
    required this.difficulty,
    required this.isNewRecord,
    required this.settings,
    required this.playerName,
    this.storage,
    this.result,
    super.key,
  });

  /// `true` solo si el tablero quedó resuelto.
  final bool isWin;

  /// Movimientos válidos realizados.
  final int moves;

  /// Segundos contados desde el primer movimiento.
  final int timeInSeconds;

  /// Dificultad de la partida terminada.
  final Difficulty difficulty;

  /// `true` si esta victoria supera los récords guardados de [difficulty].
  final bool isNewRecord;

  /// Ajustes completos para "Jugar de nuevo".
  final GameSettings settings;

  /// Nombre que se conserva al repetir la partida.
  final String playerName;

  /// Persistencia opcional. Se reenvía al repetir la partida.
  final GameStorage? storage;

  /// Motivo concreto. Si falta, se usa solo [isWin].
  final GameResult? result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = isWin ? 'Victoria' : 'Derrota';
    final detail = switch (result) {
      GameResult.timeUp => 'Se acabó el tiempo.',
      GameResult.surrendered => 'Te rendiste.',
      GameResult.victory => 'Tablero resuelto.',
      null => isWin ? 'Tablero resuelto.' : 'No se completó el tablero.',
    };
    final icon = isWin ? Icons.emoji_events_outlined : Icons.flag_outlined;
    final difficultyLabel = switch (difficulty) {
      Difficulty.easy => 'Fácil · 3×3',
      Difficulty.medium => 'Media · 4×4',
      Difficulty.hard => 'Difícil · 5×5',
    };
    final showRecord = isWin && isNewRecord;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icon,
                            size: 72,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            title,
                            key: const Key('game-over-title'),
                            style: theme.textTheme.headlineMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            detail,
                            style: theme.textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            difficultyLabel,
                            style: theme.textTheme.bodyLarge,
                          ),
                          if (showRecord) ...[
                            const SizedBox(height: 20),
                            _NewRecordBanner(theme: theme),
                          ],
                          const SizedBox(height: 24),
                          Text(
                            'Movimientos: $moves',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tiempo: ${_formatClock(timeInSeconds)}',
                            key: const Key('game-over-time'),
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 32),
                          FilledButton(
                            key: const Key('play-again'),
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute<void>(
                                  builder: (_) => GameScreen(
                                    settings: settings,
                                    storage: storage,
                                    playerName: playerName,
                                  ),
                                ),
                              );
                            },
                            child: const Text('Jugar de nuevo'),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            key: const Key('main-menu'),
                            onPressed: () {
                              Navigator.of(context)
                                  .popUntil((route) => route.isFirst);
                            },
                            child: const Text('Menú principal'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NewRecordBanner extends StatelessWidget {
  const _NewRecordBanner({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.workspace_premium_outlined,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 8),
            Text(
              '¡Nuevo récord!',
              key: const Key('new-record'),
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatClock(int totalSeconds) {
  final safe = totalSeconds < 0 ? 0 : totalSeconds;
  final minutes = (safe ~/ 60).toString().padLeft(2, '0');
  final seconds = (safe % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
