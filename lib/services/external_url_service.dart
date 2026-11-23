import 'dart:io';

/// Lanzador seguro de URLs externas mediante `xdg-open` (compatible con Linux nativo y Flatpak portal).
class ExternalUrlService {
  ExternalUrlService._();

  static Future<bool> openUrl(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null) return false;
    final scheme = uri.scheme.toLowerCase();
    if ((scheme != 'https' && scheme != 'http') || uri.host.isEmpty) {
      return false;
    }

    try {
      await Process.start('xdg-open', [uri.toString()]);
      return true;
    } catch (_) {
      return false;
    }
  }
}

