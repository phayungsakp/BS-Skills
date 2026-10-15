# BSDataGrid / BSDataGridClient Reference

Source: `BS-Web/Frontend-Core/src/components/BSDataGrid/` (`BSDataGrid.js` ~16k lines, `BSDataGridClient.js`, `BSChildDataGrid.js`, helpers + tests). Long-form doc: `BS-Web/Frontend-Core/docs/BSDataGrid.md`. Defaults below are from the Template's `forwardRef` signature - re-check the signature in the repo you are in (`rg -n "const BSDataGrid = forwardRef" -A 120`).

```js
import BSDataGrid, { BSDataGridClient } from "../../components/BSDataGrid";
```

## Data Source

| Prop | Default | Meaning |
| --- | --- | --- |
| `bsPreObj` | `"default"` | Schema (`inv`, `sec`, `tmt`, `ais`, ...). Must be in `DynamicCrud:AllowedSchemas` |
| `bsObj` | - | Table or view to read |
| `bsSaveObj` | - | Table to write when `bsObj` is a view |
| `bsCols` | all | Comma-separated column list (order = grid order) |
| `bsObjWh` | - | WHERE fragment (server side) |
| `bsObjBy` | - | ORDER BY fragment, alias `t.` allowed (`"t.create_date desc"`) |
| `bsKeyId` | metadata | Explicit PK; required for views and SP result sets |
| `bsFilterMode` | `"server"` | `"server"` or `"client"` |
| `bsCustomFilters` | `[]` | Output of `BSFilterCustom` |
| `autoLoad` | `true` | Load on mount |
| `bsDataTransform` | `null` | Transform payload before save |

## Stored Procedure Mode

| Prop | Default | Meaning |
| --- | --- | --- |
| `bsStoredProcedure` | - | Read via `/dynamic/enhanced-procedure` |
| `bsStoredProcedureSchema` | `"dbo"` | SP schema |
| `bsStoredProcedureParams` | `{}` | Extra SP params |
| `bsStoredProcedureCrud` | `false` | Route Insert/Update/Delete through the SP too (backend SP must implement the operation contract - see root `docs/Enhanced-Stored-Procedures-Guide.md`) |

Set `bsKeyId` in SP mode; metadata cannot infer the key from a result set.

## Columns, Lookups, Validation

| Prop | Default | Meaning |
| --- | --- | --- |
| `bsColumnDefs` | `[]` | Per-field overrides: `{ field, headerName, width, type, required, readOnly, defaultValue, ... }`. Types include `string`, `number`, `currency`, `boolean`, `date`, `dateTime`, `stringAvatar`, `attachFile` |
| `bsComboBox` | `[]` | Lookups: `{ Column, Display, Value, Default, PreObj, Obj, ObjWh, ObjBy }` → `/dynamic/combobox` |
| `bsSyncDisplayDefault` | `true` | Default SyncDisplay for combo configs |
| `bsUniqueFields` | `[]` | `["field"]` or `[{ field, message }]` |
| `bsHiddenColumns` | `[]` | Hidden in grid and form |
| `bsPinColsLeft` / `bsPinColsRight` | - | Pinned columns |
| `bsColumnWidth` | `"auto"` | `"auto"` or number |
| `bsShowDescColumn` | `true` | Pull description columns from metadata |
| `bsUserLookup` | - | Audit-field display: `{ table: "sec.t_com_user", idField: "user_id", displayFields: ["first_name","last_name"], separator: " " }` |
| `bsCellTooltip` | `true` | Tooltip on truncated cells |

Date display goes through `dateTypeUtils.resolveDateDisplayDataType(fieldName, value, dataType)`: metadata type first, value/time signal second, field-name heuristic last. Fix date bugs there, not per page.

Global quick filter skips `create_by`/`update_by` (`GLOBAL_FILTER_EXCLUDED_FIELDS`) in the grid and in `DynamicCrudService`.

## Add / Edit / Delete / Bulk

