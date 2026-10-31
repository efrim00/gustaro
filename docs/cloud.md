# Cloud catalogue

The catalogue lives in Postgres on Railway (project `gustaro`). Phones never
talk to the database: they ask a small read-only API, and keep a copy on the
phone so scanning works offline.

```
Editors  → /admin (Sign in with Apple) → API → Postgres
Phones   → GET /v1/catalog, /v1/photos/<id> (read-only) ← API ← Postgres
```

## Pieces

- `server/`: the Dart API (`bin/server.dart`), deployed as the `api` service.
  Migrations run at start (`lib/schema.dart`). An empty database is filled
  once from `server/seed/catalog.json`; it never overwrites data.
- `server/web/admin.html`: the editor page at `/admin`.
- App: `lib/src/sync/catalog_sync.dart` downloads a newer catalogue and
  photos at launch, in the background. The version it already has is the only
  thing it sends. If anything fails, the old catalogue stays.
- The catalogue shipped in the app is used on first launch and replaces the
  phone's copy only when it is newer (a new app version).

## Who can edit

Only Apple users in the `editor` table. The owner creates one-time invitation
links with **Invite editor**. Only Apple's anonymous user id is stored.
If every editor is lost: set `BOOTSTRAP_CODE` on the `api` service, open
`/auth/apple/start?invite=<code>` while the `editor` table is empty, then
delete the variable.

## Railway variables (service `api`)

`DATABASE_URL` (reference to Postgres), `APPLE_TEAM_ID`, `APPLE_KEY_ID`,
`APPLE_CLIENT_ID` (Services ID), `APPLE_PRIVATE_KEY` (.p8 contents, secret),
`PUBLIC_BASE_URL`. Without the Apple values the admin area is closed and the
public catalogue still works.

## Deploy

```bash
railway up --path-as-root server --service api --ci
```

Run `dart test` in `server/` first. Keep the Apple Services ID's domain and
return URL in step with `PUBLIC_BASE_URL`.

## Not done yet

- Backups: turn on Postgres backups in the Railway dashboard.
- A custom domain (Apple's sign-in is tied to the domain).
- The local CSV editor (`tool/catalog_editor.dart`) still exists but the cloud
  is the source of truth; retire it.
