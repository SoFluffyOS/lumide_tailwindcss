/// LSP registration and lifecycle management service for Tailwind CSS.
library;

import 'dart:async';

import 'package:lumide_api/lumide_api.dart';
import 'package:lumide_tailwindcss/src/constants.dart';
import 'package:lumide_tailwindcss/src/models/models.dart';
import 'package:lumide_tailwindcss/src/services/log_service.dart';
import 'package:lumide_tailwindcss/src/services/tailwind_service.dart';
import 'package:lumide_tailwindcss/src/utils/utils.dart';

/// Manages registration and lifecycle of the Tailwind CSS Language Server.
class TailwindLspService {
  TailwindLspService(this._context, this._logger, this._tailwindService);

  final LumideContext _context;
  final LogService _logger;
  final TailwindService _tailwindService;

  TailwindLspState _state = TailwindLspState.uninitialized;
  String _activeCommand = defaultTailwindLspCommand;
  List<String> _activeArgs = const ['--stdio'];
  bool _isRegistered = false;
  Future<({String command, List<String> args})?>? _installing;

  /// Callback fired when the LSP server state or details change.
  Future<void> Function(TailwindLspState state, [String? detail])?
  onDidChangeStatus;

  TailwindLspState get state => _state;
  String get activeCommand => _activeCommand;
  bool get isRegistered => _isRegistered;

  /// Initializes and registers the Tailwind CSS language server.
  /// If [force] is false, skips initialization if no Tailwind project is detected.
  Future<bool> init({bool force = false}) async {
    if (!_tailwindService.projectInfo.hasTailwind && !force) {
      _logger.info(
        'Skipping LSP initialization: no Tailwind project in workspace',
      );
      _state = TailwindLspState.uninitialized;
      return false;
    }

    final customPath =
        await _context.workspace.getConfiguration(configTailwindServerPath)
            as String?;

    final resolved =
        await _resolveLspExecutable(customPath) ?? await _installLspServer();
    if (resolved == null) {
      _state = TailwindLspState.warning;
      await onDidChangeStatus?.call(
        TailwindLspState.warning,
        'Server not installed',
      );
      return false;
    }

    _activeCommand = resolved.command;
    _activeArgs = resolved.args;

    await _registerCurrentLsp();
    _state = TailwindLspState.running;

    final versionDetail = switch (_tailwindService.projectInfo.version) {
      final String v when v.isNotEmpty => v,
      _ => switch (_tailwindService.projectInfo.isV4) {
        true => 'v4',
        false => 'Active',
      },
    };

    await onDidChangeStatus?.call(_state, versionDetail);
    return true;
  }

  /// Registers or updates the language server in Lumide.
  Future<void> _registerCurrentLsp() async {
    final initOptions = await _buildInitializationOptions();
    final resolvedIconPath = await resolveAssetPath(assetTailwindLogo);

    await _context.languages.registerLanguageServer(
      id: lspProviderIdTailwind,
      languageId: 'tailwindcss',
      displayName: pluginName,
      fileExtensions: tailwindFileExtensions,
      extensionLanguageMap: tailwindExtensionLanguageMap,
      command: _activeCommand,
      args: _activeArgs,
      iconPath: resolvedIconPath,
      initializationOptions: initOptions,
    );

    _isRegistered = true;
    _logger.info(
      'Registered Tailwind LSP ($_activeCommand) with ${tailwindFileExtensions.length} file extensions and ${tailwindExtensionLanguageMap.length} language mappings',
    );
  }

  /// Restarts the active Tailwind language server.
  Future<void> restartLsp() async {
    if (!_isRegistered) {
      final success = await init(force: true);
      if (!success) return;
    } else {
      await _registerCurrentLsp();
    }

    await _context.window.showMessage(
      'Tailwind CSS Language Server restarted ($_activeCommand)',
      title: pluginName,
    );
  }

