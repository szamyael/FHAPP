import { useEffect, useState } from 'react'
import { supabase } from './utils/supabase'
import { supabaseConfig } from './utils/supabase'

type Account = {
  id: string
  display_name: string
}

export default function App() {
  const [accounts, setAccounts] = useState<Account[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    async function getAccounts() {
      setLoading(true)
      setError(null)
      try {
        const { data, error } = await supabase
          .from('accounts')
          .select('id,display_name')

        if (error) {
          console.error('Supabase select(accounts) failed:', error)
          setError(error.message)
          setAccounts([])
          return
        }

        setAccounts((data ?? []) as Account[])
      } catch (e) {
        const message = e instanceof Error ? e.message : String(e)
        setError(message)
        setAccounts([])
      } finally {
        setLoading(false)
      }
    }

    getAccounts()
  }, [])

  return (
    <main>
      <h1>Overview</h1>

      {loading ? (
        <p>Loading…</p>
      ) : error ? (
        <div>
          <p>Failed to load data.</p>
          <pre>{error}</pre>
          <p>
            Check that the <code>accounts</code> table exists and that Row Level
            Security policies allow <code>select</code>.
          </p>
          <p>
            Supabase URL: <code>{supabaseConfig.url}</code>
            <br />
            Key prefix: <code>{supabaseConfig.keyPrefix}</code>
          </p>
          <p>
            If you see <code>TypeError: Failed to fetch</code>, check Chrome DevTools
            Console/Network for a CORS error or a blocked request. For <code>supabase-js</code>,
            prefer setting <code>VITE_SUPABASE_ANON_KEY</code> in <code>webapp/.env</code>.
          </p>
        </div>
      ) : accounts.length === 0 ? (
        <p>No data yet.</p>
      ) : (
        <ul>
          {accounts.map((a) => (
            <li key={a.id}>{a.display_name}</li>
          ))}
        </ul>
      )}
    </main>
  )
}
