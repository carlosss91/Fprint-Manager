import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/fprint_device_info.dart';
import '../services/fprint_service.dart';
import '../services/usb_maintenance_service.dart';
import '../theme/app_theme.dart';

/// Diálogo integral de diagnóstico del sistema, permisos Polkit, PAM y reinicio hardware-agnóstico.
class MaintenanceDialog extends StatefulWidget {
  final FprintBackend backend;
  final VoidCallback onHardwareReset;

  const MaintenanceDialog({
    super.key,
    required this.backend,
    required this.onHardwareReset,
  });

  @override
  State<MaintenanceDialog> createState() => _MaintenanceDialogState();
}

class _MaintenanceDialogState extends State<MaintenanceDialog> {
  SystemDiagnostics? _diag;
  bool _isLoading = true;
  bool _isOperating = false;
  String? _statusMessage;
  String? _manualCommand;
  bool _statusIsError = false;

  @override
  void initState() {
    super.initState();
    _loadDiagnostics();
  }

  Future<void> _loadDiagnostics() async {
    setState(() => _isLoading = true);
    final diag = await widget.backend.runDiagnostics();
    if (!mounted) return;
    setState(() {
      _diag = diag;
      _isLoading = false;
    });
  }

  Future<void> _handlePolkitSetup() async {
    setState(() {
      _isOperating = true;
      _manualCommand = null;
      _statusIsError = false;
      _statusMessage = 'Configurando regla Polkit para permisos biométricos...';
    });

    final result = await UsbMaintenanceService.configurePermanentPermissions();
    await _loadDiagnostics();
    widget.onHardwareReset();

    if (!mounted) return;
    setState(() {
      _isOperating = false;
      _statusIsError = !result.success && result.manualCommand == null;
      _statusMessage = result.message;
      _manualCommand = result.manualCommand;
    });
  }

  Future<void> _handlePamToggle() async {
    final current = _diag?.isPamEnabled ?? false;
    final willEnable = !current;
    setState(() {
      _isOperating = true;
      _manualCommand = null;
      _statusIsError = false;
      _statusMessage = willEnable
          ? 'Habilitando autenticación por huella en login y sudo...'
          : 'Deshabilitando autenticación por huella en el sistema...';
    });

    final result = await UsbMaintenanceService.setPamAuthenticationEnabled(willEnable);
    await _loadDiagnostics();
    widget.onHardwareReset();

    if (!mounted) return;
    setState(() {
      _isOperating = false;
      _statusIsError = !result.success && result.manualCommand == null;
      _statusMessage = result.message;
      _manualCommand = result.manualCommand;
    });
  }

