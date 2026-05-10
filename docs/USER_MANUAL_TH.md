# คู่มือการใช้งาน Paenia

Paenia คือแอป macOS สำหรับปรับแต่งสีธีมของ editor ตระกูล VS Code เช่น Cursor, Visual Studio Code, Antigravity, Trae, Windsurf, VSCodium, Kiro, Positron และ Code - OSS โดยเขียนค่าลง `settings.json` อย่างปลอดภัย มี live preview, preset, การแก้สีราย key, backup และ restore ในตัว

> คู่มือนี้อ้างอิงหน้าจอจากโฟลเดอร์ `images/` และโครงสร้างการทำงานจากซอร์สโค้ดของแอป

## ภาพรวมหน้าจอหลัก

![หน้าจอหลักโหมดมืด](../images/home/Screenshot%202569-05-09%20at%2021.26.18.png)

หน้าจอหลักแบ่งเป็น 4 ส่วน:

1. **Sidebar ซ้าย**: เลือก preset, สลับโหมด `Palette` / `Detailed`, และเลือกหมวดสี
2. **พื้นที่กลาง**: รายการสีที่แก้ได้ในหมวดปัจจุบัน
3. **Inspector ขวา**: live preview, palette swatches, รายละเอียดสีที่เลือก, ปุ่ม reset และปุ่ม `Save My Preset`
4. **Toolbar บน**: เลือก editor, backup, reload, settings และ `Apply`

แอปจะปรับ chrome ของตัวเองตาม preset ที่โหลดอยู่ เช่น preset สว่างจะทำให้ทั้ง UI เป็น light mode อัตโนมัติ

![หน้าจอหลักโหมดสว่าง](../images/home/Screenshot%202569-05-09%20at%2021.26.56.png)

## เริ่มใช้งานเร็ว

1. เปิด Paenia
2. เลือก editor จากเมนูด้านบน เช่น `Cursor`
3. เลือก preset จากกล่อง `PRESETS`
4. ปรับสีใน `Palette` หรือ `Detailed` หากต้องการ
5. กด `Apply`
6. ตรวจสอบ modal ยืนยัน แล้วกด `Apply ทันที`
7. ถ้า editor ยังไม่เปลี่ยนสี ให้ใช้คำสั่ง `Developer: Reload Window` หรือ `Reload Window` ใน editor นั้น

## เลือก Editor และ Target

เมนู editor ด้านบนใช้ทั้งสำหรับเลือก editor ที่กำลัง preview และเลือก editor ที่จะรับ theme ตอน Apply

![หน้า Apply Targets](../images/setting%20zone/Screenshot%202569-05-09%20at%2021.32.36.png)

สถานะของ target:

- `พร้อม`: มีไฟล์ `settings.json` แล้ว
- `พร้อมสร้าง`: มีโฟลเดอร์ `User` แล้ว แอปสามารถสร้าง `settings.json` ได้ตอน Apply
- `ติดตั้งแล้ว`: พบแอป แต่ยังอาจต้องเปิด editor อย่างน้อยหนึ่งครั้งก่อน
- `ไม่พร้อม`: ยังไม่พบ editor หรือ path ที่จำเป็น

กติกา Apply:

- `Cursor` จะได้รับ theme แบบเต็ม รวม `workbench.colorTheme`, `glass.theme.*`, `workbench.colorCustomizations` และ `editor.tokenColorCustomizations`
- editor อื่นจะได้รับเฉพาะ `workbench.colorCustomizations` และ `editor.tokenColorCustomizations` เพื่อไม่ไปเปลี่ยน theme หลักที่ผู้ใช้เลือกไว้เอง

## เลือก Preset

กดกล่อง preset ใน sidebar เพื่อเปิดรายการ preset ทั้งหมด

![Preset picker](../images/custom/Screenshot%202569-05-09%20at%2021.28.54.png)

ใน popover มีช่องค้นหาและ filter:

- `Minimal`: ชุดสีคัดพิเศษแนว earth tone
- `Dark`: preset โหมดมืด
- `Light`: preset โหมดสว่าง
- `My Presets`: preset ที่ผู้ใช้บันทึกเอง

เมื่อเลือก preset แอปจะโหลด palette ใหม่ทันที และ live preview ด้านขวาจะอัปเดตตามสีที่เลือก

## โหมด Palette

`Palette` ใช้แก้สีหลักของธีม เช่น `bg0`, `bg1`, `fg0`, `accent`, `blue`, `green`, `red`, `purple` การแก้สีในโหมดนี้กระทบหลาย workbench keys ที่อ้างอิงตัวแปรเดียวกัน

