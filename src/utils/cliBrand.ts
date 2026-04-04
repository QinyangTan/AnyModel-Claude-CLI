export type CliBrand =
  | 'starpaw'
  | 'cyber-fox'
  | 'baby-otter'
  | 'pixel-bunny'
  | 'openai-neon'
export type CliMascot = 'cat' | 'fox' | 'otter' | 'bunny' | 'robot'

type BrandConfig = {
  displayName: string
  mascot: CliMascot
}

const BRAND_CONFIGS: Record<CliBrand, BrandConfig> = {
  starpaw: {
    displayName: 'AnyModel Claude CLI',
    mascot: 'cat',
  },
  'cyber-fox': {
    displayName: 'Cyber Fox CLI',
    mascot: 'fox',
  },
  'baby-otter': {
    displayName: 'Baby Otter CLI',
    mascot: 'otter',
  },
  'pixel-bunny': {
    displayName: 'Pixel Bunny CLI',
    mascot: 'bunny',
  },
  'openai-neon': {
    displayName: 'OpenAI Neon CLI',
    mascot: 'robot',
  },
}

const BRAND_ALIASES: Record<string, CliBrand> = {
  starpaw: 'starpaw',
  default: 'starpaw',
  fox: 'cyber-fox',
  'cyber-fox': 'cyber-fox',
  otter: 'baby-otter',
  'baby-otter': 'baby-otter',
  bunny: 'pixel-bunny',
  rabbit: 'pixel-bunny',
  'pixel-bunny': 'pixel-bunny',
  openai: 'openai-neon',
  neon: 'openai-neon',
  robot: 'openai-neon',
  'openai-neon': 'openai-neon',
}

const MASCOT_ALIASES: Record<string, CliMascot> = {
  cat: 'cat',
  fox: 'fox',
  otter: 'otter',
  bunny: 'bunny',
  rabbit: 'bunny',
  robot: 'robot',
  openai: 'robot',
}

function normalizeBrandValue(value: string): string {
  return value.trim().toLowerCase().replace(/[_ ]+/g, '-')
}

export function getCliBrand(): CliBrand {
  const raw = process.env.CLI_BRAND
  if (!raw) return 'starpaw'
  const normalized = normalizeBrandValue(raw)
  const alias = BRAND_ALIASES[normalized]
  if (alias) {
    return alias
  }
  return 'starpaw'
}

export function getCliBrandName(): string {
  const customName = process.env.CLI_BRAND_NAME?.trim()
  if (customName) return customName
  return BRAND_CONFIGS[getCliBrand()].displayName
}

export function getCliWelcomeTitle(): string {
  return `Welcome to ${getCliBrandName()}`
}

export function getCliMascot(): CliMascot {
  const customMascot = process.env.CLI_MASCOT?.trim().toLowerCase()
  if (customMascot && MASCOT_ALIASES[customMascot]) {
    return MASCOT_ALIASES[customMascot]
  }
  return BRAND_CONFIGS[getCliBrand()].mascot
}
