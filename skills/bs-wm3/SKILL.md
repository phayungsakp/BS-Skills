---
name: bs-wm3
description: Use when working on OGA WM3 / WMS_NEW warehouse management (WM3_STD, WMS_NEW.sln) - ASP.NET WebForms .aspx pages, Layout.Master, PageCustom, GridViewExt, Entity Framework 6 edmx (WMSEntities, SecurityM_Entities), WM3 / WM3_Security SQL Server tables (t_wms_*, v_wms_*, t_com_menu), menus and permissions, React pages inside WebForms (WMS_NEW.React), Crystal Reports, or build errors like CS0006, missing DLL HintPath, pages not published, menus not appearing.
---

# WM3 (WMS_NEW)

## Overview

WM3 Standard is OGA's warehouse system: ASP.NET WebForms on .NET Framework 4.5.2, EF6 database-first, SQL Server, with new screens optionally written in React and mounted inside `.aspx` pages. It is **not** BS Platform: no Ocelot, no DynamicController, no BSDataGrid. Don't port BS Platform patterns into it.

**Source of truth:** `README.md` at the WM3_STD repo root (Thai, kept current). Read it before structural changes; this skill is the condensed rule set.

## Solution Map

| Project | Role |
| --- | --- |
| `WMS_NEW` | Web app: `.aspx`, user controls, scripts, themes, `Layout.Master`, `Web.config` |
| `WMS_NEW.Access` | Business logic and LINQ queries |
| `WMS_NEW.Source` | EF model of DB `WM3` (`DataSource.edmx`, `WMSEntities`) |
| `SecurityM.Access` / `SecurityM.Source` | Users, groups, menus; EF model of `WM3_Security` (`SecurityM_Entities`) |
| `WebSecurityApi.DTO` | Security API request/response |
| `ConfigGlobal` | Session (`_SessionVals`), enums, shared DTOs |
| `ConfigAzureDb` | EF `DbConfiguration` |
| `Prototype.Providers 2/` | Base classes/helpers (project name `Prototype.Providers`): `AGridObjectSourceQuery`, `AGridObjectSourceStore` |
| `WMS_NEW.React` | React 19 + Vite source for React pages |
| `References/` | Non-NuGet DLLs (`CustomControls.dll`, `BarcodeLib.Barcode.dll` - paid, keep repo private) |

Request flow: `.aspx` (inherits `PageCustom`, uses `Layout.Master`) → `*.Access` → EF DbContext → SQL Server `WM3` / `WM3_Security`. Most pages are server-rendered postbacks inside an `UpdatePanel` from `Layout.Master`'s `ScriptManager`.

`WMS_NEW` folders: modules in `Transaction/`, `MasterData/`, `DashBoard/`, `Authen/`, `Administrator/`, `Configuration/`, `Export/`; reports in `Report/`, `Reports/`; shared controls in `_UControls/` (`GridViewExt`, `PanelPopup`, `UploadFileEx`); `_ExtensionClass/` (`PageCustom`, HTTP client); `_scripts/` (+ `react/` bundles); `_scriptsAng/` (AngularJS); themes in `_css/`, `_theme/`, `App_Themes/` (light + dark).

## Build And Run

```bash
msbuild WMS_NEW.sln -t:Restore -p:RestorePackagesConfig=true
msbuild WMS_NEW.sln -t:Build -p:Configuration=Debug
"C:\Program Files\IIS Express\iisexpress.exe" /path:"<repo>\WMS_NEW" /port:8099 /clr:v4.0
```

Needs Visual Studio 2017+ with ASP.NET workload and the .NET 4.5.2 targeting pack. Node + pnpm only for React pages.

## Database Rules

| DB | Connection string | Holds |
| --- | --- | --- |
| `WM3` | `WMSEntities` | All WMS data: `t_wms_*`, `t_host_wms_*` (external interface), `t_com_*`, views `v_wms_*`, SPs `usp_wms_*` |
| `WM3_Security` | `SecurityM_Entities` | `t_com_user`, `t_com_user_group`, `t_com_menu`, `t_com_user_group_menu`, `t_com_resource_master`, `t_com_resource_detail` |

