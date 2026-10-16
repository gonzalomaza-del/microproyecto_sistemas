/// Modelos compartidos del 15-Puzzle.
///
/// Persona A (lógica y pantallas) y Persona B (persistencia) importan solo
/// este archivo. No contiene widgets, reglas del tablero ni acceso a disco,
/// y no importa Flutter: `puzzle_logic.dart` puede usarlo en tests puros.
library;

/// Claves JSON estables. No renombrarlas: el almacenamiento de Persona B
/// depende de estos nombres.
abstract final class JsonKeys {
  static const String difficulty = 'difficulty';
  static const String tileStyle = 'tileStyle';
  static const String themeMode = 'themeMode';
  static const String soundEnabled = 'soundEnabled';
  static const String animationsEnabled = 'animationsEnabled';
  static const String moves = 'moves';
  static const String timeInSeconds = 'timeInSeconds';
  static const String date = 'date';
  static const String playerName = 'playerName';
  static const String won = 'won';
}

/// Tamaño del tablero. El número de fichas es `size * size - 1`.
enum Difficulty {
  /// 3×3, puzzle de 8 fichas.
  easy,

  /// 4×4, 15-puzzle clásico.
  medium,

  /// 5×5, puzzle de 24 fichas.
  hard;

  /// Lado del tablero: 3, 4 o 5.
  int get size => switch (this) {
    Difficulty.easy => 3,
    Difficulty.medium => 4,
    Difficulty.hard => 5,
  };

  /// Lee el nombre del enum. Si falta o no se reconoce, devuelve [fallback].
  static Difficulty fromJson(
    Object? value, {
    Difficulty fallback = Difficulty.medium,
  }) {
    return _enumFromName(values, value, fallback);
  }
}

/// Apariencia de las fichas. La dibuja `puzzle_tile.dart`, no este archivo.
enum TileStyle {
  /// Muestra el número de la ficha.
  numeric,

  /// Muestra un color distinto por ficha.
  colorful;

  /// Lee el nombre del enum. Si falta o no se reconoce, devuelve [fallback].
  static TileStyle fromJson(
    Object? value, {
    TileStyle fallback = TileStyle.numeric,
  }) {
    return _enumFromName(values, value, fallback);
  }
}

/// Tema elegido por el usuario, sin depender de Flutter.
///
/// La UI lo traduce a ThemeMode: los nombres coinciden (`system`, `light`,
/// `dark`). La conversión no vive aquí para no arrastrar `material.dart`
/// a la lógica del juego.
enum AppThemeMode {
  /// Sigue el tema del sistema.
  system,

  /// Tema claro.
  light,

  /// Tema oscuro.
  dark;

  /// Lee el nombre del enum. Si falta o no se reconoce, devuelve [fallback].
  static AppThemeMode fromJson(
    Object? value, {
    AppThemeMode fallback = AppThemeMode.system,
  }) {
    return _enumFromName(values, value, fallback);
  }
}

/// Ajustes de la partida. Inmutable: un cambio devuelve otra instancia.
class GameSettings {
  /// Crea ajustes. Los valores omitidos son los de una partida nueva.
  const GameSettings({
    this.difficulty = Difficulty.medium,
    this.tileStyle = TileStyle.numeric,
    this.themeMode = AppThemeMode.system,
    this.soundEnabled = true,
    this.animationsEnabled = true,
  });

  /// Ajustes que debe devolver el almacenamiento si aún no hay nada guardado.
  static const GameSettings defaults = GameSettings();

  /// Tamaño y dificultad de la partida.
  final Difficulty difficulty;

  /// Estilo visual de las fichas.
  final TileStyle tileStyle;

  /// Tema de la aplicación. No es el ThemeMode de Flutter.
  final AppThemeMode themeMode;

  /// Si los efectos de sonido están activos.
  final bool soundEnabled;

  /// Si las animaciones de movimiento están activas.
  final bool animationsEnabled;

  /// Copia estos ajustes cambiando solo los campos indicados.
  GameSettings copyWith({
    Difficulty? difficulty,
    TileStyle? tileStyle,
    AppThemeMode? themeMode,
    bool? soundEnabled,
    bool? animationsEnabled,
  }) {
    return GameSettings(
      difficulty: difficulty ?? this.difficulty,
      tileStyle: tileStyle ?? this.tileStyle,
      themeMode: themeMode ?? this.themeMode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
    );
  }

