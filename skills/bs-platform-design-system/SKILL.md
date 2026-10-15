---
name: bs-platform-design-system
description: Use when building, restyling, or reviewing any screen, dialog, form, dashboard, or component in a BS Platform React frontend (BS-Web/Frontend-Core) - colors, theme presets, dark mode, typography, spacing, buttons, grids, alerts, loading states, motion - or when UI looks off-brand, hard-codes colors, breaks in dark mode, flickers, or reads as generic "AI slop".
---

# BS Platform Design System

## Overview

The design system is code, not a Figma file: `src/themes/theme.js` (`getTheme(mode, themeName)`), `src/themes/ThemeContext.js` (`useColorMode`), `src/utils/ButtonConfigs.js`, and the `BS*` components. Screens are dense enterprise data screens: scannable, consistent, quiet.

**Rule:** every color, radius, shadow and font comes from the theme or a BS component. If you are typing a hex value in a page, stop.

**REQUIRED BACKGROUND:** bs-platform (component selection, page pattern).

## Tokens

Verify against `theme.js` in the active repo before relying on values.

### Theme switching

```js
import { useColorMode } from "../themes/ThemeContext";
const { mode, toggleColorMode, themeName, setThemeName } = useColorMode();
```

- `mode`: `"light"` | `"dark"`; persisted in SecureStorage `theme-mode`.
- `themeName` (light only, persisted in `theme`): `theme-dark-navy` (default), `theme-purple`, `theme-teal`, `theme-orange`, `theme-pastel`, `theme-red-accent`. Each preset has `labelTh`/`labelEn`.
- Adding a preset = new entry in `LIGHT_THEME_PRESETS` (10 `shades` + optional `main`/`secondary`) **and** in `supportedThemes` in `ThemeContext.js`.

### Light palette (from preset)

| Token | Source |
| --- | --- |
| `primary.main/light/dark` | preset `main` or `shades[500]` / `shades[200]` / `shades[700]` |
| `secondary.main/light/dark` | preset `secondary` or `shades[600]` / `[300]` / `[800]` |
| `error` / `warning` / `info` / `success` main | `#EF4444` / `#F59E0B` / `#3B82F6` / `#10B981` |
| `background.default` / `paper` | `#F6F7FA` / `#FFFFFF` |
| `text.primary` / `secondary` | `#212121` / `#424242` |
| `divider` | `alpha(primary.main, 0.18)` |
| `grey.50-900` | Tailwind-like neutral scale |

### Dark palette (fixed, glass style)

`primary #00D4FF`, `secondary #A855F7`, `error #FF6B6B`, `warning #FFD93D`, `info #4ECDC4`, `success #6BCB77`, `background.default #0D0D0F`, `paper rgba(20,20,25,0.98)`, `text #FFFFFF / #A0A0A0`, `divider rgba(255,255,255,0.08)`. Dark `contrastText` is black on primary/warning/info/success.

### `palette.custom` (both modes)

| Key | Use |
| --- | --- |
| `saveButton`, `closeButton`, `addButton` | Action colors |
| `accordionHeader`, `accordionContent` | Dialog sections / accordions |
| `mainBackground`, `paperBackground` | Page vs card surfaces |
| `priority.{urgent,high,normal,low}` | Priority chips/labels |
| Dark only: `glass.{background,backgroundHover,border,borderHover,blur,shadow}`, `glow.{primary,secondary,success,error}`, `sectionOpen/InProcess/Close` | Glass cards, status sections |

Dark-only keys don't exist in light mode: read them with optional chaining and a light fallback.

### Type, shape, elevation

- Font: `'Prompt','Roboto','Inter',...` - Prompt is self-hosted (`public/fonts/Prompt`, Regular/Medium/Bold) for Thai. Don't add font CDNs.
- Fluid sizes via `clamp()` for `h1`-`h6`, `body1`, `body2`, `button`. Headings weight 400-500. Buttons `textTransform: none`.
- Use `Typography variant`, never raw `fontSize` px in pages.
- `shape.borderRadius: 12`; overrides: Card 16, Button 8, Chip 6, **Paper 0 (`unset`)**.
- `shadows` = soft Tailwind-like scale; contained buttons have no shadow until hover.
- DataGrid: header `alpha(primary, 0.05)`, row hover `alpha(primary, 0.03)`, border `divider` - comes from the theme override, don't restyle per page.
- Thin custom scrollbars from `MuiCssBaseline`.

