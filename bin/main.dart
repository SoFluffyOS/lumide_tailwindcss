/// Tailwind CSS IntelliSense plugin entry point for Lumide IDE.
library;

import 'package:lumide_api/lumide_api.dart';
import 'package:lumide_tailwindcss/lumide_tailwindcss.dart';

void main() => TailwindPlugin().run();

class TailwindPlugin extends LumidePlugin {
  late final LogService logService;
  late final TailwindService tailwindService;
  late final TailwindLspService lspService;
  late final TailwindStatusBarService statusBarService;

  @override
  Future<void> onActivate(LumideContext context) async {
    logService = LogService(log);
    logService.info('$pluginName plugin activating...');

    tailwindService = TailwindService(context, logService);
    lspService = TailwindLspService(context, logService, tailwindService);
    statusBarService = TailwindStatusBarService(context);

    // Sync status bar whenever LSP state or details change
    lspService.onDidChangeStatus = (state, [detail]) async {
      await statusBarService.init(state, detail);
    };

    // Detect workspace project
    final project = await tailwindService.detectWorkspace();

    // If this is a Tailwind project, initialize LSP and status bar
    if (project.hasTailwind) {
      await lspService.init();
      await statusBarService.init(
        lspService.state,
        project.version ??
            switch (project.isV4) {
              true => 'v4',
              false => null,
            },
      );
    } else {
      logService.info('No Tailwind CSS project detected. Plugin is idle.');
    }

    // React to configuration changes in Settings UI
    context.workspace.onDidChangeConfiguration((_) async {
      if (tailwindService.projectInfo.hasTailwind) {
        logService.info('Configuration updated. Refreshing Tailwind LSP...');
        await lspService.restartLsp();
      }
    });

    // Register Commands so user can trigger them anytime
    await context.commands.registerCommand(
      id: cmdTailwindRestartLsp,
      title: 'Tailwind CSS: Restart Language Server',
      category: pluginName,
      callback: ([_]) async {
        if (!tailwindService.projectInfo.hasTailwind) {
          await tailwindService.detectWorkspace();
        }
        await lspService.restartLsp();
        if (lspService.isRegistered && !statusBarService.isInitialized) {
          await statusBarService.init(lspService.state);
        }
      },
    );

    await context.commands.registerCommand(
      id: cmdTailwindShowMenu,
      title: 'Tailwind CSS: Show Actions Menu',
      category: pluginName,
      callback: ([args]) async {
        if (!statusBarService.isInitialized &&
            tailwindService.projectInfo.hasTailwind) {
          await statusBarService.init(lspService.state);
        }
        await lspService.showMenu(args);
      },
    );

    await context.commands.registerCommand(
      id: cmdTailwindCheckStatus,
      title: 'Tailwind CSS: Show Status',
      category: pluginName,
      callback: ([_]) async {
        await tailwindService.detectWorkspace();
        await lspService.showStatus();
      },
    );

    logService.info('$pluginName plugin activated successfully');
  }

  @override
  Future<void> onDeactivate() async {
    await statusBarService.dispose();
    logService.info('$pluginName plugin deactivated');
  }
}
