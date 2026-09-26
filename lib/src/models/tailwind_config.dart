/// Models for Tailwind CSS plugin.
library;

/// Represents the detected Tailwind CSS setup in a workspace.
class TailwindProjectInfo {
  const TailwindProjectInfo({
    required this.hasTailwind,
    this.configPath,
    this.packageJsonPath,
    this.version,
    this.isV4 = false,
    this.localBinaryPath,
  });

  final bool hasTailwind;
  final String? configPath;
  final String? packageJsonPath;
  final String? version;
  final bool isV4;
  final String? localBinaryPath;

  @override
  String toString() =>
      'TailwindProjectInfo(hasTailwind: $hasTailwind, configPath: $configPath, version: $version, isV4: $isV4, localBinaryPath: $localBinaryPath)';
}

/// Execution status of the Tailwind Language Server.
enum TailwindLspState {
  uninitialized('Not Started'),
  running('Active'),
  warning('Warning'),
  error('Error');

  const TailwindLspState(this.label);
  final String label;
}
