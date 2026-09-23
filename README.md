# Windower

Windower is a monorepo with a Svelte 5 + TypeScript + Vite + Tailwind CSS + Ky + Oxc frontend (`client/`) and an
optional language-agnostic backend (`server/`).

Shared agent instructions live in `AGENTS.md`; `CLAUDE.md` references that file.

## Environment Setup

This project uses [mise](https://mise.jdx.dev/) for Node version management and
[portless](https://github.com/vercel-labs/portless) for stable `https://*.localhost`
dev URLs (so multiple projects don't fight over ports).

```sh
# Install mise (if not already installed)
curl https://mise.run | sh

# Install Node and pnpm
mise trust
mise install
pnpm i

# Install portless globally (binds :443, prompts once to trust a local CA)
pnpm add -g portless

# Add the following to ~/.zshrc:
source ~/dev/windower/bin/env
```

> **Note on `pnpm add -g`.** pnpm is managed by mise here, so **don't run
> `pnpm setup`** — it installs a standalone pnpm that shadows the mise version
> and will drift out of sync. If `pnpm add -g portless` errors with
> `ERR_PNPM_NO_GLOBAL_BIN_DIR`, add these lines to `~/.zshrc` (after the
> `mise activate` line) and reload your shell instead:
>
> ```sh
> export PNPM_HOME="$HOME/.local/share/pnpm"
> export PATH="$PNPM_HOME:$PATH"
> ```

## Recommended IDE Setup

[VSCode](https://code.visualstudio.com/) + [Svelte for VS Code](https://marketplace.visualstudio.com/items?itemName=svelte.svelte-vscode)

## Development

Run these from the `client/` directory, or from the repo root with `--filter client` (e.g. `pnpm --filter client dev`).

```sh
pnpm dev          # Start dev server (https://windower.localhost)
pnpm lint         # Lint and format
pnpm test         # Run unit tests
pnpm test:e2e     # Run end-to-end tests
pnpm build        # Build for production
pnpm preview      # Preview production build (https://windower-preview.localhost)
```

End-to-end tests start their own preview server on port 4173. If that port is
occupied, run `PLAYWRIGHT_PORT=4174 pnpm --filter client test:e2e` from the root
with an available port.
