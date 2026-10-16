/// Lógica pura del 15-Puzzle.
///
/// El tablero es una lista en orden de filas. `0` es el vacío. No importa
/// Flutter ni modifica la lista que recibe.
library;

import 'dart:math';

import 'package:flutter_microproy/models/models.dart';

/// Máximo de remezclas antes de corregir la paridad con un intercambio.
const int _maxReshuffles = 8;

/// Tablero resoluble y no resuelto de lado [size] (3, 4 o 5).
///
/// Baraja con Fisher-Yates. Si sigue sin ser resoluble, remezcla hasta
/// [_maxReshuffles] veces y, si hace falta, intercambia dos fichas distintas
/// de 0: eso invierte la paridad y no mueve el vacío. Si queda resuelto,
/// aplica un movimiento legal, que conserva la resolubilidad.
List<int> generateSolvableBoard(int size, {Random? random}) {
  if (size != 3 && size != 4 && size != 5) {
    throw ArgumentError.value(size, 'size', 'Debe ser 3, 4 o 5.');
  }

  final rng = random ?? Random();
  var board = _shuffledBoard(size, rng);
  for (
    var attempt = 0;
    attempt < _maxReshuffles && !isSolvable(board, size);
    attempt++
  ) {
    board = _shuffledBoard(size, rng);
  }
  if (!isSolvable(board, size)) {
    board = _withFlippedInversionParity(board);
  }
  if (isSolved(board)) {
    board = _afterOneLegalMove(board, size);
  }

  if (!isSolvable(board, size) || isSolved(board)) {
    throw StateError('No se pudo generar un tablero resoluble de lado $size.');
  }
  return List<int>.unmodifiable(board);
}

/// `true` solo si [board] es una permutación válida y la paridad permite
/// llegar al tablero resuelto.
///
/// El vacío no es una ficha: no entra en las inversiones. Una inversión es
/// una pareja de fichas donde la mayor aparece antes que la menor.
///
/// Lado impar: resoluble cuando las inversiones son pares.
///
/// Lado par: importa la fila del vacío contada desde abajo, donde 1 es la
/// última fila. En un 4×4:
/// - fila 4 (abajo) → 1, impar → inversiones pares
/// - fila 3         → 2, par   → inversiones impares
/// - fila 2         → 3, impar → inversiones pares
/// - fila 1 (arriba)→ 4, par   → inversiones impares
///
/// La columna del vacío no cambia la paridad. Un movimiento horizontal no
/// altera las inversiones ni la fila. Uno vertical cruza `size - 1` fichas
/// y, si [size] es par, también cambia la fila: las dos paridades se
/// compensan, así que un movimiento legal nunca vuelve irresoluble el tablero.
bool isSolvable(List<int> board, int size) {
  if (!_isValidBoard(board, size)) return false;

  final inversions = _inversionCount(board);
  if (size.isOdd) return inversions.isEven;

  final rowFromBottom = _blankRowFromBottom(board, size);
  if (rowFromBottom.isOdd) return inversions.isEven;
  return inversions.isOdd;
}

/// `true` si la ficha en [index] está arriba, abajo, izquierda o derecha
/// del vacío. Diagonales, el propio vacío e índices inválidos devuelven
/// `false`.
bool canMove(List<int> board, int index, int size) {
  if (!_isValidBoard(board, size)) return false;
  if (index < 0 || index >= board.length) return false;
  if (board[index] == 0) return false;
  return _areOrthogonalNeighbors(index, getEmptyIndex(board), size);
}

/// Intercambia la ficha en [index] con el vacío.
///
/// No modifica [board]. Si el movimiento no es válido, devuelve la misma
/// instancia.
List<int> move(List<int> board, int index, int size) {
  if (!canMove(board, index, size)) return board;

  final next = List<int>.of(board);
  final empty = getEmptyIndex(board);
  next[empty] = next[index];
  next[index] = 0;
  return List<int>.unmodifiable(next);
}

