import 'package:flutter/material.dart';

import 'package:flutter_microproy/models/models.dart';
import 'package:flutter_microproy/screens/home_menu_screen.dart';
import 'package:flutter_microproy/services/storage_service.dart';
import 'package:flutter_microproy/state/app_scope.dart';
import 'package:flutter_microproy/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const storage = StorageService();
  final settings = await storage.loadSettings();
  runApp(MainApp(storage: storage, initialSettings: settings));
}

/// Raíz de la app. Guarda los ajustes vigentes y aplica el tema.
class MainApp extends StatefulWidget {
  /// Los valores por defecto permiten `const MainApp()` en las pruebas.
  const MainApp({
    this.storage = const StorageService(),
    this.initialSettings = GameSettings.defaults,
    super.key,
  });

  /// Persistencia compartida por todas las pantallas.
  final StorageService storage;

  /// Ajustes leídos al arrancar.
  final GameSettings initialSettings;

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late GameSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
  }

  /// Aplica los ajustes al instante y luego los guarda.
  Future<void> _changeSettings(GameSettings next) async {
    setState(() => _settings = next);
    try {
      await widget.storage.saveSettings(next);
    } on Object {
      // Si no se pudo guardar, el cambio sigue aplicado en esta sesión.
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      settings: _settings,
      storage: widget.storage,
      onSettingsChanged: _changeSettings,
      child: MaterialApp(
        title: '15-Puzzle Flutter',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: AppTheme.toThemeMode(_settings.themeMode),
        home: const HomeMenuScreen(),
      ),
    );
  }
}
