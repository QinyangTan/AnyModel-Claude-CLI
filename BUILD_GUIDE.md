# Claude Code Source Build Guide

> This guide documents how the missing build configuration was restored for the Claude Code source snapshot, and how the project was compiled and run successfully.

## Overview

The source snapshot includes only `src/` and `README.md`; all build configuration files were missing. This guide covers the full recovery process from scratch.

---

## Restored Configuration Files

### 1. `package.json`

Core project metadata and scripts:

- **Package name**: `@anthropic-ai/claude-code`
- **Entry point**: `src/entrypoints/cli.tsx`
- **Build output**: `dist/cli.js`
- **Script commands**:
  - `bun run build` - run the build script
  - `bun run dev` - run source directly (development mode)
  - `bun run typecheck` - TypeScript type checking

**Dependencies fall into three categories:**

| Category | Count | Examples |
|------|------|------|
| Public npm packages | ~75 | `react`, `chalk`, `zod`, `@anthropic-ai/sdk` |
| Anthropic internal packages (stubbed) | ~10 | `@ant/*`, `@anthropic-ai/sandbox-runtime` |
| Dev dependencies | ~13 | `typescript`, `@types/react`, `@types/bun` |

### 2. `tsconfig.json`

Key TypeScript compiler settings:

- **Module system**: ESNext + bundler resolution
- **JSX**: `react-jsx` (React 19 JSX transform)
- **Path alias**: `src/*` -> `./src/*` (the codebase heavily uses `import from 'src/...'`)
- **Target**: ESNext (natively supported by Bun)
- **Types**: includes both `bun-types` and `node` definitions

### 3. `globals.d.ts`

Global type declarations:

- **`MACRO` constants**: build-time injected macros
  - `MACRO.VERSION` - version
  - `MACRO.BUILD_TIME` - build timestamp
  - `MACRO.PACKAGE_URL` - npm package URL
  - `MACRO.NATIVE_PACKAGE_URL` - native package URL
  - `MACRO.FEEDBACK_CHANNEL` - feedback channel
  - `MACRO.ISSUES_EXPLAINER` - issue reporting guide
  - `MACRO.VERSION_CHANGELOG` - version changelog

- **`bun:bundle` module**: type declarations for Bun feature flags
- **Internal package type stubs**: type definitions for non-public Anthropic internal packages

### 4. `scripts/build.ts`

The main build script uses Bun's `Bun.build()` API and handles several key issues:

#### a) `bun:bundle` Feature Flag Handling

The original code uses `import { feature } from 'bun:bundle'` for compile-time dead-code elimination. The build script provides a custom Bun plugin polyfill for `feature()`, with all flags defaulting to `false` in external builds:

```
PROACTIVE, KAIROS, BRIDGE_MODE, DAEMON, VOICE_MODE,
AGENT_TRIGGERS, MONITOR_TOOL, COORDINATOR_MODE,
ABLATION_BASELINE, DUMP_SYSTEM_PROMPT, CHICAGO_MCP
```

#### b) `MACRO.*` Build-Time Constant Injection

All `MACRO.*` references are replaced at compile time through the `define` option in `Bun.build()`.

#### c) Internal Package Stub Plugin

Inline stubs are provided for non-public Anthropic packages (`@ant/*`, `@anthropic-ai/sandbox-runtime`, etc.) so named exports resolve at build time without adding runtime dependencies.

#### d) Missing Source Auto-Stub Plugin

Some files are missing from the snapshot (feature-flagged or internal-only). The build script uses `missingSourceStubPlugin` to **auto-detect and stub missing files at build time**, without creating manual source-tree stubs:

- Intercepts source imports via `onResolve` and checks whether target files exist
- Redirects missing files to a virtual `missing-source` namespace
- Provides targeted stubs for modules that require specific named exports (for example, `connectorText`, `protectedNamespace`)
- Returns generic `export default {}` for all other missing modules
- Returns empty strings for `.md`/`.txt` files, and `export {}` for `.d.ts`
- Marks auto-stubbed modules in build logs as `⚠️ Auto-stubbing missing module:`

