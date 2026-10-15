# Backend, Gateway, Database Reference

Run `scripts/bs-profile.ps1` first; it prints the live route counts per service, anonymous routes, missing DynamicController routes and `AllowedSchemas` for the repo you are in.

## Request Path

```
Browser (AxiosMaster, Bearer JWT)
  → api_gateway :8080  /gateway/v1/api/*        (Ocelot, BS-API-Secure/ApiGateway/ocelot.json)
  → <service>:8080     downstream path           (docker network "internal")
  → DB via ISqlConnectionFactory + ISqlDialect
```

Upstream prefix is always `/gateway/v1/api`. Downstream hosts are compose service names: `auth_api`, `bs_core_api`, `bs_import_export_manager`, `bs_notification`, `bs_ai_assistance`, `bs_api_mobile`.

## Ocelot Route Shape

Copy an existing neighbour; this is the Template's `dynamic/create`:

```json
{
  "DownstreamPathTemplate": "/api/dynamic/create",
  "DownstreamScheme": "http",
  "DownstreamHostAndPorts": [{ "Host": "bs_core_api", "Port": 8080 }],
  "UpstreamPathTemplate": "/gateway/v1/api/dynamic/create",
  "UpstreamHttpMethod": ["post"],
  "AuthenticationOptions": { "AuthenticationProviderKey": "Bearer", "AllowedScopes": [] },
  "RateLimitOptions": { "ClientWhitelist": [], "EnableRateLimiting": true, "Period": "1s", "Limit": 50 }
}
```

Omit `AuthenticationOptions` only for intentionally anonymous routes (login, refresh, version, logging, some Mobile lookups). Adding one is a security decision - say so in the change.

## Adding An Endpoint (checklist)

1. Controller action in the service (`[Route]` + `[HttpPost("...")]`), service method behind an interface.
2. SQL through `ISqlConnectionFactory` / `_connectionFactory.Dialect` - quote with `dialect.QuoteTable(schema, name)`, never string-concat identifiers.
3. Ocelot route with the same method, auth, rate limit.
4. Frontend call through `AxiosMaster` / a hook, path relative to `Config.API_URL` (e.g. `/dynamic/create`).
5. `dotnet build` the service **and** the gateway; rebuild both images when running in Docker.

## DynamicController (`BS-API-Core/ApiCore/Controllers/DynamicController.cs`, base `api/dynamic`)

| Method | Path | Used by |
| --- | --- | --- |
| POST | `schema` | schema discovery |
| GET | `metadata/{tableName}` | BSDataGrid column metadata |
| POST | `datagrid` | legacy grid read |
| POST | `bs-datagrid` | BSDataGrid server paging/filter/sort |
| POST | `record/{tableName}` | single record |
| POST | `create` / `update` / `delete` | row CRUD |
| POST | `bulk-create` / `bulk-update` / `bulk-delete` | bulk CRUD |
| POST | `procedure/{procedureName}` | plain SP exec |
| GET | `procedure-metadata/{procedureName}` | SP parameter metadata |
| POST | `combobox` | `bsComboBox` lookups |
| POST | `query` | read-only SELECT (service rejects DROP/DELETE/UPDATE/INSERT/ALTER/CREATE/EXEC) |
| GET | `exists/{tableName}` | table existence |
| POST | `enhanced-procedure` | BSDataGrid stored-procedure mode |

Frontend wrapper: `src/hooks/useDynamicCrud.js` → `loadMetadata`, `getTableData`, `createRecord`, `updateRecord`, `deleteRecord`, `bulkCreate`, `bulkUpdate`, `bulkDelete`, `getComboBoxData`, `executeQuery`, `executeStoredProcedure`, `executeEnhancedStoredProcedure`.

Guards (`appsettings.json` → `DynamicCrud`):
- `AllowedSchemas` - Template: `dbo, sec, tmt, imp, ams, rfi, inv, noti, rpt, ais`.
- `ForbiddenTables` - `sysdiagrams`, `__efmigrationshistory`, `aspnetusers`, `aspnetuserroles`.

## Enhanced Stored Procedures

`DynamicCrudService.ExecuteEnhancedStoredProcedureAsync` reads the SP's parameter list, maps logical names, and falls back to the platform naming convention:

