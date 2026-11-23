import 'package:flutter/material.dart';
import '../config/monetization_config.dart';
import '../models/monetization_models.dart';
import '../services/monetization_service.dart';
import '../theme/app_theme.dart';

/// Diálogo para realizar donaciones voluntarias (PayPal/Ko-fi) o activar una licencia
/// de pago único para ocultar los anuncios.
class SupportDialog extends StatefulWidget {
  final MonetizationBackend backend;
  final SupporterLicenseState initialLicenseState;
  final ValueChanged<SupporterLicenseState> onLicenseChanged;

  const SupportDialog({
    super.key,
    required this.backend,
    required this.initialLicenseState,
    required this.onLicenseChanged,
  });

  @override
  State<SupportDialog> createState() => _SupportDialogState();
}

class _SupportDialogState extends State<SupportDialog> {
  late SupporterLicenseState _licenseState;
  final TextEditingController _keyController = TextEditingController();
  bool _isActivating = false;
  String? _feedbackMessage;
  bool _feedbackIsError = false;

  @override
  void initState() {
    super.initState();
    _licenseState = widget.initialLicenseState;
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _openDonation() async {
    final launched = await widget.backend.openExternalUrl(MonetizationConfig.donationUrl);
    if (!mounted || launched) return;
    setState(() {
      _feedbackIsError = true;
      _feedbackMessage =
          'No se pudo abrir el navegador. Visita manualmente: ${MonetizationConfig.donationUrl}';
    });
  }

  Future<void> _openCheckout() async {
    final launched =
        await widget.backend.openExternalUrl(MonetizationConfig.removeAdsCheckoutUrl);
    if (!mounted || launched) return;
    setState(() {
      _feedbackIsError = true;
      _feedbackMessage =
          'No se pudo abrir la página de compra: ${MonetizationConfig.removeAdsCheckoutUrl}';
    });
  }

  Future<void> _activateLicense() async {
    setState(() {
      _isActivating = true;
      _feedbackMessage = null;
      _feedbackIsError = false;
    });

    final result = await widget.backend.activateLicenseKey(_keyController.text);
    if (!mounted) return;

    setState(() {
      _isActivating = false;
      _licenseState = result.state;
      _feedbackMessage = result.message;
      _feedbackIsError = !result.success;
    });

    if (result.success) {
      widget.onLicenseChanged(result.state);
    }
  }

  Future<void> _deactivateLicense() async {
    await widget.backend.deactivateLicense();
    const inactive = SupporterLicenseState.inactive(
      provider: MonetizationConfig.licenseProvider,
    );
    if (!mounted) return;
    setState(() {
      _licenseState = inactive;
      _keyController.clear();
      _feedbackIsError = false;
      _feedbackMessage = 'Licencia eliminada de este equipo.';
    });
    widget.onLicenseChanged(inactive);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _licenseState.isSupporter
                ? Icons.favorite_rounded
                : Icons.volunteer_activism_outlined,
            color: _licenseState.isSupporter
                ? AppColors.success(context)
                : AppColors.primary(context),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Apoyar Fprint-Manager',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 470,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDonationCard(context),
              const SizedBox(height: 12),
              _buildLicenseCard(context),
              if (_feedbackMessage != null) ...[
                const SizedBox(height: 12),
                _buildFeedbackBanner(context),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isActivating ? null : () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  Widget _buildDonationCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.coffee_outlined, size: 19, color: AppColors.primary(context)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Donación voluntaria (PayPal / Ko-fi)',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Fprint-Manager es software libre sin bloqueos funcionales. Si te resulta útil, puedes invitar a un café o enviar un aporte directo.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
            ),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: _openDonation,
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Donar con PayPal / Ko-fi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLicenseCard(BuildContext context) {
    if (_licenseState.isSupporter) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.verified_rounded,
                      size: 20, color: AppColors.success(context)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Licencia Supporter Activa',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Clave: ${_licenseState.maskedKey}',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
              if (_licenseState.customerEmail != null &&
                  _licenseState.customerEmail!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  'Titular: ${_licenseState.customerEmail}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _deactivateLicense,
                icon: const Icon(Icons.link_off_rounded, size: 16),
                label: const Text('Desactivar en este equipo'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.workspace_premium_outlined,
                    size: 19, color: AppColors.primary(context)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Quitar anuncios (${MonetizationConfig.removeAdsPriceLabel})',
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Pago único con tarjeta o PayPal. Recibirás al instante una clave de licencia para ocultar el banner en tu equipo.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _openCheckout,
              icon: const Icon(Icons.shopping_bag_outlined, size: 16),
              label: Text(
                'Obtener clave (${MonetizationConfig.removeAdsPriceLabel})',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _keyController,
              enabled: !_isActivating,
              decoration: InputDecoration(
                labelText: 'Clave de licencia Supporter',
                hintText: 'Pega aquí tu clave',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onSubmitted: (_) => _isActivating ? null : _activateLicense(),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: _isActivating ? null : _activateLicense,
                icon: _isActivating
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.key_rounded, size: 16),
                label: Text(_isActivating ? 'Validando...' : 'Activar licencia'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackBanner(BuildContext context) {
    final accent =
        _feedbackIsError ? AppColors.error(context) : AppColors.success(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      child: Text(
        _feedbackMessage!,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: accent,
        ),
      ),
    );
  }
}

