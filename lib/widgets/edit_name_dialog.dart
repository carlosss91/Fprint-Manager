import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../models/fingerprint_item.dart';
import '../theme/app_theme.dart';

/// Diálogo minimalista estilo elementary OS para editar el apodo de una huella registrada.
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
    final l10n = AppLocalizations.of(context)!;
    final localizedFingerName = l10n.fingerDisplayName(widget.item.fingerCode);
    final isCustomized =
        widget.item.name != widget.item.fingerName && widget.item.name != localizedFingerName;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.edit_outlined, color: AppColors.primary(context), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.editNameTitle,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 390,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                Text(
                  l10n.assignedFingerLabel,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                Text(
                  localizedFingerName,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.sidebar(context),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Text(
                    widget.item.fingerCode,
                    style: const TextStyle(fontSize: 10.5, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              l10n.customNameLabel,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: l10n.customNameHint,
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                suffixIcon: IconButton(
                  tooltip: l10n.clearFieldTooltip,
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
                  label: Text(
                    l10n.restoreOriginalBtn(localizedFingerName),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelBtn),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(l10n.saveBtn),
        ),
      ],
    );
  }
}
