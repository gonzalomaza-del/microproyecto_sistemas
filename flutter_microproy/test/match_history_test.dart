import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_microproy/models/models.dart';
import 'package:flutter_microproy/screens/game_screen.dart';
import 'package:flutter_microproy/screens/history_screen.dart';
import 'package:flutter_microproy/services/storage_service.dart';
import 'package:flutter_microproy/widgets/puzzle_tile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'el JSON se guarda y se recupera, y uno dañado no rompe la lectura',
    () async {
      final service = StorageService();
      final won = MatchRecord(
        playerName: 'Ari',
        timeInSeconds: 65,
        moves: 12,
        won: true,
        difficulty: Difficulty.easy,
        date: DateTime.utc(2026, 10, 15, 12),
      );
      await service.saveMatch(won);
      final loaded = await service.loadMatches();
      expect(loaded, hasLength(1));
      expect(loaded.single.playerName, 'Ari');
      expect(loaded.single.timeInSeconds, 65);
      expect(loaded.single.moves, 12);
      expect(loaded.single.won, isTrue);
      expect(loaded.single.difficulty, Difficulty.easy);
      expect(jsonDecode(jsonEncode(won.toJson())), won.toJson());

      SharedPreferences.setMockInitialValues({matchHistoryKey: '{roto'});
      final fresh = StorageService();
      expect(await fresh.loadMatches(), isEmpty);
    },
  );

  testWidgets('una derrota y una victoria quedan en el historial', (
    tester,
  ) async {
    const settings = GameSettings(
      difficulty: Difficulty.easy,
      animationsEnabled: false,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(
          settings: settings,
          playerName: 'Ari',
          initialBoard: [1, 2, 3, 4, 5, 6, 7, 0, 8],
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('surrender')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Rendirse'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(
          settings: settings,
          playerName: 'Ari',
          initialBoard: [1, 2, 3, 4, 5, 6, 7, 0, 8],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is PuzzleTile && widget.number == 8,
      ),
    );
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    final saved = await StorageService(preferences: prefs).loadMatches();
    expect(saved, hasLength(2));
    expect(saved.first.won, isFalse);
    expect(saved.last.won, isTrue);
    expect(saved.last.moves, 1);
    expect(saved.last.playerName, 'Ari');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      MaterialApp(
        home: HistoryScreen(storage: StorageService(preferences: prefs)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ari'), findsNWidgets(2));
    expect(find.text('Ganó'), findsOneWidget);
    expect(find.text('Perdió'), findsOneWidget);
    expect(find.textContaining('Fácil · 3×3'), findsNWidgets(2));
  });
}
