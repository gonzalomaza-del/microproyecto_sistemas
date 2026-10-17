/// Historial local de partidas.
///
/// Se guarda un JSON en shared_preferences, clave [matchHistoryKey].
/// En Chrome eso vive en localStorage de este navegador. En el celular,
/// en el almacén de la app. No es un archivo del proyecto.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_microproy/models/models.dart';

/// Clave única de la lista. No renombrarla: los datos ya guardados dependen de ella.
const String matchHistoryKey = 'match_history';

/// Clave de los ajustes del juego.
const String settingsKey = 'game_settings';

/// Clave de la lista de récords.
const String highScoresKey = 'high_scores';

/// Lee y escribe el historial. Un JSON dañado se trata como lista vacía.
class StorageService implements GameStorage {
  /// Crea el servicio. [preferences] se puede inyectar en pruebas.
  const StorageService({this.preferences});

  /// Almacén ya abierto. Si es null, se usa el de la plataforma.
  final SharedPreferences? preferences;

  Future<SharedPreferences> get _store async {
    return preferences ?? SharedPreferences.getInstance();
  }

  /// Partidas guardadas, de la más antigua a la más nueva.
  Future<List<MatchRecord>> loadMatches() async {
    try {
      final store = await _store;
      final raw = store.getString(matchHistoryKey);
      if (raw == null || raw.trim().isEmpty) return const [];
      return MatchRecord.listFromJson(jsonDecode(raw));
    } on Object {
      return const [];
    }
  }

  /// Agrega una partida al final de la lista y la vuelve a escribir completa.
  Future<void> saveMatch(MatchRecord match) async {
    final store = await _store;
    final current = await loadMatches();
    final encoded = jsonEncode(MatchRecord.listToJson([...current, match]));
    final saved = await store.setString(matchHistoryKey, encoded);
    if (!saved) {
      throw StateError('No se pudo guardar el historial.');
    }
  }

  /// Ajustes guardados. Si no hay nada o el JSON está dañado, usa los de fábrica.
  @override
  Future<GameSettings> loadSettings() async {
    try {
      final store = await _store;
      final raw = store.getString(settingsKey);
      if (raw == null || raw.trim().isEmpty) return GameSettings.defaults;
      return GameSettings.fromJson(jsonDecode(raw));
    } on Object {
      return GameSettings.defaults;
    }
  }

  /// Guarda los ajustes, reemplazando los anteriores.
  @override
  Future<void> saveSettings(GameSettings settings) async {
    final store = await _store;
    final encoded = jsonEncode(settings.toJson());
    final saved = await store.setString(settingsKey, encoded);
    if (!saved) {
      throw StateError('No se pudieron guardar los ajustes.');
    }
  }

  /// Récords guardados de todas las dificultades. Lista vacía si no hay o si está dañado.
  @override
  Future<List<HighScore>> loadHighScores() async {
    try {
      final store = await _store;
      final raw = store.getString(highScoresKey);
      if (raw == null || raw.trim().isEmpty) return const [];
      return HighScore.listFromJson(jsonDecode(raw));
    } on Object {
      return const [];
    }
  }

  /// Reemplaza la lista completa de récords.
  @override
  Future<void> saveHighScores(List<HighScore> scores) async {
    final store = await _store;
    final encoded = jsonEncode(HighScore.listToJson(scores));
    final saved = await store.setString(highScoresKey, encoded);
    if (!saved) {
      throw StateError('No se pudieron guardar los récords.');
    }
  }
}
