import type { Command } from '../../commands.js'

/**
 * Real agents-platform lives in Anthropic-internal trees. A physical module is
 * required here so the Bun bundler resolves the require() in commands.ts
 * without hitting the missing-source stub path (Bun 1.3.11 can segfault there).
 */
const agentsPlatform: Command | null = null

export default agentsPlatform
