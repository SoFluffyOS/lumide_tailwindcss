import 'package:lumide_tailwindcss/lumide_tailwindcss.dart';
import 'package:test/test.dart';

void main() {
  group('Models', () {
    test('TailwindProjectInfo stores configuration correctly', () {
      const info = TailwindProjectInfo(
        hasTailwind: true,
        configPath: '/path/to/tailwind.config.js',
        packageJsonPath: '/path/to/package.json',
        version: '^3.4.0',
        isV4: false,
        localBinaryPath:
            '/path/to/node_modules/.bin/tailwindcss-language-server',
      );

      expect(info.hasTailwind, isTrue);
      expect(info.configPath, equals('/path/to/tailwind.config.js'));
      expect(info.packageJsonPath, equals('/path/to/package.json'));
      expect(info.version, equals('^3.4.0'));
      expect(info.isV4, isFalse);
      expect(
        info.localBinaryPath,
        equals('/path/to/node_modules/.bin/tailwindcss-language-server'),
      );
    });

    test('TailwindProjectInfo handles v4 detection', () {
      const info = TailwindProjectInfo(
        hasTailwind: true,
        version: '^4.0.0',
        isV4: true,
      );

      expect(info.hasTailwind, isTrue);
      expect(info.isV4, isTrue);
      expect(info.configPath, isNull);
    });

    test('TailwindLspState labels are consistent', () {
      expect(TailwindLspState.uninitialized.label, equals('Not Started'));
      expect(TailwindLspState.running.label, equals('Active'));
      expect(TailwindLspState.warning.label, equals('Warning'));
      expect(TailwindLspState.error.label, equals('Error'));
    });
  });
}
