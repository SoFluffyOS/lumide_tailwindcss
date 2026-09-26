/// Plugin constants for Tailwind CSS IntelliSense.
library;

// Plugin identification
const pluginId = 'lumide_tailwindcss';
const pluginName = 'Tailwind CSS';

const folderAssets = 'assets';
const assetTailwindLogo = 'tailwind-logo.svg';

// Executable and LSP constants
const defaultTailwindLspCommand = 'tailwindcss-language-server';
const defaultTailwindLspArgs = ['--stdio'];
const tailwindLspPackage = '@tailwindcss/language-server';
const tailwindLspInstallArgs = ['install', '-g', tailwindLspPackage];
const lspProviderIdTailwind = 'tailwindcss-lsp';

// Status bar
const statusBarTailwindId = 'lumide_tailwindcss.status';
const statusBarTailwindPriority = 98; // High priority, near other language items

// Commands
const cmdTailwindRestartLsp = 'tailwindCSS.restartLsp';
const cmdTailwindShowMenu = 'tailwindCSS.showMenu';
const cmdTailwindCheckStatus = 'tailwindCSS.checkStatus';

// Configuration keys
const configTailwindServerPath = 'tailwindCSS.serverPath';
const configTailwindEmmetCompletions = 'tailwindCSS.emmetCompletions';
const configTailwindValidate = 'tailwindCSS.validate';
const configTailwindColorDecorators = 'tailwindCSS.colorDecorators';
const configTailwindIncludeLanguages = 'tailwindCSS.includeLanguages';
const configTailwindClassAttributes = 'tailwindCSS.classAttributes';
const configTailwindClassFunctions = 'tailwindCSS.classFunctions';
const configTailwindLintCssConflict = 'tailwindCSS.lint.cssConflict';
const configTailwindLintInvalidApply = 'tailwindCSS.lint.invalidApply';
const configTailwindLintInvalidScreen = 'tailwindCSS.lint.invalidScreen';
const configTailwindLintInvalidVariant = 'tailwindCSS.lint.invalidVariant';
const configTailwindLintInvalidConfigPath = 'tailwindCSS.lint.invalidConfigPath';

// Supported file extensions
const tailwindFileExtensions = [
  '.html',
  '.htm',
  '.xhtml',
  '.css',
  '.scss',
  '.sass',
  '.less',
  '.postcss',
  '.js',
  '.jsx',
  '.ts',
  '.tsx',
  '.mjs',
  '.cjs',
  '.vue',
  '.svelte',
  '.astro',
  '.php',
  '.blade.php',
  '.twig',
  '.liquid',
  '.erb',
  '.heex',
  '.mdx',
];

/// Per-extension language IDs sent to the Tailwind language server during textDocument/didOpen.
const tailwindExtensionLanguageMap = <String, String>{
  // Markup & Templates
  '.html': 'html',
  '.htm': 'html',
  '.xhtml': 'html',
  // Stylesheets
  '.css': 'css',
  '.scss': 'scss',
  '.sass': 'sass',
  '.less': 'less',
  '.postcss': 'postcss',
  // JavaScript & TypeScript
  '.js': 'javascript',
  '.jsx': 'javascriptreact',
  '.ts': 'typescript',
  '.tsx': 'typescriptreact',
  '.mjs': 'javascript',
  '.cjs': 'javascript',
  // Frameworks & Components
  '.vue': 'vue',
  '.svelte': 'svelte',
  '.astro': 'astro',
  '.php': 'php',
  '.blade.php': 'blade',
  '.twig': 'twig',
  '.liquid': 'liquid',
  '.erb': 'erb',
  '.heex': 'phoenix-heex',
  '.mdx': 'mdx',
};

/// Default user language mappings for template engines recognized as HTML syntax.
const defaultTailwindUserLanguages = <String, String>{
  'blade': 'html',
  'twig': 'html',
  'liquid': 'html',
  'erb': 'html',
  'phoenix-heex': 'html',
  'heex': 'html',
};

// Tailwind configuration files (v3 and earlier)
const tailwindConfigFiles = [
  'tailwind.config.js',
  'tailwind.config.cjs',
  'tailwind.config.mjs',
  'tailwind.config.ts',
  'tailwind.config.json',
];

// PostCSS configuration files
const postcssConfigFiles = [
  'postcss.config.js',
  'postcss.config.cjs',
  'postcss.config.mjs',
  'postcss.config.ts',
  'postcss.config.json',
  '.postcssrc',
  '.postcssrc.json',
  '.postcssrc.js',
];