![Palette mode โทน Synthwave](../images/home/Screenshot%202569-05-09%20at%2021.27.21.png)

หมวดหลักใน Palette:

- `Surfaces`: พื้นหลัง editor, sidebar, panel, selection
- `Text`: สีตัวอักษรหลัก, รอง, muted, disabled
- `Accent & Interaction`: สี focus, hover, link, border
- `Syntax Colors`: สี token เช่น string, keyword, type, function
- `Git & State`: สีสถานะไฟล์ เช่น added, modified, deleted
- `Transparency`: overlay และสี alpha state

วิธีแก้สี:

1. เลือกหมวดจาก sidebar
2. คลิก row สีที่ต้องการ
3. พิมพ์ hex เช่น `#FF79C6` หรือใช้ Color Picker
4. ดูผลทันทีใน live preview
5. กด `Apply` เมื่อพร้อมเขียนลง editor

## โหมด Detailed

`Detailed` ใช้แก้ workbench color key รายตัว เช่น `titleBar.activeBackground`, `tab.activeBackground`, `gitDecoration.modifiedResourceForeground`

![Detailed mode](../images/custom/Screenshot%202569-05-09%20at%2021.31.09.png)

หมวดใน Detailed จะสร้างจาก keys ที่มีอยู่จริงใน theme เช่น:

- `Surfaces`
- `Sidebar & Activity`
- `Tabs & Title Bar`
- `Borders & Focus`
- `Lists, Menus & Selection`
- `Inputs & Widgets`
- `Editor Details`
- `Buttons & Toolbar`
- `Git Decorations`
- `Scrollbar`
- `Terminal`
- `Status Bar`
- `Links, Chat & Notices`
- `Other Workbench Colors`

เมื่อแก้สีราย key แอปจะถือเป็น `custom override` และแสดง badge `custom` ที่ row นั้น รวมถึงตัวนับ custom ใน header

![Detailed custom overrides](../images/custom/Screenshot%202569-05-09%20at%2021.37.36.png)

ใช้ Detailed เมื่อ:

- ต้องการปรับแค่สี tab/title bar โดยไม่เปลี่ยน palette ทั้งชุด
- ต้องการแก้สีเฉพาะ key ที่ preview ดูแล้วไม่พอดี
- ต้องการ override ค่าสีที่สร้างจาก palette

## ค้นหาสีและ key

ช่อง `Filter keys...` ด้านบนของพื้นที่กลางใช้ค้นหาเฉพาะในหมวดปัจจุบัน

ค้นหาได้จาก:

- ชื่อ key เช่น `tab`, `editor`, `gitDecoration`
- ชื่อที่อ่านง่าย เช่น `Title Bar Active Background`
- คำอธิบายภาษาไทยในบางหมวดของ Palette

ถ้าไม่มีผลลัพธ์ ให้ล้างช่องค้นหา หรือเปลี่ยนหมวดใน sidebar

## Live Preview และ Inspector

Inspector ด้านขวาแสดงผล preview ของ editor จากสีที่กำลังแก้ โดย preview ใช้ลำดับค่าสีดังนี้:

1. override ที่แก้ในหน้าจอ แต่ยังไม่ได้ Apply
2. สีที่ resolve จาก `theme.json`
3. สีจริงจาก `settings.json` ของ target ที่ active
4. fallback จาก palette
5. fallback literal ของแอป

ส่วน `PALETTE` แสดงสีหลักของธีมทั้งหมด ส่วน `INSPECTOR` แสดงรายละเอียดของ row ที่เลือก เช่น ชื่อสี, hex, key และสถานะว่าเป็น base palette หรือ derived/custom

## Reset สี

ด้านล่างของ Inspector มีปุ่ม:

- `Reset Group`: ล้างการแก้สีในหมวดปัจจุบัน
- `Reset All`: ล้าง override ทั้งหมด

ทั้งสองปุ่มจะมี modal ยืนยันก่อนล้างค่า หากไม่มี override ปุ่มจะถูก disable หรือผลลัพธ์จะแจ้งว่าไม่มีรายการให้ล้าง

## บันทึก Preset ของตัวเอง

กด `Save My Preset` เพื่อบันทึก palette ปัจจุบันเป็น preset ส่วนตัว

ขั้นตอน:

1. ปรับสีใน `Palette` หรือเลือก preset ที่ต้องการเป็นฐาน
2. กด `Save My Preset`
3. ตั้งชื่อ preset
4. กด `บันทึก`
5. preset จะไปอยู่ใน filter `My Presets`

หมายเหตุ: preset ส่วนตัวเก็บเฉพาะ palette snapshot ไม่ใช่การ override ราย key ทั้งหมด

