import { createClient } from '@supabase/supabase-js'

function readEnv(name: string): string | null {
	const value = (import.meta.env as Record<string, unknown>)[name]
	if (typeof value !== 'string') return null
	const trimmed = value.trim()
	return trimmed.length === 0 ? null : trimmed
}

function requireEnv(name: string): string {
	const value = readEnv(name)
	if (value == null) {
		throw new Error(`Missing ${name}. Add it to webapp/.env and restart \`npm run dev\`.`)
	}
	return value
}

const supabaseUrl = requireEnv('VITE_SUPABASE_URL')
// supabase-js typically uses the public anon key. Keep compatibility with the
// existing publishable env var, but prefer anon when available.
const supabaseKey =
	readEnv('VITE_SUPABASE_ANON_KEY') ??
	readEnv('VITE_SUPABASE_PUBLISHABLE_DEFAULT_KEY') ??
	(() => {
		throw new Error(
			'Missing VITE_SUPABASE_ANON_KEY (preferred) or VITE_SUPABASE_PUBLISHABLE_DEFAULT_KEY. Add it to webapp/.env and restart `npm run dev`.',
		)
	})()

export const supabase = createClient(supabaseUrl, supabaseKey)

export const supabaseConfig = {
	url: supabaseUrl,
	keyPrefix: supabaseKey.slice(0, 12),
}
