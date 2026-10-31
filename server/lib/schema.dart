/// Applied in order, once each. Never edit a migration that has been
/// applied: add a new one.
const migrations = <String>[
  '''
CREATE TABLE winery (
  id integer PRIMARY KEY,
  name text NOT NULL CHECK (btrim(name) <> ''),
  region text
);
CREATE TABLE wine (
  id integer PRIMARY KEY,
  winery_id integer NOT NULL REFERENCES winery (id),
  name text NOT NULL CHECK (btrim(name) <> ''),
  type text NOT NULL CHECK (type IN
    ('red', 'white', 'rose', 'orange', 'sparkling', 'dessert')),
  grape_varieties text NOT NULL DEFAULT '[]'
    CHECK (grape_varieties::jsonb IS NOT NULL)
);
CREATE TABLE vintage (
  id integer PRIMARY KEY,
  wine_id integer NOT NULL REFERENCES wine (id),
  year integer NOT NULL CHECK (year BETWEEN 1900 AND 2100),
  abv double precision CHECK (abv BETWEEN 0 AND 100),
  acidity_g_l double precision CHECK (acidity_g_l >= 0),
  tannins_g_l double precision CHECK (tannins_g_l >= 0),
  residual_sugar_g_l double precision CHECK (residual_sugar_g_l >= 0),
  UNIQUE (wine_id, year)
);
CREATE TABLE barcode (
  id integer PRIMARY KEY,
  code text NOT NULL CHECK (code ~ '^[0-9]+\$'),
  wine_id integer NOT NULL REFERENCES wine (id),
  vintage_id integer REFERENCES vintage (id),
  bottle_size_ml integer CHECK (bottle_size_ml > 0)
);
CREATE INDEX barcode_code_idx ON barcode (code);
CREATE TABLE wine_translation (
  wine_id integer NOT NULL REFERENCES wine (id),
  lang text NOT NULL,
  description text,
  PRIMARY KEY (wine_id, lang)
);
CREATE TABLE vintage_translation (
  vintage_id integer NOT NULL REFERENCES vintage (id),
  lang text NOT NULL,
  sensory_notes text,
  food_pairings text NOT NULL DEFAULT '[]'
    CHECK (food_pairings::jsonb IS NOT NULL),
  PRIMARY KEY (vintage_id, lang)
);
CREATE TABLE wine_photo (
  wine_id integer PRIMARY KEY REFERENCES wine (id),
  jpeg bytea NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);
-- One row. data_version grows with every change; the app compares it.
CREATE TABLE meta (
  id integer PRIMARY KEY CHECK (id = 1),
  data_version bigint NOT NULL,
  schema_version integer NOT NULL
);
INSERT INTO meta VALUES (1, 0, 1);
''',
  '''
-- Who may edit the catalogue. Only Apple's pseudonymous user id is kept:
-- no name, no email.
CREATE TABLE editor (
  id serial PRIMARY KEY,
  apple_sub text NOT NULL UNIQUE,
  role text NOT NULL CHECK (role IN ('owner', 'editor')),
  created_at timestamptz NOT NULL DEFAULT now()
);
-- Tokens are stored as SHA-256 hashes, never as given out.
CREATE TABLE editor_invite (
  code_hash text PRIMARY KEY,
  role text NOT NULL CHECK (role IN ('owner', 'editor')),
  expires_at timestamptz NOT NULL,
  used_at timestamptz
);
CREATE TABLE editor_session (
  token_hash text PRIMARY KEY,
  editor_id integer NOT NULL REFERENCES editor (id) ON DELETE CASCADE,
  expires_at timestamptz NOT NULL
);
CREATE TABLE auth_attempt (
  state_hash text PRIMARY KEY,
  nonce text NOT NULL,
  invite_hash text,
  expires_at timestamptz NOT NULL
);
''',
];

/// The catalogue tables in the order they are filled (parents first).
const catalogTables = [
  'winery',
  'wine',
  'vintage',
  'barcode',
  'wine_translation',
  'vintage_translation',
];
