// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Fprint-Manager';

  @override
  String get fingerAny => 'Any finger (automatic)';

  @override
  String get fingerRightIndex => 'Right Index';

  @override
  String get fingerRightThumb => 'Right Thumb';

  @override
  String get fingerRightMiddle => 'Right Middle';

  @override
  String get fingerRightRing => 'Right Ring';

  @override
  String get fingerRightLittle => 'Right Little';

  @override
  String get fingerLeftIndex => 'Left Index';

  @override
  String get fingerLeftThumb => 'Left Thumb';

  @override
  String get fingerLeftMiddle => 'Left Middle';

  @override
  String get fingerLeftRing => 'Left Ring';

  @override
  String get fingerLeftLittle => 'Left Little';

  @override
  String get scanTypePress => 'Touch';

  @override
  String get scanTypeSwipe => 'Swipe';

  @override
  String get tooltipSupportActive => 'Supporter active • Support project';

  @override
  String get tooltipSupport => 'Support project / Remove ads';

  @override
  String get tooltipReload => 'Reload readers and fingerprints (Ctrl+R)';

  @override
  String tooltipHistory(int count) {
    return 'Verification history ($count)';
  }

  @override
  String get tooltipMaintenance => 'System diagnostics and maintenance';

  @override
  String get tooltipLightTheme => 'Switch to light theme';

  @override
  String get tooltipDarkTheme => 'Switch to dark theme';

  @override
  String get tooltipInfo => 'System information';

  @override
  String get tooltipSwitchDevice => 'Switch active biometric reader';

  @override
  String get detectingHardware => 'Detecting hardware...';

  @override
  String get fprintdUnavailable => 'fprintd unavailable';

  @override
  String get noReaderConnected => 'No reader connected';

  @override
  String get permissionDenied => 'Permission denied';

  @override
  String get readerError => 'Reader error';

  @override
  String statusSummary(String name, String scanType, int stages) {
    return '$name • $scanType • $stages stages';
  }

  @override
  String get queryingDBus => 'Querying D-Bus net.reactivated.Fprint...';

  @override
  String get readerUnavailable => 'Reader unavailable';

  @override
  String get tooltipPamToggle =>
      'Enable or disable fingerprint for login and sudo (PAM)';

  @override
  String get pamActiveShort => 'Login & Sudo: Active';

  @override
  String get pamOffShort => 'Login & Sudo: Off';

  @override
  String get searchingReaders =>
      'Searching for biometric readers on the system...';

  @override
  String get connectingDBus => 'Connecting via D-Bus to net.reactivated.Fprint';

  @override
  String get serviceUnavailableTitle => 'fprintd service unavailable';

  @override
  String get noDeviceFoundTitle => 'No fingerprint reader detected';

  @override
  String get permissionDeniedTitle => 'Insufficient D-Bus permissions';

  @override
  String get initReaderErrorTitle => 'Could not initialize biometric reader';

  @override
  String get serviceUnavailableDesc =>
      'Could not communicate with net.reactivated.Fprint. Verify that the fprintd package is installed and active on your Linux distribution.';

  @override
  String get noDeviceFoundDesc =>
      'The fprintd service is active, but libfprint did not detect any compatible connected sensors. If you have a USB reader that got stuck after suspend, try resetting the sensor.';

  @override
  String get permissionDeniedDesc =>
      'Polkit denied access to the device. Configure permanent permissions in the Diagnostics & Maintenance panel.';

  @override
  String get hardwareQueryErrorDesc =>
      'A problem occurred while querying the hardware.';

  @override
  String detectedUsbDevices(String devices) {
    return 'Detected USB devices: $devices';
  }

  @override
  String get recommendedInstall =>
      'Recommended installation:\n• elementary OS / Ubuntu / Debian: sudo apt install fprintd libpam-fprintd\n• Fedora: sudo dnf install fprintd fprintd-pam\n• Arch Linux: sudo pacman -S fprintd';

  @override
  String get retryDetection => 'Retry detection';

  @override
  String get restartReaderAndFprintd => 'Restart reader and fprintd';

  @override
  String get openDiagnostics => 'Open diagnostics';

  @override
  String get tabVerify => 'Verify';

  @override
  String get tabPrints => 'Fingerprints';

  @override
  String get enrolledFingerprints => 'Enrolled Fingerprints';

  @override
  String get deleteAllTooltip => 'Delete all fingerprints from this reader';

  @override
  String get addButton => 'Add';

  @override
  String get noEnrolledPrints => 'No enrolled fingerprints';

  @override
  String get noEnrolledPrintsHint =>
      'Press \"Add\" to enroll your first fingerprint.';

  @override
  String get targetBadge => 'Target';

  @override
  String get editCustomNameTooltip => 'Edit custom name';

  @override
  String get deletePrintTooltip => 'Delete fingerprint';

  @override
  String get badgeReading => 'READING FINGERPRINT...';

  @override
  String get badgeWaiting => 'WAITING FOR SENSOR INPUT';

  @override
  String get badgeSuccess => 'VERIFICATION SUCCESSFUL';

  @override
  String badgeSuccessWithFinger(String finger) {
    return 'VERIFICATION SUCCESSFUL • $finger';
  }

  @override
  String get badgeError => 'NO MATCH / ERROR';

  @override
  String get badgeRestarting => 'RESTARTING READER';

  @override
  String get badgeUnavailable => 'SENSOR UNAVAILABLE';

  @override
  String get badgeIdle => 'READY TO VERIFY (SPACE / CLICK)';

  @override
  String get promptIdleAuto =>
      'Press \"Verify fingerprint\" or Space to test any enrolled finger.';

  @override
  String get promptIdleNoPrints =>
      'No fingerprints enrolled yet. Press \"Register first fingerprint\".';

  @override
  String get promptAutoSelected =>
      'Automatic mode active: will verify against all your fingerprints.';

  @override
  String promptTargetSelected(String finger) {
    return 'Target: $finger. Press to verify.';
  }

  @override
  String get promptScanningAuto =>
      'Sensor active (automatic detection). Place any of your fingerprints...';

  @override
  String promptScanningTarget(String code, String finger) {
    return 'Sensor active (-f $code). Place \"$finger\" on the reader...';
  }

  @override
  String get verifyCancelledPrompt => 'Verification cancelled. Press to start.';

  @override
  String verifyMatchDetected(String finger) {
    return 'Fingerprint verified successfully!\nDetected finger: $finger';
  }

  @override
  String verifyMatchAutoUnknown(int count) {
    return 'Fingerprint verified successfully!\nMatched one of your $count enrolled fingerprints (fprintd does not report the specific finger in automatic mode).';
  }

  @override
  String get verifyNoMatchAny =>
      'Fingerprint did not match any enrolled print. Try again.';

  @override
  String verifyNoMatchTarget(String finger) {
    return 'Fingerprint did not match \"$finger\". Try again.';
  }

  @override
  String verifyErrorPrefix(String error) {
    return 'Verification error: $error';
  }

  @override
  String get cancelVerificationBtn => 'Cancel verification (Esc)';

  @override
  String get verifyAnyBtn => 'Verify fingerprint';

  @override
  String verifyTargetBtn(String finger) {
    return 'Verify $finger';
  }

  @override
  String get registerFirstPrintBtn => 'Register first fingerprint';

  @override
  String get noPrintsToVerify => 'No fingerprints enrolled to verify.';

  @override
  String get bottomBarRestarting => 'Restarting service and hardware...';

  @override
  String bottomBarStatus(String service, String polkit) {
    return 'fprintd: $service • Polkit: $polkit';
  }

  @override
  String get statusActive => 'Active';

  @override
  String get statusInactive => 'Inactive';

  @override
  String get polkitPasswordless => 'Passwordless';

  @override
  String get polkitDefault => 'Default';

  @override
  String get restartingBtn => 'Restarting...';

  @override
  String get hardwareRestartBtn => 'Hardware restart...';

  @override
  String get restartReaderServiceBtn => 'Restart reader & service';

  @override
  String get closeBtn => 'Close';

  @override
  String get cancelBtn => 'Cancel';

  @override
  String get saveBtn => 'Save';

  @override
  String get deleteBtn => 'Delete';

  @override
  String get deleteAllBtn => 'Delete All';

  @override
  String get understoodBtn => 'Got it';

  @override
  String get retryBtn => 'Retry';

  @override
  String get copyCommandBtn => 'Copy command';

  @override
  String get commandCopied => 'Command copied to clipboard.';

  @override
  String get manualRestartTitle => 'Manual restart required';

  @override
  String get configurePamTitle => 'Configure PAM (Login & sudo)';

  @override
  String get deletePrintTitle => 'Delete fingerprint';

  @override
  String deletePrintConfirm(String name, String code, String device) {
    return 'Do you want to permanently delete \"$name\" ($code) from $device?';
  }

  @override
  String deletePrintSuccess(String name) {
    return 'Fingerprint \"$name\" deleted successfully.';
  }

  @override
  String get deletePrintFailed => 'Could not delete the fingerprint.';

  @override
  String get deleteAllTitle => 'Delete all fingerprints';

  @override
  String deleteAllConfirm(String device) {
    return 'Are you sure you want to delete ALL enrolled fingerprints on $device? This action cannot be undone.';
  }

  @override
  String get deleteAllSuccess => 'All fingerprints have been deleted.';

  @override
  String get deleteAllFailed => 'Could not delete fingerprints.';

  @override
  String aliasUpdated(String finger, String name) {
    return 'Name for \"$finger\" updated to \"$name\".';
  }

  @override
  String get aboutTitle => 'About Fprint-Manager';

  @override
  String get aboutDescription =>
      'Biometric fingerprint manager for Linux desktop and elementary OS, connected via D-Bus to fprintd and libfprint.';

  @override
  String get aboutActiveReader => 'Active reader';

  @override
  String get aboutNoActiveReader => 'No active reader';

  @override
  String aboutReaderDesc(String name, String scanType, int stages) {
    return '$name ($scanType, $stages stages)';
  }

  @override
  String get aboutRuntimeEnv => 'Runtime environment';

  @override
  String get aboutFlatpak => 'Flatpak Sandbox';

  @override
  String get aboutNativeLinux => 'Native Linux';

  @override
  String get aboutSystemUser => 'System user';

  @override
  String get aboutAliasConfig => 'Aliases configuration';

  @override
  String get aboutPamAuth => 'PAM authentication';

  @override
  String get aboutPamActive => 'Active (Login, lock screen & sudo)';

  @override
  String get aboutPamDisabled => 'Disabled';

  @override
  String get aboutPolkit => 'Polkit permissions';

  @override
  String get aboutPolkitPermanent => 'Permanent';

  @override
  String get aboutPolkitDefault => 'Default';

  @override
  String get editNameTitle => 'Customize Fingerprint Name';

  @override
  String get assignedFingerLabel => 'Assigned finger:';

  @override
  String get customNameLabel => 'Descriptive name or label:';

  @override
  String get customNameHint => 'E.g. Primary finger for sudo';

  @override
  String get clearFieldTooltip => 'Clear field';

  @override
  String restoreOriginalBtn(String name) {
    return 'Restore original ($name)';
  }

  @override
  String get historyTitle => 'Verification History';

  @override
  String get clearHistoryBtn => 'Clear';

  @override
  String get historyEmptyTitle => 'No activity recorded';

  @override
  String get historyEmptyDesc =>
      'Whenever you test the biometric sensor, the results will be recorded here.';

  @override
  String enrollTitleActive(String finger) {
    return 'Enrolling: $finger';
  }

  @override
  String get enrollTitleIdle => 'Register New Fingerprint';

  @override
  String get enrollOverwriteBtn => 'Overwrite fingerprint';

  @override
  String get enrollStartBtn => 'Start enrollment';

  @override
  String get enrollSelectFinger => 'Select the finger you want to enroll:';

  @override
  String get enrollAlreadyBadge => 'Enrolled';

  @override
  String get enrollAlreadyNote =>
      'Note: This finger already has a saved print; enrolling again will replace it in fprintd.';

  @override
  String enrollSwipeHint(int stages) {
    return 'Your reader is a swipe sensor: it will require $stages smooth swipes across the sensor.';
  }

  @override
  String enrollPressHint(int stages) {
    return 'Your reader is a touch sensor: it will require placing and lifting your finger $stages times until the ring reaches 100%.';
  }

  @override
  String get enrollSwipeStart =>
      'Swipe your finger smoothly across the sensor to begin.';

  @override
  String get enrollPressStart =>
      'Place your finger firmly on the sensor to begin.';

  @override
  String enrollPreparing(String device) {
    return 'Preparing sensor $device...';
  }

  @override
  String enrollErrorPrefix(String error) {
    return 'Error during enrollment: $error';
  }

  @override
  String get enrollCompletedBadge => 'Enrollment completed • 100%!';

  @override
  String enrollStageBadge(int current, int total, int percent) {
    return 'Stage $current of $total • $percent%';
  }

  @override
  String get bannerIndieLabel => 'Indie Project';

  @override
  String bannerRemoveBtn(String price) {
    return 'Remove ($price)';
  }

  @override
  String get supportTitle => 'Support Fprint-Manager';

  @override
  String supportOpenBrowserError(String url) {
    return 'Could not open browser. Visit manually: $url';
  }

  @override
  String supportOpenCheckoutError(String url) {
    return 'Could not open checkout page: $url';
  }

  @override
  String get supportLicenseRemoved => 'License removed from this device.';

  @override
  String get supportDonationTitle => 'Voluntary donation (PayPal / Ko-fi)';

  @override
  String get supportDonationDesc =>
      'Fprint-Manager is free software with no feature locks. If you find it useful, you can buy me a coffee or send a direct contribution.';

  @override
  String get supportDonateBtn => 'Donate with PayPal / Ko-fi';

  @override
  String get supportLicenseActiveTitle => 'Supporter License Active';

  @override
  String supportLicenseKeyLabel(String key) {
    return 'Key: $key';
  }

  @override
  String supportLicenseHolderLabel(String email) {
    return 'Holder: $email';
  }

  @override
  String get supportDeactivateBtn => 'Deactivate on this device';

  @override
  String supportRemoveAdsTitle(String price) {
    return 'Remove ads ($price)';
  }

  @override
  String get supportRemoveAdsDesc =>
      'One-time payment via card or PayPal. You will immediately receive a license key to hide the banner on your device.';

  @override
  String supportGetKeyBtn(String price) {
    return 'Get license key ($price)';
  }

  @override
  String get supportKeyFieldLabel => 'Supporter license key';

  @override
  String get supportKeyFieldHint => 'Paste your key here';

  @override
  String get supportValidatingBtn => 'Validating...';

  @override
  String get supportActivateBtn => 'Activate license';

  @override
  String get maintTitle => 'Diagnostics & Maintenance';

  @override
  String get maintRefreshTooltip => 'Refresh diagnostics';

  @override
  String get maintEnvTitle => 'Linux Environment Status';

  @override
  String get maintNativeSession => 'Native Session';

  @override
  String get maintDbusRow => 'System D-Bus (net.reactivated.Fprint)';

  @override
  String get maintConnected => 'Connected';

  @override
  String get maintInactiveOrMissing => 'Inactive or not installed';

  @override
  String get maintReadersRow => 'Readers exposed by libfprint';

  @override
  String get maintNoneDetected => 'None detected';

  @override
  String get maintUsbRow => 'USB biometric sensors in sysfs';

  @override
  String get maintNoUsb => 'No USB reader (or internal SPI/I2C reader)';

  @override
  String get maintPamRow => 'PAM integration (login, lock & sudo)';

  @override
  String get maintEnabled => 'Enabled';

  @override
  String get maintDisabled => 'Disabled';

  @override
  String get maintPolkitRow => 'Passwordless Polkit rule';

  @override
  String get maintInstalled => 'Installed';

  @override
  String get maintMissingPackages =>
      'Required system packages if fprintd is not installed:';

  @override
  String get maintPolkitActive => 'Permanent Polkit permissions active';

  @override
  String get maintPolkitDefault => 'Default Polkit permissions';

  @override
  String get maintPolkitDesc =>
      'Allows users in the admin group to enroll or delete their own fingerprints without repeating their password for every action.';

  @override
  String get maintPolkitFlatpakBtn => 'View host permission command';

  @override
  String get maintPolkitReapplyBtn => 'Reapply Polkit rule';

  @override
  String get maintPolkitGrantBtn => 'Grant permanent permissions';

  @override
  String get maintPamActive => 'PAM authentication active (Login & sudo)';

  @override
  String get maintPamDisabled => 'PAM authentication disabled';

  @override
  String get maintPamActiveDesc =>
      'Enrolled fingerprints can be used to log in, unlock the screen, and authorize sudo.';

  @override
  String get maintPamDisabledDesc =>
      'Enable the pam_fprintd module to use your fingerprint at login and with sudo.';

  @override
  String get maintPamDisableBtn => 'Disable in Login & sudo';

  @override
  String get maintPamEnableBtn => 'Enable in Login & sudo';

  @override
  String get maintUsbTitle => 'Reader & fprintd Service Reset';

  @override
  String maintUsbDetected(String devices) {
    return 'Detected: $devices.';
  }

  @override
  String get maintUsbNone =>
      'No USB sensors detected in sysfs (if internal SPI/I2C, only fprintd will be restarted).';

  @override
  String maintUsbDesc(String summary) {
    return 'Recovers readers stuck after suspend or USB dock reconnection. $summary';
  }

  @override
  String get maintUsbFlatpakBtn => 'Generate host reset command';

  @override
  String get maintUsbResetBtn => 'Restart reader and fprintd service';

  @override
  String get maintStatusPolkit =>
      'Configuring Polkit rule for biometric permissions...';

  @override
  String get maintStatusPamEnable =>
      'Enabling fingerprint authentication for login and sudo...';

  @override
  String get maintStatusPamDisable =>
      'Disabling system fingerprint authentication...';

  @override
  String get maintStatusUsb =>
      'Restarting detected USB readers and fprintd service...';
}
