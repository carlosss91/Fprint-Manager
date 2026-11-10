import 'package:flutter/material.dart';
import '../services/fprint_service.dart';
import '../services/usb_maintenance_service.dart';

/// Diálogo de mantenimiento avanzado para reiniciar el hardware USB, configurar permisos y verificar PAM.
class MaintenanceDialog extends StatefulWidget {
  final VoidCallback onHardwareReset;

  const MaintenanceDialog({
    super.key,
    required this.onHardwareReset,
  });

  @override
  State<MaintenanceDialog> createState() => _MaintenanceDialogState();
}

class _MaintenanceDialogState extends State<MaintenanceDialog> {
  bool _isPolkitConfigured = false;
  bool _isPamConfigured = false;
  bool _isLoading = true;
  bool _isOperating = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final polkit = await UsbMaintenanceService.isPolkitConfigured();
    final pam = await FprintService.isPamAuthenticationEnabled();

    if (mounted) {
      setState(() {
        _isPolkitConfigured = polkit;
        _isPamConfigured = pam;
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePolkitSetup() async {
    setState(() {
      _isOperating = true;
      _statusMessage = 'Solicitando autorización para configurar Polkit...';
    });

    final success = await UsbMaintenanceService.configurePermanentPermissions();
    await _checkStatus();

    if (mounted) {
      setState(() {
        _isOperating = false;
        _statusMessage = success
            ? '¡Permisos configurados con éxito! Ya no se solicitarán contraseñas repetidas.'
            : 'No se pudo aplicar la configuración de Polkit.';
      });
    }
  }

  Future<void> _handlePamToggle() async {
    final willEnable = !_isPamConfigured;
    setState(() {
      _isOperating = true;
      _statusMessage = willEnable
          ? 'Habilitando inicio de sesión con huella en el sistema (pam-auth-update)...'
          : 'Deshabilitando inicio de sesión con huella en el sistema...';
    });

    final success = await FprintService.setPamAuthenticationEnabled(willEnable);
    await _checkStatus();
    widget.onHardwareReset();

    if (mounted) {
      setState(() {
        _isOperating = false;
        _statusMessage = success
            ? (willEnable
                ? '¡Inicio de sesión, pantalla de bloqueo y sudo habilitados con huella!'
                : 'Autenticación del sistema por huella deshabilitada.')
            : 'Fallo al ejecutar pam-auth-update.';
      });
    }
  }

  Future<void> _handleUsbReset() async {
    setState(() {
      _isOperating = true;
      _statusMessage = 'Reiniciando el bus USB (Goodix 27c6:5395) y fprintd...';
    });

    final success = await UsbMaintenanceService.resetUsbAndDaemon();
    widget.onHardwareReset();

    if (mounted) {
      setState(() {
        _isOperating = false;
        _statusMessage = success
            ? 'Bus USB y demonio reiniciados con éxito.'
            : 'Fallo al reiniciar el bus USB.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.build_circle_outlined, color: Color(0xFF3584E4)),
          SizedBox(width: 10),
          Text('Mantenimiento y Permisos del Sensor', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: 490,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Herramientas de recuperación para lectores biométricos (Goodix 27c6:5395 / Dell Precision 5540):',
                style: TextStyle(fontSize: 13.5),
              ),
              const SizedBox(height: 16),

              // Tarjeta de Permisos Polkit
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isPolkitConfigured ? Icons.verified_user_rounded : Icons.lock_outline_rounded,
                            color: _isPolkitConfigured ? const Color(0xFF2EC27E) : const Color(0xFFE01B24),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isPolkitConfigured
                                  ? 'Permisos permanentes activados'
                                  : 'Permisos sin configurar (pide contraseña frecuentemente)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _isPolkitConfigured ? const Color(0xFF2EC27E) : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Agrega una regla en /etc/polkit-1/rules.d para que el usuario pueda enrolar y borrar huellas sin diálogos repetitivos de autenticación.',
                        style: TextStyle(fontSize: 12, color: theme.hintColor),
                      ),
                      const SizedBox(height: 10),
                      FilledButton.tonalIcon(
                        onPressed: (_isOperating || _isLoading) ? null : _handlePolkitSetup,
                        icon: const Icon(Icons.security_rounded, size: 16),
                        label: Text(_isPolkitConfigured ? 'Reaplicar Regla Polkit' : 'Autorizar Permisos Permanentes'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Tarjeta de Integración PAM (Login & Sudo)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isPamConfigured ? Icons.login_rounded : Icons.warning_amber_rounded,
                            color: _isPamConfigured ? const Color(0xFF2EC27E) : const Color(0xFFF5C211),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isPamConfigured
                                      ? 'Autenticación en el Sistema: Habilitada'
                                      : 'Autenticación en el Sistema: Deshabilitada',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _isPamConfigured ? const Color(0xFF2EC27E) : null,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isPamConfigured
                                      ? 'Las huellas registradas se usan para iniciar sesión en elementary OS (Pantheon), desbloquear pantalla y autorizar comandos "sudo".'
                                      : 'Actualmente el sistema solo permite contraseña de texto. Habilita esta opción para usar el sensor biométrico.',
                                  style: TextStyle(fontSize: 12, color: theme.hintColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      FilledButton.tonalIcon(
                        onPressed: (_isOperating || _isLoading) ? null : _handlePamToggle,
                        style: FilledButton.styleFrom(
                          backgroundColor: _isPamConfigured
                              ? const Color(0xFFE01B24).withValues(alpha: 0.12)
                              : const Color(0xFF2EC27E).withValues(alpha: 0.15),
                          foregroundColor: _isPamConfigured
                              ? const Color(0xFFE01B24)
                              : (isDark ? const Color(0xFF2EC27E) : const Color(0xFF1B824B)),
                        ),
                        icon: Icon(
                          _isPamConfigured ? Icons.power_settings_new_rounded : Icons.check_circle_outline_rounded,
                          size: 16,
                        ),
                        label: Text(
                          _isPamConfigured
                              ? 'Deshabilitar de Login y Sudo'
                              : 'Habilitar en Login y Sudo (pam-auth-update)',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Tarjeta de Reinicio de Bus USB
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.usb_rounded, color: Color(0xFF3584E4), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Reinicio de Bus USB de Bajo Nivel',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'En equipos Dell Precision 5540 el sensor Goodix (27c6:5395) puede quedar bloqueado por switches USB o suspensión. Esto fuerza un ciclo eléctrico de hardware con usbreset.',
                        style: TextStyle(fontSize: 12, color: theme.hintColor),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: (_isOperating || _isLoading) ? null : _handleUsbReset,
                        icon: const Icon(Icons.restart_alt_rounded, size: 16),
                        label: const Text('Reiniciar Bus USB del Lector'),
                      ),
                    ],
                  ),
                ),
              ),

              if (_statusMessage != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF333336) : const Color(0xFFEBF3FC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusMessage!,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isOperating ? null : () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
