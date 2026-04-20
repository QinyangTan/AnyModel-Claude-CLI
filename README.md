# Claude Code Gateway Workflow on a Public Research Snapshot

Run Claude-style CLI workflows through a local LiteLLM gateway with OpenAI, Gemini, DeepSeek, or OpenRouter.

> This repo is unofficial, local-first, and layered onto a public Claude Code source snapshot. Upstream ownership remains with Anthropic.

## What This Repo Is Useful For

- Trying a Claude-style terminal workflow against a local Anthropic-compatible gateway
- Switching providers without rewriting the CLI itself
- Rebuilding and inspecting the Bun + Ink CLI from source
- Studying the exposed snapshot and its architecture for defensive research

## Quick Start

1. Install the local dependencies:

   ```bash
   bun install
   python3 -m pip install "litellm[proxy]"
   ```

2. Create a safe local env file and check your machine:

   ```bash
   ./bootstrap-gateway.sh
   ```

3. Open `examples/provider-gateway/gateway.env` and fill in one provider key:

   - `OPENAI_API_KEY`
   - `GOOGLE_API_KEY` or `GEMINI_API_KEY`
   - `DEEPSEEK_API_KEY`
   - `OPENROUTER_API_KEY`

4. Pick a route:

   ```bash
   ./use-provider auto
   # or
   ./use-provider openai openai-neon "My Local CLI"
   # or
   ./use-provider openrouter
   ```

5. Validate the setup:

   ```bash
   ./doctor-gateway
   ./scripts/smoke-test-gateway.sh
   ```

6. Start LiteLLM in one terminal:

   ```bash
   cd examples/provider-gateway
   ./start-litellm.sh
   ```

7. Start the CLI from the repo root in another terminal:

   ```bash
   ./run-claude.sh
   ```

`examples/provider-gateway/gateway.env` is local-only and gitignored. Do not commit real API keys.

## What Works / What Does Not

| Area | Current status | Notes |
|---|---|---|
| Bun build from source | Supported in this fork | `bun install && bun run build` |
| Local LiteLLM gateway routing | Supported in this fork | Routes included for OpenAI, Gemini, DeepSeek, and OpenRouter |
| Provider switching helpers | Supported in this fork | `./use-provider` and `./use-openai` update the local gateway env |
| Local diagnostics | Supported in this fork | `./doctor-gateway` and `./scripts/smoke-test-gateway.sh` |
| Official Anthropic support | Not included | This repo is unofficial and not maintained by Anthropic |
| Exact Anthropic parity on non-Anthropic backends | Not guaranteed | Some models or side features may behave differently through LiteLLM |
| Hosted gateway or managed secrets | Not included | The workflow is designed for local development |
| Clean-room reimplementation or upstream relicensing | Not included | This remains a public research/archive snapshot with fork-added tooling |

## Gateway Mode

In gateway mode, the CLI still speaks Anthropic-shaped HTTP, but it does so against a local LiteLLM server instead of Anthropic's hosted API.

Flow:

1. The CLI reads `examples/provider-gateway/gateway.env`.
2. `ANTHROPIC_BASE_URL` points the CLI at local LiteLLM, usually `http://127.0.0.1:4000`.
3. `ANTHROPIC_MODEL` selects one of the route names defined in `examples/provider-gateway/litellm.yaml`.
4. LiteLLM forwards the request to the provider whose API key you configured.

Default route names in this repo:

- `openai-via-gateway`
- `gemini-via-gateway`
- `deepseek-via-gateway`
- `openrouter-via-gateway`

The bundled `litellm.yaml` uses `drop_params: true` for better cross-provider compatibility.

### Exact Commands

Build the CLI:

```bash
bun install
bun run typecheck
bun run build
```

Bootstrap the local env:

```bash
./bootstrap-gateway.sh
```

Pick a provider:

```bash
./use-provider openrouter
./use-provider openai openai-neon
./use-provider gemini cyber-fox "Gemini Gateway CLI"
./use-provider auto
./use-openai
```

Validate before launch:

