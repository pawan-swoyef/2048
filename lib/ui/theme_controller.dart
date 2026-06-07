import 'package:flutter/widgets.dart';

import 'game_theme.dart';

export 'game_theme.dart';

/// Holds the selected theme and whether premium themes are unlocked.
///
/// [onChanged] is called whenever the selection or premium state changes, so
/// the UI layer can persist it (kept out of here to stay easily testable).
class ThemeController extends ChangeNotifier {
  final List<GameTheme> themes;
  final void Function(String selectedId, bool premiumUnlocked)? onChanged;

  String _selectedId;
  bool _premiumUnlocked;

  ThemeController({
    List<GameTheme>? themes,
    String selectedId = 'aurora',
    bool premiumUnlocked = false,
    this.onChanged,
  })  : themes = themes ?? kThemes,
        _selectedId = selectedId,
        _premiumUnlocked = premiumUnlocked;

  bool get premiumUnlocked => _premiumUnlocked;
  String get selectedId => _selectedId;

  GameTheme get current {
    for (final t in themes) {
      if (t.id == _selectedId) return t;
    }
    return themes.first;
  }

  GameTheme? _byId(String id) {
    for (final t in themes) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Whether [theme] is available to select (free, or premium when unlocked).
  bool isUnlocked(GameTheme theme) => !theme.isPremium || _premiumUnlocked;

  /// Selects a theme. Returns false if the id is unknown or the theme is locked.
  bool select(String id) {
    final theme = _byId(id);
    if (theme == null || !isUnlocked(theme)) return false;
    if (_selectedId == id) return true;
    _selectedId = id;
    _persist();
    notifyListeners();
    return true;
  }

  /// Unlocks or revokes premium themes. Revoking while a premium theme is
  /// selected reverts to the free default.
  void setPremiumUnlocked(bool value) {
    if (_premiumUnlocked == value) return;
    _premiumUnlocked = value;
    if (!value && current.isPremium) {
      _selectedId = themes.first.id;
    }
    _persist();
    notifyListeners();
  }

  void _persist() => onChanged?.call(_selectedId, _premiumUnlocked);
}

/// Exposes the active [GameTheme] to the widget tree and rebuilds dependents
/// when the theme or premium state changes.
class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController controllerOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'No ThemeScope found in context');
    return scope!.notifier!;
  }

  static GameTheme of(BuildContext context) => controllerOf(context).current;
}
