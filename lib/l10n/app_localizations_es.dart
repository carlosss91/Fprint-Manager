// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Fprint-Manager';

  @override
  String get fingerAny => 'Cualquier huella (automático)';

  @override
  String get fingerRightIndex => 'Índice Derecho';

  @override
  String get fingerRightThumb => 'Pulgar Derecho';

  @override
  String get fingerRightMiddle => 'Medio Derecho';

  @override
  String get fingerRightRing => 'Anular Derecho';

  @override
  String get fingerRightLittle => 'Meñique Derecho';

  @override
  String get fingerLeftIndex => 'Índice Izquierdo';

  @override
  String get fingerLeftThumb => 'Pulgar Izquierdo';

  @override
  String get fingerLeftMiddle => 'Medio Izquierdo';

  @override
  String get fingerLeftRing => 'Anular Izquierdo';

  @override
  String get fingerLeftLittle => 'Meñique Izquierdo';

  @override
  String get scanTypePress => 'Táctil';

  @override
  String get scanTypeSwipe => 'Deslizamiento';

  @override
  String get tooltipSupportActive => 'Supporter activo • Apoyar proyecto';

  @override
  String get tooltipSupport => 'Apoyar proyecto / Quitar anuncios';

  @override
  String get tooltipReload => 'Recargar lectores y huellas (Ctrl+R)';

  @override
  String tooltipHistory(int count) {
    return 'Historial de verificaciones ($count)';
  }

  @override
  String get tooltipMaintenance => 'Diagnóstico y mantenimiento del sistema';

  @override
  String get tooltipLightTheme => 'Cambiar a tema claro';

  @override
  String get tooltipDarkTheme => 'Cambiar a tema oscuro';

  @override
  String get tooltipInfo => 'Información del sistema';

  @override
  String get tooltipSwitchDevice => 'Cambiar lector biométrico activo';

  @override
  String get detectingHardware => 'Detectando hardware...';

  @override
  String get fprintdUnavailable => 'fprintd no disponible';

  @override
  String get noReaderConnected => 'Sin lector conectado';

  @override
  String get permissionDenied => 'Permiso denegado';

  @override
  String get readerError => 'Error de lector';

  @override
  String statusSummary(String name, String scanType, int stages) {
    return '$name • $scanType • $stages etapas';
  }

  @override
  String get queryingDBus => 'Consultando D-Bus net.reactivated.Fprint...';

  @override
  String get readerUnavailable => 'Lector no disponible';

  @override
  String get tooltipPamToggle =>
      'Habilitar o deshabilitar huella en login y sudo (PAM)';

  @override
  String get pamActiveShort => 'Login & Sudo: Activo';

  @override
  String get pamOffShort => 'Login & Sudo: Off';

  @override
  String get searchingReaders =>
      'Buscando lectores biométricos en el sistema...';

  @override
  String get connectingDBus => 'Conectando por D-Bus a net.reactivated.Fprint';

  @override
  String get serviceUnavailableTitle => 'Servicio fprintd no disponible';

  @override
  String get noDeviceFoundTitle => 'No se detectó ningún lector de huellas';

  @override
  String get permissionDeniedTitle => 'Permisos insuficientes en D-Bus';

  @override
  String get initReaderErrorTitle =>
      'No se pudo inicializar el lector biométrico';

  @override
  String get serviceUnavailableDesc =>
      'No fue posible comunicarse con net.reactivated.Fprint. Verifica que el paquete fprintd esté instalado y activo en tu distribución Linux.';

  @override
  String get noDeviceFoundDesc =>
      'El servicio fprintd está activo, pero libfprint no detectó sensores compatibles conectados. Si tienes un lector USB y quedó bloqueado tras suspender, prueba reiniciar el sensor.';

  @override
  String get permissionDeniedDesc =>
      'Polkit rechazó el acceso al dispositivo. Configura los permisos permanentes en el panel de Diagnóstico y Mantenimiento.';

  @override
  String get hardwareQueryErrorDesc =>
      'Ocurrió un problema al consultar el hardware.';

  @override
  String detectedUsbDevices(String devices) {
    return 'Dispositivos USB detectados: $devices';
  }

  @override
  String get recommendedInstall =>
      'Instalación recomendada:\n• elementary OS / Ubuntu / Debian: sudo apt install fprintd libpam-fprintd\n• Fedora: sudo dnf install fprintd fprintd-pam\n• Arch Linux: sudo pacman -S fprintd';

  @override
  String get retryDetection => 'Reintentar detección';

  @override
  String get restartReaderAndFprintd => 'Reiniciar lector y fprintd';

  @override
  String get openDiagnostics => 'Abrir diagnóstico';

  @override
  String get tabVerify => 'Verificar';

  @override
  String get tabPrints => 'Huellas';

  @override
  String get enrolledFingerprints => 'Huellas Registradas';

  @override
  String get deleteAllTooltip => 'Borrar todas las huellas de este lector';

  @override
  String get addButton => 'Agregar';

  @override
  String get noEnrolledPrints => 'Sin huellas inscritas';

  @override
  String get noEnrolledPrintsHint =>
      'Pulsa \"Agregar\" para registrar tu primera huella.';

  @override
  String get targetBadge => 'Objetivo';

  @override
  String get editCustomNameTooltip => 'Editar nombre personalizado';

  @override
  String get deletePrintTooltip => 'Eliminar huella';

  @override
  String get badgeReading => 'LEYENDO HUELLA...';

  @override
  String get badgeWaiting => 'ESPERANDO LECTURA EN EL SENSOR';

  @override
  String get badgeSuccess => 'VERIFICACIÓN EXITOSA';

  @override
  String badgeSuccessWithFinger(String finger) {
    return 'VERIFICACIÓN EXITOSA • $finger';
  }

  @override
  String get badgeError => 'SIN COINCIDENCIA / ERROR';

  @override
  String get badgeRestarting => 'REINICIANDO LECTOR';

  @override
  String get badgeUnavailable => 'SENSOR NO DISPONIBLE';

  @override
  String get badgeIdle => 'LISTO PARA VERIFICAR (ESPACIO / CLIC)';

  @override
  String get promptIdleAuto =>
      'Pulsa \"Verificar huella\" o Espacio para probar cualquiera de tus dedos.';

  @override
  String get promptIdleNoPrints =>
      'No hay huellas registradas aún. Pulsa \"Registrar primera huella\".';

  @override
  String get promptAutoSelected =>
      'Modo automático activo: verificará contra todas tus huellas.';

  @override
  String promptTargetSelected(String finger) {
    return 'Objetivo: $finger. Pulsa para verificar.';
  }

  @override
  String get promptScanningAuto =>
      'Sensor activo (detección automática). Apoya cualquiera de tus huellas...';

  @override
  String promptScanningTarget(String code, String finger) {
    return 'Sensor activo (-f $code). Apoya \"$finger\" en el lector...';
  }

  @override
  String get verifyCancelledPrompt =>
      'Verificación cancelada. Pulsa para iniciar.';

  @override
  String verifyMatchDetected(String finger) {
    return '¡Huella verificada con éxito!\nHuella detectada: $finger';
  }

  @override
  String verifyMatchAutoUnknown(int count) {
    return '¡Huella verificada con éxito!\nCoincidencia con una de tus $count huellas registradas (fprintd no informa el dedo en modo automático).';
  }

  @override
  String get verifyNoMatchAny =>
      'La huella no coincide con ninguna registrada. Intenta de nuevo.';

  @override
  String verifyNoMatchTarget(String finger) {
    return 'La huella no coincide con \"$finger\". Intenta de nuevo.';
  }

  @override
  String verifyErrorPrefix(String error) {
    return 'Error en verificación: $error';
  }

  @override
  String get cancelVerificationBtn => 'Cancelar verificación (Esc)';

  @override
  String get verifyAnyBtn => 'Verificar huella';

  @override
  String verifyTargetBtn(String finger) {
    return 'Verificar $finger';
  }

  @override
  String get registerFirstPrintBtn => 'Registrar primera huella';

  @override
  String get noPrintsToVerify =>
      'No tienes huellas registradas para verificar.';

  @override
  String get bottomBarRestarting => 'Reiniciando servicio y hardware...';

  @override
  String bottomBarStatus(String service, String polkit) {
    return 'fprintd: $service • Polkit: $polkit';
  }

  @override
  String get statusActive => 'Activo';

  @override
  String get statusInactive => 'Inactivo';

  @override
  String get polkitPasswordless => 'Sin contraseñas';

  @override
  String get polkitDefault => 'Predeterminado';

  @override
  String get restartingBtn => 'Reiniciando...';

  @override
  String get hardwareRestartBtn => 'Reinicio de hardware...';

  @override
  String get restartReaderServiceBtn => 'Reiniciar lector y servicio';

  @override
  String get closeBtn => 'Cerrar';

  @override
  String get cancelBtn => 'Cancelar';

  @override
  String get saveBtn => 'Guardar';

  @override
  String get deleteBtn => 'Eliminar';

  @override
  String get deleteAllBtn => 'Borrar Todo';

  @override
  String get understoodBtn => 'Entendido';

  @override
  String get retryBtn => 'Reintentar';

  @override
  String get copyCommandBtn => 'Copiar comando';

  @override
  String get commandCopied => 'Comando copiado al portapapeles.';

  @override
  String get manualRestartTitle => 'Reinicio manual requerido';

  @override
  String get configurePamTitle => 'Configurar PAM (Login y sudo)';

  @override
  String get deletePrintTitle => 'Eliminar huella';

  @override
  String deletePrintConfirm(String name, String code, String device) {
    return '¿Deseas eliminar permanentemente \"$name\" ($code) de $device?';
  }

  @override
  String deletePrintSuccess(String name) {
    return 'Huella \"$name\" eliminada correctamente.';
  }

  @override
  String get deletePrintFailed => 'No se pudo eliminar la huella.';

  @override
  String get deleteAllTitle => 'Borrar todas las huellas';

  @override
  String deleteAllConfirm(String device) {
    return '¿Estás seguro de que deseas borrar TODAS las huellas registradas en $device? Esta acción no se puede deshacer.';
  }

  @override
  String get deleteAllSuccess => 'Todas las huellas han sido eliminadas.';

  @override
  String get deleteAllFailed => 'No se pudieron eliminar las huellas.';

  @override
  String aliasUpdated(String finger, String name) {
    return 'Nombre de \"$finger\" actualizado a \"$name\".';
  }

  @override
  String get aboutTitle => 'Acerca de Fprint-Manager';

  @override
  String get aboutDescription =>
      'Gestor biométrico de huellas dactilares para escritorio Linux y elementary OS, conectado mediante D-Bus a fprintd y libfprint.';

  @override
  String get aboutActiveReader => 'Lector activo';

  @override
  String get aboutNoActiveReader => 'Ningún lector activo';

  @override
  String aboutReaderDesc(String name, String scanType, int stages) {
    return '$name ($scanType, $stages etapas)';
  }

  @override
  String get aboutRuntimeEnv => 'Entorno de ejecución';

  @override
  String get aboutFlatpak => 'Flatpak Sandbox';

  @override
  String get aboutNativeLinux => 'Nativo Linux';

  @override
  String get aboutSystemUser => 'Usuario del sistema';

  @override
  String get aboutAliasConfig => 'Configuración de apodos';

  @override
  String get aboutPamAuth => 'Autenticación PAM';

  @override
  String get aboutPamActive => 'Activa (Login, bloqueo y sudo)';

  @override
  String get aboutPamDisabled => 'Deshabilitado';

  @override
  String get aboutPolkit => 'Permisos Polkit';

  @override
  String get aboutPolkitPermanent => 'Permanentes';

  @override
  String get aboutPolkitDefault => 'Predeterminados';

  @override
  String get editNameTitle => 'Personalizar Nombre de Huella';

  @override
  String get assignedFingerLabel => 'Dedo asignado:';

  @override
  String get customNameLabel => 'Nombre o etiqueta descriptiva:';

  @override
  String get customNameHint => 'Ej. Dedo principal para sudo';

  @override
  String get clearFieldTooltip => 'Limpiar campo';

  @override
  String restoreOriginalBtn(String name) {
    return 'Restaurar original ($name)';
  }

  @override
  String get historyTitle => 'Historial de Verificaciones';

  @override
  String get clearHistoryBtn => 'Limpiar';

  @override
  String get historyEmptyTitle => 'Sin actividad registrada';

  @override
  String get historyEmptyDesc =>
      'Cada vez que pruebes el sensor biométrico, los resultados quedarán registrados aquí.';

  @override
  String enrollTitleActive(String finger) {
    return 'Registrando: $finger';
  }

  @override
  String get enrollTitleIdle => 'Registrar nueva huella';

  @override
  String get enrollOverwriteBtn => 'Sobrescribir huella';

  @override
  String get enrollStartBtn => 'Iniciar registro';

  @override
  String get enrollSelectFinger => 'Selecciona el dedo que deseas registrar:';

  @override
  String get enrollAlreadyBadge => 'Ya inscrita';

  @override
  String get enrollAlreadyNote =>
      'Nota: Este dedo ya tiene una huella guardada; al registrarlo nuevamente se reemplazará en fprintd.';

  @override
  String enrollSwipeHint(int stages) {
    return 'Tu lector es de deslizamiento: requerirá $stages pasadas suaves sobre el sensor.';
  }

  @override
  String enrollPressHint(int stages) {
    return 'Tu lector es táctil: requerirá apoyar y levantar el dedo $stages veces hasta completar el círculo al 100%.';
  }

  @override
  String get enrollSwipeStart =>
      'Desliza tu dedo suavemente sobre el sensor para comenzar.';

  @override
  String get enrollPressStart =>
      'Coloca tu dedo firmemente sobre el sensor para comenzar.';

  @override
  String enrollPreparing(String device) {
    return 'Preparando el sensor $device...';
  }

  @override
  String enrollErrorPrefix(String error) {
    return 'Error durante el registro: $error';
  }

  @override
  String get enrollCompletedBadge => '¡Registro completado • 100%!';

  @override
  String enrollStageBadge(int current, int total, int percent) {
    return 'Etapa $current de $total • $percent%';
  }

  @override
  String get bannerIndieLabel => 'Proyecto Indie';

  @override
  String bannerRemoveBtn(String price) {
    return 'Quitar ($price)';
  }

  @override
  String get supportTitle => 'Apoyar Fprint-Manager';

  @override
  String supportOpenBrowserError(String url) {
    return 'No se pudo abrir el navegador. Visita manualmente: $url';
  }

  @override
  String supportOpenCheckoutError(String url) {
    return 'No se pudo abrir la página de compra: $url';
  }

  @override
  String get supportLicenseRemoved => 'Licencia eliminada de este equipo.';

  @override
  String get supportDonationTitle => 'Donación voluntaria (PayPal / Ko-fi)';

  @override
  String get supportDonationDesc =>
      'Fprint-Manager es software libre sin bloqueos funcionales. Si te resulta útil, puedes invitar a un café o enviar un aporte directo.';

  @override
  String get supportDonateBtn => 'Donar con PayPal / Ko-fi';

  @override
  String get supportLicenseActiveTitle => 'Licencia Supporter Activa';

  @override
  String supportLicenseKeyLabel(String key) {
    return 'Clave: $key';
  }

  @override
  String supportLicenseHolderLabel(String email) {
    return 'Titular: $email';
  }

  @override
  String get supportDeactivateBtn => 'Desactivar en este equipo';

  @override
  String supportRemoveAdsTitle(String price) {
    return 'Quitar anuncios ($price)';
  }

  @override
  String get supportRemoveAdsDesc =>
      'Pago único con tarjeta o PayPal. Recibirás al instante una clave de licencia para ocultar el banner en tu equipo.';

  @override
  String supportGetKeyBtn(String price) {
    return 'Obtener clave ($price)';
  }

  @override
  String get supportKeyFieldLabel => 'Clave de licencia Supporter';

  @override
  String get supportKeyFieldHint => 'Pega aquí tu clave';

  @override
  String get supportValidatingBtn => 'Validando...';

  @override
  String get supportActivateBtn => 'Activar licencia';

  @override
  String get maintTitle => 'Diagnóstico y Mantenimiento';

  @override
  String get maintRefreshTooltip => 'Actualizar diagnóstico';

  @override
  String get maintEnvTitle => 'Estado del Entorno Linux';

  @override
  String get maintNativeSession => 'Sesión Nativa';

  @override
  String get maintDbusRow => 'Bus del sistema D-Bus (net.reactivated.Fprint)';

  @override
  String get maintConnected => 'Conectado';

  @override
  String get maintInactiveOrMissing => 'Inactivo o no instalado';

  @override
  String get maintReadersRow => 'Lectores expuestos por libfprint';

  @override
  String get maintNoneDetected => 'Ninguno detectado';

  @override
  String get maintUsbRow => 'Sensores biométricos USB en sysfs';

  @override
  String get maintNoUsb => 'Sin lector USB (o lector interno SPI/I2C)';

  @override
  String get maintPamRow => 'Integración PAM (login, bloqueo y sudo)';

  @override
  String get maintEnabled => 'Habilitado';

  @override
  String get maintDisabled => 'Deshabilitado';

  @override
  String get maintPolkitRow => 'Regla Polkit sin contraseñas repetidas';

  @override
  String get maintInstalled => 'Instalada';

  @override
  String get maintMissingPackages =>
      'Paquetes del sistema necesarios si fprintd no está instalado:';

  @override
  String get maintPolkitActive => 'Permisos permanentes Polkit activos';

  @override
  String get maintPolkitDefault => 'Permisos Polkit predeterminados';

  @override
  String get maintPolkitDesc =>
      'Permite que usuarios del grupo administrativo registren o eliminen sus propias huellas sin repetir la contraseña en cada acción.';

  @override
  String get maintPolkitFlatpakBtn => 'Ver comando de permisos para anfitrión';

  @override
  String get maintPolkitReapplyBtn => 'Reaplicar regla Polkit';

  @override
  String get maintPolkitGrantBtn => 'Autorizar permisos permanentes';

  @override
  String get maintPamActive => 'Autenticación PAM activa (Login y sudo)';

  @override
  String get maintPamDisabled => 'Autenticación PAM desactivada';

  @override
  String get maintPamActiveDesc =>
      'Las huellas registradas permiten iniciar sesión, desbloquear pantalla y autorizar sudo.';

  @override
  String get maintPamDisabledDesc =>
      'Activa el módulo pam_fprintd para usar tu huella al iniciar sesión y en sudo.';

  @override
  String get maintPamDisableBtn => 'Deshabilitar en Login y sudo';

  @override
  String get maintPamEnableBtn => 'Habilitar en Login y sudo';

  @override
  String get maintUsbTitle => 'Reinicio de Lector y Servicio fprintd';

  @override
  String maintUsbDetected(String devices) {
    return 'Detectado: $devices.';
  }

  @override
  String get maintUsbNone =>
      'No se detectaron sensores USB en sysfs (si es interno SPI/I2C, solo se reiniciará fprintd).';

  @override
  String maintUsbDesc(String summary) {
    return 'Recupera lectores bloqueados tras suspensión o reconexión de docks USB. $summary';
  }

  @override
  String get maintUsbFlatpakBtn => 'Generar comando de reinicio para anfitrión';

  @override
  String get maintUsbResetBtn => 'Reiniciar lector y servicio fprintd';

  @override
  String get maintStatusPolkit =>
      'Configurando regla Polkit para permisos biométricos...';

  @override
  String get maintStatusPamEnable =>
      'Habilitando autenticación por huella en login y sudo...';

  @override
  String get maintStatusPamDisable =>
      'Deshabilitando autenticación por huella en el sistema...';

  @override
  String get maintStatusUsb =>
      'Reiniciando lectores USB detectados y servicio fprintd...';
}
