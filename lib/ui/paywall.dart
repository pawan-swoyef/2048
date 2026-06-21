import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../iap/iap_service.dart';
import 'theme_controller.dart';

class _Plan {
  final String id;
  final String name;
  final String sub;
  final String price;
  final String per;
  final String? badge;
  const _Plan(this.id, this.name, this.sub, this.price, this.per, [this.badge]);
}

const _plans = <_Plan>[
  _Plan('monthly', 'Monthly', 'Billed monthly', '\$1.99', '/month'),
  _Plan('yearly', 'Yearly', '\$0.67 / month', '\$7.99', '/year',
      'BEST VALUE · SAVE 67%'),
  _Plan('lifetime2048', 'Lifetime', 'One-time, forever', '\$9.99', 'once'),
];

/// Premium upgrade screen (paywall). Handles loading real store products,
/// showing their real prices, and processing real purchases/restores.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  int _selected = 1; // default to Yearly

  ProductDetails? _findProduct(String planId, List<ProductDetails> storeProducts) {
    for (final prod in storeProducts) {
      if (prod.id == planId) return prod;
    }
    return null;
  }

  void _purchase(IAPService iapService) {
    final plan = _plans[_selected];
    final prod = _findProduct(plan.id, iapService.products);

    if (prod != null) {
      iapService.buyProduct(prod);
    } else {
      // Fallback behavior when running on local devices/simulators without store products configured
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Store product not found. Simulating premium unlock...'),
          duration: Duration(seconds: 2),
        ),
      );
      ThemeScope.controllerOf(context).setPremiumUnlocked(true);
    }
  }

  void _restore(IAPService iapService) {
    if (iapService.isAvailable) {
      iapService.restorePurchases();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Store is not available on this device.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final iapService = IAPScope.of(context);
    final premiumUnlocked = ThemeScope.controllerOf(context).premiumUnlocked;

    if (premiumUnlocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Premium unlocked! 🎉')),
          );
        }
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: theme.backgroundGradient,
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        const Text('👑', style: TextStyle(fontSize: 46)),
                        const SizedBox(height: 6),
                        const Text(
                          'Go Premium',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Unlock the full experience',
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                        const SizedBox(height: 22),
                        if (iapService.errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.redAccent),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.redAccent),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    iapService.errorMessage!,
                                    style: const TextStyle(color: Colors.white, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        _benefits(),
                        const SizedBox(height: 22),
                        for (var i = 0; i < _plans.length; i++) ...[
                          _planCard(i, iapService.products),
                          const SizedBox(height: 12),
                        ],
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: theme.primaryButtonText,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: iapService.isLoading ? null : () => _purchase(iapService),
                            child: const Text('Continue',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: iapService.isLoading ? null : () => _restore(iapService),
                          child: const Text(
                            'Restore purchase',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Subscriptions auto-renew until cancelled. Cancel anytime in '
                          'Google Play.\nTerms of Service · Privacy Policy',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10, color: Colors.white60, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (iapService.isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _benefits() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: const [
          _Benefit('🚫', 'Remove all ads', 'No banners, no interruptions'),
          _Benefit('↩️', 'Unlimited Undo', 'Take back any move, anytime'),
          _Benefit('🎨', 'All 7 themes', 'Neon, Ocean, Gold & more'),
        ],
      ),
    );
  }

  Widget _planCard(int i, List<ProductDetails> storeProducts) {
    final plan = _plans[i];
    final prod = _findProduct(plan.id, storeProducts);
    final selected = i == _selected;

    final name = prod?.title ?? plan.name;
    final price = prod?.price ?? plan.price;
    final subText = (prod?.description != null && prod!.description.isNotEmpty)
        ? prod.description
        : plan.sub;

    final cleanedName = name.split('(').first.trim();

    return GestureDetector(
      onTap: () => setState(() => _selected = i),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 16, 16, 14),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0x26FFD23F)
              : Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFFFFD23F) : Colors.white24,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            _radio(selected),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          cleanedName,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (plan.badge != null) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD23F),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                plan.badge!,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF5A4500),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subText,
                      style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(price,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                Text(plan.per,
                    style: const TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _radio(bool selected) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? const Color(0xFFFFD23F) : Colors.white,
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFD23F),
                ),
              ),
            )
          : null,
    );
  }
}


class _Benefit extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  const _Benefit(this.icon, this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                Text(subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
