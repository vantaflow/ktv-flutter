# ktv-sync

Worker Cloudflare de **synchronisation inter-appareils** de KTV.

- **Identité** : compte **Trakt** (le client envoie son access_token ; le Worker le vérifie via `/users/settings` et en dérive le `slug`).
- **Confidentialité** : le corps synchronisé est **chiffré côté client** (AES-GCM). Le Worker ne stocke qu'un blob opaque — il ne peut pas lire les identifiants IPTV.
- **Stockage** : KV (`sync:{slug}` = `{version, updatedAt, blob}`) + D1 (registre `accounts`).

## Déploiement

```bash
cd worker/ktv-sync
npx wrangler login                     # une fois

# 1) KV
npx wrangler kv namespace create SYNC  # → copie l'id dans wrangler.toml (kv_namespaces)

# 2) Secret : le client_id de l'app Trakt KTV
npx wrangler secret put TRAKT_CLIENT_ID

# 3) Déploiement
npx wrangler deploy
```

> **D1 optionnelle** : le registre `accounts` (D1) n'est qu'un bonus de
> visibilité. Le Worker tourne en **KV-only** par défaut (le binding `DB` est
> commenté dans `wrangler.toml`, l'écriture D1 est best-effort). Pour l'activer :
> `wrangler d1 create ktv-sync` + `wrangler d1 execute ktv-sync --remote --file=schema.sql`,
> puis décommenter le bloc `[[d1_databases]]`.

**Déjà déployé** : `https://ktv-sync.khalilbenaz.workers.dev` (KV `SYNC`, secret Trakt posé).

L'URL obtenue (`https://ktv-sync.<compte>.workers.dev`) est à renseigner dans
l'app : **Réglages → Synchronisation → Serveur** (valeur par défaut
`https://ktv-sync.khalilbenaz.workers.dev`).

## API

| Méthode | Chemin   | Auth (Bearer Trakt) | Effet |
|---------|----------|---------------------|-------|
| `GET`   | `/sync`  | requis              | `{version, updatedAt, blob}` ou `204` si vide |
| `PUT`   | `/sync`  | requis              | body `{blob}`, en-tête `If-Match: <version>` → `200 {version}` ou `409 {version, blob}` |
| `GET`   | `/health`| non                 | `{ok:true}` |
