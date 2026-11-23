import 'dart:convert';
import 'dart:io';

/// Servicio para guardar y recuperar nombres personalizados (apodos) de las huellas.
/// Respeta XDG_CONFIG_HOME (compatible de forma nativa con entornos Flatpak).
class AliasService {
  static String get configDirectoryPath {
    final xdgConfig = Platform.environment['XDG_CONFIG_HOME'];
    if (xdgConfig != null && xdgConfig.trim().isNotEmpty) {
      return '$xdgConfig/fprint-manager';
    }
    final home = Platform.environment['HOME'] ?? '';
    return '$home/.config/fprint-manager';
  }

  static String get _filePath => '$configDirectoryPath/finger_aliases.json';

  /// Carga el mapa de apodos guardados: { 'right-index-finger': 'Dedo de Login' }.
  static Future<Map<String, String>> loadAliases() async {
    try {
      final file = File(_filePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isEmpty) return {};
        final dynamic decoded = jsonDecode(content);
        if (decoded is Map<String, dynamic>) {
          return decoded.map((key, value) => MapEntry(key, value.toString()));
        }
      }
    } catch (_) {}
    return {};
  }

  /// Guarda o actualiza el nombre personalizado para un dedo específico.
  static Future<bool> saveAlias(String fingerCode, String customName) async {
    try {
      final dir = Directory(configDirectoryPath);
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

  /// Elimina el apodo de un dedo específico.
  static Future<void> removeAlias(String fingerCode) async {
    try {
      final aliases = await loadAliases();
      if (aliases.remove(fingerCode) != null) {
        final file = File(_filePath);
        await file.writeAsString(jsonEncode(aliases));
      }
    } catch (_) {}
  }

  /// Limpia todos los apodos locales tras eliminar todas las huellas.
  static Future<void> clearAllAliases() async {
    try {
      final file = File(_filePath);
      if (await file.exists()) {
        await file.writeAsString('{}');
      }
    } catch (_) {}
  }
}