## Apply Theme

กดปุ่ม `Apply` หรือใช้ `⌘S` เพื่อเขียนสีลง `settings.json`

ก่อนเขียนไฟล์ แอปจะเปิด modal ยืนยันและแสดง target ทั้งหมดที่จะถูก Apply พร้อม path ของแต่ละไฟล์

สิ่งที่เกิดขึ้นตอน Apply:

1. แอปเขียน `theme.json` เป็น source of truth
2. validate สีทั้งหมดว่าถูกต้องเป็น `#RRGGBB` หรือ `#RRGGBBAA`
3. backup `settings.json` ของ target ก่อนเขียน
4. render `workbench.colorCustomizations` และ `editor.tokenColorCustomizations`
5. patch ไฟล์ด้วย brace-balanced parser
6. ตรวจ bracket/brace balance ก่อนเขียนจริง
7. แสดง result modal ว่าสำเร็จ, สำเร็จบางส่วน หรือผิดพลาด

ถ้า Apply สำเร็จ แต่สีใน editor ยังไม่เปลี่ยน ให้ reload window ใน editor นั้น

## Backup ทันที

ปุ่ม backup ใน toolbar หรือ `⌘B` ใช้สร้าง snapshot ของ `settings.json` สำหรับ target ที่เลือกอยู่ โดยไม่ต้อง Apply

ใช้เมื่อ:

- ต้องการเก็บสถานะปัจจุบันก่อนทดลองปรับสี
- ต้องการ snapshot เพิ่มนอกเหนือจาก auto-backup ที่เกิดตอน Apply

## จัดการ Backup และ Restore

เปิด `Settings` แล้วเลือก `Backups`

![Original snapshots](../images/backup/Screenshot%202569-05-09%20at%2021.33.35.png)

มี backup 2 ประเภท:

1. **Original Snapshots**: snapshot อัตโนมัติครั้งแรกที่ Paenia เห็น `settings.json` ของ editor นั้น ใช้ rollback กลับสภาพก่อนใช้แอป และลบจาก UI ไม่ได้
2. **Regular Backups**: snapshot ปกติก่อน Apply หรือจากปุ่ม backup

![Regular backup list](../images/backup/Screenshot%202569-05-09%20at%2021.34.31.png)

ในรายการ backup:

- ปุ่มลูกศรย้อนกลับใช้ restore backup นั้น
- ปุ่มถังขยะใช้ลบ backup ถาวร
- แอปเก็บ backup สูงสุด 15 ไฟล์ต่อ editor
- ถ้ามีไฟล์เกิน จะมีปุ่ม `Prune now`

ข้อควรระวัง: การ restore จะเขียนทับ `settings.json` ปัจจุบัน ควรแน่ใจว่า backup ที่เลือกคือสถานะที่ต้องการ

## Settings

เปิด Settings ได้จากปุ่มเฟือง หรือ `⌘,`

หมวด Settings:

- `Apply Targets`: เลือก editor ที่จะรับ theme และตั้ง path
- `Backups`: ดู original snapshots, regular backups, restore และ prune
- `Storage`: ดูตำแหน่งไฟล์ที่ Paenia ใช้
- `Help & Support`: quick start, shortcut และ safety notes
- `About`: เวอร์ชันแอปและข้อมูลระบบ

### ตรวจสอบอัปเดต

หลังเปิดแอปประมาณ 1–2 วินาที แอปจะเช็ก release ล่าสุดจาก GitHub แบบเงียบ ๆ ถ้ามีเวอร์ชันใหม่กว่าที่ติดตั้งอยู่ จะมีกล่องโต้ตอบภาษาไทยให้เปิดหน้าดาวน์โหลด (หรือเลื่อน / เลือกไม่เตือนรุ่นนี้)

ใน `Settings > About` ที่กลุ่ม **อัปเดต** กด **ตรวจสอบอัปเดต** เพื่อเช็กทันทีด้วยตัวเอง แอปจะไม่ดาวน์โหลดหรือติดตั้งแทนคุณ — ต้องโหลด `.dmg` แล้วลากทับเอง

ต้องเชื่อมอินเทอร์เน็ตไปยัง `api.github.com` ขณะเช็ก

## Custom Editor และ Custom Path

ใน `Settings > Apply Targets` สามารถเพิ่ม editor เองได้ด้วย `เพิ่ม Editor เอง`

ข้อมูลที่ต้องใส่:

- ชื่อ editor
- path ของ `settings.json`

ตัวอย่าง path ที่เหมาะสม:

