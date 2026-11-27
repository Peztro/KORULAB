import 'package:flutter/material.dart';

/// Panel de emojis por categorías que inserta el elegido en [controlador],
/// en la posición del cursor.
class SelectorEmojis extends StatefulWidget {
  const SelectorEmojis({
    super.key,
    required this.controlador,
    this.altura = 280,
  });

  final TextEditingController controlador;
  final double altura;

  @override
  State<SelectorEmojis> createState() => _SelectorEmojisState();
}

class _SelectorEmojisState extends State<SelectorEmojis> {
  int _categoria = 0;

  static const _categorias = <(IconData, String, List<String>)>[
    (
      Icons.emoji_emotions_rounded,
      'Caras',
      [
        '😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣', '😊', '😇', //
        '🙂', '😉', '😌', '😍', '🥰', '😘', '😋', '😛', '😜', '🤪', //
        '🤓', '😎', '🥳', '🤩', '🤗', '🤔', '🤭', '🤫', '😐', '😶', //
        '🙄', '😏', '😮', '😯', '😲', '🥺', '😢', '😭', '😤', '😡', //
        '😱', '😨', '😰', '😓', '🥱', '😴', '🤒', '🤧', '😷', '🤯',
      ],
    ),
    (
      Icons.waving_hand_rounded,
      'Gestos',
      [
        '👍', '👎', '👏', '🙌', '👐', '🤝', '🙏', '✌️', '🤞', '🤟', //
        '🤘', '👌', '🤌', '👈', '👉', '👆', '👇', '☝️', '✋', '👋', //
        '💪', '🫶', '❤️', '🧡', '💛', '💚', '💙', '💜', '🤍', '💯', //
        '✨', '⭐', '🌟', '🔥', '💥', '🎉', '🎊', '🏆', '🥇', '✅',
      ],
    ),
    (
      Icons.eco_rounded,
      'Naturaleza',
      [
        '🌱', '🌿', '🍀', '🍃', '🌳', '🌲', '🌴', '🌵', '🌾', '🌻', //
        '🌼', '🌸', '🌺', '🌷', '🍁', '🍂', '🍄', '🌍', '🌎', '🌏', //
        '☀️', '🌤️', '⛅', '🌧️', '⛈️', '🌈', '❄️', '💧', '🌊', '🌙', //
        '🐝', '🦋', '🐞', '🐢', '🐸', '🐦', '🐟', '🐬', '🐻', '🦊', //
        '♻️', '🚲', '🚶', '🔋', '💡', '🚰', '🗑️', '🌞', '🪴', '🐌',
      ],
    ),
    (
      Icons.school_rounded,
      'Objetos',
      [
        '📚', '📖', '✏️', '📝', '📌', '📎', '🔍', '💻', '📱', '🎒', //
        '🧪', '🔬', '🧭', '🗺️', '⏰', '📅', '🎨', '🎵', '🎮', '⚽', //
        '🍎', '🥕', '🥑', '🍌', '🍉', '🥤', '☕', '🍕', '🍪', '🎁',
      ],
    ),
  ];

  void _insertar(String emoji) {
    final c = widget.controlador;
    final texto = c.text;
    final seleccion = c.selection;
    final inicio = seleccion.isValid ? seleccion.start : texto.length;
    final fin = seleccion.isValid ? seleccion.end : texto.length;
    c.value = TextEditingValue(
      text: texto.replaceRange(inicio, fin, emoji),
      selection: TextSelection.collapsed(offset: inicio + emoji.length),
    );
  }

  void _borrar() {
    final c = widget.controlador;
    final texto = c.text;
    if (texto.isEmpty) return;
    final seleccion = c.selection;
    final fin = seleccion.isValid ? seleccion.end : texto.length;
    if (seleccion.isValid && !seleccion.isCollapsed) {
      c.value = TextEditingValue(
        text: texto.replaceRange(seleccion.start, fin, ''),
        selection: TextSelection.collapsed(offset: seleccion.start),
      );
      return;
    }
    if (fin == 0) return;
    // Borra el último carácter completo (un emoji puede ocupar varios).
    final antes = texto.substring(0, fin).characters;
    final nuevoAntes = antes.skipLast(1).toString();
    c.value = TextEditingValue(
      text: nuevoAntes + texto.substring(fin),
      selection: TextSelection.collapsed(offset: nuevoAntes.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (_, _, emojis) = _categorias[_categoria];
    return Container(
      height: widget.altura,
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          Row(
            children: [
              for (final (i, (icono, nombre, _)) in _categorias.indexed)
                Expanded(
                  child: IconButton(
                    tooltip: nombre,
                    isSelected: i == _categoria,
                    selectedIcon: Icon(icono, color: theme.colorScheme.primary),
                    onPressed: () => setState(() => _categoria = i),
                    icon: Icon(
                      icono,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              IconButton(
                tooltip: 'Borrar',
                onPressed: _borrar,
                icon: const Icon(Icons.backspace_outlined),
              ),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 46,
              ),
              itemCount: emojis.length,
              itemBuilder: (context, i) => InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _insertar(emojis[i]),
                child: Center(
                  child: Text(emojis[i], style: const TextStyle(fontSize: 26)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
