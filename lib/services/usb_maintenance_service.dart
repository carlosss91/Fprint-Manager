import 'dart:io';
import '../models/fprint_device_info.dart';

/// Servicio agnóstico de mantenimiento del sistema Linux:
/// - Detección de entorno Flatpak vs ejecución nativa
/// - Descubrimiento dinámico de lectores USB mediante udev/libfprint y sysfs
/// - Reinicio seguro del bus USB y del demonio fprintd
/// - Gestión de reglas Polkit y perfiles PAM (pam-auth-update / authselect)
class UsbMaintenanceService {
  static const String polkitRulePath = '/etc/polkit-1/rules.d/50-fprint-manager.rules';

  static const Map<String, String> _knownVendorNames = {
    '27c6': 'Goodix',
    '06cb': 'Synaptics',
    '04f3': 'ELAN Microelectronics',
    '138a': 'Validity Sensors',
    '147e': 'Upek',
    '08ff': 'AuthenTec',
    '1c7a': 'Egis Technology',
    '10a5': 'Fingerprint Cards (FPC)',
    '2808': 'FocalTech',
    '0483': 'STMicroelectronics',
    '0a5c': 'Broadcom',
    '1162': 'SecuGen',
  };

  /// Vendors cuyo catálogo USB principal corresponde a sensores biométricos dedicados.
  static const Set<String> _dedicatedFingerprintVendors = {
    '27c6',
    '138a',
    '147e',
    '08ff',
    '1c7a',
    '10a5',
    '2808',
    '1162',
  };

  /// Detecta si la aplicación se está ejecutando dentro del sandbox Flatpak.
  static bool get isRunningInFlatpak => File('/.flatpak-info').existsSync();

