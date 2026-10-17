/// Partida jugable del 15-Puzzle.
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:flutter_microproy/logic/puzzle_logic.dart';
import 'package:flutter_microproy/models/models.dart';
import 'package:flutter_microproy/screens/game_over_screen.dart';
import 'package:flutter_microproy/services/storage_service.dart';
import 'package:flutter_microproy/widgets/puzzle_tile.dart';

/// Fase visible de la partida.
enum _Phase {
  /// Tablero listo. El reloj aún no corre.
  ready,

  /// El jugador ya hizo al menos un movimiento válido.
  playing,

  /// Victoria, tiempo agotado o rendición. No admite más movimientos.
  finished,
}

/// Pantalla de juego. Debe vivir bajo un [Navigator].
///
/// El sonido no se reproduce aquí: no hay reproductor en `material.dart`.
class GameScreen extends StatefulWidget {
  /// Crea la partida con los ajustes recibidos.
  ///
  /// [random] solo hace repetible la generación en pruebas. En la app se omite.
  const GameScreen({
    required this.settings,
    required this.playerName,
    this.storage,
    this.random,
    this.initialBoard,
    super.key,
  });

  /// Dificultad, estilo y preferencias de la partida.
  final GameSettings settings;

  /// Nombre visible durante la partida. Ya viene validado.
  final String playerName;

  /// Persistencia de récords. Si es null, no se marca ni se guarda récord.
  final GameStorage? storage;

  /// Generador opcional. Si es null, la baraja es aleatoria.
  final Random? random;