/// `true` solo para `[1, 2, 3, …, n, 0]`.
bool isSolved(List<int> board) {
  if (board.isEmpty) return false;
  for (var i = 0; i < board.length - 1; i++) {
    if (board[i] != i + 1) return false;
  }
  return board.last == 0;
}

/// Índice del vacío, o `-1` si el tablero no tiene un 0.
int getEmptyIndex(List<int> board) => board.indexOf(0);

/// `true` si [candidate] es estrictamente mejor que los récords de su dificultad.
///
/// Gana menos movimientos. Si empatan en movimientos, gana menos tiempo.
/// Un empate exacto no es un récord nuevo. La primera marca de esa dificultad sí.
bool isNewHighScore(HighScore candidate, List<HighScore> existing) {
  for (final score in existing) {
    if (score.difficulty != candidate.difficulty) continue;
    final fewerMoves = score.moves < candidate.moves;
    final sameMovesAndNotSlower =
        score.moves == candidate.moves &&
        score.timeInSeconds <= candidate.timeInSeconds;
    if (fewerMoves || sameMovesAndNotSlower) return false;
  }
  return true;
}

/// Segundos de juego antes de la derrota por tiempo: 3×3, 4×4 y 5×5.
int timeLimitSeconds(int size) {
  return switch (size) {
    3 => 180,
    4 => 300,
    5 => 480,
    _ => throw ArgumentError.value(size, 'size', 'Debe ser 3, 4 o 5.'),
  };
}

List<int> _shuffledBoard(int size, Random random) {
  final length = size * size;
  final board = List<int>.generate(length, (i) => (i + 1) % length);
  for (var i = board.length - 1; i > 0; i--) {
    final j = random.nextInt(i + 1);
    final tile = board[i];
    board[i] = board[j];
    board[j] = tile;
  }
  return board;
}

/// Intercambia las dos primeras fichas distintas de 0.
///
/// Una transposición invierte la paridad de las inversiones y deja el vacío
/// en la misma fila, así que un tablero válido pasa de irresoluble a resoluble.
List<int> _withFlippedInversionParity(List<int> board) {
  final next = List<int>.of(board);
  final first = next.indexWhere((tile) => tile != 0);
  final second = next.indexWhere((tile) => tile != 0, first + 1);
  final tile = next[first];
  next[first] = next[second];
  next[second] = tile;
  return next;
}

List<int> _afterOneLegalMove(List<int> board, int size) {
  final empty = getEmptyIndex(board);
  final row = empty ~/ size;
  final col = empty % size;
  final neighbor = switch ((row, col)) {
    (_, final c) when c > 0 => empty - 1,
    (_, final c) when c < size - 1 => empty + 1,
    (final r, _) when r > 0 => empty - size,
    _ => empty + size,
  };
  return List<int>.of(move(board, neighbor, size));
}

bool _isValidBoard(List<int> board, int size) {
  if (size < 2) return false;
  final length = size * size;
  if (board.length != length) return false;

  final seen = <int>{};
  for (final tile in board) {
    if (tile < 0 || tile >= length || !seen.add(tile)) return false;
  }
  return seen.length == length;
}

/// Fila del vacío contada desde abajo. 1 es la última fila.
int _blankRowFromBottom(List<int> board, int size) {
  final rowFromTop = getEmptyIndex(board) ~/ size;
  return size - rowFromTop;
}

int _inversionCount(List<int> board) {
  final tiles = <int>[
    for (final tile in board)
      if (tile != 0) tile,
  ];
  var count = 0;
  for (var i = 0; i < tiles.length; i++) {
    for (var j = i + 1; j < tiles.length; j++) {
      if (tiles[i] > tiles[j]) count++;
    }
  }
  return count;
}

bool _areOrthogonalNeighbors(int a, int b, int size) {
  final rowDelta = (a ~/ size - b ~/ size).abs();
  final colDelta = (a % size - b % size).abs();
  return (rowDelta == 1 && colDelta == 0) || (rowDelta == 0 && colDelta == 1);
}