  /// Comprueba si un binario está disponible en el PATH del entorno actual.
  static Future<bool> hasBinary(String binaryName) async {
    try {
      final result = await Process.run('which', [binaryName]);
      return result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Verifica si la regla personalizada de Polkit está instalada en el anfitrión.
  static Future<bool> isPolkitConfigured() async {
    try {
      return await File(polkitRulePath).exists();
    } catch (_) {
      return false;
    }
  }

  /// Verifica si el módulo pam_fprintd está habilitado en los archivos PAM estándar.
  static Future<bool> isPamAuthenticationEnabled() async {
    const pamFiles = [
      '/etc/pam.d/common-auth', // Debian / Ubuntu / elementary OS
      '/etc/pam.d/system-auth', // Fedora / RHEL / Arch
      '/etc/pam.d/system-local-login', // Arch
    ];

    for (final path in pamFiles) {
      try {
        final file = File(path);
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
    }
    return false;
  }

  /// Lee las reglas udev instaladas de libfprint para conocer los pares VID:PID soportados.
  static Future<Set<String>> _loadLibfprintUdevPairs() async {
    final pairs = <String>{};
    final udevDirs = ['/usr/lib/udev/rules.d', '/lib/udev/rules.d'];
    final pairRegex = RegExp(
      r'idVendor\}=="([0-9a-fA-F]{4})".*?idProduct\}=="([0-9a-fA-F]{4})"',
    );

    for (final dirPath in udevDirs) {
      try {
        final dir = Directory(dirPath);
        if (!await dir.exists()) continue;
        await for (final entity in dir.list()) {
          if (entity is File && entity.path.contains('fprint')) {
            final content = await entity.readAsString();
            for (final line in content.split('\n')) {
              final match = pairRegex.firstMatch(line);
              if (match != null) {
                pairs.add('${match.group(1)!.toLowerCase()}:${match.group(2)!.toLowerCase()}');
              }
            }
          }
        }
      } catch (_) {}
    }
    return pairs;
  }

  /// Descubre dinámicamente lectores de huellas USB en /sys/bus/usb/devices.
  static Future<List<UsbFingerprintDevice>> detectUsbFingerprintReaders() async {
    final found = <UsbFingerprintDevice>[];
    final seenPaths = <String>{};

    try {
      final usbRoot = Directory('/sys/bus/usb/devices');
      if (!await usbRoot.exists()) return found;

      final udevPairs = await _loadLibfprintUdevPairs();
      final keywordRegex = RegExp(
        r'(fingerprint|biometric|fprint|match-on-chip)',
        caseSensitive: false,
      );
      final synapticsFpRegex = RegExp(
        r'(fingerprint|validity|prometheus|metallica|biometric|fs\d{4})',
        caseSensitive: false,
      );

      await for (final entry in usbRoot.list()) {
        final name = entry.uri.pathSegments.where((s) => s.isNotEmpty).last;
        // Ignorar interfaces USB (ej. 1-7:1.0) y controladores raíz (usb1)
        if (name.contains(':') || name.startsWith('usb')) continue;

        final vendorFile = File('${entry.path}/idVendor');
        final productFile = File('${entry.path}/idProduct');
        if (!await vendorFile.exists() || !await productFile.exists()) continue;

        final vendorId = (await vendorFile.readAsString()).trim().toLowerCase();
        final productId = (await productFile.readAsString()).trim().toLowerCase();
        if (vendorId == '1d6b') continue; // Linux Foundation Root Hub

        String productDesc = '';
        String manufacturerDesc = '';
        try {
          final pf = File('${entry.path}/product');
          if (await pf.exists()) productDesc = (await pf.readAsString()).trim();
          final mf = File('${entry.path}/manufacturer');
          if (await mf.exists()) manufacturerDesc = (await mf.readAsString()).trim();
        } catch (_) {}

        final pair = '$vendorId:$productId';
        final combinedDesc = '$manufacturerDesc $productDesc'.trim();

        final matchesUdev = udevPairs.contains(pair);
        final matchesDedicatedVendor = _dedicatedFingerprintVendors.contains(vendorId);
        final matchesSynapticsFp =
            vendorId == '06cb' && synapticsFpRegex.hasMatch(combinedDesc);
        final matchesKeyword = keywordRegex.hasMatch(combinedDesc);

        if (matchesUdev ||
            matchesDedicatedVendor ||
            matchesSynapticsFp ||
            matchesKeyword) {
          if (seenPaths.add(entry.path)) {
            found.add(
              UsbFingerprintDevice(
                vendorId: vendorId,
                productId: productId,
                vendorName: _knownVendorNames[vendorId] ??
                    (manufacturerDesc.isNotEmpty ? manufacturerDesc : 'Fabricante $vendorId'),
                productName: productDesc.isNotEmpty
                    ? productDesc
                    : 'Lector biométrico USB ($pair)',
                sysfsPath: entry.path,
              ),
            );
          }
        }
      }
    } catch (_) {}

    return found;
  }

  /// Comando listo para copiar/ejecutar en la terminal del sistema anfitrión para Polkit.
  static String buildPolkitSetupCommand() {
    return "pkexec sh -c 'cat <<\"EOF\" > $polkitRulePath\n"
        'polkit.addRule(function(action, subject) {\n'
        '    if (action.id.indexOf("net.reactivated.fprint.device.") === 0 && subject.isInGroup("sudo")) {\n'
        '        return polkit.Result.YES;\n'
        '    }\n'
        '});\n'
        "EOF\nchmod 644 $polkitRulePath'";
  }

  /// Instala la regla de Polkit para evitar diálogos repetitivos de contraseña.
  static Future<({bool success, String message, String? manualCommand})>
      configurePermanentPermissions() async {
    if (isRunningInFlatpak) {
      return (
        success: false,
        message:
            'Dentro de Flatpak la app está aislada del sistema. Copia y ejecuta este comando en la terminal de tu equipo:',
        manualCommand: buildPolkitSetupCommand(),
      );
    }

    if (!await hasBinary('pkexec')) {
      return (
        success: false,
        message: 'No se encontró pkexec en el sistema. Ejecuta el comando manualmente con sudo:',
        manualCommand: buildPolkitSetupCommand().replaceFirst('pkexec ', 'sudo '),
      );
    }

    try {
      const ruleContent = '''polkit.addRule(function(action, subject) {
    if (action.id.indexOf("net.reactivated.fprint.device.") === 0 && (subject.isInGroup("sudo") || subject.isInGroup("wheel"))) {
        return polkit.Result.YES;
    }
});
''';

      final script =
          "cat << 'EOF' > $polkitRulePath\n$ruleContent\nEOF\nchmod 644 $polkitRulePath";
      final result = await Process.run('pkexec', ['sh', '-c', script]);
      if (result.exitCode == 0) {
        return (
          success: true,
          message: 'Permisos permanentes de Polkit instalados correctamente.',
          manualCommand: null,
        );
      }
      return (
        success: false,
        message: 'Autorización cancelada o denegada por el usuario.',
        manualCommand: null,
      );
    } catch (e) {
      return (
        success: false,
        message: 'No se pudo configurar Polkit: $e',
        manualCommand: buildPolkitSetupCommand(),
      );
    }
  }

  /// Genera un script agnóstico para reiniciar los lectores USB detectados y fprintd.
  static String buildUsbResetShellCommand(List<UsbFingerprintDevice> devices) {
    if (devices.isEmpty) {
      return 'systemctl restart fprintd';
    }

    final buffer = StringBuffer();
    for (final dev in devices) {
      buffer.writeln(
        'if command -v usbreset >/dev/null 2>&1; then usbreset ${dev.usbId} || true; fi',
      );
      buffer.writeln(
        'if [ -w "${dev.sysfsPath}/authorized" ]; then echo 0 > "${dev.sysfsPath}/authorized" && sleep 0.3 && echo 1 > "${dev.sysfsPath}/authorized"; fi',
      );
    }
    buffer.write('systemctl restart fprintd');
    return buffer.toString();
  }

  /// Reinicia los lectores USB detectados dinámicamente y reinicia el demonio fprintd.
  static Future<({bool success, String message, String? manualCommand})>
      resetUsbAndDaemon([List<UsbFingerprintDevice>? knownDevices]) async {
    final devices = knownDevices ?? await detectUsbFingerprintReaders();
    final innerScript = buildUsbResetShellCommand(devices);

    if (isRunningInFlatpak) {
      return (
        success: false,
        message:
            'Flatpak no permite reiniciar buses USB del anfitrión directamente. Ejecuta este comando en tu terminal:',
        manualCommand: 'pkexec sh -c \'$innerScript\'',
      );
    }

    if (!await hasBinary('pkexec')) {
      return (
        success: false,
        message: 'No se encontró pkexec. Ejecuta este comando con sudo en tu terminal:',
        manualCommand: 'sudo sh -c \'$innerScript\'',
      );
    }

    try {
      final result = await Process.run('pkexec', ['sh', '-c', innerScript]);
      if (result.exitCode == 0) {
        final devLabel = devices.isNotEmpty
            ? ' (${devices.map((d) => d.usbId).join(', ')})'
            : '';
        return (
          success: true,
          message: 'Servicio fprintd${devLabel.isNotEmpty ? " y bus USB$devLabel" : ""} reiniciados.',
          manualCommand: null,
        );
      }
      return (
        success: false,
        message: 'Autorización cancelada o error al reiniciar el servicio.',
        manualCommand: null,
      );
    } catch (e) {
      return (
        success: false,
        message: 'Error al reiniciar lector: $e',
        manualCommand: 'sudo sh -c \'$innerScript\'',
      );
    }
  }

  /// Activa o desactiva la autenticación por huella en PAM usando la herramienta de la distro.
  static Future<({bool success, String message, String? manualCommand})>
      setPamAuthenticationEnabled(bool enable) async {
    final hasPamAuthUpdate = await hasBinary('pam-auth-update');
    final hasAuthselect = await hasBinary('authselect');

    String command;
    List<String> args;
    if (hasPamAuthUpdate) {
      final flag = enable ? '--enable' : '--disable';
      command = 'pam-auth-update $flag fprintd';
      args = ['pam-auth-update', flag, 'fprintd'];
    } else if (hasAuthselect) {
      final sub = enable ? 'enable-feature' : 'disable-feature';
      command = 'authselect $sub with-fingerprint';
      args = ['authselect', sub, 'with-fingerprint'];
    } else {
      command = enable
          ? 'sudo pam-auth-update --enable fprintd'
          : 'sudo pam-auth-update --disable fprintd';
      return (
        success: false,
        message:
            'Configura PAM manualmente según tu distribución (pam-auth-update o authselect):',
        manualCommand: command,
      );
    }

    if (isRunningInFlatpak) {
      return (
        success: false,
        message:
            'Para modificar la configuración PAM del sistema desde Flatpak, ejecuta en tu terminal:',
        manualCommand: 'sudo $command',
      );
    }

    if (!await hasBinary('pkexec')) {
      return (
        success: false,
        message: 'No se encontró pkexec. Ejecuta con sudo en tu terminal:',
        manualCommand: 'sudo $command',
      );
    }

    try {
      final result = await Process.run('pkexec', args);
      if (result.exitCode == 0) {
        return (
          success: true,
          message: enable
              ? 'Inicio de sesión, pantalla de bloqueo y sudo habilitados con huella.'
              : 'Autenticación biométrica del sistema deshabilitada.',
          manualCommand: null,
        );
      }
      return (
        success: false,
        message: 'Autorización cancelada o sin cambios en PAM.',
        manualCommand: null,
      );
    } catch (e) {
      return (
        success: false,
        message: 'Error configurando PAM: $e',
        manualCommand: 'sudo $command',
      );
    }
  }
}
