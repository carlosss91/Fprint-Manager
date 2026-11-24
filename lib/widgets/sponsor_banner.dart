import 'package:flutter/material.dart';
import '../config/monetization_config.dart';
import '../l10n/app_localizations.dart';
import '../models/monetization_models.dart';
import '../theme/app_theme.dart';

/// Banner publicitario minimalista y respetuoso con la privacidad (EthicalAds / aviso propio).
/// - Se oculta automáticamente para usuarios Supporter.
/// - Notifica la impresión (`view_url`) una única vez por anuncio visible.
class SponsorBanner extends StatefulWidget {
  final EthicalAdItem ad;
  final VoidCallback onOpenAd;
  final VoidCallback onRemoveAds;
  final ValueChanged<String> onReportImpression;

  const SponsorBanner({
    super.key,
    required this.ad,
    required this.onOpenAd,
    required this.onRemoveAds,
    required this.onReportImpression,
  });

  @override
  State<SponsorBanner> createState() => _SponsorBannerState();
}

class _SponsorBannerState extends State<SponsorBanner> {
  final Set<String> _reportedViewUrls = {};
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _scheduleImpressionIfNeeded();
  }

  @override
  void didUpdateWidget(SponsorBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ad.viewUrl != widget.ad.viewUrl) {
      _scheduleImpressionIfNeeded();
    }
  }

  void _scheduleImpressionIfNeeded() {
    final viewUrl = widget.ad.viewUrl;
    if (viewUrl == null ||
        viewUrl.isEmpty ||
        _reportedViewUrls.contains(viewUrl)) {
      return;
    }

    _reportedViewUrls.add(viewUrl);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onReportImpression(viewUrl);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final primary = AppColors.primary(context);
    final labelText = widget.ad.isFallbackHouseAd ? l10n.bannerIndieLabel : 'EthicalAds';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _hovered
              ? primary.withValues(alpha: 0.08)
              : AppColors.sidebar(context),
          border: Border(
            top: BorderSide(color: AppColors.border(context), width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: primary.withValues(alpha: 0.28)),
              ),
              child: Text(
                labelText,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: widget.onOpenAd,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                  child: Text(
                    widget.ad.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.3,
                      color: AppColors.textSecondary(context),
                      decoration: _hovered ? TextDecoration.underline : null,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                foregroundColor: primary,
              ),
              onPressed: widget.onRemoveAds,
              child: Text(
                l10n.bannerRemoveBtn(MonetizationConfig.removeAdsPriceLabel),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

