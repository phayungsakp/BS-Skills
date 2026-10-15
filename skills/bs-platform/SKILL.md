---
name: bs-platform
description: Use when working in a BS Platform repository (BS-Platform-Template, BS-MyInventory, BS-AI-Assistance-WM3 or any fork with BS-Web/Frontend-Core, BS-API-Core, BS-API-Secure) - building pages with BSDataGrid, BSDataGridClient, BSDialog, BSAutoComplete, BSFilterCustom, wiring DynamicController or Ocelot gateway routes, menu permissions, resources/localization, stored procedures, DB_PROVIDER switching, AI Assistant, or debugging "MUI X Expired package version", 401/refresh loops, and 404 on /gateway/v1/api.
---

# BS Platform

## Overview

BS Platform = React (CRA + CRACO, MUI 7, MUI X Pro) frontend behind an Ocelot gateway in front of .NET microservices, with metadata-driven CRUD (`DynamicController`) and DB-managed menus/permissions/resources.

**Core rule:** the live checkout beats this skill. Every fact below is a starting point to verify, not permission to skip reading the source. Forks drift: same folder names, different props, routes, schemas and base paths.

## First Moves

1. Read the nearest `AGENTS.md`; run `git status --short` and preserve unrelated changes.
2. Profile the repo (prints versions, lockfile, base path, gateway coverage, schemas, compose services):
   `powershell -NoProfile -ExecutionPolicy Bypass -File <skill-dir>/scripts/bs-profile.ps1 -Root <repo>`
   Exit 1 = it found drift worth fixing or reporting. Read the `[WARN]` lines.
3. Find shared components by symbol, not memory:
   `rg -n "BSDataGrid|BSDialog|BSAutoComplete|BSFilterCustom|useDynamicCrud|usePermission|useResource" BS-Web/Frontend-Core/src`
4. Fix in the shared component/hook when more than one page is affected; patch the page only for page-only behavior.

## Repo Map

| Area | Location | Notes |
| --- | --- | --- |
| Frontend | `BS-Web/Frontend-Core` | CRA `react-scripts 5` + CRACO build, React 19, React Router 7, MUI 7, MUI X DataGrid Pro 7 |
| Frontend docs | `BS-Web/Frontend-Core/docs/` | `BSDataGrid.md`, `BSDataGridClient.md`, `BsAutoComplete.md`, `BSFilterCustomExample.md`, `BSAlert.md`, `BSDatepicker.md`, `BSTextField.md`, `BSGanttChart.md`, `TopLinearProgress.md`, `JWT_TROUBLESHOOTING.md`, `QUICK_FIX_401.md` |
| Core API | `BS-API-Core/ApiCore` | `DynamicController`, `AutoCompleteController`, `ExcelController`, `FileController`, `LoggingController` |
| Gateway / auth | `BS-API-Secure/ApiGateway` (`ocelot.json`), `BS-API-Secure/Authentication`, `TokenManagement` | Everything the browser calls goes through `/gateway/v1/api/*` |
| Other services | `BS-Import-Export-Manager`, `BS-Notification` (SignalR), `BS-Report-Manager-Viewer`, `BS-Printing-Manager`, `BS-AI-Assistant`, `BS-API-Mobile`, `BS-OMS-API` | Not every fork has all of them |
| Runtime | root `docker-compose.yml` | Services: `api_gateway` (8080), `auth_api`, `bs_core_api`, `bs_import_export_manager`, `bs_notification` (8081), `bs_web` (3000), `bs_report_viewer` (8082), `bs_ai_assistance`, `bs_api_mobile` |
| Architecture docs | root `docs/` | `BS-Platform-Architecture.md`, `Database-Provider-Configuration.md`, `Enhanced-Stored-Procedures-Guide.md` |

Known variants (verify `package.json` `homepage` and `.env.*` `REACT_APP_BASE_URL`):

| Repo | Base path | Identity |
| --- | --- | --- |
| BS-Platform-Template (branch `template`) | `homepage: "."`, `REACT_APP_BASE_URL=/` | Framework layer only, `BS-Web-Framework` |
| BS-MyInventory | `/my-inventory` | Inventory app + AI Assistant |
| BS-AI-Assistance-WM3 | `/my-inventory` (inherited) | MyInventory fork for WM3 AI work |

Never hard-code a base path or API host; use `Config.BASE_URL` / `Config.API_URL` from `src/utils/Config.js`.

## Frontend Package And License Gate

**Team license rule: MUI X DataGrid is licensed for `7.29.9` only.** Every `@mui/x-data-grid` and `@mui/x-data-grid-pro` copy in the lockfile must be exactly `7.29.9`. Any other version (higher too) = "MUI X: Expired package version" / watermark in production. Never upgrade them, never accept `^`/`~`.

Run this gate before any frontend build/deploy and whenever `package.json` or the lockfile changes:

