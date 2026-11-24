import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Fprint-Manager'**
  String get appTitle;

  /// No description provided for @fingerAny.
  ///
  /// In en, this message translates to:
  /// **'Any finger (automatic)'**
  String get fingerAny;

  /// No description provided for @fingerRightIndex.
  ///
  /// In en, this message translates to:
  /// **'Right Index'**
  String get fingerRightIndex;

  /// No description provided for @fingerRightThumb.
  ///
  /// In en, this message translates to:
  /// **'Right Thumb'**
  String get fingerRightThumb;

  /// No description provided for @fingerRightMiddle.
  ///
  /// In en, this message translates to:
  /// **'Right Middle'**
  String get fingerRightMiddle;

  /// No description provided for @fingerRightRing.
  ///
  /// In en, this message translates to:
  /// **'Right Ring'**
  String get fingerRightRing;

  /// No description provided for @fingerRightLittle.
  ///
  /// In en, this message translates to:
  /// **'Right Little'**
  String get fingerRightLittle;

  /// No description provided for @fingerLeftIndex.
  ///
  /// In en, this message translates to:
  /// **'Left Index'**
  String get fingerLeftIndex;

  /// No description provided for @fingerLeftThumb.
  ///
  /// In en, this message translates to:
  /// **'Left Thumb'**
  String get fingerLeftThumb;

  /// No description provided for @fingerLeftMiddle.
  ///
  /// In en, this message translates to:
  /// **'Left Middle'**
  String get fingerLeftMiddle;

  /// No description provided for @fingerLeftRing.
  ///
  /// In en, this message translates to:
  /// **'Left Ring'**
  String get fingerLeftRing;

  /// No description provided for @fingerLeftLittle.
  ///
  /// In en, this message translates to:
  /// **'Left Little'**
  String get fingerLeftLittle;

  /// No description provided for @scanTypePress.
  ///
  /// In en, this message translates to:
  /// **'Touch'**
  String get scanTypePress;

  /// No description provided for @scanTypeSwipe.
  ///
  /// In en, this message translates to:
  /// **'Swipe'**
  String get scanTypeSwipe;

  /// No description provided for @tooltipSupportActive.
  ///
  /// In en, this message translates to:
  /// **'Supporter active • Support project'**
  String get tooltipSupportActive;

  /// No description provided for @tooltipSupport.
  ///
  /// In en, this message translates to:
  /// **'Support project / Remove ads'**
  String get tooltipSupport;

  /// No description provided for @tooltipReload.
  ///
  /// In en, this message translates to:
  /// **'Reload readers and fingerprints (Ctrl+R)'**
  String get tooltipReload;

  /// No description provided for @tooltipHistory.
  ///
  /// In en, this message translates to:
  /// **'Verification history ({count})'**
  String tooltipHistory(int count);

  /// No description provided for @tooltipMaintenance.
  ///
  /// In en, this message translates to:
  /// **'System diagnostics and maintenance'**
  String get tooltipMaintenance;

  /// No description provided for @tooltipLightTheme.
  ///
  /// In en, this message translates to:
  /// **'Switch to light theme'**
  String get tooltipLightTheme;

  /// No description provided for @tooltipDarkTheme.
  ///
  /// In en, this message translates to:
  /// **'Switch to dark theme'**
  String get tooltipDarkTheme;

  /// No description provided for @tooltipInfo.
  ///
  /// In en, this message translates to:
  /// **'System information'**
  String get tooltipInfo;

  /// No description provided for @tooltipSwitchDevice.
  ///
  /// In en, this message translates to:
  /// **'Switch active biometric reader'**
  String get tooltipSwitchDevice;

  /// No description provided for @detectingHardware.
  ///
  /// In en, this message translates to:
  /// **'Detecting hardware...'**
  String get detectingHardware;

  /// No description provided for @fprintdUnavailable.
  ///
  /// In en, this message translates to:
  /// **'fprintd unavailable'**
  String get fprintdUnavailable;

  /// No description provided for @noReaderConnected.
  ///
  /// In en, this message translates to:
  /// **'No reader connected'**
  String get noReaderConnected;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get permissionDenied;

  /// No description provided for @readerError.
  ///
  /// In en, this message translates to:
  /// **'Reader error'**
  String get readerError;

  /// No description provided for @statusSummary.
  ///
  /// In en, this message translates to:
  /// **'{name} • {scanType} • {stages} stages'**
  String statusSummary(String name, String scanType, int stages);

  /// No description provided for @queryingDBus.
  ///
  /// In en, this message translates to:
  /// **'Querying D-Bus net.reactivated.Fprint...'**
  String get queryingDBus;

  /// No description provided for @readerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Reader unavailable'**
  String get readerUnavailable;

  /// No description provided for @tooltipPamToggle.
  ///
  /// In en, this message translates to:
  /// **'Enable or disable fingerprint for login and sudo (PAM)'**
  String get tooltipPamToggle;

  /// No description provided for @pamActiveShort.
  ///
  /// In en, this message translates to:
  /// **'Login & Sudo: Active'**
  String get pamActiveShort;

  /// No description provided for @pamOffShort.
  ///
  /// In en, this message translates to:
  /// **'Login & Sudo: Off'**
  String get pamOffShort;

  /// No description provided for @searchingReaders.
  ///
  /// In en, this message translates to:
  /// **'Searching for biometric readers on the system...'**
  String get searchingReaders;

  /// No description provided for @connectingDBus.
  ///
  /// In en, this message translates to:
  /// **'Connecting via D-Bus to net.reactivated.Fprint'**
  String get connectingDBus;

  /// No description provided for @serviceUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'fprintd service unavailable'**
  String get serviceUnavailableTitle;

  /// No description provided for @noDeviceFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'No fingerprint reader detected'**
  String get noDeviceFoundTitle;

  /// No description provided for @permissionDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Insufficient D-Bus permissions'**
  String get permissionDeniedTitle;

  /// No description provided for @initReaderErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not initialize biometric reader'**
  String get initReaderErrorTitle;

  /// No description provided for @serviceUnavailableDesc.
  ///
  /// In en, this message translates to:
  /// **'Could not communicate with net.reactivated.Fprint. Verify that the fprintd package is installed and active on your Linux distribution.'**
  String get serviceUnavailableDesc;

  /// No description provided for @noDeviceFoundDesc.
  ///
  /// In en, this message translates to:
  /// **'The fprintd service is active, but libfprint did not detect any compatible connected sensors. If you have a USB reader that got stuck after suspend, try resetting the sensor.'**
  String get noDeviceFoundDesc;

  /// No description provided for @permissionDeniedDesc.
  ///
  /// In en, this message translates to:
  /// **'Polkit denied access to the device. Configure permanent permissions in the Diagnostics & Maintenance panel.'**
  String get permissionDeniedDesc;

  /// No description provided for @hardwareQueryErrorDesc.
  ///
  /// In en, this message translates to:
  /// **'A problem occurred while querying the hardware.'**
  String get hardwareQueryErrorDesc;

  /// No description provided for @detectedUsbDevices.
  ///
  /// In en, this message translates to:
  /// **'Detected USB devices: {devices}'**
  String detectedUsbDevices(String devices);

  /// No description provided for @recommendedInstall.
  ///
  /// In en, this message translates to:
  /// **'Recommended installation:\n• elementary OS / Ubuntu / Debian: sudo apt install fprintd libpam-fprintd\n• Fedora: sudo dnf install fprintd fprintd-pam\n• Arch Linux: sudo pacman -S fprintd'**
  String get recommendedInstall;

  /// No description provided for @retryDetection.
  ///
  /// In en, this message translates to:
  /// **'Retry detection'**
  String get retryDetection;

  /// No description provided for @restartReaderAndFprintd.
  ///
  /// In en, this message translates to:
  /// **'Restart reader and fprintd'**
  String get restartReaderAndFprintd;

  /// No description provided for @openDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Open diagnostics'**
  String get openDiagnostics;

  /// No description provided for @tabVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get tabVerify;

  /// No description provided for @tabPrints.
  ///
  /// In en, this message translates to:
  /// **'Fingerprints'**
  String get tabPrints;

  /// No description provided for @enrolledFingerprints.
  ///
  /// In en, this message translates to:
  /// **'Enrolled Fingerprints'**
  String get enrolledFingerprints;

  /// No description provided for @deleteAllTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete all fingerprints from this reader'**
  String get deleteAllTooltip;

  /// No description provided for @addButton.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addButton;

  /// No description provided for @noEnrolledPrints.
  ///
  /// In en, this message translates to:
  /// **'No enrolled fingerprints'**
  String get noEnrolledPrints;

  /// No description provided for @noEnrolledPrintsHint.
  ///
  /// In en, this message translates to:
  /// **'Press \"Add\" to enroll your first fingerprint.'**
  String get noEnrolledPrintsHint;

  /// No description provided for @targetBadge.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get targetBadge;

  /// No description provided for @editCustomNameTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit custom name'**
  String get editCustomNameTooltip;

  /// No description provided for @deletePrintTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete fingerprint'**
  String get deletePrintTooltip;

  /// No description provided for @badgeReading.
  ///
  /// In en, this message translates to:
  /// **'READING FINGERPRINT...'**
  String get badgeReading;

  /// No description provided for @badgeWaiting.
  ///
  /// In en, this message translates to:
  /// **'WAITING FOR SENSOR INPUT'**
  String get badgeWaiting;

  /// No description provided for @badgeSuccess.
  ///
  /// In en, this message translates to:
  /// **'VERIFICATION SUCCESSFUL'**
  String get badgeSuccess;

  /// No description provided for @badgeSuccessWithFinger.
  ///
  /// In en, this message translates to:
  /// **'VERIFICATION SUCCESSFUL • {finger}'**
  String badgeSuccessWithFinger(String finger);

  /// No description provided for @badgeError.
  ///
  /// In en, this message translates to:
  /// **'NO MATCH / ERROR'**
  String get badgeError;

  /// No description provided for @badgeRestarting.
  ///
  /// In en, this message translates to:
  /// **'RESTARTING READER'**
  String get badgeRestarting;

  /// No description provided for @badgeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'SENSOR UNAVAILABLE'**
  String get badgeUnavailable;

  /// No description provided for @badgeIdle.
  ///
  /// In en, this message translates to:
  /// **'READY TO VERIFY (SPACE / CLICK)'**
  String get badgeIdle;

  /// No description provided for @promptIdleAuto.
  ///
  /// In en, this message translates to:
  /// **'Press \"Verify fingerprint\" or Space to test any enrolled finger.'**
  String get promptIdleAuto;

  /// No description provided for @promptIdleNoPrints.
  ///
  /// In en, this message translates to:
  /// **'No fingerprints enrolled yet. Press \"Register first fingerprint\".'**
  String get promptIdleNoPrints;

  /// No description provided for @promptAutoSelected.
  ///
  /// In en, this message translates to:
  /// **'Automatic mode active: will verify against all your fingerprints.'**
  String get promptAutoSelected;

  /// No description provided for @promptTargetSelected.
  ///
  /// In en, this message translates to:
  /// **'Target: {finger}. Press to verify.'**
  String promptTargetSelected(String finger);

  /// No description provided for @promptScanningAuto.
  ///
  /// In en, this message translates to:
  /// **'Sensor active (automatic detection). Place any of your fingerprints...'**
  String get promptScanningAuto;

  /// No description provided for @promptScanningTarget.
  ///
  /// In en, this message translates to:
  /// **'Sensor active (-f {code}). Place \"{finger}\" on the reader...'**
  String promptScanningTarget(String code, String finger);

  /// No description provided for @verifyCancelledPrompt.
  ///
  /// In en, this message translates to:
  /// **'Verification cancelled. Press to start.'**
  String get verifyCancelledPrompt;

  /// No description provided for @verifyMatchDetected.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint verified successfully!\nDetected finger: {finger}'**
  String verifyMatchDetected(String finger);

  /// No description provided for @verifyMatchAutoUnknown.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint verified successfully!\nMatched one of your {count} enrolled fingerprints (fprintd does not report the specific finger in automatic mode).'**
  String verifyMatchAutoUnknown(int count);

  /// No description provided for @verifyNoMatchAny.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint did not match any enrolled print. Try again.'**
  String get verifyNoMatchAny;

  /// No description provided for @verifyNoMatchTarget.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint did not match \"{finger}\". Try again.'**
  String verifyNoMatchTarget(String finger);

  /// No description provided for @verifyErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Verification error: {error}'**
  String verifyErrorPrefix(String error);

  /// No description provided for @cancelVerificationBtn.
  ///
  /// In en, this message translates to:
  /// **'Cancel verification (Esc)'**
  String get cancelVerificationBtn;

  /// No description provided for @verifyAnyBtn.
  ///
  /// In en, this message translates to:
  /// **'Verify fingerprint'**
  String get verifyAnyBtn;

  /// No description provided for @verifyTargetBtn.
  ///
  /// In en, this message translates to:
  /// **'Verify {finger}'**
  String verifyTargetBtn(String finger);

  /// No description provided for @registerFirstPrintBtn.
  ///
  /// In en, this message translates to:
  /// **'Register first fingerprint'**
  String get registerFirstPrintBtn;

  /// No description provided for @noPrintsToVerify.
  ///
  /// In en, this message translates to:
  /// **'No fingerprints enrolled to verify.'**
  String get noPrintsToVerify;

  /// No description provided for @bottomBarRestarting.
  ///
  /// In en, this message translates to:
  /// **'Restarting service and hardware...'**
  String get bottomBarRestarting;

  /// No description provided for @bottomBarStatus.
  ///
  /// In en, this message translates to:
  /// **'fprintd: {service} • Polkit: {polkit}'**
  String bottomBarStatus(String service, String polkit);

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get statusInactive;

  /// No description provided for @polkitPasswordless.
  ///
  /// In en, this message translates to:
  /// **'Passwordless'**
  String get polkitPasswordless;

  /// No description provided for @polkitDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get polkitDefault;

  /// No description provided for @restartingBtn.
  ///
  /// In en, this message translates to:
  /// **'Restarting...'**
  String get restartingBtn;

  /// No description provided for @hardwareRestartBtn.
  ///
  /// In en, this message translates to:
  /// **'Hardware restart...'**
  String get hardwareRestartBtn;

  /// No description provided for @restartReaderServiceBtn.
  ///
  /// In en, this message translates to:
  /// **'Restart reader & service'**
  String get restartReaderServiceBtn;

  /// No description provided for @closeBtn.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeBtn;

  /// No description provided for @cancelBtn.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelBtn;

  /// No description provided for @saveBtn.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveBtn;

  /// No description provided for @deleteBtn.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteBtn;

  /// No description provided for @deleteAllBtn.
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get deleteAllBtn;

  /// No description provided for @understoodBtn.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get understoodBtn;

  /// No description provided for @retryBtn.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryBtn;

  /// No description provided for @copyCommandBtn.
  ///
  /// In en, this message translates to:
  /// **'Copy command'**
  String get copyCommandBtn;

  /// No description provided for @commandCopied.
  ///
  /// In en, this message translates to:
  /// **'Command copied to clipboard.'**
  String get commandCopied;

  /// No description provided for @manualRestartTitle.
  ///
  /// In en, this message translates to:
  /// **'Manual restart required'**
  String get manualRestartTitle;

  /// No description provided for @configurePamTitle.
  ///
  /// In en, this message translates to:
  /// **'Configure PAM (Login & sudo)'**
  String get configurePamTitle;

  /// No description provided for @deletePrintTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete fingerprint'**
  String get deletePrintTitle;

  /// No description provided for @deletePrintConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want to permanently delete \"{name}\" ({code}) from {device}?'**
  String deletePrintConfirm(String name, String code, String device);

  /// No description provided for @deletePrintSuccess.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint \"{name}\" deleted successfully.'**
  String deletePrintSuccess(String name);

  /// No description provided for @deletePrintFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the fingerprint.'**
  String get deletePrintFailed;

  /// No description provided for @deleteAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all fingerprints'**
  String get deleteAllTitle;

  /// No description provided for @deleteAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete ALL enrolled fingerprints on {device}? This action cannot be undone.'**
  String deleteAllConfirm(String device);

  /// No description provided for @deleteAllSuccess.
  ///
  /// In en, this message translates to:
  /// **'All fingerprints have been deleted.'**
  String get deleteAllSuccess;

  /// No description provided for @deleteAllFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete fingerprints.'**
  String get deleteAllFailed;

  /// No description provided for @aliasUpdated.
  ///
  /// In en, this message translates to:
  /// **'Name for \"{finger}\" updated to \"{name}\".'**
  String aliasUpdated(String finger, String name);

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About Fprint-Manager'**
  String get aboutTitle;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'Biometric fingerprint manager for Linux desktop and elementary OS, connected via D-Bus to fprintd and libfprint.'**
  String get aboutDescription;

  /// No description provided for @aboutActiveReader.
  ///
  /// In en, this message translates to:
  /// **'Active reader'**
  String get aboutActiveReader;

  /// No description provided for @aboutNoActiveReader.
  ///
  /// In en, this message translates to:
  /// **'No active reader'**
  String get aboutNoActiveReader;

  /// No description provided for @aboutReaderDesc.
  ///
  /// In en, this message translates to:
  /// **'{name} ({scanType}, {stages} stages)'**
  String aboutReaderDesc(String name, String scanType, int stages);

  /// No description provided for @aboutRuntimeEnv.
  ///
  /// In en, this message translates to:
  /// **'Runtime environment'**
  String get aboutRuntimeEnv;

  /// No description provided for @aboutFlatpak.
  ///
  /// In en, this message translates to:
  /// **'Flatpak Sandbox'**
  String get aboutFlatpak;

  /// No description provided for @aboutNativeLinux.
  ///
  /// In en, this message translates to:
  /// **'Native Linux'**
  String get aboutNativeLinux;

  /// No description provided for @aboutSystemUser.
  ///
  /// In en, this message translates to:
  /// **'System user'**
  String get aboutSystemUser;

  /// No description provided for @aboutAliasConfig.
  ///
  /// In en, this message translates to:
  /// **'Aliases configuration'**
  String get aboutAliasConfig;

  /// No description provided for @aboutPamAuth.
  ///
  /// In en, this message translates to:
  /// **'PAM authentication'**
  String get aboutPamAuth;

  /// No description provided for @aboutPamActive.
  ///
  /// In en, this message translates to:
  /// **'Active (Login, lock screen & sudo)'**
  String get aboutPamActive;

  /// No description provided for @aboutPamDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get aboutPamDisabled;

  /// No description provided for @aboutPolkit.
  ///
  /// In en, this message translates to:
  /// **'Polkit permissions'**
  String get aboutPolkit;

  /// No description provided for @aboutPolkitPermanent.
  ///
  /// In en, this message translates to:
  /// **'Permanent'**
  String get aboutPolkitPermanent;

  /// No description provided for @aboutPolkitDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get aboutPolkitDefault;

  /// No description provided for @editNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Customize Fingerprint Name'**
  String get editNameTitle;

  /// No description provided for @assignedFingerLabel.
  ///
  /// In en, this message translates to:
  /// **'Assigned finger:'**
  String get assignedFingerLabel;

  /// No description provided for @customNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Descriptive name or label:'**
  String get customNameLabel;

  /// No description provided for @customNameHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. Primary finger for sudo'**
  String get customNameHint;

  /// No description provided for @clearFieldTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear field'**
  String get clearFieldTooltip;

  /// No description provided for @restoreOriginalBtn.
  ///
  /// In en, this message translates to:
  /// **'Restore original ({name})'**
  String restoreOriginalBtn(String name);

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification History'**
  String get historyTitle;

  /// No description provided for @clearHistoryBtn.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearHistoryBtn;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No activity recorded'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Whenever you test the biometric sensor, the results will be recorded here.'**
  String get historyEmptyDesc;

  /// No description provided for @enrollTitleActive.
  ///
  /// In en, this message translates to:
  /// **'Enrolling: {finger}'**
  String enrollTitleActive(String finger);

  /// No description provided for @enrollTitleIdle.
  ///
  /// In en, this message translates to:
  /// **'Register New Fingerprint'**
  String get enrollTitleIdle;

  /// No description provided for @enrollOverwriteBtn.
  ///
  /// In en, this message translates to:
  /// **'Overwrite fingerprint'**
  String get enrollOverwriteBtn;

  /// No description provided for @enrollStartBtn.
  ///
  /// In en, this message translates to:
  /// **'Start enrollment'**
  String get enrollStartBtn;

  /// No description provided for @enrollSelectFinger.
  ///
  /// In en, this message translates to:
  /// **'Select the finger you want to enroll:'**
  String get enrollSelectFinger;

  /// No description provided for @enrollAlreadyBadge.
  ///
  /// In en, this message translates to:
  /// **'Enrolled'**
  String get enrollAlreadyBadge;

  /// No description provided for @enrollAlreadyNote.
  ///
  /// In en, this message translates to:
  /// **'Note: This finger already has a saved print; enrolling again will replace it in fprintd.'**
  String get enrollAlreadyNote;

  /// No description provided for @enrollSwipeHint.
  ///
  /// In en, this message translates to:
  /// **'Your reader is a swipe sensor: it will require {stages} smooth swipes across the sensor.'**
  String enrollSwipeHint(int stages);

  /// No description provided for @enrollPressHint.
  ///
  /// In en, this message translates to:
  /// **'Your reader is a touch sensor: it will require placing and lifting your finger {stages} times until the ring reaches 100%.'**
  String enrollPressHint(int stages);

  /// No description provided for @enrollSwipeStart.
  ///
  /// In en, this message translates to:
  /// **'Swipe your finger smoothly across the sensor to begin.'**
  String get enrollSwipeStart;

  /// No description provided for @enrollPressStart.
  ///
  /// In en, this message translates to:
  /// **'Place your finger firmly on the sensor to begin.'**
  String get enrollPressStart;

  /// No description provided for @enrollPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing sensor {device}...'**
  String enrollPreparing(String device);

  /// No description provided for @enrollErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error during enrollment: {error}'**
  String enrollErrorPrefix(String error);

  /// No description provided for @enrollCompletedBadge.
  ///
  /// In en, this message translates to:
  /// **'Enrollment completed • 100%!'**
  String get enrollCompletedBadge;

  /// No description provided for @enrollStageBadge.
  ///
  /// In en, this message translates to:
  /// **'Stage {current} of {total} • {percent}%'**
  String enrollStageBadge(int current, int total, int percent);

  /// No description provided for @bannerIndieLabel.
  ///
  /// In en, this message translates to:
  /// **'Indie Project'**
  String get bannerIndieLabel;

  /// No description provided for @bannerRemoveBtn.
  ///
  /// In en, this message translates to:
  /// **'Remove ({price})'**
  String bannerRemoveBtn(String price);

  /// No description provided for @supportTitle.
  ///
  /// In en, this message translates to:
  /// **'Support Fprint-Manager'**
  String get supportTitle;

  /// No description provided for @supportOpenBrowserError.
  ///
  /// In en, this message translates to:
  /// **'Could not open browser. Visit manually: {url}'**
  String supportOpenBrowserError(String url);

  /// No description provided for @supportOpenCheckoutError.
  ///
  /// In en, this message translates to:
  /// **'Could not open checkout page: {url}'**
  String supportOpenCheckoutError(String url);

  /// No description provided for @supportLicenseRemoved.
  ///
  /// In en, this message translates to:
  /// **'License removed from this device.'**
  String get supportLicenseRemoved;

  /// No description provided for @supportDonationTitle.
  ///
  /// In en, this message translates to:
  /// **'Voluntary donation (PayPal / Ko-fi)'**
  String get supportDonationTitle;

  /// No description provided for @supportDonationDesc.
  ///
  /// In en, this message translates to:
  /// **'Fprint-Manager is free software with no feature locks. If you find it useful, you can buy me a coffee or send a direct contribution.'**
  String get supportDonationDesc;

  /// No description provided for @supportDonateBtn.
  ///
  /// In en, this message translates to:
  /// **'Donate with PayPal / Ko-fi'**
  String get supportDonateBtn;

  /// No description provided for @supportLicenseActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Supporter License Active'**
  String get supportLicenseActiveTitle;

  /// No description provided for @supportLicenseKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Key: {key}'**
  String supportLicenseKeyLabel(String key);

  /// No description provided for @supportLicenseHolderLabel.
  ///
  /// In en, this message translates to:
  /// **'Holder: {email}'**
  String supportLicenseHolderLabel(String email);

  /// No description provided for @supportDeactivateBtn.
  ///
  /// In en, this message translates to:
  /// **'Deactivate on this device'**
  String get supportDeactivateBtn;

  /// No description provided for @supportRemoveAdsTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove ads ({price})'**
  String supportRemoveAdsTitle(String price);

  /// No description provided for @supportRemoveAdsDesc.
  ///
  /// In en, this message translates to:
  /// **'One-time payment via card or PayPal. You will immediately receive a license key to hide the banner on your device.'**
  String get supportRemoveAdsDesc;

  /// No description provided for @supportGetKeyBtn.
  ///
  /// In en, this message translates to:
  /// **'Get license key ({price})'**
  String supportGetKeyBtn(String price);

  /// No description provided for @supportKeyFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Supporter license key'**
  String get supportKeyFieldLabel;

  /// No description provided for @supportKeyFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Paste your key here'**
  String get supportKeyFieldHint;

  /// No description provided for @supportValidatingBtn.
  ///
  /// In en, this message translates to:
  /// **'Validating...'**
  String get supportValidatingBtn;

  /// No description provided for @supportActivateBtn.
  ///
  /// In en, this message translates to:
  /// **'Activate license'**
  String get supportActivateBtn;

  /// No description provided for @maintTitle.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics & Maintenance'**
  String get maintTitle;

  /// No description provided for @maintRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh diagnostics'**
  String get maintRefreshTooltip;

  /// No description provided for @maintEnvTitle.
  ///
  /// In en, this message translates to:
  /// **'Linux Environment Status'**
  String get maintEnvTitle;

  /// No description provided for @maintNativeSession.
  ///
  /// In en, this message translates to:
  /// **'Native Session'**
  String get maintNativeSession;

  /// No description provided for @maintDbusRow.
  ///
  /// In en, this message translates to:
  /// **'System D-Bus (net.reactivated.Fprint)'**
  String get maintDbusRow;

  /// No description provided for @maintConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get maintConnected;

  /// No description provided for @maintInactiveOrMissing.
  ///
  /// In en, this message translates to:
  /// **'Inactive or not installed'**
  String get maintInactiveOrMissing;

  /// No description provided for @maintReadersRow.
  ///
  /// In en, this message translates to:
  /// **'Readers exposed by libfprint'**
  String get maintReadersRow;

  /// No description provided for @maintNoneDetected.
  ///
  /// In en, this message translates to:
  /// **'None detected'**
  String get maintNoneDetected;

  /// No description provided for @maintUsbRow.
  ///
  /// In en, this message translates to:
  /// **'USB biometric sensors in sysfs'**
  String get maintUsbRow;

  /// No description provided for @maintNoUsb.
  ///
  /// In en, this message translates to:
  /// **'No USB reader (or internal SPI/I2C reader)'**
  String get maintNoUsb;

  /// No description provided for @maintPamRow.
  ///
  /// In en, this message translates to:
  /// **'PAM integration (login, lock & sudo)'**
  String get maintPamRow;

  /// No description provided for @maintEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get maintEnabled;

  /// No description provided for @maintDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get maintDisabled;

  /// No description provided for @maintPolkitRow.
  ///
  /// In en, this message translates to:
  /// **'Passwordless Polkit rule'**
  String get maintPolkitRow;

  /// No description provided for @maintInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get maintInstalled;

  /// No description provided for @maintMissingPackages.
  ///
  /// In en, this message translates to:
  /// **'Required system packages if fprintd is not installed:'**
  String get maintMissingPackages;

  /// No description provided for @maintPolkitActive.
  ///
  /// In en, this message translates to:
  /// **'Permanent Polkit permissions active'**
  String get maintPolkitActive;

  /// No description provided for @maintPolkitDefault.
  ///
  /// In en, this message translates to:
  /// **'Default Polkit permissions'**
  String get maintPolkitDefault;

  /// No description provided for @maintPolkitDesc.
  ///
  /// In en, this message translates to:
  /// **'Allows users in the admin group to enroll or delete their own fingerprints without repeating their password for every action.'**
  String get maintPolkitDesc;

  /// No description provided for @maintPolkitFlatpakBtn.
  ///
  /// In en, this message translates to:
  /// **'View host permission command'**
  String get maintPolkitFlatpakBtn;

  /// No description provided for @maintPolkitReapplyBtn.
  ///
  /// In en, this message translates to:
  /// **'Reapply Polkit rule'**
  String get maintPolkitReapplyBtn;

  /// No description provided for @maintPolkitGrantBtn.
  ///
  /// In en, this message translates to:
  /// **'Grant permanent permissions'**
  String get maintPolkitGrantBtn;

  /// No description provided for @maintPamActive.
  ///
  /// In en, this message translates to:
  /// **'PAM authentication active (Login & sudo)'**
  String get maintPamActive;

  /// No description provided for @maintPamDisabled.
  ///
  /// In en, this message translates to:
  /// **'PAM authentication disabled'**
  String get maintPamDisabled;

  /// No description provided for @maintPamActiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Enrolled fingerprints can be used to log in, unlock the screen, and authorize sudo.'**
  String get maintPamActiveDesc;

  /// No description provided for @maintPamDisabledDesc.
  ///
  /// In en, this message translates to:
  /// **'Enable the pam_fprintd module to use your fingerprint at login and with sudo.'**
  String get maintPamDisabledDesc;

  /// No description provided for @maintPamDisableBtn.
  ///
  /// In en, this message translates to:
  /// **'Disable in Login & sudo'**
  String get maintPamDisableBtn;

  /// No description provided for @maintPamEnableBtn.
  ///
  /// In en, this message translates to:
  /// **'Enable in Login & sudo'**
  String get maintPamEnableBtn;

  /// No description provided for @maintUsbTitle.
  ///
  /// In en, this message translates to:
  /// **'Reader & fprintd Service Reset'**
  String get maintUsbTitle;

  /// No description provided for @maintUsbDetected.
  ///
  /// In en, this message translates to:
  /// **'Detected: {devices}.'**
  String maintUsbDetected(String devices);

  /// No description provided for @maintUsbNone.
  ///
  /// In en, this message translates to:
  /// **'No USB sensors detected in sysfs (if internal SPI/I2C, only fprintd will be restarted).'**
  String get maintUsbNone;

  /// No description provided for @maintUsbDesc.
  ///
  /// In en, this message translates to:
  /// **'Recovers readers stuck after suspend or USB dock reconnection. {summary}'**
  String maintUsbDesc(String summary);

  /// No description provided for @maintUsbFlatpakBtn.
  ///
  /// In en, this message translates to:
  /// **'Generate host reset command'**
  String get maintUsbFlatpakBtn;

  /// No description provided for @maintUsbResetBtn.
  ///
  /// In en, this message translates to:
  /// **'Restart reader and fprintd service'**
  String get maintUsbResetBtn;

  /// No description provided for @maintStatusPolkit.
  ///
  /// In en, this message translates to:
  /// **'Configuring Polkit rule for biometric permissions...'**
  String get maintStatusPolkit;

  /// No description provided for @maintStatusPamEnable.
  ///
  /// In en, this message translates to:
  /// **'Enabling fingerprint authentication for login and sudo...'**
  String get maintStatusPamEnable;

  /// No description provided for @maintStatusPamDisable.
  ///
  /// In en, this message translates to:
  /// **'Disabling system fingerprint authentication...'**
  String get maintStatusPamDisable;

  /// No description provided for @maintStatusUsb.
  ///
  /// In en, this message translates to:
  /// **'Restarting detected USB readers and fprintd service...'**
  String get maintStatusUsb;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