  /// Tablero inicial de prueba. En la app se omite.
  final List<int>? initialBoard;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  _Phase _phase = _Phase.ready;
  List<int> _board = const [];
  int _moves = 0;
  int _seconds = 0;
  late final int _timeLimit;
  Timer? _timer;
  String? _error;
  bool _ended = false;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    final size = widget.settings.difficulty.size;
    _timeLimit = _readTimeLimit(size);
    try {
      _board =
          widget.initialBoard ??
          generateSolvableBoard(size, random: widget.random);
    } on Object catch (error) {
      _error = 'No se pudo iniciar la partida: $error';
    }
  }

  int _readTimeLimit(int size) {
    try {
      return timeLimitSeconds(size);
    } on Object {
      return 0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onTileTap(int index) {
    if (_ended || _error != null) return;
    final size = widget.settings.difficulty.size;
    if (!canMove(_board, index, size)) return;

    final next = move(_board, index, size);
    final solved = isSolved(next);
    setState(() {
      _board = next;
      _moves++;
      if (solved) {
        _phase = _Phase.finished;
        _timer?.cancel();
      } else if (_phase == _Phase.ready) {
        _phase = _Phase.playing;
        _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
      }
    });
    if (solved) _end(GameResult.victory);
  }

  void _onTick(Timer timer) {
    if (!mounted || _ended || _phase != _Phase.playing) return;
    final seconds = _seconds + 1;
    if (seconds >= _timeLimit) {
      _seconds = _timeLimit;
      _end(GameResult.timeUp);
      return;
    }
    setState(() => _seconds = seconds);
  }

  Future<void> _confirmSurrender() async {
    if (_ended || _error != null || _confirming) return;
    _confirming = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rendirse'),
          content: const Text(
            'La partida terminará como derrota. ¿Quieres rendirte?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Rendirse'),
            ),
          ],
        );
      },
    );
    _confirming = false;
    if (confirmed != true || !mounted || _ended) return;
    await _end(GameResult.surrendered);
  }

  Future<void> _confirmLeave() async {
    if (_ended || _error != null || _confirming) return;
    _confirming = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Salir'),
          content: const Text('¿Desea salir de la partida?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sí'),
            ),
          ],
        );
      },
    );
    _confirming = false;
    if (confirmed != true || !mounted || _ended) return;
    _timer?.cancel();
    _timer = null;
    _ended = true;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _onBackPressed() {
    if (_ended || _error != null) {
      Navigator.of(context).maybePop();
      return;
    }
    _confirmLeave();
  }

  Future<void> _end(GameResult result) async {
    if (_ended) return;
    _ended = true;
    _timer?.cancel();
    _timer = null;
    final seconds = result == GameResult.timeUp ? _timeLimit : _seconds;
    final isWin = result == GameResult.victory;
    final isNewRecord = isWin ? await _saveIfRecord(seconds) : false;
    await _saveMatch(seconds, won: isWin);
    if (!mounted) return;
    if (_phase != _Phase.finished) {
      setState(() => _phase = _Phase.finished);
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => GameOverScreen(
          isWin: isWin,
          moves: _moves,
          timeInSeconds: seconds,
          difficulty: widget.settings.difficulty,
          isNewRecord: isNewRecord,
          settings: widget.settings,
          storage: widget.storage,
          playerName: widget.playerName,
          result: result,
        ),
      ),
    );
  }

  Future<void> _saveMatch(int seconds, {required bool won}) async {
    try {
      await StorageService()
          .saveMatch(
            MatchRecord(
              playerName: widget.playerName,
              timeInSeconds: seconds,
              moves: _moves,
              won: won,
              difficulty: widget.settings.difficulty,
              date: DateTime.now().toUtc(),
            ),
          )
          .timeout(const Duration(seconds: 2));
    } on Object {
      // El resultado se muestra aunque el historial no pueda escribirse.
    }
  }

  Future<bool> _saveIfRecord(int seconds) async {
    final storage = widget.storage;
    if (storage == null) return false;
    try {
      final existing = await storage.loadHighScores();
      final candidate = HighScore(
        difficulty: widget.settings.difficulty,
        moves: _moves,
        timeInSeconds: seconds,
        date: DateTime.now().toUtc(),
      );
      if (!isNewHighScore(candidate, existing)) return false;
      await storage.saveHighScores([...existing, candidate]);
      return true;
    } on Object {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final canLeave = _ended || _error != null;
    return PopScope(
      canPop: canLeave,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || canLeave) return;
        _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            key: const Key('back'),
            tooltip: 'Atrás',
            icon: const BackButtonIcon(),
            onPressed: _onBackPressed,
          ),
          title: const Text('15-Puzzle'),
          actions: [
            TextButton(
              key: const Key('surrender'),
              onPressed: _ended || _error != null ? null : _confirmSurrender,
              child: const Text('Rendirse'),
            ),
          ],
        ),
        body: SafeArea(
          child: _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 700;
                    final stats = _Stats(
                      playerName: widget.playerName,
                      moves: _moves,
                      seconds: _seconds,
                      timeLimit: _timeLimit,
                      waiting: _phase == _Phase.ready,
                    );
                    final board = _Board(
                      board: _board,
                      size: widget.settings.difficulty.size,
                      style: widget.settings.tileStyle,
                      enabled: !_ended,
                      animate: widget.settings.animationsEnabled,
                      onTap: _onTileTap,
                    );
                    if (wide) {
                      return Row(
                        children: [
                          Expanded(child: board),
                          SizedBox(width: 280, child: Center(child: stats)),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        stats,
                        Expanded(child: board),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({
    required this.playerName,
    required this.moves,
    required this.seconds,
    required this.timeLimit,
    required this.waiting,
  });

  final String playerName;
  final int moves;
  final int seconds;
  final int timeLimit;
  final bool waiting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            playerName,
            key: const Key('player-name'),
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Movimientos: $moves',
            key: const Key('moves'),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatClock(seconds)} / ${_formatClock(timeLimit)}',
            key: const Key('timer'),
            style: theme.textTheme.titleLarge,
          ),
          if (waiting)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'El tiempo corre desde el primer movimiento.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({
    required this.board,
    required this.size,
    required this.style,
    required this.enabled,
    required this.animate,
    required this.onTap,
  });

  final List<int> board;
  final int size;
  final TileStyle style;
  final bool enabled;
  final bool animate;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = min(constraints.maxWidth, constraints.maxHeight) - 32;
        final boardSide = side.clamp(0, 560).toDouble();
        final grid = SizedBox(
          width: boardSide,
          height: boardSide,
          child: GridView.builder(
            primary: false,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: size,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: board.length,
            itemBuilder: (context, index) {
              final number = board[index];
              final isEmpty = number == 0;
              return PuzzleTile(
                number: number,
                style: style,
                isEmpty: isEmpty,
                onTap: !enabled || isEmpty ? null : () => onTap(index),
              );
            },
          ),
        );
        return Center(
          child: animate
              ? AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: KeyedSubtree(
                    key: ValueKey<String>(board.join(',')),
                    child: grid,
                  ),
                )
              : grid,
        );
      },
    );
  }
}

String _formatClock(int totalSeconds) {
  final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
