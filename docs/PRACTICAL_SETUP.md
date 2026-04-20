# Practical Setup

## What This Repo Helps With

This repo is most useful when you want to run a Claude-style terminal workflow through a local LiteLLM gateway instead of Anthropic's hosted backend.

That lets you:

- keep the CLI workflow local
- switch between OpenAI, Gemini, DeepSeek, and OpenRouter
- inspect the source snapshot and helper scripts directly

This setup is unofficial. The upstream code and brand remain Anthropic's.

## Minimum Setup

1. Install Bun.
2. Install Python 3 with `pip`.
3. Install LiteLLM:

   ```bash
   python3 -m pip install "litellm[proxy]"
   ```

4. Install repo dependencies:

   ```bash
   bun install
   ```

5. Bootstrap the local env file:

   ```bash
   ./bootstrap-gateway.sh
   ```

That will create `examples/provider-gateway/gateway.env` from the safe example file if it does not already exist.

## Choose a Provider

Open `examples/provider-gateway/gateway.env` and set the key for the provider you want to use.

Examples:

- OpenAI: `OPENAI_API_KEY=...`
- Gemini: `GOOGLE_API_KEY=...` or `GEMINI_API_KEY=...`
- DeepSeek: `DEEPSEEK_API_KEY=...`
- OpenRouter: `OPENROUTER_API_KEY=...`

Then point the local route at that provider:

```bash
./use-provider openai
./use-provider gemini
./use-provider deepseek
./use-provider openrouter
./use-provider auto
```

`auto` picks the first configured provider key in the helper script's preference order.

## Run Doctor Checks

Before starting the gateway, run the local checks:

```bash
./doctor-gateway
./scripts/smoke-test-gateway.sh
```

What these checks cover:

- required files are present
- `gateway.env` exists
- the selected route matches `examples/provider-gateway/litellm.yaml`
- the matching provider key is set
- branding values are valid
- helper scripts are executable

## Start LiteLLM

In one terminal:

```bash
cd examples/provider-gateway
./start-litellm.sh
```

This reads `gateway.env`, validates the selected provider key, and starts LiteLLM on port `4000`.

## Launch the CLI

In another terminal from the repo root:

```bash
./run-claude.sh
```

The root wrapper forwards to `examples/provider-gateway/run-claude.sh`, which will build the CLI if `dist/cli.js` is missing.

## Common Setup Mistakes

### `gateway.env` does not exist

Run:

```bash
./bootstrap-gateway.sh
```

### Selected provider route does not match the key you filled in

Example: `ANTHROPIC_MODEL=openrouter-via-gateway` but only `OPENAI_API_KEY` is set.

Fix it by either:

- switching routes with `./use-provider ...`
- or filling in the matching provider key

### `litellm` command is missing

Install LiteLLM in the same Python environment you plan to use:

```bash
python3 -m pip install "litellm[proxy]"
```

### `bun` is missing

Install Bun, reopen the terminal, and rerun:

```bash
./bootstrap-gateway.sh
```

### You accidentally edited `gateway.env.example`

Keep secrets in `examples/provider-gateway/gateway.env`, not in the example file. The example file is safe to commit; `gateway.env` is not.