## Components Over Raw MUI

| Need | Use | Not |
| --- | --- | --- |
| Save / Close actions | `BSSaveOutlinedButton`, `BSCloseOutlinedButton` (contained, `ACTION_BUTTON_THEMES` success/close, logs activity) | `<Button color="success">` |
| Other action buttons | `ButtonConfigs().ACTION_BUTTON_THEMES.{success,close,warning,error,info,primary,clear}` in `sx` | ad-hoc gradients |
| Dialog | `BSDialog` (draggable, minimize, fullscreen) | `<Dialog>` |
| Table | `BSDataGrid` / `BSDataGridClient` | `<Table>` or raw `DataGridPro` |
| Inputs | `BSTextField`, `BSDatepicker`, `BSAutoComplete`, `BSSwitch` | raw `TextField` / pickers |
| Feedback | `BSAlert`, `BSAlertSnackber`, `BSAlertSwal2` | `window.alert`, raw `Snackbar` |
| Loading | `TopLinearProgress`, `BSLinearProgressWithLabel`, `contexts/BSFullScreenLoader` (blocking save/process only) | spinners centered in empty pages |
| Breadcrumb | `CustomBreadcrumbs` (from `MainLayout`) | per-page breadcrumb |

## Layout Pattern

```jsx
<Paper sx={{ p: 2, width: "100%", height: "100%", display: "flex", flexDirection: "column" }}>
  {/* optional: BSFilterCustom / toolbar row */}
  <BSDataGrid ... />
</Paper>
```

- One `Paper` per page body; `MainLayout` already provides sidebar, header, breadcrumb.
- Spacing on the 8px MUI scale (`p: 2`, `gap: 1.5`); no magic px margins.
- Forms in dialogs use `bsDialogColumns` (default 4) and `bsDialogSection`/`bsDialogTab` instead of custom grids.
- Dense by default: small/medium controls, no hero banners, no giant empty states, no decorative illustrations on data screens.
- Status = color **plus** text/icon (chips with labels), never color alone.

## Dark Mode

Every new screen must work in both modes. Use `theme.palette.*`, `alpha(theme.palette.primary.main, x)`, `theme.palette.divider`, `background.paper`. Check by toggling `toggleColorMode()`; look for white boxes, invisible text, hard-coded `#fff`/`#000`, borders that vanish.

## Motion

Follow `BS-Web/Frontend-Core/docs/FramerMotion-Usage-Guide.md` (framer-motion 11):
- OK: `whileHover`/`whileTap` scale on small buttons/chips/icons; opacity-only reveal on summary boxes.
- Not OK: animating page roots, grid containers, `layout` animations around BSDataGrid, re-keying containers to replay animations. These flicker and jump.

## Localization In UI

Visible strings come from resources (`useResource`) or BS component `bsLocale`; Thai and English must both fit - leave room, avoid fixed-width labels. Don't hard-code Thai or English copy in shared components.

## Red Flags - Stop And Fix

- Hex/rgb literal in a page or component outside `theme.js`/`ButtonConfigs.js`
- New `createTheme` or `ThemeProvider` below `App`
- Raw MUI `Dialog`/`Table`/`Snackbar` where a BS component exists
- Gradient hero, glassmorphism card, or glow in **light** mode pages
- Animation on a grid or page root
- Text that only works in one mode or one language
- Restyling DataGrid headers per page

## Review Checklist

1. Light + dark both readable (toggle and look).
2. All six presets still look right (switch `themeName`; primary is not always navy).
3. No literal colors; spacing on theme scale.
4. BS components used where they exist.
5. Thai + English labels fit.
6. Motion limited to small elements.
