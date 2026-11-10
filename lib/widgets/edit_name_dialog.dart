import 'package:flutter/material.dart';
import '../models/fingerprint_item.dart';

/// Diálogo minimalista estilo elementary OS para editar el nombre o apodo de una huella registrada.
class EditNameDialog extends StatefulWidget {
  final FingerprintItem item;
  final ValueChanged<String> onSaved;

  const EditNameDialog({
    super.key,
    required this.item,
    required this.onSaved,
  });

  @override
  State<EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<EditNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.item.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final text = _controller.text.trim();
    widget.onSaved(text.isEmpty ? widget.item.fingerName : text);
    Navigator.of(context).pop();
  }

  void _resetToDefault() {
    setState(() {
      _controller.text = widget.item.fingerName;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCustomized = widget.item.name != widget.item.fingerName;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.edit_outlined, color: Color(0xFF3584E4), size: 22),
          SizedBox(width: 10),
          Text('Personalizar Nombre de Huella', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Dedo asignado: ', style: TextStyle(fontSize: 12.5, color: Colors.grey)),
                Text(
                  widget.item.fingerName,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.item.fingerCode,
                    style: const TextStyle(fontSize: 10.5, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Nombre o etiqueta descriptiva:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Ej. Dedo principal para sudo',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                suffixIcon: IconButton(
                  tooltip: 'Limpiar campo',
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => _controller.clear(),
                ),
              ),
              onSubmitted: (_) => _save(),
            ),
            if (isCustomized) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: _resetToDefault,
                  icon: const Icon(Icons.restore_rounded, size: 16),
                  label: const Text('Restablecer al nombre estándar del sistema', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF3584E4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

