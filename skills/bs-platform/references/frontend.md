# Frontend Reference (`BS-Web/Frontend-Core`)

## Boot Order

`src/index.js` → production console suppression → `muiLicenseManager.initialize()` → `<App/>` (StrictMode only if `REACT_APP_ENABLE_STRICT_MODE=true`).

`src/App.js`:

```
ThemeContextProvider (themes/ThemeContext.js - MUI theme + CssBaseline)
  AuthProvider (contexts/AuthContext.js)
    NotificationsProvider (SignalR)
      BrowserRouter basename={Config.BASE_URL}
        AppRoutes → LoginPage | MainLayout(lang) → PermissionRoute → <Outlet context={{ permission }}/> → page
```

`MainLayout` owns sidebar (`SidebarMenu`, `SidebarSubmenu`), breadcrumbs, language switch, notification popups and passes `lang` to pages.

## Env (`.env.example` → `.env.development` / `.env.production`, loaded by `env-cmd`)

| Var | Use |
| --- | --- |
| `REACT_APP_API_URL` | Gateway base, e.g. `http://localhost:8080/gateway/v1/api` → `Config.API_URL` |
| `REACT_APP_BASE_URL` | Router basename (`/` Template, `/my-inventory` MyInventory) → `Config.BASE_URL` |
| `REACT_APP_REPORT_VIEWER_URL` | Report viewer service |
| `REACT_APP_API_LICENSE_KEY` | Must match backend JWT signing key |
| `REACT_APP_ENCRYPYION`, `REACT_APP_STORAGE_SECRET` | SecureStorage seeds (misspelling is real - don't rename) |
| `REACT_APP_MUI_X_LICENSE_KEY` | MUI X Pro license (packages must be `7.29.9`) |
| `REACT_APP_DEFAULT_SCHEMA` | Default schema when `bsPreObj` missing |
| `REACT_APP_DECIMAL_PLACES` | Number scale → `Config.SCALE` |
| `REACT_APP_DATE_FORMAT`, `REACT_APP_DATETIME_FORMAT`, `REACT_APP_USE_24_HOUR` | Date display (`config/dateConfig.js`, `utils/dateUtils.js`) |
| `REACT_APP_SESSION_TIMEOUT` | ms |
| `REACT_APP_BSDATAGRID_VERBOSE_LOG` | Grid debug logging |

Read values through `src/utils/Config.js`; add new keys there instead of reading `process.env` in components. CRA bakes env at build time - rebuild after changing them.

## Hooks And Utils

| Module | Use |
| --- | --- |
| `utils/AxiosMaster.js` | The axios instance: base URL, Bearer token, cross-tab refresh lock (`refresh_lock`/`refresh_result`), activity logging |
| `hooks/useDynamicCrud.js` | `useDynamicCrud(tableName)` → metadata, table data, CRUD, bulk, combobox, query, SP, enhanced SP |
| `hooks/useApi.js` | `useApi(fn, options)`, `useCrud(service)`, `usePagination(service, params)` |
| `hooks/usePermission.js` | `usePermission(path?)` → `{ canView, canAdd, canEdit, canDelete }`; `getPermission(path)` |
| `hooks/useResource.js` | Resources cached in SecureStorage key `resource` (fields `resource_en/th/other`, `description_en/th/other`) |
| `hooks/useForm.js` | `useForm(initialData, requiredFields)` |
| `hooks/useMenuItems.js` | Menu tree for layout |
| `utils/SecureStorage.js` | Encrypted storage (`menu`, `resource`, `lang`, `theme`, `theme-mode`, tokens) |
| `utils/StorageRecovery.js` | Recovers from corrupted/stale storage - first stop for "works in incognito" bugs |
| `utils/TokenRefreshManager.js`, `utils/JWTDebugger.js` | Token refresh / debugging |
| `utils/logger.js`, `utils/ActivityLogger.js` | Browser log queue → `/logging/log`; `logActivity({...})` |
| `utils/dateUtils.js`, `config/dateConfig.js` | Date formatting |
| `utils/muiLicenseManager.js` | MUI X license init |

### Resources

```js
const { getResources, getResource } = useResource();
const res = await getResources("t_inv_category", lang); // [{ resource_name, resource_value, resource_description }]
getResource(res, "item_category");                      // value, or the key itself when missing
```

Resource group is usually the table name or page key. Missing key → returns the key, so always pass a readable fallback in pages that build labels manually.

### Permission

- Routed page: `const { permission } = useOutletContext()` → menu row with `is_view`, `is_add`, `is_edit`, `is_delete`.
- Anywhere else: `usePermission(path)`.
- `PermissionRoute` redirects to `/404` when `is_view` is false and sends `/` to the first viewable menu. Menu/permission changes need re-login (cached in SecureStorage `menu`).

## Tests

CRA Jest + Testing Library. Existing focused tests: `components/BSFilterCustom.test.js`, `components/BSDataGrid/{dateTypeUtils,formDataUtils,exportUtils}.test.js`, `components/ReportViewer/*.test.mjs`, `utils/{dateUtils,logger}.test.js`.

- MUI `Collapse`/transitions are async: use `findBy*` / `waitFor`.
- Add a focused test next to the helper you change; don't snapshot whole grids.

## Build

- `npm run build` = `craco build` with `DISABLE_ESLINT_PLUGIN=true`, `GENERATE_SOURCEMAP=false`.
- `npm run build:prod` = build + `javascript-obfuscator build/static/js`.
- `homepage` in `package.json` decides asset paths; must agree with `REACT_APP_BASE_URL` and the nginx/IIS mount.
- Verify the served bundle (hard refresh, check file hash) before concluding a fix failed.
