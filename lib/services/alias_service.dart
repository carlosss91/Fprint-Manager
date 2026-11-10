import 'dart:convert';
import 'dart:io';

/// Servicio para guardar y recuperar nombres personalizados (apodos) de las huellas registradas.
/// Almacena los datos en ~/.config/fprint-manager/finger_aliases.json cumpliendo el estándar XDG.
class AliasService {
  static String get _configDirPath {
    final home = Platform.environment['HOME'] ?? '';
    return '$home/.config/fprint-manager';
  }

  static String get _filePath => '$_configDirPath/finger_aliases.json';

  /// Carga el mapa de apodos guardados: { 'right-index-finger': 'Dedo de Login' }
  static Future<Map<String, String>> loadAliases() async {
    try {
      final file = File(_filePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        final Map<String, dynamic> decoded = jsonDecode(content);
        return decoded.map((key, value) => MapEntry(key, value.toString()));
      }
    } catch (_) {}
    return {};
  }

  /// Guarda o actualiza el nombre personalizado para un dedo específico.
  static Future<bool> saveAlias(String fingerCode, String customName) async {
    try {
      final dir = Directory(_configDirPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final aliases = await loadAliases();
      if (customName.trim().isEmpty) {
        aliases.remove(fingerCode);
      } else {
        aliases[fingerCode] = customName.trim();
      }

      final file = File(_filePath);
      await file.writeAsString(jsonEncode(aliases));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Elimina el apodo de un dedo cuando se elimina la huella.
  static Future<void> removeAlias(String fingerCode) async {
    try {
      final aliases = await loadAliases();
      if (aliases.containsKey(fingerCode)) {
        aliases.remove(fingerCode);
        final file = File(_filePath);
        await file.writeAsString(jsonEncode(aliases));
      }
    } catch (_) {}
  }
}

