import 'dart:io';

import 'package:lumide_tailwindcss/lumide_tailwindcss.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Tailwind Detection Helpers', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('tailwind_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('v3 config files are recognized in constants', () {
      expect(tailwindConfigFiles, contains('tailwind.config.js'));
      expect(tailwindConfigFiles, contains('tailwind.config.ts'));
      expect(tailwindConfigFiles, contains('tailwind.config.cjs'));
      expect(tailwindConfigFiles, contains('tailwind.config.mjs'));
    });

    test('all supported file extensions have per-extension language IDs', () {
      for (final ext in tailwindFileExtensions) {
        expect(
          tailwindExtensionLanguageMap.containsKey(ext),
          isTrue,
          reason: 'Missing language ID mapping for $ext',
        );
        expect(
          tailwindExtensionLanguageMap[ext],
          isNotEmpty,
          reason: 'Language ID cannot be empty for $ext',
        );
      }
    });

    test('syntax mapping matches language server expectations', () {
      expect(tailwindExtensionLanguageMap['.html'], 'html');
      expect(tailwindExtensionLanguageMap['.css'], 'css');
      expect(tailwindExtensionLanguageMap['.tsx'], 'typescriptreact');
      expect(tailwindExtensionLanguageMap['.jsx'], 'javascriptreact');
      expect(tailwindExtensionLanguageMap['.vue'], 'vue');
      expect(tailwindExtensionLanguageMap['.svelte'], 'svelte');
      expect(tailwindExtensionLanguageMap['.astro'], 'astro');
      expect(tailwindExtensionLanguageMap['.php'], 'php');
      expect(tailwindExtensionLanguageMap['.blade.php'], 'blade');

      expect(defaultTailwindUserLanguages['blade'], 'html');
      expect(defaultTailwindUserLanguages['twig'], 'html');
    });

    test('simulated local node_modules binary path resolution', () async {
      final binDir = Directory(p.join(tempDir.path, 'node_modules', '.bin'));
      await binDir.create(recursive: true);

      final binFile = File(p.join(binDir.path, 'tailwindcss-language-server'));
      await binFile.writeAsString('#!/usr/bin/env node\n');

      expect(await binFile.exists(), isTrue);
    });

    test('simulated v4 CSS header detection', () async {
      final cssFile = File(p.join(tempDir.path, 'app.css'));
      await cssFile.writeAsString(
        '@import "tailwindcss";\n\nbody { margin: 0; }',
      );

      // Verify that opening first 4096 bytes detects directive
      final length = await cssFile.length();
      final end = length < 4096 ? length : 4096;
      final chunk = await cssFile
          .openRead(0, end)
          .transform(const SystemEncoding().decoder)
          .join();

      expect(chunk.contains('@import "tailwindcss"'), isTrue);
    });
  });
}
