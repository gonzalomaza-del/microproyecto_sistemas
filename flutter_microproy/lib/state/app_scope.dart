/// Datos compartidos por toda la app: ajustes actuales y almacenamiento.
library;

import 'package:flutter/widgets.dart';

import 'package:flutter_microproy/models/models.dart';
import 'package:flutter_microproy/services/storage_service.dart';

/// Deja los ajustes y el storage disponibles para cualquier pantalla.
///
/// Uso: `AppScope.of(context).settings`. Cuando los ajustes cambian,
/// las pantallas que lo leen se vuelven a dibujar solas.
class AppScope extends InheritedWidget {
  /// Crea el scope. Lo usa solo `main.dart`.
  const AppScope({
    required this.settings,
    required this.storage,
    required this.onSettingsChanged,
    required super.child,
    super.key,
  });

  /// Ajustes vigentes.
  final GameSettings settings;

  /// Persistencia de ajustes, récords e historial.
  final StorageService storage;

  /// Aplica y guarda ajustes nuevos.
  final ValueChanged<GameSettings> onSettingsChanged;

  /// Busca el scope más cercano. Falla si la pantalla no está dentro de la app.
  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No hay un AppScope encima de este widget.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) {
    return oldWidget.settings != settings;
  }
}
