/**
 * ktv-sync — synchronisation inter-appareils de KTV.
 *
 * Identité = compte Trakt (le client envoie son access_token Trakt ; on le
 * vérifie via /users/settings et on en dérive le slug, clé du compte).
 * Le corps synchronisé est CHIFFRÉ CÔTÉ CLIENT (AES-GCM) : le serveur ne stocke
 * qu'un blob opaque, il ne peut pas lire les identifiants IPTV ni les données.
 *
 * Stockage :
 *   - KV  SYNC : `sync:{slug}` = { version, updatedAt, blob }  (blob = chiffré)
 *   - D1  DB   : table `accounts` (slug, created_at, updated_at, version) pour
 *                le registre/visibilité.
 *
 * Endpoints :
 *   GET  /sync           → { version, updatedAt, blob } | 204 si vide
 *   PUT  /sync           → body { blob } ; en-tête If-Match: <version>
 *                          200 { version } | 409 { version, updatedAt, blob }
 *   GET  /health         → ok
 */

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET,PUT,POST,OPTIONS',
  'Access-Control-Allow-Headers': 'Authorization,Content-Type,If-Match',
};

const json = (obj, status = 200, extra = {}) =>
  new Response(JSON.stringify(obj), { status, headers: { 'Content-Type': 'application/json', ...CORS, ...extra } });

/** Vérifie l'access_token Trakt → slug (mis en cache KV ~1 h pour épargner Trakt). */
async function slugFromTrakt(env, token) {
  if (!token) return null;
  const cacheKey = `tok:${token}`;
  const cached = await env.SYNC.get(cacheKey);
  if (cached) return cached;
  const r = await fetch('https://api.trakt.tv/users/settings', {
    headers: {
      'Content-Type': 'application/json',
      'trakt-api-version': '2',
      'trakt-api-key': env.TRAKT_CLIENT_ID,
      Authorization: `Bearer ${token}`,
      // Trakt renvoie 403 aux requêtes sans User-Agent (fetch Workers n'en met pas).
      'User-Agent': 'KTV-Sync/1.0 (+https://github.com/khalilbenaz/ktv-flutter)',
    },
  });
  if (!r.ok) return null;
  const data = await r.json();
  const slug = data?.user?.ids?.slug;
  if (!slug) return null;
  await env.SYNC.put(cacheKey, slug, { expirationTtl: 3600 });
  return slug;
}

function bearer(req) {
  const h = req.headers.get('Authorization') || '';
  const m = h.match(/^Bearer\s+(.+)$/i);
  return m ? m[1].trim() : null;
}

export default {
  async fetch(req, env) {
    const url = new URL(req.url);
    if (req.method === 'OPTIONS') return new Response(null, { status: 204, headers: CORS });
    if (url.pathname === '/health') return json({ ok: true });

    // --- Logs de débogage (non authentifié, temporaire) : l'app POSTe ses
    //     traces/crashs ; GET renvoie les derniers (pour lecture par l'auteur). ---
    if (url.pathname === '/log') {
      if (req.method === 'POST') {
        let b;
        try { b = await req.json(); } catch { return json({ error: 'bad' }, 400); }
        const entry = {
          t: Date.now(),
          id: String(b?.id || '?').slice(0, 40),
          model: String(b?.model || '').slice(0, 100),
          v: String(b?.version || '').slice(0, 20),
          pf: String(b?.platform || '').slice(0, 40),
          lines: Array.isArray(b?.lines) ? b.lines.slice(-60).map((x) => String(x).slice(0, 600)) : [],
        };
        const raw = await env.SYNC.get('logs:recent');
        const arr = raw ? JSON.parse(raw) : [];
        arr.push(entry);
        while (arr.length > 400) arr.shift();
        await env.SYNC.put('logs:recent', JSON.stringify(arr), { expirationTtl: 172800 });
        return json({ ok: true });
      }
      if (req.method === 'GET') {
        const raw = await env.SYNC.get('logs:recent');
        return new Response(raw || '[]', { headers: { 'Content-Type': 'application/json', ...CORS } });
      }
    }

    if (url.pathname !== '/sync') return json({ error: 'not_found' }, 404);

    const slug = await slugFromTrakt(env, bearer(req));
    if (!slug) return json({ error: 'unauthorized' }, 401);
    const key = `sync:${slug}`;

    if (req.method === 'GET') {
      const raw = await env.SYNC.get(key);
      if (!raw) return new Response(null, { status: 204, headers: CORS });
      return json(JSON.parse(raw));
    }

    if (req.method === 'PUT') {
      let body;
      try {
        body = await req.json();
      } catch {
        return json({ error: 'bad_json' }, 400);
      }
      if (typeof body?.blob !== 'string' || body.blob.length > 4_000_000) {
        return json({ error: 'bad_blob' }, 400);
      }
      const current = await env.SYNC.get(key);
      const cur = current ? JSON.parse(current) : { version: 0 };
      const ifMatch = req.headers.get('If-Match');
      // Concurrence optimiste : refuse si la version connue du client ≠ actuelle.
      if (ifMatch != null && String(cur.version) !== String(ifMatch)) {
        return json({ error: 'conflict', version: cur.version, updatedAt: cur.updatedAt, blob: cur.blob }, 409);
      }
      const next = { version: (cur.version || 0) + 1, updatedAt: Date.now(), blob: body.blob };
      await env.SYNC.put(key, JSON.stringify(next));
      // Registre D1 (best-effort, ne bloque pas la synchro).
      try {
        await env.DB.prepare(
          `INSERT INTO accounts (slug, created_at, updated_at, version) VALUES (?1, ?2, ?2, ?3)
           ON CONFLICT(slug) DO UPDATE SET updated_at = ?2, version = ?3`
        ).bind(slug, next.updatedAt, next.version).run();
      } catch (_) {}
      return json({ version: next.version, updatedAt: next.updatedAt });
    }

    return json({ error: 'method_not_allowed' }, 405);
  },
};
