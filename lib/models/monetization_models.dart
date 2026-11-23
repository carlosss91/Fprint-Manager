import '../config/monetization_config.dart';

/// Representación de un anuncio de texto obtenido de EthicalAds o un aviso propio de respaldo.
class EthicalAdItem {
  final String text;
  final String linkUrl;
  final String? viewUrl;
  final bool isFallbackHouseAd;

  const EthicalAdItem({
    required this.text,
    required this.linkUrl,
    this.viewUrl,
    this.isFallbackHouseAd = false,
  });
}

/// Estado persistido de la licencia Supporter (eliminación de anuncios).
class SupporterLicenseState {
  final bool isSupporter;
  final String licenseKey;
  final LicenseProvider provider;
  final String? customerEmail;
  final DateTime? activatedAt;
  final DateTime? lastValidatedAt;

  const SupporterLicenseState({
    required this.isSupporter,
    required this.licenseKey,
    required this.provider,
    this.customerEmail,
    this.activatedAt,
    this.lastValidatedAt,
  });

  const SupporterLicenseState.inactive({
    this.provider = LicenseProvider.gumroad,
  })  : isSupporter = false,
        licenseKey = '',
        customerEmail = null,
        activatedAt = null,
        lastValidatedAt = null;

  /// Clave parcialmente oculta para mostrar en la interfaz con privacidad.
  String get maskedKey {
    final trimmed = licenseKey.trim();
    if (trimmed.length <= 8) return trimmed;
    final prefix = trimmed.substring(0, 4);
    final suffix = trimmed.substring(trimmed.length - 4);
    return '$prefix••••$suffix';
  }

  Map<String, dynamic> toJson() => {
        'isSupporter': isSupporter,
        'licenseKey': licenseKey,
        'provider': provider.name,
        'customerEmail': customerEmail,
        'activatedAt': activatedAt?.toIso8601String(),
        'lastValidatedAt': lastValidatedAt?.toIso8601String(),
      };

  factory SupporterLicenseState.fromJson(Map<String, dynamic> json) {
    final providerName = json['provider'] as String?;
    final provider = LicenseProvider.values.firstWhere(
      (p) => p.name == providerName,
      orElse: () => LicenseProvider.gumroad,
    );

    return SupporterLicenseState(
      isSupporter: (json['isSupporter'] as bool?) ?? false,
      licenseKey: (json['licenseKey'] as String?) ?? '',
      provider: provider,
      customerEmail: json['customerEmail'] as String?,
      activatedAt: json['activatedAt'] != null
          ? DateTime.tryParse(json['activatedAt'] as String)
          : null,
      lastValidatedAt: json['lastValidatedAt'] != null
          ? DateTime.tryParse(json['lastValidatedAt'] as String)
          : null,
    );
  }
}

/// Resultado de un intento de activación de clave de licencia.
class LicenseActivationResult {
  final bool success;
  final String message;
  final SupporterLicenseState state;

  const LicenseActivationResult({
    required this.success,
    required this.message,
    required this.state,
  });
}