| Prop | Default | Meaning |
| --- | --- | --- |
| `bsBulkMode` | `null` | **Wins over legacy bulk props.** `{ enable, add, addInline, edit, delete, showCheckbox, showSplitButton }` |
| `bsBulkEdit` / `bsBulkAdd` / `bsBulkDelete` / `bsBulkAddInline` / `bsEnableBulkMode` | `false` | Legacy flags |
| `bsShowCheckbox` | `false` | Bulk flags do **not** show checkboxes by themselves |
| `bsSelectionType` | `"checkbox"` | or `"radio"` |
| `showAdd` / `bsVisibleEdit` / `bsVisibleDelete` / `bsVisibleView` | `true`/`true`/`true`/`false` | Row/toolbar buttons (`bsVisibleView` needs `onView`) |
| `readOnly` | `false` | Hides add/edit/delete |
| `bsAutoPermission` | `true` | Apply menu permissions automatically |
| `bsRowConfig` | - | `(row) => ({ showCheckbox, showEdit, showDelete, backgroundColor, textColor, disabled })` |
| `bsCustomActions` | `[]` | Toolbar buttons `{ label, icon?, onClick(apiRef), color?, disabled?, hidden? }` |
| `bsOnBeforeSave` | - | `async ({ formData, ... }) => boolean`; `false` cancels |
| `bsOnAfterSave` | - | After successful add/edit |
| `bsDefaultFormValues` | `{}` | Defaults for new records |
| `onCheckBoxSelected`, `onDataBind`, `onFilteredDataChange` | - | Selection / loaded data / visible data callbacks |

Mixed flows (inline add + dialog edit) are expressed with `bsBulkMode` - keep the split the user asked for.

## Dialog Form

| Prop | Default | Meaning |
| --- | --- | --- |
| `bsDialogSize` | `"Default"` | `"Small"`, `"Default"`, `"Large"`, `"FullScreen"` |
| `bsDialogColumns` | `4` | Fields per row: 1, 2, 3, 4, 6, 12 |
| `bsDialogDraggable` | `true` | Drag by title |
| `bsDialogTab` | - | `[{ Column: "a,b", name }]` **or** `[{ Tabs: [{ Tab: { Column, name } }] }]` |
| `bsDialogSection` | - | `[{ Column: "a,b", name, icon?, showHeader? }]` |

These are config arrays, not components.

## Master-Detail

```jsx
<BSDataGrid
  bsPreObj="inv" bsObj="t_inv_receive"
  bsPrimaryKeys={["receive_id"]}
  bsDialogSize="Large"
  bsChildGrids={[{
    name: "Items",                 // tab label
    bsPreObj: "inv", bsObj: "t_inv_receive_item",
    foreignKeys: ["receive_id"],   // values come from the parent row
    bsVisibleEdit: true, bsVisibleDelete: true, height: 350,
  }]}
/>
```

Child grids render via `BSChildDataGrid`. Parent must be saved before child rows can be added (`bsSaveRecordFirst` message). Don't build another master-detail framework.

## Display / Export

`bsLocale` (`"en"`/`"th"`), `bsRowPerPage` (20), `bsPageSizeOptions` (`[20,100,200,500,1000]`), `bsShowRowNumber` (true), `bsShowCharacterCount`, `showToolbar`, `height` (`"auto"`), `bsExportFileName`, `bsPrintTitle`, `addRecordText`, `bsParentRecordLabel`.

Verbose logging: `REACT_APP_BSDATAGRID_VERBOSE_LOG=true`.

## BSDataGridClient

Parent owns `data` (array) and `columns`. Same display props (`bsCols`, pins, paging, `bsShowCheckbox`, `bsUserLookup`, export/print). Toolbar via `showAdd`, `onAdd`, `onInlineAdd`, `onRefresh`, `onExportExcel`, `onExportCsv`, `onPrint`, `bsCustomActions`. Bulk via `onBulkEdit`, `onBulkDelete`, `onBulkAdd`, `bulkEditMode`, `onBulkSave`, `onBulkDiscard`, `hasUnsavedChanges`, `changesCount`.

- No built-in server CRUD and no row edit/delete like `BSDataGrid`; the parent saves.
- Parent protects unsaved rows across paging, filtering, refresh and navigation.
- Need server data? Switch to `BSDataGrid` instead of a `useEffect` fetch loop.
- Example page: `src/pages/Examples/BSDataGridClientExample.js`.

## When A Fix "Does Nothing" In The Browser

Check in order: actual import path (folder vs old flat file), the served bundle (hard refresh / rebuilt?), merged column order (`bsCols` vs `bsColumnDefs` vs metadata), whether the callback you edited is the one wired (`bsOnBeforeSave` vs legacy `onEdit`). Then patch.