1. Use the package manager that owns the lockfile (`package-lock.json` → npm, `pnpm-lock.yaml` → pnpm). Never mix. In Windows PowerShell call `npm.cmd` if `npm.ps1` is blocked.
2. Check: `bs-profile.ps1` warns on any declared spec or lockfile entry that is not `7.29.9`. Known drift: repos declare `"^7.29.9"`, so npm resolved top-level `@mui/x-data-grid` to `7.29.12` while `-pro` (and its nested `x-data-grid`) stayed `7.29.9`. Searching the lockfile for `x-data-grid-pro` alone misses this - the bad entry is `node_modules/@mui/x-data-grid`.
3. Fix from `BS-Web/Frontend-Core` (rewrites `package.json` to exact `"7.29.9"` and regenerates lockfile entries with correct `resolved`/`integrity`):
   `npm.cmd install @mui/x-data-grid@7.29.9 @mui/x-data-grid-pro@7.29.9 --save-exact`
4. Prove: `npm.cmd ci`, then `npm.cmd ls @mui/x-data-grid @mui/x-data-grid-pro --all` - every line `7.29.9`. Rerun `bs-profile.ps1` → no MUI X warning.
5. Commit `package.json` and `package-lock.json` together.
6. Do **not** hand-edit `"version"` in `package-lock.json`: the entry's `resolved` URL and `integrity` hash still point at the old tarball, so `npm ci` fails (`EINTEGRITY`) or silently re-resolves. If someone already hand-edited it, step 3 repairs it.
7. License key comes from `REACT_APP_MUI_X_LICENSE_KEY`, applied by `muiLicenseManager.initialize()` in `src/index.js`. Do not remove that call or the production console suppression next to it.
8. Never edit `build/`, `bin/`, `obj/`.

"Expired package version" / watermark = MUI X version drift first, license key env second, stale browser storage third, grid code last.

## Component Selection

| Need | Use |
| --- | --- |
| Server-backed CRUD over a table/view, child grids, stored procedures | `BSDataGrid` (default export of `components/BSDataGrid`) |
| Rows owned by the page (preview, import staging, offline) | `BSDataGridClient` (named export of `components/BSDataGrid`) |
| Dialog shell (draggable, minimize, fullscreen) | `BSDialog` |
| Lookup/combobox input | `BSAutoComplete`, or `bsComboBox` config inside BSDataGrid |
| Advanced filter panel | `BSFilterCustom` → pass result to `bsCustomFilters` |
| Inputs | `BSTextField`, `BSDatepicker`, `BSSwitch`, `BSFileUpload`, `BSImportFile` |
| Feedback | `BSAlert` (inline), `BSAlertSnackber` (toast - legacy spelling is the real name), `BSAlertSwal2` (modal confirm) |
| Save / close buttons | `components/Button/BSSaveOutlinedButton`, `BSCloseOutlinedButton` (they log activity) |
| Loading | `TopLinearProgress`, `BSLinearProgressWithLabel` |
| Timeline | `BSGanttChart` (`@svar-ui/react-gantt`) |
| Report preview | `components/ReportViewer` |

Do not rebuild any of these with raw MUI. Do not rename legacy public names (`BSAlertSnackber`, `REACT_APP_ENCRYPYION`, `bsColumes`) during unrelated work.

## Page Pattern

Routes under `PermissionRoute` receive the matched menu row through the outlet context; `MainLayout` passes `lang`. Condensed from BS-MyInventory `pages/Master/Category.js`:

```jsx
import { Paper } from "@mui/material";
import { useEffect, useState } from "react";
import { useOutletContext } from "react-router-dom";
import BSDataGrid from "../../components/BSDataGrid";
import { useResource } from "../../hooks/useResource";

export default function Category({ lang = "en" }) {
  const { permission } = useOutletContext(); // menu row: is_view / is_add / is_edit / is_delete
  const { getResources } = useResource();
  const [res, setRes] = useState([]);
  useEffect(() => { getResources("t_inv_category", lang).then((r) => setRes(r || [])); }, [lang]); // eslint-disable-line react-hooks/exhaustive-deps
  const r = (name, fallback) => res.find((x) => x.resource_name === name)?.resource_value ?? fallback;

  return (
    <Paper sx={{ p: 2, width: "100%", height: "100%", display: "flex", flexDirection: "column" }}>
      <BSDataGrid
        bsLocale={lang}
        bsPreObj="inv"                     // schema - must be in DynamicCrud:AllowedSchemas
        bsObj="t_inv_category"             // table or view
        bsCols="category_id,item_category,description,is_active"
        bsObjBy="item_category asc"
        bsKeyId="category_id"              // explicit PK; required for views / SP results
        bsUniqueFields={[{ field: "item_category", message: "Item Category already exists." }]}
        bsColumnDefs={[
          { field: "category_id", width: 110, readOnly: true },
          { field: "item_category", headerName: r("item_category", "Item Category"), required: true },
          { field: "is_active", defaultValue: 1 },
        ]}
        bsDialogSize="Large"
        bsDialogColumns={2}
        bsDialogSection={[{ Column: "item_category,description", name: r("CategoryInformation", "Category Information") }]}
        bsBulkMode={{ enable: true, add: permission?.is_add, addInline: permission?.is_add,
                      edit: false, delete: permission?.is_delete }}
        showAdd={permission?.is_add}
        bsVisibleEdit={permission?.is_edit}
        bsVisibleDelete={permission?.is_delete}
        bsVisibleView={permission?.is_view}
      />
    </Paper>
  );
}
```

