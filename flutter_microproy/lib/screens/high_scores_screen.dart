/// Mejores puntajes por dificultad, con opción de borrarlos.
library;

import 'package:flutter/material.dart';

import 'package:flutter_microproy/models/models.dart';
import 'package:flutter_microproy/services/storage_service.dart';
import 'package:flutter_microproy/state/app_scope.dart';

/// Pantalla de marcadores. Es StatefulWidget porque carga los récords
/// del almacenamiento y se actualiza al borrarlos.
class HighScoresScreen extends StatefulWidget {
  /// Crea la pantalla. Lee los récords a través de [AppScope].
  const HighScoresScreen({super.key});

  @override
  State<HighScoresScreen> createState() => _HighScoresScreenState();
}

class _HighScoresScreenState extends State<HighScoresScreen> {
  StorageService? _storage;
  Future<List<HighScore>>? _scores;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _storage ??= AppScope.of(context).storage;
    _scores ??= _storage!.loadHighScores();
  }

  /// Pide confirmación y, si el usuario acepta, borra todos los récords.
  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Borrar marcadores'),
          content: const Text(
            'Se eliminarán los récords de todas las dificultades. '
            'Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Borrar'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    try {
      await _storage!.saveHighScores(const []);
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudieron borrar los marcadores.')),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _scores = Future.value(const []));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Marcadores borrados.')));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HighScore>>(
      future: _scores,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState != ConnectionState.done;
        final scores = snapshot.data ?? const <HighScore>[];
        return Scaffold(
          appBar: AppBar(
            title: const Text('Marcadores'),
            actions: [
              IconButton(
                tooltip: 'Borrar marcadores',
                icon: const Icon(Icons.delete_sweep_outlined),
                onPressed: loading || scores.isEmpty ? null : _confirmClear,
              ),
            ],
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: loading
                    ? const CircularProgressIndicator()
                    : _buildContent(context, scores),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, List<HighScore> scores) {
    final backButton = Padding(
      padding: const EdgeInsets.only(top: 16),
      child: OutlinedButton.icon(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back),
        label: const Text('Volver al menú'),
      ),
    );

    if (scores.isEmpty) {
      final theme = Theme.of(context);
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('Aún no hay récords', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Gana una partida y tu mejor resultado aparecerá aquí.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            backButton,
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        for (final difficulty in Difficulty.values)
          _DifficultyCard(
            difficulty: difficulty,
            best: _bestFor(scores, difficulty),
          ),
        backButton,
      ],
    );
  }
}

/// El mejor récord de una dificultad: menos movimientos y, si empatan,
/// menos tiempo. Es la misma regla que usa `isNewHighScore`.
HighScore? _bestFor(List<HighScore> scores, Difficulty difficulty) {
  HighScore? best;
  for (final score in scores) {
    if (score.difficulty != difficulty) continue;
    final better =
        best == null ||
        score.moves < best.moves ||
        (score.moves == best.moves && score.timeInSeconds < best.timeInSeconds);
    if (better) best = score;
  }
  return best;
}

/// Tarjeta con el récord de una dificultad, o un aviso si no tiene.
class _DifficultyCard extends StatelessWidget {
  const _DifficultyCard({required this.difficulty, required this.best});

  final Difficulty difficulty;
  final HighScore? best;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final record = best;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_label(difficulty)} · ${difficulty.size}×${difficulty.size}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (record == null)
              Text('Sin récord todavía.', style: theme.textTheme.bodyMedium)
            else
              Wrap(
                spacing: 32,
                runSpacing: 12,
                children: [
                  _Stat(
                    icon: Icons.touch_app_outlined,
                    label: 'Movimientos',
                    value: '${record.moves}',
                  ),
                  _Stat(
                    icon: Icons.timer_outlined,
                    label: 'Tiempo',
                    value: _formatTime(record.timeInSeconds),
                  ),
                  _Stat(
                    icon: Icons.calendar_today_outlined,
                    label: 'Fecha',
                    value: _formatDate(record.date),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Un dato del récord con su ícono y su etiqueta.
class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.bodySmall),
            Text(value, style: theme.textTheme.titleMedium),
          ],
        ),
      ],
    );
  }
}

String _label(Difficulty difficulty) {
  return switch (difficulty) {
    Difficulty.easy => 'Fácil',
    Difficulty.medium => 'Medio',
    Difficulty.hard => 'Difícil',
  };
}

String _formatTime(int totalSeconds) {
  final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day/$month/${local.year}';
}
