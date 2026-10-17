/// Ajustes del juego: dificultad, tema, estilo de fichas y animaciones.
library;

import 'package:flutter/material.dart';

import 'package:flutter_microproy/models/models.dart';
import 'package:flutter_microproy/state/app_scope.dart';

/// Pantalla de configuración. Cada cambio se aplica y se guarda al instante.
///
/// Es StatefulWidget porque guarda la selección actual mientras el usuario
/// la modifica, y la redibuja con setState.
class SettingsScreen extends StatefulWidget {
  /// Crea la pantalla. Lee y escribe los ajustes a través de [AppScope].
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  GameSettings? _settings;
  ValueChanged<GameSettings>? _onChanged;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = AppScope.of(context);
    _settings ??= scope.settings;
    _onChanged = scope.onSettingsChanged;
  }

  /// Actualiza la pantalla y avisa a la app para que aplique y guarde.
  void _update(GameSettings next) {
    setState(() => _settings = next);
    _onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings!;
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const _SectionTitle('Dificultad por defecto'),
                SegmentedButton<Difficulty>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: Difficulty.easy,
                      label: Text('Fácil'),
                      tooltip: '3×3, 8 fichas',
                    ),
                    ButtonSegment(
                      value: Difficulty.medium,
                      label: Text('Medio'),
                      tooltip: '4×4, 15 fichas',
                    ),
                    ButtonSegment(
                      value: Difficulty.hard,
                      label: Text('Difícil'),
                      tooltip: '5×5, 24 fichas',
                    ),
                  ],
                  selected: {settings.difficulty},
                  onSelectionChanged: (selection) {
                    _update(settings.copyWith(difficulty: selection.first));
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Fácil 3×3 · Medio 4×4 · Difícil 5×5',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const _SectionTitle('Tema'),
                SegmentedButton<AppThemeMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: AppThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined),
                      label: Text('Claro'),
                    ),
                    ButtonSegment(
                      value: AppThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined),
                      label: Text('Oscuro'),
                    ),
                    ButtonSegment(
                      value: AppThemeMode.system,
                      icon: Icon(Icons.brightness_auto_outlined),
                      label: Text('Auto'),
                      tooltip: 'Igual que el sistema',
                    ),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (selection) {
                    _update(settings.copyWith(themeMode: selection.first));
                  },
                ),
                const _SectionTitle('Estilo de las fichas'),
                SegmentedButton<TileStyle>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: TileStyle.numeric,
                      icon: Icon(Icons.pin_outlined),
                      label: Text('Numérico'),
                    ),
                    ButtonSegment(
                      value: TileStyle.colorful,
                      icon: Icon(Icons.palette_outlined),
                      label: Text('Colorido'),
                    ),
                  ],
                  selected: {settings.tileStyle},
                  onSelectionChanged: (selection) {
                    _update(settings.copyWith(tileStyle: selection.first));
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Animaciones'),
                  subtitle: const Text('Movimiento suave de las fichas'),
                  value: settings.animationsEnabled,
                  onChanged: (value) {
                    _update(settings.copyWith(animationsEnabled: value));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Título pequeño encima de cada grupo de opciones.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