  /// Displays the interactive Tailwind menu, anchored to the click position if provided.
  Future<void> showMenu([Map<String, dynamic>? args]) async {
    Map<String, int>? position;
    if (args != null && args.containsKey('position')) {
      if (args['position'] case final Map<dynamic, dynamic> posMap) {
        if (posMap['x'] is num && posMap['y'] is num) {
          position = {
            'x': (posMap['x'] as num).toInt(),
            'y': (posMap['y'] as num).toInt(),
          };
        }
      }
    }

    const items = [
      QuickPickItem(
        label: 'Restart Language Server',
        tooltip: 'Restart the Tailwind CSS IntelliSense language server',
        payload: 'restart',
      ),
      QuickPickItem(
        label: 'Check Tailwind Status',
        tooltip: 'View detected configuration, version, and server details',
        payload: 'status',
      ),
      QuickPickItem(
        label: 'Configure Server Executable Path',
        tooltip: 'Specify a custom path to tailwindcss-language-server',
        payload: 'set_path',
      ),
    ];

    final picked = await _context.window.showQuickPick(
      items,
      placeholder: 'Tailwind CSS Actions',
      position: position,
    );

    if (picked == null) return;

    final payload = picked.payload as String? ?? picked.label;
    if (payload == 'restart') {
      await restartLsp();
      return;
    }

    if (payload == 'status') {
      await showStatus();
      return;
    }

    if (payload == 'set_path') {
      await promptServerPath();
    }
  }

  /// Prompts user to input a custom language server path.
  Future<void> promptServerPath() async {
    final currentPath =
        await _context.workspace.getConfiguration(configTailwindServerPath)
            as String?;

    final customPath = await _context.window.showInputBox(
      prompt: 'Enter absolute path to tailwindcss-language-server executable',
      title: 'Tailwind CSS Language Server Path',
      value: currentPath ?? _activeCommand,
    );

    if (customPath case final path? when path.trim().isNotEmpty) {
      await _context.workspace.updateConfiguration(
        configTailwindServerPath,
        path.trim(),
      );

      final available = await _tailwindService.checkExecutable(path.trim());
      if (available) {
        _activeCommand = path.trim();
        _activeArgs = const ['--stdio'];
        await _registerCurrentLsp();
        _state = TailwindLspState.running;
        await onDidChangeStatus?.call(_state, 'Custom Path');
        await _context.window.showMessage(
          'Tailwind CSS Language Server updated to: ${path.trim()}',
          title: pluginName,
        );
      } else {
        await _context.window.showMessage(
          'Could not run executable at "${path.trim()}". Please ensure it exists and is executable.',
          title: pluginName,
          type: MessageType.error,
        );
      }
    }
  }

  /// Shows the detected workspace status and LSP status in a message dialog.
  Future<void> showStatus() async {
    final project = _tailwindService.projectInfo;
    final serverVersion = _tailwindService.lspServerVersion ?? 'Unknown';

    final statusText = StringBuffer('Tailwind CSS Status:\n');
    statusText.writeln('• Workspace has Tailwind: ${project.hasTailwind}');

    if (project.configPath case final config?) {
      statusText.writeln('• Config file: $config');
    } else if (project.isV4) {
      statusText.writeln('• Config: Tailwind v4 (CSS @theme / @import)');
    } else {
      statusText.writeln('• Config file: None detected');
    }

    if (project.version case final ver?) {
      statusText.writeln('• Tailwind package version: $ver');
    }

    if (project.localBinaryPath case final localBin?) {
      statusText.writeln('• Local binary: $localBin');
    }

    statusText.writeln('• Server Executable: $_activeCommand');
    statusText.writeln('• Server Version: $serverVersion');
    statusText.writeln('• Status: ${_state.label}');

    await _context.window.showMessage(
      statusText.toString(),
      title: 'Tailwind CSS Status',
    );
  }

  /// Installs `@tailwindcss/language-server` globally with npm, then resolves
  /// the global binary. Concurrent calls share one install.
  Future<({String command, List<String> args})?> _installLspServer() =>
      _installing ??= _runInstall().whenComplete(() => _installing = null);

