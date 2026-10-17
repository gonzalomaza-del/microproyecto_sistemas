import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_microproy/logic/puzzle_logic.dart';
import 'package:flutter_microproy/models/models.dart';
import 'package:flutter_microproy/screens/game_over_screen.dart';
import 'package:flutter_microproy/screens/game_screen.dart';
import 'package:flutter_microproy/widgets/puzzle_tile.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const settings = GameSettings(
    difficulty: Difficulty.easy,
    animationsEnabled: false,
  );

  test('un empate no es récord y la primera marca sí', () {
    final first = HighScore(
      difficulty: Difficulty.easy,
      moves: 10,
      timeInSeconds: 40,
      date: DateTime.utc(2026),
    );
    expect(isNewHighScore(first, const []), isTrue);

    final equal = HighScore(
      difficulty: Difficulty.easy,
      moves: 10,
      timeInSeconds: 40,
      date: DateTime.utc(2026, 1, 2),
    );
    expect(isNewHighScore(equal, [first]), isFalse);

    final better = HighScore(
      difficulty: Difficulty.easy,
      moves: 9,
      timeInSeconds: 90,
      date: DateTime.utc(2026, 1, 3),
    );
    expect(isNewHighScore(better, [first]), isTrue);
  });

  testWidgets('muestra victoria, tiempo y récord', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GameOverScreen(
          isWin: true,
          moves: 12,
          timeInSeconds: 125,
          difficulty: Difficulty.easy,
          isNewRecord: true,
          settings: settings,
          playerName: 'Ana',
          result: GameResult.victory,
        ),
      ),
    );

    expect(find.text('Victoria'), findsOneWidget);
    expect(find.text('Tiempo: 02:05'), findsOneWidget);
    expect(find.text('¡Nuevo récord!'), findsOneWidget);
    expect(find.text('Movimientos: 12'), findsOneWidget);
  });

  testWidgets('una derrota no muestra récord', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GameOverScreen(
          isWin: false,
          moves: 3,
          timeInSeconds: 180,
          difficulty: Difficulty.easy,
          isNewRecord: true,
          settings: settings,
          playerName: 'Ana',
          result: GameResult.timeUp,
        ),
      ),
    );

    expect(find.text('Derrota'), findsOneWidget);
    expect(find.text('Se acabó el tiempo.'), findsOneWidget);
    expect(find.text('¡Nuevo récord!'), findsNothing);
  });

  testWidgets('los botones vuelven a jugar y al menú', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(
          body: Center(child: Text('Menú', key: Key('menu-title'))),
        ),
      ),
    );
    final context = tester.element(find.byType(Scaffold));
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameOverScreen(
          isWin: false,
          moves: 0,
          timeInSeconds: 0,
          difficulty: Difficulty.easy,
          isNewRecord: false,
          settings: settings,
          playerName: 'Ana',
          result: GameResult.surrendered,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Te rendiste.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('play-again')));
    await tester.pumpAndSettle();
    expect(find.text('15-Puzzle'), findsOneWidget);
    expect(find.byType(GameScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('surrender')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Rendirse'));
    await tester.pumpAndSettle();
    expect(find.text('Derrota'), findsOneWidget);

    await tester.tap(find.byKey(const Key('main-menu')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('menu-title')), findsOneWidget);
  });

  testWidgets('guardar un récord real desde la partida', (tester) async {
    final storage = _MemoryStorage();
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          settings: settings,
          playerName: 'Ana',
          storage: storage,
          initialBoard: const [1, 2, 3, 4, 5, 6, 7, 0, 8],
        ),
      ),
    );

    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is PuzzleTile && widget.number == 8,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Victoria'), findsOneWidget);
    expect(find.text('¡Nuevo récord!'), findsOneWidget);
    expect(storage.saved, hasLength(1));
    expect(storage.saved.single.moves, 1);
  });

  testWidgets('la flecha atrás pide confirmación y puede cancelarse', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const GameScreen(
                        settings: settings,
                        playerName: 'Ari',
                      ),
                    ),
                  );
                },
                child: const Text('Entrar'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('back')));
    await tester.pumpAndSettle();
    expect(find.text('¿Desea salir de la partida?'), findsOneWidget);

    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();
    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.text('Derrota'), findsNothing);

    await tester.tap(find.byKey(const Key('back')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sí'));
    await tester.pumpAndSettle();
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Derrota'), findsNothing);
  });
}

class _MemoryStorage implements GameStorage {
  List<HighScore> saved = const [];

  @override
  Future<GameSettings> loadSettings() async => GameSettings.defaults;

  @override
  Future<void> saveSettings(GameSettings settings) async {}

  @override
  Future<List<HighScore>> loadHighScores() async => saved;

  @override
  Future<void> saveHighScores(List<HighScore> scores) async {
    saved = scores;
  }
}
