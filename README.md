# bs-skills

Agent skills พื้นฐานของทีม สำหรับงาน BS Platform และ WM3 ใช้ได้กับ Claude Code, Codex, Cursor, Gemini CLI, GitHub Copilot และ agent อื่นที่อ่าน `SKILL.md` ได้

| Skill | ใช้ตอนไหน |
| --- | --- |
| [`bs-platform`](skills/bs-platform/SKILL.md) | งานใน repo BS Platform (Template, MyInventory, AI-WM3 และ fork อื่น): BSDataGrid, DynamicController, Ocelot gateway, permission, resource, stored procedure, DB provider, AI Assistant, MUI X license |
| [`bs-platform-design-system`](skills/bs-platform-design-system/SKILL.md) | งาน UI ของ BS Platform: theme token, preset สี, dark mode, ปุ่ม, layout, motion |
| [`bs-wm3`](skills/bs-wm3/SKILL.md) | งาน WM3 / WMS_NEW: ASP.NET WebForms, EF6, ตาราง `t_wms_*`, เมนูใน `WM3_Security`, หน้า React ใน WebForms |

Agent จะโหลด skill เองเมื่องานตรงกับ `description` ไม่ต้องเรียกเอง (ถ้าจะบังคับใน Claude Code พิมพ์ `/bs-platform` ได้)

## ติดตั้ง

ต้องมี Node.js 22+ และสิทธิ์อ่าน repo นี้

```bash
npx skills add phayungsakp/bs-skills -g
```

ตัวติดตั้งจะถามว่าจะลง agent ไหน และลง skill ตัวไหน ถ้าไม่อยากตอบคำถาม:

```bash
npx skills add phayungsakp/bs-skills -g --all
```

ลงเฉพาะ skill เดียว หรือลงเข้า project แทน global (รันที่ root ของ project แล้วตัด `-g` ออก):

```bash
npx skills add phayungsakp/bs-skills --skill bs-wm3
```

ถ้า clone ผ่าน `npx` ไม่ได้ (repo private หรือหลัง proxy) ให้ clone เองแล้วติดตั้งจาก path:

```bash
git clone git@github.com:phayungsakp/bs-skills.git
```

```bash
npx skills add ./bs-skills -g
```

### อัปเดต / ถอนการติดตั้ง

```bash
npx skills update -g
```

```bash
npx skills remove bs-platform bs-platform-design-system bs-wm3 -g
```

### ติดตั้งเอง (ไม่ใช้ npx)

copy โฟลเดอร์ใน `skills/` ไปไว้ที่โฟลเดอร์ skill ของ agent:

| Agent | Global | Project |
| --- | --- | --- |
| Claude Code | `~/.claude/skills/` | `.claude/skills/` |
| Codex / agent ทั่วไป | `~/.agents/skills/` | `.agents/skills/` |

## Script ตรวจ repo

`bs-platform` มี script ตรวจ repo ที่ agent จะรันเอง หรือจะรันเองก็ได้:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File skills/bs-platform/scripts/bs-profile.ps1 -Root "D:\path\to\BS-Platform"
```

แสดง version ของ stack, lockfile, base path, จำนวน route ของ gateway แยกตาม service, route ที่ไม่ต้อง login, DynamicController operation ที่ไม่มี route ใน Ocelot, `AllowedSchemas` และ service ใน docker-compose ถ้าเจอปัญหาจะ exit 1 พร้อมบรรทัด `[WARN]`

เรื่องที่ต้องรู้: license MUI X ของทีมใช้ได้กับ **`@mui/x-data-grid` และ `@mui/x-data-grid-pro` เวอร์ชัน `7.29.9` เท่านั้น** script จะเตือนถ้า `package.json` ไม่ได้ pin เป็น `7.29.9` ตรงๆ หรือ `package-lock.json` มี copy ไหนเป็นเวอร์ชันอื่น วิธีแก้ (แก้ทั้ง `package.json` และ lockfile ให้ถูกต้องในคำสั่งเดียว รันที่ `BS-Web/Frontend-Core`):

```bash
npm install @mui/x-data-grid@7.29.9 @mui/x-data-grid-pro@7.29.9 --save-exact
```

อย่าแก้เลข version ใน `package-lock.json` ด้วยมือ เพราะ `resolved` กับ `integrity` จะยังชี้ไป tarball เก่า

## แก้ skill

- 1 skill = 1 โฟลเดอร์ใน `skills/` มี `SKILL.md` ที่ขึ้นต้นด้วย frontmatter `name` (ตรงกับชื่อโฟลเดอร์) และ `description` (ขึ้นต้นด้วย "Use when ..." บอกแค่ว่าใช้ตอนไหน)
- รายละเอียดยาวๆ ไว้ใน `references/` เครื่องมือไว้ใน `scripts/`
- ทุกข้อเท็จจริงใน skill ต้องตรวจกับ source จริงแล้ว ถ้า repo เปลี่ยน (prop, route, schema, version) ให้แก้ skill ใน PR เดียวกัน
- ตรวจก่อน push:

```bash
npx skills add . --list
```