  /// Mapa JSON con [JsonKeys]. No incluye campos nulos.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      JsonKeys.difficulty: difficulty.name,
      JsonKeys.tileStyle: tileStyle.name,
      JsonKeys.themeMode: themeMode.name,
      JsonKeys.soundEnabled: soundEnabled,
      JsonKeys.animationsEnabled: animationsEnabled,
    };
  }

  /// Reconstruye los ajustes. Un mapa nulo, mal formado o con valores
  /// desconocidos no lanza: cada campo inválido usa su valor por defecto.
  factory GameSettings.fromJson(Object? json) {
    final map = _asJsonMap(json);
    if (map == null) return defaults;
    return GameSettings(
      difficulty: Difficulty.fromJson(map[JsonKeys.difficulty]),
      tileStyle: TileStyle.fromJson(map[JsonKeys.tileStyle]),
      themeMode: AppThemeMode.fromJson(map[JsonKeys.themeMode]),
      soundEnabled: _readBool(map[JsonKeys.soundEnabled], true),
      animationsEnabled: _readBool(map[JsonKeys.animationsEnabled], true),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GameSettings &&
        other.difficulty == difficulty &&
        other.tileStyle == tileStyle &&
        other.themeMode == themeMode &&
        other.soundEnabled == soundEnabled &&
        other.animationsEnabled == animationsEnabled;
  }

  @override
  int get hashCode => Object.hash(
    difficulty,
    tileStyle,
    themeMode,
    soundEnabled,
    animationsEnabled,
  );

  @override
  String toString() {
    return 'GameSettings('
        'difficulty: $difficulty, '
        'tileStyle: $tileStyle, '
        'themeMode: $themeMode, '
        'soundEnabled: $soundEnabled, '
        'animationsEnabled: $animationsEnabled)';
  }
}

/// Un récord terminado. Inmutable. No decide si es el mejor: solo guarda datos.
class HighScore {
  /// Crea un récord. [moves] y [timeInSeconds] deben ser cero o mayores.
  const HighScore({
    required this.difficulty,
    required this.moves,
    required this.timeInSeconds,
    required this.date,
  });

  /// Fecha usada cuando el JSON no trae una fecha válida.
  static final DateTime unsetDate = DateTime.utc(1970);

  /// Dificultad en la que se consiguió el récord.
  final Difficulty difficulty;

  /// Movimientos usados. Nunca es negativo al salir de [fromJson].
  final int moves;

  /// Duración de la partida, en segundos enteros.
  final int timeInSeconds;

  /// Momento en que se registró, en UTC si viene de [fromJson].
  final DateTime date;

  /// Un objeto JSON. [date] se guarda en ISO-8601 UTC.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      JsonKeys.difficulty: difficulty.name,
      JsonKeys.moves: moves,
      JsonKeys.timeInSeconds: timeInSeconds,
      JsonKeys.date: date.toUtc().toIso8601String(),
    };
  }

  /// Reconstruye un récord. Si el mapa es nulo o inválido, no lanza:
  /// dificultad media, 0 movimientos, 0 segundos y [unsetDate].
  factory HighScore.fromJson(Object? json) {
    final map = _asJsonMap(json);
    if (map == null) {
      return HighScore(
        difficulty: Difficulty.medium,
        moves: 0,
        timeInSeconds: 0,
        date: unsetDate,
      );
    }
    return HighScore(
      difficulty: Difficulty.fromJson(map[JsonKeys.difficulty]),
      moves: _readInt(map[JsonKeys.moves], 0),
      timeInSeconds: _readInt(map[JsonKeys.timeInSeconds], 0),
      date: _readDate(map[JsonKeys.date]),
    );
  }

  /// Lee una lista JSON. Ignora elementos que no son objetos.
  /// La lista devuelta no se puede modificar; para agregar un récord, cópiala.
  static List<HighScore> listFromJson(Object? json) {
    if (json is! List) return const [];
    final scores = <HighScore>[];
    for (final item in json) {
      final map = _asJsonMap(item);
      if (map == null) continue;
      scores.add(HighScore.fromJson(map));
    }
    return List.unmodifiable(scores);
  }

  /// Serializa la lista completa. Es el formato que debe guardarse en disco.
  static List<Map<String, dynamic>> listToJson(List<HighScore> scores) {
    return [for (final score in scores) score.toJson()];
  }

  @override
  bool operator ==(Object other) {
    return other is HighScore &&
        other.difficulty == difficulty &&
        other.moves == moves &&
        other.timeInSeconds == timeInSeconds &&
        other.date == date;
  }

  @override
  int get hashCode => Object.hash(difficulty, moves, timeInSeconds, date);

  @override
  String toString() {
    return 'HighScore('
        'difficulty: $difficulty, '
        'moves: $moves, '
        'timeInSeconds: $timeInSeconds, '
        'date: $date)';
  }
}

/// Una partida terminada, ganada o perdida. No es un récord: es el historial.
class MatchRecord {
  /// Crea el registro de una partida ya cerrada.
  const MatchRecord({
    required this.playerName,
    required this.timeInSeconds,
    required this.moves,
    required this.won,
    required this.difficulty,
    required this.date,
  });

  /// Nombre visible. Vacío si el JSON no lo trae.
  final String playerName;

  /// Segundos contados desde el primer movimiento.
  final int timeInSeconds;

  /// Movimientos válidos.
  final int moves;

  /// `true` si el tablero quedó resuelto.
  final bool won;

  /// Dificultad con la que se jugó.
  final Difficulty difficulty;

