/// Ficha visual del tablero. No decide si el movimiento es legal.
library;

import 'package:flutter/material.dart';

import 'package:flutter_microproy/models/models.dart';

/// Separación de tono para que dos números seguidos no compartan color.
const double _hueStep = 137.508;

/// Pieza del 15-Puzzle. Llena la celda que le asigne el padre.
class PuzzleTile extends StatelessWidget {
  /// Crea la ficha. Si [isEmpty] es verdadero o [number] es 0, no se dibuja
  /// ni recibe toques, aunque [onTap] no sea null.
  const PuzzleTile({
    required this.number,
    required this.style,
    required this.isEmpty,
    this.onTap,
    super.key,
  });

  /// Número visible. `0` se trata como vacío.
  final int number;

  /// Estilo numérico o de color.
  final TileStyle style;

  /// Callback del toque. Se ignora en el vacío.
  final VoidCallback? onTap;

  /// Si esta celda es el hueco del tablero.
  final bool isEmpty;

  bool get _hidden => isEmpty || number == 0;

  @override
  Widget build(BuildContext context) {
    if (_hidden) return const SizedBox.expand();

    final theme = Theme.of(context);
    final background = switch (style) {
      TileStyle.numeric => theme.colorScheme.surfaceContainerHighest,
      TileStyle.colorful => _colorForNumber(number),
    };
    final foreground = switch (style) {
      TileStyle.numeric => theme.colorScheme.onSurface,
      TileStyle.colorful => _foregroundOn(background),
    };
    final border = switch (style) {
      TileStyle.numeric => theme.colorScheme.outlineVariant,
      TileStyle.colorful => foreground.withValues(alpha: 0.28),
    };

    return SizedBox.expand(
      child: Semantics(
        button: onTap != null,
        label: 'Ficha $number',
        child: Material(
          color: background,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: border),
          ),
          child: InkWell(
            onTap: onTap,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final side = constraints.biggest.shortestSide;
                final fontSize = side.isFinite && side > 0 ? side * 0.4 : 24.0;
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$number',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          color: foreground,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Color estable por número. El paso de tono separa fichas vecinas.
Color _colorForNumber(int number) {
  final hue = (((number - 1) * _hueStep) % 360 + 360) % 360;
  return HSLColor.fromAHSL(1, hue, 0.62, 0.46).toColor();
}

Color _foregroundOn(Color background) {
  final brightness = ThemeData.estimateBrightnessForColor(background);
  return brightness == Brightness.dark ? Colors.white : Colors.black;
}
