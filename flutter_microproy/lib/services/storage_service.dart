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

/// Lee y escribe el historial. Un JSON dañado se trata como lista vacía.
class StorageService {
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
}
