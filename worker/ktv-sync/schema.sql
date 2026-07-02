-- Registre des comptes de synchronisation (le blob vit dans KV).
CREATE TABLE IF NOT EXISTS accounts (
  slug        TEXT PRIMARY KEY,
  created_at  INTEGER,
  updated_at  INTEGER,
  version     INTEGER DEFAULT 0
);
