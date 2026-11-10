import 'dart:io';
import '../models/fingerprint_item.dart';
import 'alias_service.dart';

/// Servicio para interactuar de forma segura con fprintd en Linux Desktop.
class FprintService {
  /// Retorna el usuario del sistema actual.
  static String getUsername() {
    return Platform.environment['USER'] ?? 'chals';
  }

  /// Lista las huellas registradas del usuario mediante fprintd-list combinadas con los apodos locales.
  static Future<List<FingerprintItem>> listEnrolledFingers() async {
    try {
      final user = getUsername();
      final result = await Process.run('fprintd-list', [user]);
      final aliases = await AliasService.loadAliases();

      if (result.exitCode == 0) {
        final matches = RegExp(r'#\d+:\s+([\w-]+)').allMatches(result.stdout.toString());
        final list = <FingerprintItem>[];
        int index = 0;
        for (final m in matches) {
          final code = m.group(1)!;
          final defaultName = FingerprintItem.getFriendlyName(code);
          final customName = aliases[code] ?? defaultName;

          list.add(
            FingerprintItem(
              id: 'fp-0$index',
              name: customName,
              fingerCode: code,
              fingerName: defaultName,
            ),
          );
          index++;
        }
        return list;
      }
    } catch (_) {}
    return [];
  }

  /// Actualiza el nombre personalizado de una huella existente.
  static Future<bool> updateFingerName(String fingerCode, String newName) async {
    return AliasService.saveAlias(fingerCode, newName);
  }

  /// Verifica si el módulo pam_fprintd está activado y no comentado en /etc/pam.d/common-auth.
  static Future<bool> isPamAuthenticationEnabled() async {
    try {
      final file = File('/etc/pam.d/common-auth');
      if (await file.exists()) {
        final lines = await file.readAsLines();
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.contains('pam_fprintd.so') && !trimmed.startsWith('#')) {
            return true;
          }
        }
      }
    } catch (_) {}
    return false;
  }

  /// Habilita o deshabilita la autenticación por huella para login, bloqueo y sudo en el sistema.
  static Future<bool> setPamAuthenticationEnabled(bool enable) async {
    try {
      final flag = enable ? '--enable' : '--disable';
      final result = await Process.run('pkexec', ['pam-auth-update', flag, 'fprintd']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Obtiene el número de etapas requeridas para el sensor actual mediante D-Bus.
  static Future<int> getNumEnrollStages() async {
    try {
      final result = await Process.run('gdbus', [
        'call',
        '--system',
        '--dest',
        'net.reactivated.Fprint',
        '--object-path',
        '/net/reactivated/Fprint/Device/0',
        '--method',
        'org.freedesktop.DBus.Properties.Get',
        'net.reactivated.Fprint.Device',
        'num-enroll-stages',
      ]);
      if (result.exitCode == 0) {
        final match = RegExp(r'<(\d+)>').firstMatch(result.stdout.toString());
        if (match != null) {
          return int.parse(match.group(1)!);
        }
      }
    } catch (_) {}
    return 9; // Estándar para Goodix en Dell Precision 5540
  }

  /// Obtiene el nombre del hardware del sensor biométrico.
  static Future<String> getDeviceName() async {
    try {
      final result = await Process.run('gdbus', [
        'call',
        '--system',
        '--dest',
        'net.reactivated.Fprint',
        '--object-path',
        '/net/reactivated/Fprint/Device/0',
        '--method',
        'org.freedesktop.DBus.Properties.Get',
        'net.reactivated.Fprint.Device',
        'name',
      ]);
      if (result.exitCode == 0) {
        final match = RegExp(r"<'([^']+)'").firstMatch(result.stdout.toString());
        if (match != null) {
          return match.group(1)!;
        }
      }
    } catch (_) {}
    return 'Goodix HTK32 Fingerprint Sensor';
  }

  /// Elimina una huella específica usando la bandera obligatoria -f y limpia su apodo.
  static Future<bool> deleteFinger(String fingerCode) async {
    try {
      final user = getUsername();
      final result = await Process.run('fprintd-delete', [user, '-f', fingerCode]);
      if (result.exitCode == 0) {
        await AliasService.removeAlias(fingerCode);
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Elimina todas las huellas dactilares del usuario actual.
  static Future<bool> deleteAllFingers() async {
    try {
      final user = getUsername();
      final result = await Process.run('fprintd-delete', [user]);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Inicia el subproceso de enrolamiento con la bandera -f explícita.
  static Future<Process> startEnrollProcess(String fingerCode) {
    final user = getUsername();
    return Process.start('fprintd-enroll', ['-f', fingerCode, user]);
  }

  /// Inicia el subproceso de verificación con la bandera -f explícita.
  static Future<Process> startVerifyProcess(String fingerCode) {
    final user = getUsername();
    return Process.start('fprintd-verify', ['-f', fingerCode, user]);
  }
}