- Flags such as `is_active` are text `'YES'` / `'NO'` - not `'Y'`, not bit.
- `v_wms_inventory_data` is the main stock view (item, location, zone, lot, expiry, status). Heavy joins: filter by warehouse first on big sites.
- Lot, expiry and attribute 1-5 live in `t_wms_inventory_attribute`, not `t_wms_inventory`.
- Zone ↔ location via `t_wms_zone_location`; unzoned locations show `zone = NULL`.
- User warehouse access: `t_wms_wh_user` - every data query is scoped to it.
- Model changes: open `WMS_NEW.Source/DataSource.edmx` → Update Model from Database. Generated `t_*.cs` / `v_*.cs` are never hand-edited.
- Raw SQL via `model.Database.SqlQuery<T>(sql, new SqlParameter(...))` - always parameters, never string-concat user input.

## Config (`WMS_NEW/Web.config`)

Points at the team dev server. `connectionStrings` contain SQL credentials - never commit production values. Key `appSettings`: `APP_ID` (filters menus/resources), `PLATFORM` (`Web`), `WEB_SECURE_API_URL` + `WEB_SECURE_API_FUNC_LOGIN/LOGOUT/GETMENU`, `ReportUrl`, `DateFormat`, `TimeFormat`, `UICulture`, `GridDataMaxLength`, `GridFontSize`, `FolderImages`, `FolderTemp`. Session is `InProc`, 30 min → sticky sessions behind a load balancer.

## Login, Menus, Permissions

1. `Login.aspx` → Security API (`WEB_SECURE_API_URL`).
2. `GetMenu` with `APP_ID`, `PLATFORM`, language, user groups → `Session["MenuView"]` → sidebar in `Layout.Master`.
3. Menus load **once at login**: after DB menu changes, log out and in.

`.aspx` pages on `Layout.Master` get the session check for free. **`[WebMethod]` and `.ashx` do not** - check `_SessionVals.UserName` and warehouse permission yourself, every time.

## Adding A Page

1. `.aspx` in the module folder with `MasterPageFile="~/Layout.Master"`; code-behind inherits `PageCustom`.
2. Fill the three placeholders: `head`, `ContentBreadcrumb`, `ContentPlaceHolder1`.
3. Confirm `WMS_NEW.csproj` lists `.aspx` (`Content`) **and** `.aspx.cs` + `.aspx.designer.cs` (`Compile`). Old-style project: files missing from the csproj are not compiled or published (e.g. `DashBoard/DashboardOutbound.aspx` today).
4. Grids: `GridViewExt` + an `*.Access` class deriving `AGridObjectSourceQuery` / `AGridObjectSourceStore`.
5. Add the menu in `WM3_Security` (DB, not git - every environment needs it), then re-login. Copy a sibling menu:

```sql
DECLARE @id varchar(40) = LOWER(NEWID()), @sibling varchar(40) = '<sibling menu_id>';

INSERT INTO t_com_resource_master (resource_master_id, app_id, resource_name, description, default_value, create_date, create_by)
SELECT @id, app_id, N'<Menu name>', N'<Menu name>', N'<Menu name>', GETDATE(), '<you>' FROM t_com_menu WHERE menu_id = @sibling;

INSERT INTO t_com_menu (menu_id, app_id, platform, menu_group, menu_group_sequence, parent_menu_id, menu_name, menu_sequence, process, resource_master_id, is_active, create_date, create_by)
SELECT @id, app_id, platform, menu_group, menu_group_sequence, parent_menu_id, N'<Menu name>', <sequence>, N'~/Folder/Page.aspx', @id, 'YES', GETDATE(), '<you>' FROM t_com_menu WHERE menu_id = @sibling;

INSERT INTO t_com_user_group_menu (user_group_id, menu_id, is_active, create_date, create_by)
SELECT user_group_id, @id, 'YES', GETDATE(), '<you>' FROM t_com_user_group_menu WHERE menu_id = @sibling AND is_active = 'YES';
```