  /// Momento del registro, en UTC si viene de [fromJson].
  final DateTime date;

  /// Objeto JSON estable. [date] va en ISO-8601 UTC.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      JsonKeys.playerName: playerName,
      JsonKeys.timeInSeconds: timeInSeconds,
      JsonKeys.moves: moves,
      JsonKeys.won: won,
      JsonKeys.difficulty: difficulty.name,
      JsonKeys.date: date.toUtc().toIso8601String(),
    };
  }

  /// Reconstruye una partida. Un JSON nulo o roto no lanza.
  factory MatchRecord.fromJson(Object? json) {
    final map = _asJsonMap(json);
    if (map == null) {
      return MatchRecord(
        playerName: '',
        timeInSeconds: 0,
        moves: 0,
        won: false,
        difficulty: Difficulty.medium,
        date: HighScore.unsetDate,
      );
    }
    final name = map[JsonKeys.playerName];
    return MatchRecord(
      playerName: name is String ? name.trim() : '',
      timeInSeconds: _readInt(map[JsonKeys.timeInSeconds], 0),
      moves: _readInt(map[JsonKeys.moves], 0),
      won: _readBool(map[JsonKeys.won], false),
      difficulty: Difficulty.fromJson(map[JsonKeys.difficulty]),
      date: _readDate(map[JsonKeys.date]),
    );
  }

  /// Lee una lista JSON. Ignora elementos que no son objetos.
  static List<MatchRecord> listFromJson(Object? json) {
    if (json is! List) return const [];
    final records = <MatchRecord>[];
    for (final item in json) {
      if (_asJsonMap(item) == null) continue;
      records.add(MatchRecord.fromJson(item));
    }
    return List.unmodifiable(records);
  }

  /// Serializa la lista completa, en el orden en que debe guardarse.
  static List<Map<String, dynamic>> listToJson(List<MatchRecord> records) {
    return [for (final record in records) record.toJson()];
  }
}

/// Contrato de persistencia. Persona A depende de esta interfaz;
/// no debe importar la implementación.
///
/// Persona B la implementa en `lib/services/storage_service.dart`.
/// Ninguna de las dos personas edita el archivo de la otra.
abstract interface class GameStorage {
  /// Ajustes guardados. Si no hay datos, devuelve [GameSettings.defaults].
  /// No devuelve null.
  Future<GameSettings> loadSettings();

  /// Reemplaza los ajustes guardados.
  Future<void> saveSettings(GameSettings settings);

  /// Todos los récords. Si no hay datos, devuelve una lista vacía.
  /// No devuelve null. Filtrar por dificultad le corresponde a quien llama.
  Future<List<HighScore>> loadHighScores();

  /// Reemplaza la lista completa. No agrega un elemento por su cuenta.
  Future<void> saveHighScores(List<HighScore> scores);
}

// Persona B — referencia, sin implementación en este archivo.
//
// Archivo propio: lib/services/storage_service.dart
// Implementar GameStorage y nada más de este contrato:
// - Cargar y guardar GameSettings con toJson/fromJson.
// - Guardar los récords con HighScore.listToJson y leerlos con listFromJson.
// - Si no hay archivo o el JSON está dañado, devolver defaults o lista vacía.
// - No convertir AppThemeMode a ThemeMode aquí; eso lo hace la UI.
// - main.dart queda a cargo de Persona B: inyecta GameStorage y aplica el tema.
//
// Regla de récord: isNewHighScore en puzzle_logic.dart.
// Misma dificultad, gana menos movimientos; si empatan, menos tiempo.
// Un empate exacto no es récord nuevo. El storage solo guarda la lista.

T _enumFromName<T extends Enum>(List<T> values, Object? raw, T fallback) {
  if (raw is T) return raw;
  if (raw is! String) return fallback;
  final name = raw.trim().toLowerCase();
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}

Map<String, dynamic>? _asJsonMap(Object? json) {
  if (json is! Map) return null;
  final map = <String, dynamic>{};
  for (final entry in json.entries) {
    final key = entry.key;
    if (key is! String) return null;
    map[key] = entry.value;
  }
  return map;
}

bool _readBool(Object? value, bool fallback) {
  if (value is bool) return value;
  if (value is! String) return fallback;
  return switch (value.trim().toLowerCase()) {
    'true' => true,
    'false' => false,
    _ => fallback,
  };
}

int _readInt(Object? value, int fallback) {
  final int? parsed;
  if (value is int) {
    parsed = value;
  } else if (value is num && value == value.roundToDouble()) {
    parsed = value.toInt();
  } else if (value is String) {
    parsed = int.tryParse(value.trim());
  } else {
    parsed = null;
  }
  if (parsed == null || parsed < 0) return fallback;
  return parsed;
}

DateTime _readDate(Object? value) {
  if (value is DateTime) return value.toUtc();
  if (value is String) {
    return DateTime.tryParse(value.trim())?.toUtc() ?? HighScore.unsetDate;
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }
  return HighScore.unsetDate;
}
