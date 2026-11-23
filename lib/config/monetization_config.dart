/// Pasarelas soportadas para validar claves de licencia que eliminan los anuncios.
enum LicenseProvider {
  /// Gumroad: Merchant of Record con soporte nativo para PayPal y tarjetas (10% + 0,50$).
  gumroad,

  /// Polar.sh: Merchant of Record con comisiones más bajas (5% + 0,50$), pagos por Stripe/banco.
  polar,
}

/// Configuración centralizada de monetización para el desarrollador.
/// Edita estos valores con tus propios enlaces e identificadores antes de compilar la versión final.
class MonetizationConfig {
  MonetizationConfig._();

  /// Activa o desactiva por completo el banner inferior para usuarios sin licencia.
  static const bool enableAdBanner = true;

  /// Identificador de editor (publisher slug) obtenido en EthicalAds (ej. "fprint-manager").
  /// Si está vacío, se muestra un banner propio discreto invitando a apoyar la app.
  static const String ethicalAdsPublisherId = '';

  /// Palabras clave contextuales enviadas a EthicalAds (sin rastreo personal).
  static const List<String> ethicalAdsKeywords = [
    'linux',
    'security',
    'open-source',
    'desktop',
    'ubuntu',
  ];

  /// Enlace para donaciones voluntarias directas (Ko-fi a tu PayPal con 0% comisión, o paypal.me).
  static const String donationUrl = 'https://paypal.me/chals911';

  /// Etiqueta de precio mostrada en los botones de eliminación de anuncios.
  static const String removeAdsPriceLabel = '1,99 €';

  /// Proveedor utilizado para verificar las claves de licencia Supporter.
  static const LicenseProvider licenseProvider = LicenseProvider.gumroad;

  /// Enlace de compra directa donde el usuario adquiere la clave por 1,99 €.
  static const String removeAdsCheckoutUrl =
      'https://chals91.gumroad.com/l/Fprint-Manager';

  /// ID del producto en Gumroad (obligatorio si `licenseProvider == LicenseProvider.gumroad`).
  static const String gumroadProductId = 'cegys1V4q9NEFFLoYJejzw==';

  /// ID de organización en Polar.sh (obligatorio si `licenseProvider == LicenseProvider.polar`).
  static const String polarOrganizationId = '';

  static bool get hasEthicalAdsConfigured =>
      ethicalAdsPublisherId.trim().isNotEmpty;

  static bool get hasLicenseBackendConfigured {
    switch (licenseProvider) {
      case LicenseProvider.gumroad:
        return gumroadProductId.trim().isNotEmpty;
      case LicenseProvider.polar:
        return polarOrganizationId.trim().isNotEmpty;
    }
  }
}

