/// Path and asset resolution utilities for Tailwind CSS plugin.
library;

import 'dart:io';
import 'dart:isolate';

import 'package:lumide_tailwindcss/src/constants.dart';
import 'package:path/path.dart' as p;

/// Normalizes a file URI or raw path string to a native filesystem path.
String normalizeFilePath(String raw) {
  if (raw.startsWith('file://')) {
    try {
      return Uri.parse(raw).toFilePath();
    } catch (_) {
      return raw;
    }
  }
  return raw;
}

/// Resolves the absolute filesystem path to an asset bundled with the plugin.
Future<String?> resolveAssetPath(String assetName) async {
  try {
    final baseUri =
        Uri.parse('package:lumide_tailwindcss/lumide_tailwindcss.dart');
    final resolvedBase = await Isolate.resolvePackageUri(baseUri);

    if (resolvedBase != null && resolvedBase.isScheme('file')) {
      final libDir = p.dirname(resolvedBase.toFilePath());
      final packageRoot = p.dirname(libDir);
      final assetPath = p.normalize(
        p.join(packageRoot, folderAssets, assetName),
      );

      if (await File(assetPath).exists()) {
        return assetPath;
      }
    }
  } catch (_) {}

  final scriptPath = Platform.script.toFilePath();
  final scriptDir = p.dirname(scriptPath);

  final candidates = [
    p.join(scriptDir, '..', folderAssets, assetName),
    p.join(scriptDir, folderAssets, assetName),
    p.join(Directory.current.path, folderAssets, assetName),
  ];

  for (final candidate in candidates) {
    final normalized = p.normalize(candidate);
    if (await File(normalized).exists()) {
      return normalized;
    }
  }

  return null;
}
