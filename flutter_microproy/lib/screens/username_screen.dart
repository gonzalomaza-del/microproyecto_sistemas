/// Pantalla para pedir el nombre antes de elegir dificultad.
library;

import 'package:flutter/material.dart';

import 'package:flutter_microproy/screens/difficulty_selection_screen.dart';

/// Longitud máxima visible sobre el contador de movimientos.
const int maxPlayerNameLength = 24;

/// Pide un nombre no vacío y continúa a la selección de dificultad.
class UsernameScreen extends StatefulWidget {
  /// Crea la pantalla de nombre.
  const UsernameScreen({super.key});

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continue() {
    if (_formKey.currentState?.validate() != true) return;
    final name = _controller.text.trim();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DifficultySelectionScreen(playerName: name),
      ),
    );
  }

  String? _validate(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Escribe un nombre.';
    if (name.length > maxPlayerNameLength) {
      return 'Máximo $maxPlayerNameLength caracteres.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Tu nombre')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¿Cómo te llamas?',
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'El nombre se verá durante la partida.',
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      key: const Key('username-field'),
                      controller: _controller,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      textCapitalization: TextCapitalization.words,
                      maxLength: maxPlayerNameLength,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de usuario',
                        border: OutlineInputBorder(),
                      ),
                      validator: _validate,
                      onFieldSubmitted: (_) => _continue(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const Key('username-continue'),
                        onPressed: _continue,
                        child: const Text('Continuar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