  Future<({String command, List<String> args})?> _runInstall() async {
    _logger.info('Installing $tailwindLspPackage with npm');
    await onDidChangeStatus?.call(
      TailwindLspState.uninitialized,
      'Installing server',
    );
    await _context.window.showMessage(
      'Installing the Tailwind CSS language server with npm...',
      title: pluginName,
    );

    try {
      final result = await _context.shell.run('npm', tailwindLspInstallArgs);
      if (result.exitCode != 0) {
        throw StateError('${result.stderr}\n${result.stdout}'.trim());
      }
      _tailwindService.forgetExecutable(defaultTailwindLspCommand);
      final isInstalled = await _tailwindService.checkExecutable(
        defaultTailwindLspCommand,
      );
      if (!isInstalled) {
        throw StateError(
          'npm finished, but $defaultTailwindLspCommand is not on PATH.',
        );
      }
      _logger.info('Installed $tailwindLspPackage');
      return (command: defaultTailwindLspCommand, args: defaultTailwindLspArgs);
    } catch (error) {
      _logger.warning('Could not install $tailwindLspPackage: $error');
      unawaited(
        _context.window.showMessage(
          'Could not install the Tailwind CSS language server: $error\n\n'
          'Run `npm ${tailwindLspInstallArgs.join(' ')}` or set a custom server path in settings ($configTailwindServerPath).',
          title: pluginName,
          type: MessageType.warning,
        ),
      );
      return null;
    }
  }

  /// Resolves the LSP server executable (custom path -> local node_modules -> global binary).
  Future<({String command, List<String> args})?> _resolveLspExecutable(
    String? explicitPath,
  ) async {
    // 1. Check explicit custom setting
    if (explicitPath case final path? when path.trim().isNotEmpty) {
      final available = await _tailwindService.checkExecutable(path.trim());
      if (available) {
        return (command: path.trim(), args: const ['--stdio']);
      }
    }

    // 2. Check local workspace node_modules binary
    if (_tailwindService.projectInfo.localBinaryPath case final localBin?) {
      final available = await _tailwindService.checkExecutable(localBin);
      if (available) {
        return (command: localBin, args: const ['--stdio']);
      }
    }

    // 3. Check standard global command on PATH
    final hasGlobal = await _tailwindService.checkExecutable(
      defaultTailwindLspCommand,
    );
    if (hasGlobal) {
      return (
        command: defaultTailwindLspCommand,
        args: const ['--stdio'],
      );
    }

    return null;
  }

  /// Builds server initialization options and settings for the LSP.
  Future<Map<String, dynamic>> _buildInitializationOptions() async {
    final emmet =
        await _context.workspace.getConfiguration(
              configTailwindEmmetCompletions,
            )
            as bool? ??
        false;

    final validate =
        await _context.workspace.getConfiguration(configTailwindValidate)
            as bool? ??
        true;

    final colorDecorators =
        await _context.workspace.getConfiguration(
              configTailwindColorDecorators,
            )
            as bool? ??
        true;

    final includeLanguages =
        await _context.workspace.getConfiguration(
              configTailwindIncludeLanguages,
            )
            as Map<String, dynamic>? ??
        {};

    final classAttributes =
        await _context.workspace.getConfiguration(
              configTailwindClassAttributes,
            )
            as List<dynamic>? ??
        ['class', 'className', 'ngClass', 'class:list'];

    final cssConflict =
        await _context.workspace.getConfiguration(
              configTailwindLintCssConflict,
            )
            as String? ??
        'warning';

    final invalidApply =
        await _context.workspace.getConfiguration(
              configTailwindLintInvalidApply,
            )
            as String? ??
        'error';

    final invalidScreen =
        await _context.workspace.getConfiguration(
              configTailwindLintInvalidScreen,
            )
            as String? ??
        'error';

    final invalidVariant =
        await _context.workspace.getConfiguration(
              configTailwindLintInvalidVariant,
            )
            as String? ??
        'error';

    final invalidConfigPath =
        await _context.workspace.getConfiguration(
              configTailwindLintInvalidConfigPath,
            )
            as String? ??
        'error';

    final userLanguages = <String, String>{
      ...defaultTailwindUserLanguages,
      for (final entry in includeLanguages.entries)
        if (entry.value is String) entry.key: entry.value as String,
    };

    return {
      'userLanguages': userLanguages,
      'tailwindCSS': {
        'emmetCompletions': emmet,
        'validate': validate,
        'colorDecorators': colorDecorators,
        'includeLanguages': userLanguages,
        'classAttributes': classAttributes,
        'lint': {
          'cssConflict': cssConflict,
          'invalidApply': invalidApply,
          'invalidScreen': invalidScreen,
          'invalidVariant': invalidVariant,
          'invalidConfigPath': invalidConfigPath,
        },
      },
    };
  }
}