```text
/Users/<user>/Library/Application Support/<Editor Name>/User/settings.json
```

ระบบตรวจ path 3 ระดับ:

- `Path ใช้ได้ — ปลอดภัย`: ใช้งานได้
- `Path มีจุดน่าสงสัย`: ใช้ได้แต่ต้องยืนยัน เช่น ไฟล์ยังไม่มี, ไม่ลงท้ายด้วย `.json`, ไม่ตรงรูปแบบ `User/settings.json`
- `ไม่อนุญาตให้ใช้ path นี้`: ถูก block เช่น path ใน `/System/`, `/usr/`, `/Library/`, app bundle, framework

## ไฟล์ที่ Paenia ใช้

ไฟล์หลัก:

```text
~/Library/Application Support/Paenia/theme.json
```

โฟลเดอร์ backup:

```text
~/Library/Application Support/Paenia/Backups
~/Library/Application Support/Paenia/OriginalBackups
```

ตำแหน่งติดตั้งแอปตามเอกสารโปรเจกต์:

```text
~/Applications/Paenia.app
```

## Keyboard Shortcuts

| Shortcut | การทำงาน |
| --- | --- |
| `⌘S` | Apply theme |
| `⌘B` | Backup target ที่เลือก |
| `⌘R` | Reload จาก disk |
| `⌘,` | เปิด Settings |
| `⌥⌘I` | Toggle Inspector ตาม shortcut เดิมใน help |

หมายเหตุ: จากหน้าจอปัจจุบัน Inspector ถูกออกแบบให้แสดงอยู่ตลอดเพื่อให้เห็น preview ระหว่างแก้สี

## ความปลอดภัยของการเขียนไฟล์

Paenia ออกแบบให้ไม่เขียนไฟล์แบบเสี่ยง:

- ใช้ `theme.json` เป็น source of truth
- เขียน `theme.json` แบบ atomic
- backup ก่อนเขียน target ทุกครั้ง
- ถ้าเขียน target ไม่สำเร็จ backup ที่เพิ่งสร้างเพื่อ operation นั้นจะถูกทิ้ง ไม่ปะปนกับ backup ที่ valid
- ใช้ brace-balanced patcher แทน regex แบบง่าย
- ไม่เขียนไฟล์ถ้า bracket/brace ไม่สมดุล
- ไม่แตะ Cursor SQLite database
- editor ที่ไม่ใช่ Cursor จะไม่ถูกเขียน `glass.theme.*` และไม่ถูกเปลี่ยน `workbench.colorTheme`

## แก้ปัญหาที่พบบ่อย

### Apply สำเร็จแต่ editor ยังไม่เปลี่ยนสี

ให้เปิด command palette ใน editor แล้วรัน `Reload Window`

### Apply ไม่สำเร็จเพราะ settings.json เสียอยู่แล้ว

ผลลัพธ์ Apply จะแสดง target ที่มีปัญหา และถ้ามี backup ล่าสุดที่ valid จะมีปุ่มกู้คืนให้ กู้คืนแล้วลอง Apply ใหม่

### เลือก target ไม่ได้

ตรวจว่า editor ถูกติดตั้งแล้วหรือยัง และควรเปิด editor อย่างน้อยหนึ่งครั้งเพื่อให้สร้างโฟลเดอร์ `User`

### Custom path ถูก block

แอปไม่อนุญาตให้เขียน path ระบบ เช่น `/System/`, `/usr/`, `/Library/`, `/private/var/` หรือไฟล์ภายใน `.app`, `.bundle`, `.framework`

### อยากกลับไปก่อนใช้ Paenia

ไปที่ `Settings > Backups > Original Snapshots` แล้วกด `Restore Original` ของ editor ที่ต้องการ

## Workflow แนะนำ

สำหรับผู้ใช้ทั่วไป:

1. เลือก preset ที่ใกล้เคียง
2. ปรับสีหลักใน `Palette`
3. ดู live preview
4. กด `Save My Preset`
5. กด `Apply`

สำหรับผู้ใช้ที่ต้องการปรับละเอียด:

1. เลือก preset เป็นฐาน
2. สลับเป็น `Detailed`
3. ปรับเฉพาะหมวดที่ต้องการ เช่น `Tabs & Title Bar`
4. ใช้ `Filter keys...` หา key เฉพาะ
5. ตรวจ badge `custom`
6. Apply และ reload editor

สำหรับการทดลองหลายแบบ:

1. กด backup ก่อนเริ่ม
2. ลอง preset/สีหลายชุด
3. บันทึก preset ที่ชอบ
4. ถ้าไม่พอใจ ให้ restore backup หรือ restore original
