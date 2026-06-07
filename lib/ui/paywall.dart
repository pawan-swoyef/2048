import 'package:flutter/material.dart';

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
  _Plan('lifetime', 'Lifetime', 'One-time, forever', '\$9.99', 'once'),
];

/// Premium upgrade screen (paywall). Until billing is wired up, "Continue"
/// simulates a successful purchase by unlocking premium.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  int _selected = 1; // default to Yearly

  void _purchase() {
    // TODO: replace with real Google Play Billing (in_app_purchase).
    ThemeScope.controllerOf(context).setPremiumUnlocked(true);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Premium unlocked! 🎉')),
    );
  }

  void _restore() {
    // TODO: query past purchases via billing. Placeholder for now.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No previous purchase found.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
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
                _benefits(),
                const SizedBox(height: 22),
                for (var i = 0; i < _plans.length; i++) ...[
                  _planCard(i),
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
                    onPressed: _purchase,
                    child: const Text('Continue',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: _restore,
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
        ),
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

  Widget _planCard(int i) {
    final plan = _plans[i];
    final selected = i == _selected;
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
                      Text(plan.name,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                      if (plan.badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD23F),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(plan.badge!,
                              style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF5A4500))),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(plan.sub,
                      style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(plan.price,
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
