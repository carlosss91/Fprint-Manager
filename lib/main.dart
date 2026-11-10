import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/fingerprint_item.dart';
import 'models/verification_log.dart';
import 'services/fprint_service.dart';
import 'services/usb_maintenance_service.dart';
import 'widgets/edit_name_dialog.dart';
import 'widgets/enrollment_dialog.dart';
import 'widgets/fingerprint_scanner_widget.dart';
import 'widgets/maintenance_dialog.dart';
import 'widgets/verification_history_dialog.dart';

void main() {
  runApp(const FprintManagerApp());
}

class FprintManagerApp extends StatefulWidget {
  const FprintManagerApp({super.key});

  @override
  State<FprintManagerApp> createState() => _FprintManagerAppState();
}

class _FprintManagerAppState extends State<FprintManagerApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    const elementaryBlue = Color(0xFF3584E4);
    const elementaryRed = Color(0xFFE01B24);

    return MaterialApp(
      title: 'Fprint-Manager',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF6F8FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: elementaryBlue,
          brightness: Brightness.light,
          primary: elementaryBlue,
          surface: Colors.white,
          error: elementaryRed,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFFE4E7EB), width: 1),
          ),
        ),
        dividerColor: const Color(0xFFE5E7EB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1E1E20),
        colorScheme: ColorScheme.fromSeed(
          seedColor: elementaryBlue,
          brightness: Brightness.dark,
          primary: elementaryBlue,
          surface: const Color(0xFF2A2A2E),
          error: elementaryRed,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF2A2A2E),
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFF3A3A3E), width: 1),
          ),
        ),
        dividerColor: const Color(0xFF3A3A3E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF242426),
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
        ),
      ),
      home: FprintHomePage(
        onToggleTheme: _toggleTheme,
        currentThemeMode: _themeMode,
      ),
    );
  }
}

class FprintHomePage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode currentThemeMode;

  const FprintHomePage({
    super.key,
    required this.onToggleTheme,
    required this.currentThemeMode,
  });

  @override
  State<FprintHomePage> createState() => _FprintHomePageState();
}

