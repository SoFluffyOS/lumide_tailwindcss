# lumide_tailwindcss

[![pub package](https://img.shields.io/pub/v/lumide_tailwindcss.svg)](https://pub.dev/packages/lumide_tailwindcss) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) [![Powered by SoFluffy](https://img.shields.io/badge/Powered%20by-SoFluffy-orange)](https://sofluffy.io)

The official Tailwind CSS extension for [Lumide IDE](https://lumide.dev).

`lumide_tailwindcss` provides Tailwind CSS IntelliSense through the official [`@tailwindcss/language-server`](https://github.com/tailwindlabs/tailwindcss-intellisense).

## Highlights

- Complete classes, arbitrary values (`top-[117px]`), and variants (`sm:hover:bg-sky-500`).
- Preview colors in completions and the editor.
- Hover a class to see its generated CSS.
- Lint conflicting classes (`p-2 p-4`) and invalid `@apply`, `@screen`, `@variant`, and `theme()` usage.
- Detect Tailwind v3 (`tailwind.config.*`) and v4 (`@import "tailwindcss"`, `@theme`) projects.
- Find configs in monorepo packages (`apps/*`, `packages/*`, `web/`, `frontend/`).
- Check status, restart the server, or set its path from the status bar.

## Languages

- **Markup**: HTML, XHTML, Blade, Twig, Liquid, ERB, HEEx, MDX
- **Styles**: CSS, SCSS, Sass, Less, PostCSS
- **Scripts**: JavaScript, TypeScript, Vue, Svelte, Astro, PHP

Add more with `tailwindCSS.includeLanguages`.

## Commands

Use the Command Palette (`Cmd+Shift+P` / `Ctrl+Shift+P`) or the status bar item.

| Command | Purpose |
|---|---|
| `tailwindCSS.showMenu` | Open the actions menu |
| `tailwindCSS.restartLsp` | Restart the language server |
| `tailwindCSS.checkStatus` | Show the detected config, version, and server |

## Requirements

- **Node.js**: A Node.js runtime must be installed.
- **Local server**: Uses `node_modules/.bin/tailwindcss-language-server` when your project has one.
- **Automatic install**: Otherwise installs `@tailwindcss/language-server` globally with npm if it is missing.
- **Custom executable**: Set `tailwindCSS.serverPath` to use another server.

## Settings

| Setting | Default | Description |
|---|---|---|
| `tailwindCSS.serverPath` | — | Optional executable override |
| `tailwindCSS.emmetCompletions` | `false` | Complete classes in Emmet abbreviations (`div.flex`) |
| `tailwindCSS.validate` | `true` | Enable linting |
| `tailwindCSS.colorDecorators` | `true` | Show inline color previews |
| `tailwindCSS.includeLanguages` | — | Map extra languages, e.g. `{"plaintext": "html"}` |
| `tailwindCSS.classAttributes` | `class`, `className`, `ngClass`, `class:list` | Attributes to scan for classes |
| `tailwindCSS.lint.cssConflict` | `warning` | Classes that apply conflicting CSS |
| `tailwindCSS.lint.invalidApply` | `error` | Invalid `@apply` usage |
| `tailwindCSS.lint.invalidScreen` | `error` | Unknown `@screen` names |
| `tailwindCSS.lint.invalidVariant` | `error` | Unknown `@variant` names |
| `tailwindCSS.lint.invalidConfigPath` | `error` | Invalid `theme()` paths |

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

Built with ❤️ by [SoFluffy](https://sofluffy.io).

## Happy Coding 🦊