```bash
./doctor-gateway
./scripts/smoke-test-gateway.sh
```

Start LiteLLM:

```bash
cd examples/provider-gateway
./start-litellm.sh
```

Run the CLI:

```bash
cd /path/to/claude-code-main
./run-claude.sh
```

## Helper Scripts

| Script | What it does | Typical use |
|---|---|---|
| `./bootstrap-gateway.sh` | Confirms repo context, checks Bun/Python/LiteLLM, and creates a safe local `gateway.env` if missing | First run on a new machine |
| `./use-provider` | Switches `ANTHROPIC_MODEL`, `ANTHROPIC_SMALL_FAST_MODEL`, and optional branding | Swap between OpenAI, Gemini, DeepSeek, and OpenRouter |
| `./use-openai` | Shortcut wrapper for `./use-provider openai` | Faster OpenAI selection |
| `./doctor-gateway` | Verifies local env, route names, provider keys, and branding values | Quick readiness check before launch |
| `./run-claude.sh` | Root-level wrapper that launches the example gateway workflow | Normal local CLI entrypoint |
| `examples/provider-gateway/start-litellm.sh` | Starts the local LiteLLM proxy using the bundled config | Terminal 1 |
| `examples/provider-gateway/run-claude.sh` | Builds the CLI if needed, then runs it with the local gateway env | Terminal 2 |
| `./scripts/smoke-test-gateway.sh` | Runs safe local validation without making real provider calls | CI and local sanity checks |

## Safety / Secrets

- `examples/provider-gateway/gateway.env` is for local use only and is already gitignored.
- `examples/provider-gateway/gateway.env.example` is the safe template meant for the repository.
- In gateway mode, `ANTHROPIC_API_KEY` is the local LiteLLM master key expected by `litellm.yaml`, not an Anthropic cloud credential.
- Provider keys should stay only in your local `gateway.env` or your shell environment.
- Before pushing changes, double-check that no `.env` file or real API key is staged.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `Missing .../gateway.env` | Local env file has not been created yet | Run `./bootstrap-gateway.sh` |
| `Selected ... but ... API KEY is empty` | The chosen provider route does not have a matching key set | Edit `examples/provider-gateway/gateway.env` and add the matching key |
| `model route not found in litellm.yaml` | `ANTHROPIC_MODEL` does not match a configured route name | Run `./use-provider ...` again or update `litellm.yaml` deliberately |
| `LiteLLM is not on PATH` | LiteLLM is not installed in your current Python environment | Run `python3 -m pip install "litellm[proxy]"` |
| `bun not found` | Bun is not installed or your shell has not reloaded PATH | Install Bun, reopen the terminal, and rerun `./bootstrap-gateway.sh` |
| `dist/cli.js` missing | The CLI has not been built yet | Run `bun run build` or just launch `./run-claude.sh` and let it build |
| Smoke test fails in CI for provider keys | The example env intentionally leaves provider keys empty | Run the smoke test with `--ci` or use a local env file with a real provider key |

## Practical Setup Doc

For a shorter, task-oriented walkthrough, see [docs/PRACTICAL_SETUP.md](docs/PRACTICAL_SETUP.md).

## Unofficial Status and Ownership

This repository contains a mirrored Claude Code source snapshot plus fork-added gateway tooling.

- The original Claude Code source and related intellectual property are owned by Anthropic.
- This repository is not affiliated with, endorsed by, or maintained by Anthropic.
- Except where explicitly stated, no rights are granted to use, reproduce, sublicense, or redistribute upstream Anthropic source code.
- This repository should not be presented as official Anthropic software.

### Fork-Added Files and Licensing Scope

Only files authored in this fork are licensed under `LICENSE.fork-additions` (MIT), and only for portions authored by the fork maintainer.

Fork-added or fork-authored files include:

