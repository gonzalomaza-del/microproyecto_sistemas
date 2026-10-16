import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_microproy/logic/puzzle_logic.dart';
import 'package:flutter_microproy/main.dart';
import 'package:flutter_microproy/models/models.dart';
import 'package:flutter_microproy/widgets/puzzle_tile.dart';

void main() {
  test('cada dificultad tiene el lado del enunciado', () {
    expect(Difficulty.easy.size, 3);
    expect(Difficulty.medium.size, 4);
    expect(Difficulty.hard.size, 5);
    expect(timeLimitSeconds(3), 180);
    expect(timeLimitSeconds(4), 300);
    expect(timeLimitSeconds(5), 480);
  });

  test('los tres tamaños salen resolubles y se pueden mover', () {
    for (final size in [3, 4, 5]) {
      for (var seed = 0; seed < 20; seed++) {
        final board = generateSolvableBoard(size, random: Random(seed));
        expect(board, hasLength(size * size), reason: 'size $size seed $seed');
        expect(isSolvable(board, size), isTrue, reason: '$board');
        expect(isSolved(board), isFalse);
        final index = [
          for (var i = 0; i < board.length; i++)
            if (canMove(board, i, size)) i,
        ].first;
        final moved = move(board, index, size);
        expect(isSolvable(moved, size), isTrue, reason: 'size $size');
        expect(identical(moved, board), isFalse);
      }
    }
    expect(() => generateSolvableBoard(2), throwsArgumentError);
  });

  testWidgets('Jugar pide el nombre y luego abre cada dificultad', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MainApp());
    await tester.tap(find.byKey(const Key('play')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('username-continue')));
    await tester.pump();
    expect(find.text('Escribe un nombre.'), findsOneWidget);
    expect(find.text('Dificultad'), findsNothing);

    await tester.enterText(find.byKey(const Key('username-field')), '   ');
    await tester.tap(find.byKey(const Key('username-continue')));
    await tester.pump();
    expect(find.text('Escribe un nombre.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('username-field')), '  Ari  ');
    await tester.tap(find.byKey(const Key('username-continue')));
    await tester.pumpAndSettle();
    expect(find.text('Hola, Ari'), findsOneWidget);

    final cases = {'play-easy': 9, 'play-medium': 16, 'play-hard': 25};
    for (final entry in cases.entries) {
      await tester.tap(find.byKey(Key(entry.key)));
      await tester.pumpAndSettle();
      expect(find.text('Ari'), findsOneWidget);
      expect(find.text('Movimientos: 0'), findsOneWidget);
      expect(
        find.byType(PuzzleTile),
        findsNWidgets(entry.value),
        reason: entry.key,
      );
      expect(tester.takeException(), isNull);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });
}