Or use Authentication > Menu and AssignMenu in the app.

## React Pages Inside WebForms

Reference implementation: Stock Health.

| File | Role |
| --- | --- |
| `WMS_NEW.React/src/stock-health/` | Component source (`mock.js` for `dev`) |
| `WMS_NEW.React/vite.config.js` | Builds one IIFE file |
| `WMS_NEW/_scripts/react/stock-health.js` | Built bundle - **committed** |
| `WMS_NEW/DashBoard/StockHealth.aspx` | Host: `<div id="stock-health-root" data-api=...>` + `<script src=...?v=<ticks>>` |
| `WMS_NEW/DashBoard/StockHealth.aspx.cs` | `[WebMethod(EnableSession = true)]` JSON endpoints |

```bash
pnpm -C WMS_NEW.React install
pnpm -C WMS_NEW.React dev     # mock data, no .NET
pnpm -C WMS_NEW.React build   # overwrites WMS_NEW/_scripts/react/*.js
```

Rules:
- The .NET build does not run Node: after changing React, run `build` and commit the bundle with the source.
- Scope all CSS under the root class (Stock Health: `.sh-root`). No resets, no global selectors - the legacy theme breaks.
- No server controls in the same `ContentPlaceHolder1` as the React root: partial postback wipes the React DOM.
- Every button `type="button"` - the whole page is one `<form runat="server">`.
- Call page methods with `POST`, `Content-Type: application/json`; the result is in `.d`.
- Page method guard (from `StockHealth.aspx.cs`):

```csharp
static List<t_wms_wh> UserWarehouses(WMSEntities model)
{
    var user = _SessionVals.UserName;
    if (string.IsNullOrEmpty(user))
        throw new UnauthorizedAccessException("Session expired");
    return (from wu in model.t_wms_wh_user
            where wu.is_active == "YES" && wu.user_id.ToUpper() == user.ToUpper()
            select wu.t_wms_wh).Distinct().ToList().OrderBy(w => w.wh_id).ToList();
}
```

Every `[WebMethod]` resolves the requested warehouse **from this list**, never trusting the `whId` sent by the browser.

## DLL And Reference Rules

The repo must build right after a fresh clone (`bin/`, `packages/` are not in git):
- `<HintPath>` only to `..\packages\...` (and listed in that project's `packages.config`) or `..\References\...`.
- New non-NuGet DLL → `References/` + commit.
- In-solution dependencies use `<ProjectReference>`, never another project's `bin\Debug`.
- Never a machine path (`D:\ProjectVS\...`, personal OneDrive).
- Before pushing reference changes, build from a fresh clone in an empty folder - the working copy's old `bin`/`packages` hide breakage.

## Known Traps

| Symptom | Cause / Fix |
| --- | --- |
| `CS0006` metadata file not found | Repo path > ~125 chars pushes Crystal Reports package paths past 260. Clone to a short path |
| Page builds locally but missing after publish | Not in `WMS_NEW.csproj` |
| Menu added but not visible | Menus cached at login → re-login; check `t_com_user_group_menu` |
| React page blank after postback | Server control in the React placeholder |
| Clicking a React button reloads the page | Missing `type="button"` |
| Page method returns data for warehouses the user can't access | Missing `t_wms_wh_user` guard |
| Publish fails on profile | `FolderProfile*.pubxml` are gitignored; create your own |
| Fonts differ on offline servers | Stock Health loads Google Fonts |
| SignalR client errors | `_scriptsAng/services/carDashboardSvc.js` has no Hub in this solution |

## Related

- WM3 PDA functions / handheld API (`WebAPI_WMS`, `FUNCTION_ID`, `Commons/InitialControl`): the WM3 PDA Function Manager tool (`BS-WM3-XAMAAPP-Function/SourceCode`, README) generates and applies the setup SQL - dry-run before commit, and its deploy script refuses to overwrite the server `Web.config`.
- AI assistant over WM3 data lives in a BS Platform fork (BS-AI-Assistance-WM3) → use bs-platform.