- `doctor-gateway`
- `use-provider`
- `use-openai`
- `run-claude.sh` (root wrapper)
- `bootstrap-gateway.sh`
- `scripts/smoke-test-gateway.sh`
- `examples/provider-gateway/start-litellm.sh`
- `examples/provider-gateway/run-claude.sh`
- `examples/provider-gateway/SETUP.txt`
- `examples/provider-gateway/litellm.yaml`
- `examples/provider-gateway/gateway.env.example`
- `BUILD_GUIDE.md`
- `docs/PRACTICAL_SETUP.md`
- README sections explicitly describing fork-added tooling and workflows

All other files remain subject to their original copyright and license status (if any), and are excluded from the fork-added MIT grant.

## Research / Archive Context

This repository still exists as a defensive research and source-exposure archive.

- It mirrors a publicly exposed Claude Code source snapshot that became accessible on March 31, 2026 through an npm source-map exposure.
- It is maintained for education, defensive security research, and software supply-chain analysis.
- It is not a clean-room rewrite and not a claim of upstream ownership.

Related research writing:

- [Original publication — Hong Minhee, *Is legal the same as legitimate: AI reimplementation and the erosion of copyleft*](https://writings.hongminhee.org/2026/03/legal-vs-legitimate/)

The essay is dated March 9, 2026 and serves as companion analysis that predates the March 31, 2026 source exposure documented in this repo.

### Why This Archive Exists

The snapshot is useful for:

- educational study
- software supply-chain exposure analysis
- secure software engineering discussion
- architecture review of modern agentic CLI systems

### How the Public Snapshot Became Accessible

[Chaofan Shou (@Fried_rice)](https://x.com/Fried_rice) publicly noted that Claude Code source material was reachable through an exposed `.map` file in the npm package, which in turn referenced unobfuscated TypeScript sources hosted in Anthropic's R2 bucket.

## Repository Scope

Claude Code is Anthropic's CLI for interacting with Claude from the terminal to perform engineering tasks such as editing files, running commands, searching codebases, and coordinating workflows.

This repository contains a mirrored `src/` snapshot for research and analysis, plus fork-added local gateway tooling.

- Language: TypeScript
- Runtime: Bun
- Terminal UI: React + [Ink](https://github.com/vadimdemedes/ink)
- Extra local workflow: LiteLLM provider gateway under `examples/provider-gateway/`

## Built with `oh-my-codex`

The README and archive-context work on this branch were AI-assisted and orchestrated with Yeachan Heo's [oh-my-codex (OmX)](https://github.com/Yeachan-Heo/oh-my-codex), a Codex workflow layer.

- `$team` mode was used for coordinated review of repo fit, wording risk, and architecture consistency.
- `$ralph` mode was used for persistent execution, verification, and final sign-off before completion.
- This repository does not claim ownership of the original code and should not be interpreted as an official Anthropic repository.

## Architecture Notes

### High-Level Layout

```text
src/
├── main.tsx                 # CLI startup and initialization
├── commands.ts              # Command registry
├── tools.ts                 # Tool registry
├── QueryEngine.ts           # LLM query engine
├── commands/                # Slash command implementations
├── tools/                   # Tool implementations
├── components/              # Ink UI components
├── services/                # Service integrations
├── bridge/                  # IDE bridge system
├── coordinator/             # Multi-agent orchestration
├── plugins/                 # Plugin loader
└── skills/                  # Skill system
```

### Key Subsystems

| Subsystem | What it does |
|---|---|
| `src/tools/` | Tool definitions, schemas, permissions, and execution logic |
| `src/commands/` | Slash command implementations such as review, config, tasks, and doctor flows |
| `src/services/` | API, MCP, OAuth, LSP, and integration services |
| `src/bridge/` | IDE bridge code for editors such as VS Code and JetBrains |
| `src/coordinator/` | Multi-agent coordination and team workflows |
| `src/plugins/` | Built-in and third-party plugin support |
| `src/skills/` | Reusable workflow definitions executed through the skill system |

### Notable Design Patterns

- Parallel startup prefetch for settings, keychain reads, and network setup
- Lazy loading for heavier integrations and feature-gated systems
- Tool-driven orchestration rather than a single monolithic agent loop
- Bridge-based editor integration for IDE-connected workflows