class _FprintHomePageState extends State<FprintHomePage>
    with SingleTickerProviderStateMixin {
  List<FingerprintItem> _fingerprints = [];
  final List<VerificationLog> _verificationLogs = [];
  bool _isLoadingList = true;
  String _deviceName = 'Goodix HTK32 Fingerprint Sensor';
  int _totalEnrollStages = 9;
  bool _isPolkitConfigured = false;
  bool _isPamEnabled = false;

  // Dedo seleccionado para la verificación con la bandera obligatoria -f
  String? _selectedVerifyFingerCode;

  SensorState _sensorState = SensorState.idle;
  String _sensorStatusText = 'Selecciona una huella y presiona para verificar con el sensor.';
  bool _isRestartingUsb = false;
  Timer? _resetTimer;
  Process? _activeVerifyProcess;

  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initHardwareAndList();
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    _activeVerifyProcess?.kill();
    _pulseController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  /// Carga la información del hardware, huellas y permisos de Polkit y PAM
  Future<void> _initHardwareAndList() async {
    final device = await FprintService.getDeviceName();
    final stages = await FprintService.getNumEnrollStages();
    final fingers = await FprintService.listEnrolledFingers();
    final polkit = await UsbMaintenanceService.isPolkitConfigured();
    final pam = await FprintService.isPamAuthenticationEnabled();

    if (mounted) {
      setState(() {
        _deviceName = device;
        _totalEnrollStages = stages;
        _fingerprints = fingers;
        _isPolkitConfigured = polkit;
        _isPamEnabled = pam;
        _isLoadingList = false;

        if (_fingerprints.isNotEmpty &&
            (_selectedVerifyFingerCode == null ||
                !_fingerprints.any((f) => f.fingerCode == _selectedVerifyFingerCode))) {
          _selectedVerifyFingerCode = _fingerprints.first.fingerCode;
        } else if (_fingerprints.isEmpty) {
          _selectedVerifyFingerCode = null;
        }
      });
    }
  }

  /// Inicia la verificación física usando obligatoriamente la bandera `-f <dedo>`
  Future<void> _startRealVerification() async {
    if (_sensorState == SensorState.scanning) {
      _cancelActiveVerification();
      return;
    }

    if (_fingerprints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay huellas registradas en el sistema para verificar.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final targetFingerCode = _selectedVerifyFingerCode ?? _fingerprints.first.fingerCode;
    final item = _fingerprints.firstWhere(
      (f) => f.fingerCode == targetFingerCode,
      orElse: () => _fingerprints.first,
    );
    final targetName = item.name;

    _resetTimer?.cancel();
    setState(() {
      _sensorState = SensorState.scanning;
      _sensorStatusText = 'Sensor activo (-f $targetFingerCode).\nColoca tu "$targetName" sobre el lector Goodix...';
    });

    try {
      final process = await FprintService.startVerifyProcess(targetFingerCode);
      _activeVerifyProcess = process;

      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        if (!mounted) return;

        if (line.contains('verify-match')) {
          setState(() {
            _sensorState = SensorState.success;
            _sensorStatusText = '¡Huella verificada con éxito!\nCoincidencia confirmada con: $targetName';
            _verificationLogs.add(
              VerificationLog(
                timestamp: DateTime.now(),
                fingerCode: targetFingerCode,
                fingerName: targetName,
                isSuccess: true,
                details: 'verify-match • Coincidencia exitosa en Goodix',
              ),
            );
          });
          _scheduleReset();
        } else if (line.contains('verify-no-match')) {
          setState(() {
            _sensorState = SensorState.error;
            _sensorStatusText = 'Huella no coincide con "$targetName". Intenta de nuevo.';
            _verificationLogs.add(
              VerificationLog(
                timestamp: DateTime.now(),
                fingerCode: targetFingerCode,
                fingerName: targetName,
                isSuccess: false,
                details: 'verify-no-match • El dedo apoyado no coincide con el objetivo',
              ),
            );
          });
          _scheduleReset();
        } else if (line.contains('verify-retry-scan') || line.contains('verify-swipe-too-short')) {
          setState(() {
            _sensorStatusText = 'Lectura incompleta. Apoya el dedo firmemente en el sensor.';
          });
        } else if (line.contains('verify-finger-not-centered')) {
          setState(() {
            _sensorStatusText = 'Centra el dedo sobre el sensor biométrico.';
          });
        }
      });

      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((errorLine) {
        if (!mounted) return;
        if (errorLine.contains('failed to claim') || errorLine.contains('Device was already claimed')) {
          setState(() {
            _sensorState = SensorState.error;
            _sensorStatusText = 'El sensor está ocupado. Intenta reiniciar el lector USB.';
          });
          _scheduleReset();
        }
      });

      process.exitCode.then((code) {
        if (mounted && _sensorState == SensorState.scanning) {
          setState(() {
            _sensorState = SensorState.idle;
            _sensorStatusText = 'Selecciona una huella y presiona para verificar con el sensor.';
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _sensorState = SensorState.error;
          _sensorStatusText = 'Error al ejecutar fprintd-verify: $e';
        });
        _scheduleReset();
      }
    }
  }

  void _cancelActiveVerification() {
    _activeVerifyProcess?.kill();
    _activeVerifyProcess = null;
    setState(() {
      _sensorState = SensorState.idle;
      _sensorStatusText = 'Verificación cancelada. Presiona para iniciar.';
    });
  }

  void _scheduleReset() {
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted && _sensorState != SensorState.scanning) {
        setState(() {
          _sensorState = SensorState.idle;
          _sensorStatusText = 'Selecciona una huella y presiona para verificar con el sensor.';
        });
      }
    });
  }

  /// Abre el diálogo para personalizar el nombre de una huella registrada
  void _editFingerName(FingerprintItem item) {
    showDialog(
      context: context,
      builder: (ctx) => EditNameDialog(
        item: item,
        onSaved: (newName) async {
          await FprintService.updateFingerName(item.fingerCode, newName);
          await _initHardwareAndList();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Nombre de "${item.fingerName}" actualizado a "$newName".'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          }
        },
      ),
    );
  }

  /// Reinicia el bus USB (27c6:5395) y el servicio del sistema
  Future<void> _restartUsbReader() async {
    if (_isRestartingUsb) return;

    _cancelActiveVerification();
    setState(() {
      _isRestartingUsb = true;
    });

    final success = await UsbMaintenanceService.resetUsbAndDaemon();
    await _initHardwareAndList();

    if (!mounted) return;

    setState(() {
      _isRestartingUsb = false;
      _sensorState = SensorState.idle;
      _sensorStatusText = 'Sensor reiniciado. Listo para verificar.';
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.info_outline_rounded,
              color: success ? const Color(0xFF2EC27E) : const Color(0xFF3584E4),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                success
                    ? 'Bus USB (Goodix 27c6:5395) y servicio fprintd reiniciados exitosamente.'
                    : 'Reinicio finalizado.',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    );
  }

  /// Diálogo para eliminar una huella específica mediante fprintd-delete -f
  void _confirmDeleteFingerprint(FingerprintItem item) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 10),
              const Text('Eliminar huella', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            '¿Deseas eliminar permanentemente "${item.name}" (${item.fingerCode}) usando la bandera "-f"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () async {
                Navigator.of(ctx).pop();
                final deleted = await FprintService.deleteFinger(item.fingerCode);
                await _initHardwareAndList();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        deleted
                            ? 'Huella "${item.name}" eliminada de fprintd.'
                            : 'No se pudo eliminar la huella.',
                      ),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                }
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  /// Diálogo para eliminar todas las huellas dactilares del usuario
  void _confirmDeleteAllFingerprints() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Row(
            children: [
              Icon(Icons.delete_forever_rounded, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 10),
              const Text('Borrar todas las huellas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            '¿Estás seguro de que deseas borrar TODAS las huellas registradas en este equipo? Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () async {
                Navigator.of(ctx).pop();
                final success = await FprintService.deleteAllFingers();
                await _initHardwareAndList();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Todas las huellas han sido eliminadas.'
                            : 'No se pudieron eliminar las huellas.',
                      ),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                }
              },
              child: const Text('Borrar Todo'),
            ),
          ],
        );
      },
    );
  }

  void _showAddFingerprintDialog() {
    _cancelActiveVerification();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => EnrollmentDialog(
        totalStages: _totalEnrollStages,
        enrolledFingers: _fingerprints.map((f) => f.fingerCode).toList(),
        onEnrollmentFinished: () async {
          await _initHardwareAndList();
        },
      ),
    );
  }

  void _showMaintenanceDialog() {
    showDialog(
      context: context,
      builder: (ctx) => MaintenanceDialog(
        onHardwareReset: () async {
          await _initHardwareAndList();
        },
      ),
    );
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => VerificationHistoryDialog(
        logs: _verificationLogs,
        onClearLogs: () {
          setState(() => _verificationLogs.clear());
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Color(0xFF3584E4)),
            SizedBox(width: 10),
            Text('Acerca de Fprint-Manager', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gestor de autenticación biométrica de huellas dactilares para Linux Desktop (elementary OS Pantheon / GTK).',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Text('• Almacenamiento: /var/lib/fprint/${FprintService.getUsername()}/ (Base de datos del sistema)', style: const TextStyle(fontSize: 12.5, color: Colors.grey)),
              Text('• ¿Sirve para Login y Sudo?: ${_isPamEnabled ? "SÍ (Módulo pam_fprintd activo en /etc/pam.d/common-auth)" : "NO (Desactivado en PAM)"}', style: const TextStyle(fontSize: 12.5, color: Colors.grey)),
              Text('• Hardware: $_deviceName (Dell Precision 5540)', style: const TextStyle(fontSize: 12.5, color: Colors.grey)),
              Text('• Dispositivo USB: 27c6:5395 Goodix HTK32', style: const TextStyle(fontSize: 12.5, color: Colors.grey)),
              Text('• Pasos de lectura: $_totalEnrollStages etapas', style: const TextStyle(fontSize: 12.5, color: Colors.grey)),
              Text('• Parámetro obligatorio: bandera -f activada', style: const TextStyle(fontSize: 12.5, color: Colors.grey)),
              Text('• Permisos Polkit: ${_isPolkitConfigured ? "Permanentes (Sin contraseñas repetidas)" : "Predeterminados"}', style: const TextStyle(fontSize: 12.5, color: Colors.grey)),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  /// Manejo de atajos de teclado para escritorio (Espacio/Enter: Escanear, Esc: Cancelar, Ctrl+R: Recargar)
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.enter) {
        _startRealVerification();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        if (_sensorState == SensorState.scanning) {
          _cancelActiveVerification();
          return KeyEventResult.handled;
        }
      } else if (HardwareKeyboard.instance.isControlPressed &&
          event.logicalKey == LogicalKeyboardKey.keyR) {
        _initHardwareAndList();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Focus(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        // 1. HEADERBAR ESTILO ELEMENTARY OS / MACOS
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            decoration: BoxDecoration(
              color: theme.appBarTheme.backgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3584E4).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.fingerprint_rounded,
                        color: Color(0xFF3584E4),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Fprint-Manager',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF333336) : const Color(0xFFE9ECEF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Dell Precision 5540',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3584E4),
                        ),
                      ),
                    ),
                    const Spacer(),

                    // Botón para ver el historial de autenticaciones
                    IconButton(
                      tooltip: 'Historial de verificaciones (${_verificationLogs.length})',
                      icon: Badge(
                        isLabelVisible: _verificationLogs.isNotEmpty,
                        label: Text('${_verificationLogs.length}'),
                        backgroundColor: const Color(0xFF3584E4),
                        child: const Icon(Icons.history_rounded, size: 20),
                      ),
                      onPressed: _showHistoryDialog,
                    ),
                    const SizedBox(width: 4),

                    // Botón de herramientas / mantenimiento avanzado
                    IconButton(
                      tooltip: 'Mantenimiento del sensor y permisos Polkit',
                      icon: const Icon(Icons.build_circle_outlined, size: 20),
                      onPressed: _showMaintenanceDialog,
                    ),
                    const SizedBox(width: 4),

                    IconButton(
                      tooltip: isDark ? 'Cambiar a tema claro' : 'Cambiar a tema oscuro',
                      icon: Icon(
                        isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                        size: 19,
                      ),
                      onPressed: widget.onToggleTheme,
                    ),
                    const SizedBox(width: 4),

                    IconButton(
                      tooltip: 'Información del dispositivo',
                      icon: const Icon(Icons.info_outline_rounded, size: 19),
                      onPressed: _showInfoDialog,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 2. CUERPO PRINCIPAL DIVIDIDO (RESPONSIVO)
        body: Column(
          children: [
            _buildDeviceStatusStrip(context),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWideLayout = constraints.maxWidth >= 720;

                  if (isWideLayout) {
                    final listPanelWidth = constraints.maxWidth * 0.42 > 380.0
                        ? 380.0
                        : (constraints.maxWidth * 0.42 < 310.0 ? 310.0 : constraints.maxWidth * 0.42);

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: listPanelWidth,
                          child: _buildFingerprintsListPanel(context),
                        ),
                        VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: theme.dividerColor,
                        ),
                        Expanded(
                          child: _buildSensorInteractivePanel(context),
                        ),
                      ],
                    );
                  } else {
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildSensorInteractivePanel(context),
                          Divider(height: 1, thickness: 1, color: theme.dividerColor),
                          _buildFingerprintsListPanel(context),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
            _buildBottomActionBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceStatusStrip(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222225) : const Color(0xFFF1F3F5),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF2EC27E),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Lector Goodix (27c6:5395) • $_totalEnrollStages etapas • Bandera -f activa',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6C757D),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final willEnable = !_isPamEnabled;
              final success = await FprintService.setPamAuthenticationEnabled(willEnable);
              await _initHardwareAndList();
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? (willEnable
                            ? 'Inicio de sesión, bloqueo y sudo habilitados con huella.'
                            : 'Autenticación con huella en el sistema deshabilitada.')
                        : 'No se pudo cambiar la configuración de PAM.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _isPamEnabled
                    ? const Color(0xFF2EC27E).withValues(alpha: 0.15)
                    : const Color(0xFFF5C211).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _isPamEnabled
                      ? const Color(0xFF2EC27E).withValues(alpha: 0.35)
                      : const Color(0xFFF5C211).withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isPamEnabled ? Icons.shield_rounded : Icons.shield_outlined,
                    size: 13,
                    color: _isPamEnabled ? const Color(0xFF2EC27E) : const Color(0xFFF5C211),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _isPamEnabled ? 'Login & Sudo: Activo' : 'Login & Sudo: Desactivado',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _isPamEnabled
                          ? (isDark ? const Color(0xFF2EC27E) : const Color(0xFF1B824B))
                          : (isDark ? const Color(0xFFF5C211) : const Color(0xFFB58105)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              '${_fingerprints.length} huellas registradas',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFingerprintsListPanel(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Huellas Registradas',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3584E4).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_fingerprints.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3584E4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_fingerprints.isNotEmpty)
                  IconButton(
                    tooltip: 'Borrar todas las huellas de fprintd',
                    style: IconButton.styleFrom(
                      foregroundColor: const Color(0xFFE01B24),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.delete_sweep_rounded, size: 20),
                    onPressed: _confirmDeleteAllFingerprints,
                  ),
                const SizedBox(width: 4),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _showAddFingerprintDialog,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Agregar', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoadingList
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : _fingerprints.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.fingerprint_rounded,
                                size: 48,
                                color: theme.disabledColor,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No hay huellas registradas',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Haz clic en "Agregar" para registrar tu huella usando la bandera -f en fprintd.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: theme.hintColor, fontSize: 12.5),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        itemCount: _fingerprints.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = _fingerprints[index];
                          final isSelected = item.fingerCode == _selectedVerifyFingerCode;
                          return _buildFingerprintCard(context, item, isSelected);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFingerprintCard(BuildContext context, FingerprintItem item, bool isSelected) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCustomized = item.name != item.fingerName;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2E) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF3584E4)
              : (isDark ? const Color(0xFF3A3A3E) : const Color(0xFFE4E7EB)),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFF3584E4).withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          setState(() {
            _selectedVerifyFingerCode = item.fingerCode;
            _sensorStatusText = 'Seleccionado: ${item.name} (-f ${item.fingerCode}). Listo para verificar.';
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF3584E4).withValues(alpha: 0.15)
                      : (isDark ? const Color(0xFF38383D) : const Color(0xFFEBF3FC)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.fingerprint_rounded,
                  color: isSelected ? const Color(0xFF3584E4) : const Color(0xFF6C757D),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              fontSize: 14,
                              color: isSelected ? const Color(0xFF3584E4) : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3584E4).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Objetivo activo',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3584E4),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (isCustomized) ...[
                          Text(
                            item.fingerName,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF333336) : const Color(0xFFEAECEF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '-f ${item.fingerCode}',
                            style: TextStyle(
                              fontSize: 10,
                              fontFamily: 'monospace',
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Botón para editar el nombre de la huella
              IconButton(
                tooltip: 'Personalizar nombre',
                style: IconButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: const Color(0xFF3584E4),
                ),
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: () => _editFingerName(item),
              ),

              // Botón para eliminar la huella
              IconButton(
                tooltip: 'Eliminar esta huella de fprintd',
                style: IconButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: const Color(0xFFE01B24),
                  hoverColor: const Color(0xFFE01B24).withValues(alpha: 0.08),
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 19),
                onPressed: () => _confirmDeleteFingerprint(item),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSensorInteractivePanel(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isScanning = _sensorState == SensorState.scanning;

    Color badgeColor;
    IconData stateIcon;
    String badgeTitle;

    switch (_sensorState) {
      case SensorState.scanning:
        badgeColor = const Color(0xFF3584E4);
        stateIcon = Icons.hourglass_top_rounded;
        badgeTitle = 'ESPERANDO LECTURA EN SENSOR FÍSICO';
        break;
      case SensorState.success:
        badgeColor = const Color(0xFF2EC27E);
        stateIcon = Icons.check_circle_rounded;
        badgeTitle = 'VERIFICACIÓN EXITOSA (VERIFY-MATCH)';
        break;
      case SensorState.error:
        badgeColor = const Color(0xFFE01B24);
        stateIcon = Icons.error_rounded;
        badgeTitle = 'FALLO DE LECTURA / NO COINCIDE';
        break;
      case SensorState.idle:
        badgeColor = isDark ? const Color(0xFF7C828A) : const Color(0xFF4A5568);
        stateIcon = Icons.touch_app_rounded;
        badgeTitle = 'LISTO PARA LECTURA (ESPACIO/CLICK)';
        break;
    }

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.35), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(stateIcon, size: 14, color: badgeColor),
                      const SizedBox(width: 7),
                      Text(
                        badgeTitle,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: badgeColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // WIDGET CENTRAL CON ANIMACIONES AVANZADAS (ONDAS, RELLENO, SHAKE, BOUNCE)
                FingerprintScannerWidget(
                  state: _sensorState,
                  progress: _sensorState == SensorState.success ? 1.0 : (isScanning ? 0.45 : 0.0),
                  pulseAnimation: _scaleAnimation,
                  onTap: _startRealVerification,
                  size: 160,
                ),

                const SizedBox(height: 16),

                // Selector explícito del dedo que se verificará con bandera -f
                if (_fingerprints.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF262629) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? const Color(0xFF3A3A3E) : const Color(0xFFE4E7EB),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedVerifyFingerCode,
                        isExpanded: true,
                        hint: const Text('Selecciona el dedo a verificar'),
                        items: _fingerprints.map((item) {
                          return DropdownMenuItem(
                            value: item.fingerCode,
                            child: Row(
                              children: [
                                const Icon(Icons.fingerprint, size: 16, color: Color(0xFF3584E4)),
                                const SizedBox(width: 8),
                                Expanded(child: Text(item.name, overflow: TextOverflow.ellipsis)),
                                Text('(-f ${item.fingerCode})', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: isScanning
                            ? null
                            : (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedVerifyFingerCode = val;
                                    final selected = _fingerprints.firstWhere((f) => f.fingerCode == val);
                                    _sensorStatusText = 'Seleccionado: ${selected.name}. Listo para verificar.';
                                  });
                                }
                              },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    _sensorStatusText,
                    key: ValueKey<String>(_sensorStatusText),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: _sensorState == SensorState.success
                          ? const Color(0xFF2EC27E)
                          : _sensorState == SensorState.error
                              ? const Color(0xFFE01B24)
                              : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: isScanning ? const Color(0xFFE01B24) : const Color(0xFF3584E4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      onPressed: isScanning ? _cancelActiveVerification : _startRealVerification,
                      icon: Icon(isScanning ? Icons.stop_rounded : Icons.fingerprint, size: 18),
                      label: Text(
                        isScanning
                            ? 'Cancelar Verificación (Esc)'
                            : (_selectedVerifyFingerCode != null
                                ? 'Verificar ${_fingerprints.firstWhere((f) => f.fingerCode == _selectedVerifyFingerCode, orElse: () => _fingerprints.first).name}'
                                : 'Verificar con Sensor Real'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242426) : Colors.white,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    _isRestartingUsb ? Icons.sync_rounded : Icons.shield_outlined,
                    size: 18,
                    color: _isRestartingUsb ? const Color(0xFF3584E4) : const Color(0xFF2EC27E),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _isRestartingUsb
                          ? 'Reiniciando bus USB (Goodix 27c6:5395)...'
                          : 'fprintd.service: Activo • Polkit: ${_isPolkitConfigured ? "Sin contraseñas" : "Predeterminado"}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: _isRestartingUsb ? null : _restartUsbReader,
              icon: _isRestartingUsb
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.restart_alt_rounded, size: 18),
              label: Text(
                _isRestartingUsb ? 'Reiniciando...' : 'Reiniciar Sensor y Servicio USB',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
