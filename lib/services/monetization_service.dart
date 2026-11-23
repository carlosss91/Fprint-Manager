import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../config/monetization_config.dart';
import '../models/monetization_models.dart';
import 'alias_service.dart';
import 'external_url_service.dart';

/// Contrato para gestionar licencias Supporter, anuncios EthicalAds y enlaces de apoyo.
abstract class MonetizationBackend {
  Future<SupporterLicenseState> loadLicenseState();
  Future<LicenseActivationResult> activateLicenseKey(String licenseKey);
  Future<void> deactivateLicense();
  Future<EthicalAdItem?> fetchAd();
  Future<void> reportAdImpression(String viewUrl);
  Future<bool> openExternalUrl(String url);
}

/// Implementación HTTP pura (`dart:io`) para EthicalAds, Gumroad y Polar.sh, con persistencia XDG.
class HttpMonetizationBackend implements MonetizationBackend {
  static String get _licenseFilePath =>
      '${AliasService.configDirectoryPath}/supporter_license.json';

  @override
  Future<SupporterLicenseState> loadLicenseState() async {
    try {
      final file = File(_licenseFilePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isEmpty) {
          return const SupporterLicenseState.inactive(
            provider: MonetizationConfig.licenseProvider,
          );
        }
        final dynamic decoded = jsonDecode(content);
        if (decoded is Map<String, dynamic>) {
          return SupporterLicenseState.fromJson(decoded);
        }
      }
    } catch (_) {}
    return const SupporterLicenseState.inactive(
      provider: MonetizationConfig.licenseProvider,
    );
  }

  Future<void> _saveLicenseState(SupporterLicenseState state) async {
    final dir = Directory(AliasService.configDirectoryPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final file = File(_licenseFilePath);
    await file.writeAsString(jsonEncode(state.toJson()));
  }

  @override
  Future<void> deactivateLicense() async {
    try {
      final file = File(_licenseFilePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  @override
  Future<LicenseActivationResult> activateLicenseKey(String licenseKey) async {
    final trimmedKey = licenseKey.trim();
    if (trimmedKey.isEmpty) {
      return LicenseActivationResult(
        success: false,
        message: 'Introduce una clave de licencia válida antes de activar.',
        state: await loadLicenseState(),
      );
    }

    if (!MonetizationConfig.hasLicenseBackendConfigured) {
      final missingField =
          MonetizationConfig.licenseProvider == LicenseProvider.gumroad
              ? 'gumroadProductId'
              : 'polarOrganizationId';
      return LicenseActivationResult(
        success: false,
        message:
            'La validación de licencias aún no está configurada por el autor ($missingField vacío en MonetizationConfig).',
        state: await loadLicenseState(),
      );
    }

    switch (MonetizationConfig.licenseProvider) {
      case LicenseProvider.gumroad:
        return _activateGumroad(trimmedKey);
      case LicenseProvider.polar:
        return _activatePolar(trimmedKey);
    }
  }

  Future<LicenseActivationResult> _activateGumroad(String licenseKey) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client
          .postUrl(Uri.parse('https://api.gumroad.com/v2/licenses/verify'))
          .timeout(const Duration(seconds: 10));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'application/x-www-form-urlencoded; charset=utf-8',
      );

      final body = Uri(
        queryParameters: {
          'product_id': MonetizationConfig.gumroadProductId.trim(),
          'license_key': licenseKey,
          'increment_uses_count': 'true',
        },
      ).query;
      request.write(body);

      final response = await request.close().timeout(const Duration(seconds: 10));
      final responseText =
          await response.transform(utf8.decoder).join().timeout(const Duration(seconds: 10));
      final dynamic decoded = jsonDecode(responseText);

      if (response.statusCode == 200 && decoded is Map<String, dynamic>) {
        final success = decoded['success'] == true;
        final purchase = decoded['purchase'];
        final refunded =
            purchase is Map<String, dynamic> && purchase['refunded'] == true;
        final chargebacked =
            purchase is Map<String, dynamic> && purchase['chargebacked'] == true;

        if (success && !refunded && !chargebacked) {
          final email =
              purchase is Map<String, dynamic> ? purchase['email'] as String? : null;
          final now = DateTime.now();
          final newState = SupporterLicenseState(
            isSupporter: true,
            licenseKey: licenseKey,
            provider: LicenseProvider.gumroad,
            customerEmail: email,
            activatedAt: now,
            lastValidatedAt: now,
          );
          await _saveLicenseState(newState);
          return LicenseActivationResult(
            success: true,
            message: '¡Licencia Supporter activada! Los anuncios han sido eliminados.',
            state: newState,
          );
        }

        if (refunded || chargebacked) {
          return LicenseActivationResult(
            success: false,
            message: 'Esta compra figura como reembolsada o anulada en Gumroad.',
            state: await loadLicenseState(),
          );
        }

        final serverMsg = decoded['message']?.toString();
        return LicenseActivationResult(
          success: false,
          message: serverMsg != null && serverMsg.isNotEmpty
              ? 'Clave no válida ($serverMsg).'
              : 'La clave de licencia no es válida o no pertenece a este producto.',
          state: await loadLicenseState(),
        );
      }

      return LicenseActivationResult(
        success: false,
        message: 'No se pudo validar la clave en Gumroad (HTTP ${response.statusCode}).',
        state: await loadLicenseState(),
      );
    } on SocketException {
      return LicenseActivationResult(
        success: false,
        message: 'Sin conexión a internet. Conéctate para validar tu clave por primera vez.',
        state: await loadLicenseState(),
      );
    } on TimeoutException {
      return LicenseActivationResult(
        success: false,
        message: 'Tiempo de espera agotado al contactar con el servidor de licencias.',
        state: await loadLicenseState(),
      );
    } catch (e) {
      return LicenseActivationResult(
        success: false,
        message: 'Error al verificar la licencia: $e',
        state: await loadLicenseState(),
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<LicenseActivationResult> _activatePolar(String licenseKey) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client
          .postUrl(Uri.parse('https://api.polar.sh/v1/customer-portal/license-keys/validate'))
          .timeout(const Duration(seconds: 10));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'application/json; charset=utf-8',
      );
      request.write(
        jsonEncode({
          'key': licenseKey,
          'organization_id': MonetizationConfig.polarOrganizationId.trim(),
        }),
      );

      final response = await request.close().timeout(const Duration(seconds: 10));
      final responseText =
          await response.transform(utf8.decoder).join().timeout(const Duration(seconds: 10));
      final dynamic decoded = jsonDecode(responseText);

      if (response.statusCode == 200 && decoded is Map<String, dynamic>) {
        final status = decoded['status']?.toString().toLowerCase() ?? '';
        if (status == 'granted') {
          final customer = decoded['customer'];
          final email =
              customer is Map<String, dynamic> ? customer['email'] as String? : null;
          final now = DateTime.now();
          final newState = SupporterLicenseState(
            isSupporter: true,
            licenseKey: licenseKey,
            provider: LicenseProvider.polar,
            customerEmail: email,
            activatedAt: now,
            lastValidatedAt: now,
          );
          await _saveLicenseState(newState);
          return LicenseActivationResult(
            success: true,
            message: '¡Licencia Supporter activada! Los anuncios han sido eliminados.',
            state: newState,
          );
        }

        return LicenseActivationResult(
          success: false,
          message: 'La clave en Polar no está activa (estado: $status).',
          state: await loadLicenseState(),
        );
      }

      return LicenseActivationResult(
        success: false,
        message: 'Clave de licencia no válida en Polar (HTTP ${response.statusCode}).',
        state: await loadLicenseState(),
      );
    } on SocketException {
      return LicenseActivationResult(
        success: false,
        message: 'Sin conexión a internet. Conéctate para validar tu clave por primera vez.',
        state: await loadLicenseState(),
      );
    } on TimeoutException {
      return LicenseActivationResult(
        success: false,
        message: 'Tiempo de espera agotado al contactar con Polar.sh.',
        state: await loadLicenseState(),
      );
    } catch (e) {
      return LicenseActivationResult(
        success: false,
        message: 'Error al verificar la licencia: $e',
        state: await loadLicenseState(),
      );
    } finally {
      client.close(force: true);
    }
  }

  EthicalAdItem _fallbackHouseAd() {
    return EthicalAdItem(
      text:
          'Apoya el desarrollo independiente de Fprint-Manager o quita este espacio por ${MonetizationConfig.removeAdsPriceLabel}.',
      linkUrl: MonetizationConfig.removeAdsCheckoutUrl,
      isFallbackHouseAd: true,
    );
  }

  @override
  Future<EthicalAdItem?> fetchAd() async {
    if (!MonetizationConfig.enableAdBanner) return null;
    if (!MonetizationConfig.hasEthicalAdsConfigured) {
      return _fallbackHouseAd();
    }

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 6);
    try {
      final uri = Uri.https('server.ethicalads.io', '/api/v1/decision/', {
        'publisher': MonetizationConfig.ethicalAdsPublisherId.trim(),
        'ad_types': 'text-v1',
        'format': 'json',
        if (MonetizationConfig.ethicalAdsKeywords.isNotEmpty)
          'keywords': MonetizationConfig.ethicalAdsKeywords.join('|'),
      });

      final request = await client.getUrl(uri).timeout(const Duration(seconds: 6));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.userAgentHeader, 'Fprint-Manager/1.0 (Linux)');

      final response = await request.close().timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) {
        return _fallbackHouseAd();
      }

      final rawBody =
          await response.transform(utf8.decoder).join().timeout(const Duration(seconds: 6));
      if (rawBody.trim().isEmpty) {
        return _fallbackHouseAd();
      }

      final dynamic decoded = jsonDecode(rawBody);
      if (decoded is! Map<String, dynamic>) {
        return _fallbackHouseAd();
      }

      final rawText = (decoded['text'] ?? decoded['body'] ?? decoded['html'])?.toString() ?? '';
      final cleanText = _stripHtmlAndEntities(rawText);
      final link = decoded['link']?.toString() ?? '';
      final viewUrl = decoded['view_url']?.toString();

      if (cleanText.isEmpty || link.isEmpty) {
        return _fallbackHouseAd();
      }

      return EthicalAdItem(
        text: cleanText,
        linkUrl: link,
        viewUrl: (viewUrl != null && viewUrl.isNotEmpty) ? viewUrl : null,
        isFallbackHouseAd: false,
      );
    } catch (_) {
      return _fallbackHouseAd();
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<void> reportAdImpression(String viewUrl) async {
    final uri = Uri.tryParse(viewUrl.trim());
    if (uri == null || uri.scheme.toLowerCase() != 'https' || uri.host.isEmpty) {
      return;
    }

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 5);
    try {
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 5));
      request.headers.set(HttpHeaders.userAgentHeader, 'Fprint-Manager/1.0 (Linux)');
      final response = await request.close().timeout(const Duration(seconds: 5));
      await response.drain<void>();
    } catch (_) {
      // Fallo silencioso para no afectar la experiencia de usuario
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<bool> openExternalUrl(String url) {
    return ExternalUrlService.openUrl(url);
  }

  static String _stripHtmlAndEntities(String input) {
    final withoutTags = input.replaceAll(RegExp(r'<[^>]*>'), ' ');
    return withoutTags
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

