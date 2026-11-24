import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isOperating = true;
      _manualCommand = null;
      _statusIsError = false;
      _statusMessage = l10n.maintStatusPolkit;
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
    final l10n = AppLocalizations.of(context)!;
    final current = _diag?.isPamEnabled ?? false;
    final willEnable = !current;
    setState(() {
      _isOperating = true;
      _manualCommand = null;
      _statusIsError = false;
      _statusMessage = willEnable
          ? l10n.maintStatusPamEnable
          : l10n.maintStatusPamDisable;
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
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isOperating = true;
      _manualCommand = null;
      _statusIsError = false;
      _statusMessage = l10n.maintStatusUsb;
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
    final l10n = AppLocalizations.of(context)!;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.commandCopied),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final diag = _diag;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.build_circle_outlined, color: AppColors.primary(context)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.maintTitle,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: l10n.maintRefreshTooltip,
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
                    _buildDiagnosticsCard(context, l10n, diag),
                    const SizedBox(height: 12),
                    _buildPolkitCard(context, l10n, diag),
                    const SizedBox(height: 12),
                    _buildPamCard(context, l10n, diag),
                    const SizedBox(height: 12),
                    _buildUsbResetCard(context, l10n, diag),
                    if (_statusMessage != null) ...[
                      const SizedBox(height: 14),
                      _buildStatusFeedback(context, l10n),
                    ],
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _isOperating ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.closeBtn),
        ),
      ],
    );
  }

  Widget _buildDiagnosticsCard(
    BuildContext context,
    AppLocalizations l10n,
    SystemDiagnostics diag,
  ) {
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
                Text(
                  l10n.maintEnvTitle,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary(context).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    diag.isRunningInFlatpak ? l10n.aboutFlatpak : l10n.maintNativeSession,
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
              label: l10n.maintDbusRow,
              ok: diag.fprintdAvailable,
              detail: diag.fprintdAvailable
                  ? l10n.maintConnected
                  : l10n.maintInactiveOrMissing,
            ),
            _DiagRow(
              label: l10n.maintReadersRow,
              ok: diag.devices.isNotEmpty,
              detail: diag.devices.isNotEmpty
                  ? '${diag.devices.length} (${diag.devices.map((d) => d.name).join(", ")})'
                  : l10n.maintNoneDetected,
            ),
            _DiagRow(
              label: l10n.maintUsbRow,
              ok: diag.usbDevices.isNotEmpty,
              detail: diag.usbDevices.isNotEmpty
                  ? diag.usbDevices.map((d) => '${d.vendorName} [${d.usbId}]').join(', ')
                  : l10n.maintNoUsb,
              neutralWhenFalse: true,
            ),
            _DiagRow(
              label: l10n.maintPamRow,
              ok: diag.isPamEnabled,
              detail: diag.isPamEnabled ? l10n.maintEnabled : l10n.maintDisabled,
              neutralWhenFalse: true,
            ),
            _DiagRow(
              label: l10n.maintPolkitRow,
              ok: diag.isPolkitRuleInstalled,
              detail: diag.isPolkitRuleInstalled
                  ? l10n.maintInstalled
                  : l10n.polkitDefault,
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
                      l10n.maintMissingPackages,
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

  Widget _buildPolkitCard(
    BuildContext context,
    AppLocalizations l10n,
    SystemDiagnostics diag,
  ) {
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
                        ? l10n.maintPolkitActive
                        : l10n.maintPolkitDefault,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.maintPolkitDesc,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
            ),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: _isOperating ? null : _handlePolkitSetup,
              icon: const Icon(Icons.security_rounded, size: 16),
              label: Text(
                diag.isRunningInFlatpak
                    ? l10n.maintPolkitFlatpakBtn
                    : (diag.isPolkitRuleInstalled
                        ? l10n.maintPolkitReapplyBtn
                        : l10n.maintPolkitGrantBtn),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPamCard(
    BuildContext context,
    AppLocalizations l10n,
    SystemDiagnostics diag,
  ) {
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
                        ? l10n.maintPamActive
                        : l10n.maintPamDisabled,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              diag.isPamEnabled
                  ? l10n.maintPamActiveDesc
                  : l10n.maintPamDisabledDesc,
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
                    ? l10n.maintPamDisableBtn
                    : l10n.maintPamEnableBtn,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsbResetCard(
    BuildContext context,
    AppLocalizations l10n,
    SystemDiagnostics diag,
  ) {
    final usbSummary = diag.usbDevices.isNotEmpty
        ? l10n.maintUsbDetected(
            diag.usbDevices.map((d) => '${d.productName} (${d.usbId})').join(', '),
          )
        : l10n.maintUsbNone;

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
                Text(
                  l10n.maintUsbTitle,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.maintUsbDesc(usbSummary),
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _isOperating ? null : _handleUsbReset,
              icon: const Icon(Icons.restart_alt_rounded, size: 16),
              label: Text(
                diag.isRunningInFlatpak
                    ? l10n.maintUsbFlatpakBtn
                    : l10n.maintUsbResetBtn,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFeedback(BuildContext context, AppLocalizations l10n) {
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
                label: Text(l10n.copyCommandBtn),
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
