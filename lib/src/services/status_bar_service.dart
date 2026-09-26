/// Status bar management for the Tailwind CSS plugin.
library;

import 'package:lumide_api/lumide_api.dart';
import 'package:lumide_tailwindcss/src/constants.dart';
import 'package:lumide_tailwindcss/src/models/models.dart';
import 'package:lumide_tailwindcss/src/utils/utils.dart';

class TailwindStatusBarService {
  TailwindStatusBarService(this._context);

  final LumideContext _context;
  String? _iconPath;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  String? get iconPath => _iconPath;

  /// Initializes and registers the Tailwind status bar item.
  Future<void> init(TailwindLspState state, [String? detail]) async {
    if (_isInitialized) {
      await update(state, detail);
      return;
    }

    _iconPath = await resolveAssetPath(assetTailwindLogo);

    final itemText = switch (_iconPath) {
      final String _ => '',
      _ => 'Tailwind',
    };

    final tooltipText = switch (detail) {
      final String d when d.trim().isNotEmpty => 'Tailwind CSS: ${d.trim()}',
      _ => 'Tailwind CSS IntelliSense (${state.label})',
    };

    await _context.statusBar.createItem(
      id: statusBarTailwindId,
      text: itemText,
      iconPath: _iconPath,
      alignment: 'right',
      priority: 14,
      tooltip: tooltipText,
      command: cmdTailwindShowMenu,
    );

    _isInitialized = true;
  }

  /// Updates the status bar item with the current LSP state or project detail.
  Future<void> update(TailwindLspState state, [String? detail]) async {
    if (!_isInitialized) {
      await init(state, detail);
      return;
    }

    final itemText = switch (_iconPath) {
      final String _ => '',
      _ => 'Tailwind',
    };

    final tooltipText = switch (detail) {
      final String d when d.trim().isNotEmpty => 'Tailwind CSS: ${d.trim()}',
      _ => 'Tailwind CSS IntelliSense (${state.label})',
    };

    await _context.statusBar.updateItem(
      statusBarTailwindId,
      text: itemText,
      iconPath: _iconPath,
      tooltip: tooltipText,
      command: cmdTailwindShowMenu,
    );
  }

  /// Removes the status bar item.
  Future<void> dispose() async {
    if (!_isInitialized) return;
    await _context.statusBar.disposeItem(statusBarTailwindId);
    _isInitialized = false;
  }
}
