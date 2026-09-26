/// Workspace inspection and environment detection for Tailwind CSS.
library;

import 'dart:convert';
import 'dart:io';

import 'package:lumide_api/lumide_api.dart';
import 'package:lumide_tailwindcss/src/constants.dart';
import 'package:lumide_tailwindcss/src/models/models.dart';
import 'package:lumide_tailwindcss/src/services/log_service.dart';
import 'package:lumide_tailwindcss/src/utils/utils.dart';
import 'package:path/path.dart' as p;

class TailwindService {
  TailwindService(this._context, this._logger);

  final LumideContext _context;
  final LogService _logger;

  TailwindProjectInfo _projectInfo =
      const TailwindProjectInfo(hasTailwind: false);
  String? _lspServerVersion;
  final Map<String, bool> _executableCache = {};

  TailwindProjectInfo get projectInfo => _projectInfo;
  String? get lspServerVersion => _lspServerVersion;

  /// Detects Tailwind CSS in the current workspace.
  Future<TailwindProjectInfo> detectWorkspace() async {
    final rootUri = await _context.workspace.getRootUri();
    if (rootUri == null) {
      _projectInfo = const TailwindProjectInfo(hasTailwind: false);
      return _projectInfo;
    }

    final rootPath = normalizeFilePath(rootUri);
    final rootDir = Directory(rootPath);
    if (!await rootDir.exists()) {
      _projectInfo = const TailwindProjectInfo(hasTailwind: false);
      return _projectInfo;
    }

    // 1. Check workspace root
    final rootCheck = await _inspectDirectory(rootPath);
    if (rootCheck.hasTailwind) {
      final localBin = await _findLocalExecutable(rootPath);
      _projectInfo = TailwindProjectInfo(
        hasTailwind: true,
        configPath: rootCheck.configPath,
        packageJsonPath: rootCheck.packageJsonPath,
        version: rootCheck.version,
        isV4: rootCheck.isV4,
        localBinaryPath: localBin,
      );
      _logger.info('Detected Tailwind at workspace root: $_projectInfo');
      return _projectInfo;
    }

    // 2. Check monorepo packages / subdirectories (e.g., apps/*, packages/*, web, frontend)
    final subdirs = await _findMonorepoSubdirectories(rootPath);
    for (final subdir in subdirs) {
      final subCheck = await _inspectDirectory(subdir);
      if (subCheck.hasTailwind) {
        final localBin = (await _findLocalExecutable(subdir)) ??
            (await _findLocalExecutable(rootPath));
        _projectInfo = TailwindProjectInfo(
          hasTailwind: true,
          configPath: subCheck.configPath,
          packageJsonPath: subCheck.packageJsonPath,
          version: subCheck.version,
          isV4: subCheck.isV4,
          localBinaryPath: localBin,
        );
        _logger.info(
          'Detected Tailwind in monorepo package "$subdir": $_projectInfo',
        );
        return _projectInfo;
      }
    }

    _projectInfo = const TailwindProjectInfo(hasTailwind: false);
    _logger.info('No Tailwind CSS project detected in workspace');
    return _projectInfo;
  }

  /// Inspects a single directory for Tailwind v3 configs, package.json, or v4 CSS imports.
  Future<
      ({
        bool hasTailwind,
        String? configPath,
        String? packageJsonPath,
        String? version,
        bool isV4
      })> _inspectDirectory(String dirPath) async {
    // 1. Check for tailwind.config.*
    String? foundConfig;
    for (final configFile in tailwindConfigFiles) {
      final file = File(p.join(dirPath, configFile));
      if (await file.exists()) {
        foundConfig = file.path;
        break;
      }
    }

    // 2. Check package.json for tailwindcss dependency
    String? pkgJsonPath;
    String? detectedVersion;
    bool isV4 = false;

    final pkgJsonFile = File(p.join(dirPath, 'package.json'));
    if (await pkgJsonFile.exists()) {
      pkgJsonPath = pkgJsonFile.path;
      try {
        final content = await pkgJsonFile.readAsString();
        final json = jsonDecode(content);
        if (json is Map<String, dynamic>) {
          final deps = json['dependencies'];
          final devDeps = json['devDependencies'];
          final version = switch (deps) {
                final Map<dynamic, dynamic> d when d['tailwindcss'] != null =>
                  d['tailwindcss'],
                _ => null,
              } ??
              switch (devDeps) {
                final Map<dynamic, dynamic> d when d['tailwindcss'] != null =>
                  d['tailwindcss'],
                _ => null,
              };

          if (version is String) {
            detectedVersion = version;
            if (version.contains('4.') ||
                version.startsWith('^4') ||
                version.startsWith('~4')) {
              isV4 = true;
            }
          }
        }
      } catch (e) {
        _logger.warning('Failed to parse package.json in $dirPath: $e');
      }
    }

    // 3. Check for Tailwind v4 CSS imports if no config or dependency was found
    if (foundConfig == null && detectedVersion == null) {
      final v4Detected = await _detectTailwindV4Css(dirPath);
      if (v4Detected) {
        isV4 = true;
      }
    }

    final hasTailwind = foundConfig != null || detectedVersion != null || isV4;
    return (
      hasTailwind: hasTailwind,
      configPath: foundConfig,
      packageJsonPath: pkgJsonPath,
      version: detectedVersion,
      isV4: isV4,
    );
  }