  Future<void> _handleUsbReset() async {
    setState(() {
      _isOperating = true;
      _manualCommand = null;
      _statusIsError = false;
      _statusMessage = 'Reiniciando lectores USB detectados y servicio fprintd...';
    });

    final result = await UsbMaintenanceService.resetUsbAndDaemon(_diag?.usbDevices);
    await _loadDiagnostics();
    widget.onHardwareReset();

    if (!mounted) return;
    setState(() {
      _isOperating = false;
      _statusIsError = !result.success && result.manualCommand == null;
      _statusMessage = result.message;
      _manualCommand = result.manualCommand;
    });
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Comando copiado al portapapeles.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final diag = _diag;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.build_circle_outlined, color: AppColors.primary(context)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Diagnóstico y Mantenimiento',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: 'Actualizar diagnóstico',
            onPressed: (_isLoading || _isOperating) ? null : _loadDiagnostics,
            icon: const Icon(Icons.refresh_rounded, size: 19),
          ),
        ],
      ),
      content: SizedBox(
        width: 540,
        child: _isLoading || diag == null
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDiagnosticsCard(context, diag),
                    const SizedBox(height: 12),
                    _buildPolkitCard(context, diag),
                    const SizedBox(height: 12),
                    _buildPamCard(context, diag),
                    const SizedBox(height: 12),
                    _buildUsbResetCard(context, diag),
                    if (_statusMessage != null) ...[
                      const SizedBox(height: 14),
                      _buildStatusFeedback(context),
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

  Widget _buildDiagnosticsCard(BuildContext context, SystemDiagnostics diag) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.monitor_heart_outlined,
                    size: 19, color: AppColors.primary(context)),
                const SizedBox(width: 8),
                const Text(
                  'Estado del Entorno Linux',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary(context).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    diag.isRunningInFlatpak ? 'Sandbox Flatpak' : 'Sesión Nativa',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _DiagRow(
              label: 'Bus del sistema D-Bus (net.reactivated.Fprint)',
              ok: diag.fprintdAvailable,
              detail: diag.fprintdAvailable
                  ? 'Conectado'
                  : 'Inactivo o no instalado',
            ),
            _DiagRow(
              label: 'Lectores expuestos por libfprint',
              ok: diag.devices.isNotEmpty,
              detail: diag.devices.isNotEmpty
                  ? '${diag.devices.length} (${diag.devices.map((d) => d.name).join(", ")})'
                  : 'Ninguno detectado',
            ),
            _DiagRow(
              label: 'Sensores biométricos USB en sysfs',
              ok: diag.usbDevices.isNotEmpty,
              detail: diag.usbDevices.isNotEmpty
                  ? diag.usbDevices.map((d) => '${d.vendorName} [${d.usbId}]').join(', ')
                  : 'Sin lector USB (o lector interno SPI/I2C)',
              neutralWhenFalse: true,
            ),
            _DiagRow(
              label: 'Integración PAM (login, bloqueo y sudo)',
              ok: diag.isPamEnabled,
              detail: diag.isPamEnabled ? 'Habilitado' : 'Deshabilitado',
              neutralWhenFalse: true,
            ),
            _DiagRow(
              label: 'Regla Polkit sin contraseñas repetidas',
              ok: diag.isPolkitRuleInstalled,
              detail: diag.isPolkitRuleInstalled ? 'Instalada' : 'Por defecto',
              neutralWhenFalse: true,
            ),
            if (!diag.fprintdAvailable) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error(context).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.error(context).withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paquetes del sistema necesarios si fprintd no está instalado:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error(context),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const SelectableText(
                      'Ubuntu / elementary OS / Debian:\n'
                      '  sudo apt install fprintd libpam-fprintd\n'
                      'Fedora:\n'
                      '  sudo dnf install fprintd fprintd-pam\n'
                      'Arch Linux:\n'
                      '  sudo pacman -S fprintd',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPolkitCard(BuildContext context, SystemDiagnostics diag) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  diag.isPolkitRuleInstalled
                      ? Icons.verified_user_rounded
                      : Icons.lock_outline_rounded,
                  color: diag.isPolkitRuleInstalled
                      ? AppColors.success(context)
                      : AppColors.warning(context),
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    diag.isPolkitRuleInstalled
                        ? 'Permisos permanentes Polkit activos'
                        : 'Permisos Polkit predeterminados',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Permite que usuarios del grupo administrativo registren o eliminen sus propias huellas sin repetir la contraseña en cada acción.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
            ),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: _isOperating ? null : _handlePolkitSetup,
              icon: const Icon(Icons.security_rounded, size: 16),
              label: Text(
                diag.isRunningInFlatpak
                    ? 'Ver comando de permisos para anfitrión'
                    : (diag.isPolkitRuleInstalled
                        ? 'Reaplicar regla Polkit'
                        : 'Autorizar permisos permanentes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPamCard(BuildContext context, SystemDiagnostics diag) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  diag.isPamEnabled
                      ? Icons.login_rounded
                      : Icons.shield_outlined,
                  color: diag.isPamEnabled
                      ? AppColors.success(context)
                      : AppColors.warning(context),
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    diag.isPamEnabled
                        ? 'Autenticación PAM activa (Login y sudo)'
                        : 'Autenticación PAM desactivada',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              diag.isPamEnabled
                  ? 'Las huellas registradas permiten iniciar sesión, desbloquear pantalla y autorizar sudo.'
                  : 'Activa el módulo pam_fprintd para usar tu huella al iniciar sesión y en sudo.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
            ),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: _isOperating ? null : _handlePamToggle,
              icon: Icon(
                diag.isPamEnabled
                    ? Icons.power_settings_new_rounded
                    : Icons.check_circle_outline_rounded,
                size: 16,
              ),
              label: Text(
                diag.isPamEnabled
                    ? 'Deshabilitar en Login y sudo'
                    : 'Habilitar en Login y sudo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsbResetCard(BuildContext context, SystemDiagnostics diag) {
    final usbSummary = diag.usbDevices.isNotEmpty
        ? 'Detectado: ${diag.usbDevices.map((d) => "${d.productName} (${d.usbId})").join(", ")}.'
        : 'No se detectaron sensores USB en sysfs (si es interno SPI/I2C, solo se reiniciará fprintd).';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.usb_rounded, color: AppColors.primary(context), size: 19),
                const SizedBox(width: 8),
                const Text(
                  'Reinicio de Lector y Servicio fprintd',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Recupera lectores bloqueados tras suspensión o reconexión de docks USB. $usbSummary',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _isOperating ? null : _handleUsbReset,
              icon: const Icon(Icons.restart_alt_rounded, size: 16),
              label: Text(
                diag.isRunningInFlatpak
                    ? 'Generar comando de reinicio para anfitrión'
                    : 'Reiniciar lector y servicio fprintd',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFeedback(BuildContext context) {
    final accent = _statusIsError ? AppColors.error(context) : AppColors.primary(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _statusMessage!,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: _statusIsError ? accent : null,
            ),
          ),
          if (_manualCommand != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.canvas(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: SelectableText(
                _manualCommand!,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _copyToClipboard(_manualCommand!),
                icon: const Icon(Icons.copy_rounded, size: 15),
                label: const Text('Copiar comando'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DiagRow extends StatelessWidget {
  final String label;
  final bool ok;
  final String detail;
  final bool neutralWhenFalse;

  const _DiagRow({
    required this.label,
    required this.ok,
    required this.detail,
    this.neutralWhenFalse = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = ok
        ? AppColors.success(context)
        : (neutralWhenFalse ? AppColors.warning(context) : AppColors.error(context));
    final icon = ok
        ? Icons.check_circle_rounded
        : (neutralWhenFalse ? Icons.info_rounded : Icons.error_rounded);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style.copyWith(fontSize: 12),
                children: [
                  TextSpan(text: '$label: '),
                  TextSpan(
                    text: detail,
                    style: TextStyle(fontWeight: FontWeight.w600, color: color),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
