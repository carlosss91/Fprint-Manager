import 'dart:io';

/// Servicio de mantenimiento para el bus USB y permisos Polkit (Dell Precision 5540 y hardware compatible).
class UsbMaintenanceService {
  /// Ubicación del archivo de reglas Polkit para omitir contraseñas repetitivas.
  static const String polkitRulePath = '/etc/polkit-1/rules.d/50-fprint-manager.rules';

  /// Verifica si ya están configurados los permisos permanentes de Polkit.
  static Future<bool> isPolkitConfigured() async {
    try {
      final file = File(polkitRulePath);
      return await file.exists();
    } catch (_) {
      return false;
    }
  }

  /// Instala una regla en Polkit para que los usuarios administradores (sudo)
  /// puedan gestionar sus huellas sin solicitudes continuas de contraseña.
  static Future<bool> configurePermanentPermissions() async {
    try {
      // Contenido JavaScript estándar para Polkit 120+
      const ruleContent = '''polkit.addRule(function(action, subject) {
    if (action.id.indexOf("net.reactivated.fprint.device.") === 0 && subject.isInGroup("sudo")) {
        return polkit.Result.YES;
    }
});
''';

      final script = "cat << 'EOF' > $polkitRulePath\n$ruleContent\nEOF\nchmod 644 $polkitRulePath";
      final result = await Process.run('pkexec', ['sh', '-c', script]);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Reinicia el bus USB del lector Goodix (27c6:5395 / Dell Precision 5540) y el demonio fprintd.
  /// Previene bloqueos causados por conmutadores USB externos o transiciones de suspensión.
  static Future<bool> resetUsbAndDaemon() async {
    try {
      // Script para reiniciar por usbreset o sysfs y reiniciar fprintd
      const script = '''
if command -v usbreset >/dev/null 2>&1; then
    usbreset 27c6:5395 || usbreset 27c6:538d || true
fi

# Reautorización a través de sysfs en caso de que usbreset no cubra el puerto
for dev in /sys/bus/usb/devices/*/idVendor; do
    if [ -f "\$dev" ] && grep -qi "27c6" "\$dev" 2>/dev/null; then
        devdir=\$(dirname "\$dev")
        if [ -w "\$devdir/authorized" ]; then
            echo 0 > "\$devdir/authorized" 2>/dev/null || true
            sleep 0.3
            echo 1 > "\$devdir/authorized" 2>/dev/null || true
        fi
    fi
done

systemctl restart fprintd
''';

      final result = await Process.run('pkexec', ['sh', '-c', script]);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Reinicio ligero del servicio del sistema sin privilegios de bus si no son necesarios.
  static Future<bool> restartDaemonQuick() async {
    try {
      final result = await Process.run('systemctl', ['restart', 'fprintd']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}

