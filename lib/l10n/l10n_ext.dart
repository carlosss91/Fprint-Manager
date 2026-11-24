import '../models/fingerprint_item.dart';
import '../models/fprint_device_info.dart';
import 'app_localizations.dart';

extension AppLocalizationsX on AppLocalizations {
  /// Returns the localized human-readable name for a fprintd finger code.
  String fingerDisplayName(String code) {
    return switch (code) {
      kAnyFingerCode => fingerAny,
      'right-index-finger' => fingerRightIndex,
      'right-thumb' => fingerRightThumb,
      'right-middle-finger' => fingerRightMiddle,
      'right-ring-finger' => fingerRightRing,
      'right-little-finger' => fingerRightLittle,
      'left-index-finger' => fingerLeftIndex,
      'left-thumb' => fingerLeftThumb,
      'left-middle-finger' => fingerLeftMiddle,
      'left-ring-finger' => fingerLeftRing,
      'left-little-finger' => fingerLeftLittle,
      _ => code,
    };
  }

  /// Returns the localized label for the reader scan type.
  String scanTypeLabel(ScanType scanType) {
    return scanType == ScanType.swipe ? scanTypeSwipe : scanTypePress;
  }
}

