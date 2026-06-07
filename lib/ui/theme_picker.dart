import 'package:flutter/material.dart';

import 'paywall.dart';
import 'theme_controller.dart';

/// A grid for browsing and selecting themes. Premium themes show a lock until
/// the subscription is unlocked.
class ThemePickerScreen extends StatelessWidget {
  const ThemePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ThemeScope.controllerOf(context);
    final active = controller.current;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: active.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _header(context, controller),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  padding: const EdgeInsets.all(16),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.82,
                  children: [
                    for (final theme in controller.themes)
                      _ThemeCard(
                        theme: theme,
                        unlocked: controller.isUnlocked(theme),
                        selected: theme.id == controller.selectedId,
                        onTap: () => _onTap(context, controller, theme),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, ThemeController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Text(
            'Themes',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          if (controller.premiumUnlocked)
            const Row(
              children: [
                Icon(Icons.workspace_premium, color: Color(0xFFFFD23F), size: 18),
                SizedBox(width: 4),
                Text('Premium',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ],
            )
          else
            TextButton.icon(
              onPressed: () => _openPaywall(context),
              icon: const Icon(Icons.workspace_premium,
                  color: Color(0xFFFFD23F), size: 18),
              label: const Text('Go Premium',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  void _openPaywall(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PaywallScreen()),
    );
  }

  void _onTap(BuildContext context, ThemeController controller, GameTheme theme) {
    if (controller.isUnlocked(theme)) {
      controller.select(theme.id);
    } else {
      _showLockedDialog(context, controller, theme);
    }
  }

  void _showLockedDialog(
      BuildContext context, ThemeController controller, GameTheme theme) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: theme.dialogCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.workspace_premium, color: Colors.white, size: 40),
              const SizedBox(height: 10),
              Text(
                '“${theme.name}” is a Premium theme',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Subscribe to unlock all premium themes and unlimited undo.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Not now',
                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: theme.primaryButtonText,
                    ),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _openPaywall(context);
                    },
                    child: const Text('Go Premium',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final GameTheme theme;
  final bool unlocked;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.theme,
    required this.unlocked,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.backgroundGradient,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.white : Colors.white24,
            width: selected ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _preview()),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          theme.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.onBackground,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (selected)
                        const Icon(Icons.check_circle, color: Colors.white, size: 20),
                    ],
                  ),
                ],
              ),
            ),
            if (!unlocked)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock, color: Colors.white, size: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// A small 2x2 preview of representative tiles in this theme.
  Widget _preview() {
    const values = [2, 64, 8, 512];
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: theme.boardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.glassStroke, width: 1),
      ),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (final v in values)
            Container(
              decoration: BoxDecoration(
                color: theme.tileColors(v).background,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: FittedBox(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    '$v',
                    style: TextStyle(
                      color: theme.tileColors(v).text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