| Logical | Default SP parameter |
| --- | --- |
| Operation | `@in_vchOperation` (`SELECT` / `INSERT` / `UPDATE` / `DELETE`) |
| Page / PageSize | `@in_intPage` / `@in_intPageSize` |
| UserId | `@in_vchUserId` (skipped if caller passes `UserId` in params) |
| SortModel / FilterModel | `@in_vchSortModel` / `@in_vchFilterModel` (JSON) |

Command timeout 120 s. Name SP parameters with the `@in_<type><Name>` convention so mapping needs no config. Guide (partly older wording): root `docs/Enhanced-Stored-Procedures-Guide.md`, `docs/Enhanced-Stored-Procedures-Complete-Guide.md`.

## Auth Flow

| Gateway path | Service | Anonymous |
| --- | --- | --- |
| `login` | `auth_api /auth/login` | yes |
| `refresh` | `auth_api /auth/refresh` | yes |
| `logout` | `auth_api /auth/logout` | no |
| `menu`, `menu/menuAssign`, `menu/saveAssign`, `menu/favorite` | `auth_api /menu/*` | no |
| `resource`, `resource/save`, `users/switch/lang` | `auth_api` | no |
| `alive`, `alive/status` | `auth_api /alive/*` | no |
| `users/register|update|delete|reset|clear_logon`, `reset_password`, `role` | `auth_api /users/*` | no |

Token lifetimes come from env `EXPIRES` / `REFRESH` (minutes; Template example 15 / 30). The frontend refresh lock lives in `AxiosMaster.js` (`refresh_lock` / `refresh_result` keys, cross-tab). 401 loops: read `BS-Web/Frontend-Core/docs/JWT_TROUBLESHOOTING.md` and `QUICK_FIX_401.md` before changing interceptors; the frontend `REACT_APP_API_LICENSE_KEY` must match backend `SecretKey`/`ISSUER_SIGIN_KEY`.

Menus, permissions (`is_view/is_add/is_edit/is_delete`) and resources live in the security DB (`SERVERDB_SECURITY`, schema from env `DB_SCHEMA`, default `sec`; tables `t_com_user`, `t_com_user_group`, `t_com_resource`, `t_com_application`, menu tables), are fetched at login and cached in `SecureStorage`; a DB change needs re-login to show.

## Database Providers

- Each service: `DotNetEnv.Env.Load()` then `DB_PROVIDER` = `SqlServer` | `PostgreSql` | `MySql`, connection strings `SERVERDB` (app) and `SERVERDB_SECURITY` (security DB). Read the service `Program.cs` before touching startup.
- Dialects: `Services/Implementation/Dialects/{SqlServer,PostgreSql,MySql}Dialect.cs` behind `ISqlDialect`; connections via `SqlConnectionFactory` (`ISqlConnectionFactory`).
- Anything provider-specific (paging, quoting, upsert, date functions, identity) goes in the dialect. Don't branch on provider in controllers.
- Docs: root `docs/Database-Provider-Configuration.md`, `docs/Database-Provider-Agnostic-Workflow.md`.
- Root `.env.example` holds env names only. Never commit real connection strings or keys.

## Other Services (gateway prefixes)

| Service | Examples |
| --- | --- |
| `bs_import_export_manager` | `UploadExcelBulk`, `CreateStagingTable`, `DropStagingTable`, `GridConfig`, `DownloadTemplateByMapping`, `*ImportMaster` |
| `bs_notification` | `notify/all`, `notify/user/{userId}`, `notify/read/{notifyId}`, SignalR hub `/notificationHub` |
| `bs_core_api` | `autocomplete` (BSAutoComplete), `logging/log` (browser logger flush) |
| `bs_ai_assistance` | `ai/{everything}`, `dashboard/*` - see `ai-assistant.md` |
| `bs_api_mobile` | `Mobile/*` (Inbound, Outbound, PutAway, Count, StatusChange, InventoryViewer, AppVersion) |
| `bs_report_viewer` | direct `REACT_APP_REPORT_VIEWER_URL` (compose port 8082), not via Ocelot in the Template |
