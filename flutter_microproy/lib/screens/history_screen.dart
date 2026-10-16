/// Lista de partidas guardadas en el dispositivo o en el navegador.
library;

import 'package:flutter/material.dart';

import 'package:flutter_microproy/models/models.dart';
import 'package:flutter_microproy/services/storage_service.dart';

/// Muestra el historial, de la partida más reciente a la más antigua.
class HistoryScreen extends StatefulWidget {
  /// Crea la pantalla. [storage] se puede inyectar en pruebas.
  const HistoryScreen({this.storage, super.key});

  /// Origen de los datos. Si es null, usa [StorageService] real.
  final StorageService? storage;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final Future<List<MatchRecord>> _matches;

  @override
  void initState() {
    super.initState();
    _matches = (widget.storage ?? StorageService()).loadMatches();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: FutureBuilder<List<MatchRecord>>(
        future: _matches,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('No se pudo leer el historial.'));
          }
          final records = (snapshot.data ?? const <MatchRecord>[]).reversed
              .toList();
          if (records.isEmpty) {
            return const Center(
              child: Text('Todavía no hay partidas guardadas.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return _MatchTile(record: records[index]);
            },
          );
        },
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({required this.record});

  final MatchRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final difficulty = switch (record.difficulty) {
      Difficulty.easy => 'Fácil · 3×3',
      Difficulty.medium => 'Medio · 4×4',
      Difficulty.hard => 'Difícil · 5×5',
    };
    final result = record.won ? 'Ganó' : 'Perdió';
    return Card(
      child: ListTile(
        title: Text(
          record.playerName.isEmpty ? 'Sin nombre' : record.playerName,
        ),
        subtitle: Text(
          '$difficulty · ${_formatClock(record.timeInSeconds)} · '
          '${record.moves} movimientos',
        ),
        trailing: Text(
          result,
          style: theme.textTheme.titleMedium?.copyWith(
            color: record.won
                ? theme.colorScheme.primary
                : theme.colorScheme.error,
            fontWeight: FontWeight.w700,
          ),
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