#### e) External Dependency Handling

All public npm packages are marked `external`, so they are not bundled and are resolved from `node_modules` at runtime.

### 5. Source Fixes

In `src/main.tsx`, the short flag `-d2e` is incompatible with Commander.js v13 (short flags must be one character). It was changed to the long flag `--debug-to-stderr` only.

---

## Build Steps

### Prerequisites

- [Bun](https://bun.sh) >= 1.1 (1.3+ recommended)
- Windows / macOS / Linux

### Step 1: Install Dependencies

```bash
bun install
```

This installs ~600+ packages (including transitive dependencies) and usually takes 1-2 minutes.

**Run this before building.** If you skip `bun install`, `bun run build` may crash with **SIGTRAP / segmentation fault** on some Bun versions instead of showing a clear missing-dependency error.

### Step 2: Build

```bash
bun run build
```

The build script will:
1. Initialize the `bun:bundle` feature flag polyfill
2. Inject `MACRO.*` build-time constants
3. Generate inline stubs for internal Anthropic packages
4. Automatically detect and stub missing source files in the snapshot
5. Bundle the `src/entrypoints/cli.tsx` entry point
6. Output `dist/cli.js` (about 11.7 MB) and `dist/cli.js.map`

### Step 3: Verify

```bash
# Check version
bun dist/cli.js --version
# Output: 1.0.0-research (Claude Code)

# Show help
bun dist/cli.js --help

# Start interactive UI (requires an API key)
bun dist/cli.js
```

### Custom Version String

```bash
CLAUDE_CODE_VERSION=2.0.0 bun run build
```

---

## Build Outputs

| File | Size | Description |
|------|------|------|
| `dist/cli.js` | ~11.7 MB | Main program bundle (ESM) |
| `dist/cli.js.map` | ~38.6 MB | Source map |

---

## Technical Notes

### Architecture Overview

```
Entry point: src/entrypoints/cli.tsx
    ↓ (dynamic import)
Main app: src/main.tsx (Commander.js CLI)
    ↓
Terminal UI: src/ink/ (custom Ink implementation + React 19)
    ↓
Core systems:
├── src/tools/       (~40 tool implementations)
├── src/commands/    (~50 slash commands)
├── src/services/    (API, MCP, OAuth, analytics)
├── src/hooks/       (permission system)
└── src/coordinator/ (multi-agent orchestration)
```

### Core Tech Stack

| Component | Technology |
|------|------|
| Runtime | Bun |
| Language | TypeScript (strict) |
| Terminal UI | React 19 + custom Ink fork |
| CLI framework | Commander.js 13 |
| Schema validation | Zod v3 |
| Protocols | MCP SDK, LSP |
| API | Anthropic SDK |
| Telemetry | OpenTelemetry 2.x |
| Layout engine | pure TypeScript yoga-layout implementation |

### Caveats

1. **Internal packages are unavailable**: `@ant/*` and some `@anthropic-ai/*` packages are not published to public npm. Related features (Chrome integration, computer use, sandbox runtime, etc.) are unavailable in this build.

2. **All feature flags are disabled**: all `bun:bundle` flags default to `false`, removing code paths for experimental features (voice, daemon mode, coordinator mode, etc.).

3. **An API key is required for real usage**: the CLI can compile and start (terminal UI and themes work), but model usage still requires an Anthropic API key or OAuth login.

4. **React reconciler version requirement**: the project uses `useEffectEvent`, which requires `react-reconciler@0.33.0` (not 0.31.0), as that version includes the required scheduler support.

5. **Internal stubs need complete method signatures**: some internal packages (for example, `SandboxManager` in `@anthropic-ai/sandbox-runtime`) need full static methods in stubs (`isSupportedPlatform`, `checkDependencies`, `wrapWithSandbox`, etc.), or runtime errors occur when undefined properties are accessed. The build script already includes complete signatures for known internal classes.

6. **Unofficial build**: this build is for educational and security research only and is not an official Anthropic release.