Outside routed pages use `usePermission(path?)` → `{ canView, canAdd, canEdit, canDelete }`. `bsAutoPermission` defaults to `true`; keep it unless the page owns permissions.

Full prop reference, child grids, stored-procedure mode, bulk rules: `references/bsdatagrid.md`.

## Frontend Rules

- HTTP goes through `src/utils/AxiosMaster.js` (JWT header, cross-tab refresh lock, activity logging) or hooks built on it: `useDynamicCrud(tableName)`, `useApi`, `useCrud`, `usePagination`. No raw `fetch`/`axios.create` for gateway calls.
- Labels come from resources: `useResource()` → `getResource`, `getResourceDescription`, `getResources(group, locale)`, `getResourceByGroupAndName`. Do not hard-code Thai/English when the screen around it uses resources.
- Storage: `utils/SecureStorage.js` (keys `menu`, `theme`, `theme-mode`, tokens). Don't read tokens from plain `localStorage` in new code.
- Theme: read `theme.palette.*` / `theme.palette.custom.*`; never hard-code colors. **REQUIRED SUB-SKILL:** bs-platform-design-system for any UI/visual work.
- Details (providers, hooks, env vars, logging): `references/frontend.md`.

## Backend, Gateway, Database Rules

- A frontend call works only when the route exists in **both** the service controller and `ocelot.json`. Adding an endpoint = controller + Ocelot route (+ `AuthenticationOptions` unless intentionally anonymous) + rebuild gateway image. `bs-profile.ps1` flags DynamicController operations missing from Ocelot.
- Dynamic CRUD only touches schemas in `BS-API-Core/ApiCore/appsettings.json` → `DynamicCrud:AllowedSchemas` (Template: `dbo, sec, tmt, imp, ams, rfi, inv, noti, rpt, ais`) and refuses `ForbiddenTables`. A new schema = deliberate edit there.
- Services call `DotNetEnv.Env.Load()` then read `DB_PROVIDER` (`SqlServer` | `PostgreSql` | `MySql`), `SERVERDB`, `SERVERDB_SECURITY`. SQL differences belong in `ISqlDialect` (`SqlServerDialect`, `PostgreSqlDialect`, `MySqlDialect`) via `ISqlConnectionFactory`; never write provider-specific SQL in a controller.
- Verify the live table/view/SP before writing SQL. Don't infer columns from file names.
- Endpoint list, gateway map, enhanced stored procedures, adding an endpoint: `references/backend-gateway.md`.
- AI Assistant (`BS-AI-Assistant`, `ais.t_ai_*` tables, chat/knowledge routes): `references/ai-assistant.md`.

## Verification

Smallest proof that covers the change, from the affected service:

```powershell
# Frontend (BS-Web/Frontend-Core)
npm.cmd test -- --watchAll=false BSFilterCustom.test.js   # focused; also dateTypeUtils, formDataUtils, exportUtils, logger
npm.cmd run build          # CRACO, DISABLE_ESLINT_PLUGIN, no sourcemaps
npm.cmd run build:prod     # build + javascript-obfuscator, only when packaging matters

# Backend
dotnet build BS-API-Core/ApiCore/ApiCore.sln
dotnet build BS-API-Secure/ApiGateway/ApiGateway.sln
dotnet build BS-AI-Assistant/AiAssistant/AiAssistant.sln
```

Exit code and final summary decide; warning noise is not failure. Auth-gated pages: focused tests + source inspection + successful production build is acceptable proof - say so explicitly instead of claiming browser verification.

## Common Mistakes

| Mistake | Fix |
| --- | --- |
| Assuming every fork has the same base path, props, routes | Run `bs-profile.ps1`; read the file |
| Patching one page when the bug is in `BSDataGrid`/hook | Fix shared code once |
| Import from old flat `components/BSDataGrid.js` | Import from the folder `components/BSDataGrid` |
| Treating `bsDialogTab`, `bsDialogSection`, `bsChildGrids` as components | They are config arrays |
| Bulk flags but no checkboxes | Add `bsShowCheckbox` or `bsBulkMode.showCheckbox` |
| Controller endpoint added, frontend 404 | Add the Ocelot route |
| "Table not found"/403 for a new schema | Add schema to `AllowedSchemas` |
| `t_ais_*` table names | Real names are `ais.t_ai_*` |
| Wiring `BSDataGridClient` to server CRUD with `useEffect` | Use `BSDataGrid` |
| Hard-coded colors / animated grids and page roots | Theme tokens; motion only on small controls |
| Collapsing "inline add + dialog edit" into one mode | Keep the requested split (`bsBulkMode`) |
| Reverting unrelated user changes | Never |
