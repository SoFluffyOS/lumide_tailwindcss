import 'dart:io';

import 'package:lumide_tailwindcss/lumide_tailwindcss.dart';
import 'package:test/test.dart';

void main() {
  group('PathUtils', () {
    test('normalizeFilePath handles raw paths and file URIs', () {
      expect(normalizeFilePath('/foo/bar/baz'), equals('/foo/bar/baz'));
      expect(
        normalizeFilePath('file:///foo/bar/baz'),
        equals('/foo/bar/baz'),
      );
    });

    test('resolveAssetPath resolves tailwind-logo.svg asset', () async {
      final resolved = await resolveAssetPath(assetTailwindLogo);
      expect(resolved, isNotNull);
      expect(resolved, endsWith(assetTailwindLogo));
      expect(await File(resolved!).exists(), isTrue);
    });

    test('resolveAssetPath returns null for non-existent asset', () async {
      final resolved = await resolveAssetPath('non_existent_asset_file.png');
      expect(resolved, isNull);
    });
  });
}