  /// Locates candidate monorepo packages (e.g., apps/*, packages/*, web, frontend, client).
  Future<List<String>> _findMonorepoSubdirectories(String rootPath) async {
    final candidates = <String>[];
    final rootDir = Directory(rootPath);
    if (!await rootDir.exists()) return candidates;

    final directSubnames = ['apps', 'packages', 'web', 'frontend', 'client'];
    for (final name in directSubnames) {
      final sub = Directory(p.join(rootPath, name));
      if (!await sub.exists()) continue;

      if (name == 'apps' || name == 'packages') {
        try {
          final entries = await sub.list(followLinks: false).toList();
          for (final entry in entries) {
            if (entry is Directory) {
              candidates.add(entry.path);
            }
          }
        } catch (_) {}
      } else {
        candidates.add(sub.path);
      }
    }

    return candidates;
  }

  /// Scans common CSS entry points for Tailwind v4 `@import "tailwindcss";` or `@theme`.
  /// Reads only the first 4KB chunk of each file to avoid allocating memory for large bundles.
  Future<bool> _detectTailwindV4Css(String dirPath) async {
    final commonCssPaths = [
      p.join(dirPath, 'src', 'index.css'),
      p.join(dirPath, 'src', 'app.css'),
      p.join(dirPath, 'src', 'globals.css'),
      p.join(dirPath, 'src', 'main.css'),
      p.join(dirPath, 'styles', 'globals.css'),
      p.join(dirPath, 'styles', 'main.css'),
      p.join(dirPath, 'resources', 'css', 'app.css'),
      p.join(dirPath, 'assets', 'css', 'main.css'),
      p.join(dirPath, 'app', 'globals.css'),
      p.join(dirPath, 'app.css'),
      p.join(dirPath, 'main.css'),
      p.join(dirPath, 'index.css'),
    ];

    for (final path in commonCssPaths) {
      final file = File(path);
      if (await file.exists()) {
        final matches = await _checkCssFileForTailwind(file);
        if (matches) return true;
      }
    }

    return false;
  }

  /// Efficiently checks if the CSS file header contains Tailwind v4 directives.
  Future<bool> _checkCssFileForTailwind(File file) async {
    try {
      final length = await file.length();
      final end = switch (length < 4096) {
        true => length,
        false => 4096,
      };
      if (end == 0) return false;

      final chunk = await utf8.decodeStream(file.openRead(0, end));
      return chunk.contains('@import "tailwindcss"') ||
          chunk.contains("@import 'tailwindcss'") ||
          chunk.contains('@theme');
    } catch (_) {
      return false;
    }
  }

  /// Checks for a locally installed `node_modules/.bin/tailwindcss-language-server`.
  Future<String?> _findLocalExecutable(String baseDir) async {
    final binName = switch (Platform.isWindows) {
      true => '$defaultTailwindLspCommand.cmd',
      false => defaultTailwindLspCommand,
    };

    final localPath = p.join(baseDir, 'node_modules', '.bin', binName);
    final file = File(localPath);
    if (await file.exists()) {
      return p.normalize(localPath);
    }
    return null;
  }

  /// Drops the cached result for [command], e.g. after installing it.
  void forgetExecutable(String command) =>
      _executableCache.remove(command.trim());

  /// Verifies if an executable is runnable via the Lumide shell interface with caching.
  Future<bool> checkExecutable(String command) async {
    final normalized = command.trim();
    if (normalized.isEmpty) return false;

    if (_executableCache.containsKey(normalized)) {
      return _executableCache[normalized] == true;
    }

    // Direct check for absolute / existing file path
    final file = File(normalized);
    if (p.isAbsolute(normalized) && await file.exists()) {
      _executableCache[normalized] = true;
      return true;
    }

    try {
      final result = await _context.shell.run(normalized, ['--version']);
      if (result.exitCode == 0) {
        final versionOutput = result.stdout.toString().trim();
        if (versionOutput.isNotEmpty) {
          _lspServerVersion = versionOutput;
        }
        _executableCache[normalized] = true;
        return true;
      }
    } catch (_) {}

    final whichCmd = switch (Platform.isWindows) {
      true => 'where',
      false => 'which',
    };

    try {
      final result = await _context.shell.run(whichCmd, [normalized]);
      final success = result.exitCode == 0;
      _executableCache[normalized] = success;
      return success;
    } catch (_) {}

    _executableCache[normalized] = false;
    return false;
  }
}
