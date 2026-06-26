# KNOWLEDGE.md — შემაჯამებელი ცოდნა (მოკლედ)

> ერთ ფაილში მთელი ცოდნა ამ პროექტზე — რომ ნებისმიერმა ახალმა ადამიანმა (ან ახალმა
> Claude სესიამ) სწრაფად აიღოს კონტექსტი. დეტალები ცალკე ფაილებშია (README, memory/).

---

## 1. რა არის ეს

AutoCAD ↔ Claude ინტეგრაცია **MCP** (Model Context Protocol) გავლით.
Claude პირდაპირ მართავს გახსნილ AutoCAD-ს ~45 ხელსაწყოთი (create_line, get_layers,
query_entities და ა.შ.).

ორი რეჟიმი:
1. **Live Plugin** — .NET პლაგინი ჩატვირთულია AutoCAD-ში, საუბრობს HTTP-ით `localhost:12345`.
2. **Headless** — `accoreconsole.exe` უშვებს `.scr`/`.lsp` სკრიპტებს `.dwg` ფაილებზე (batch).

ნაგებობა:
```
src/             Node.js MCP სერვერი (TypeScript) → dist/index.js
autocad-plugin/  C# .NET პლაგინი AutoCAD-ისთვის
scripts/         ავტომატიზაციის სკრიპტები (.scr, .lsp)
memory/          რა ისწავლა აგენტმა (თარიღების მიხედვით)
```

---

## 2. ამ მანქანის თავისებურებები (მნიშვნელოვანი!)

- AutoCAD აქ არის **2027**, არა 2026. (ასევე გვაქვს 2018/2021.)
- AutoCAD 2027 → **.NET 10**. პლაგინი retarget-ებულია `net8.0` → **`net10.0-windows`**,
  csproj-ის HintPath-ები `AutoCAD 2026` → `AutoCAD 2027`.
- AutoCAD 2027 რეგისტრირდება როგორც **R26.0** (არა R27!) — autoloader bundle-ში
  `SeriesMin="R26.0"`, თორემ ჩუმად გამოეტოვება.
- **Python დაყენებული არ არის.** გამოთვლებისთვის → **Node.js** (`C:\Program Files\nodejs`, v24.16).
- TLS-ჩამჭრელი proxy/AV-ის გამო `npm install` ფეილდება (`UNABLE_TO_VERIFY_LEAF_SIGNATURE`).
  გამოსავალი: **`NODE_OPTIONS=--use-system-ca`**.

### ავტო-ჩატვირთვა (NETLOAD აღარ სჭირდება)
Bundle: `%APPDATA%\Autodesk\ApplicationPlugins\AutoCADMCP.bundle\` (PackageContents.xml +
Contents\ DLL-ებით). AutoCAD-ი ყოველ გაშვებაზე თვითონ ტვირთავს.
⚠️ პლაგინის გადაკომპილებისას **ხელახლა დააკოპირე** ახალი DLL bundle-ის Contents\-ში (კოპიოა, არა ლინკი).

### მარტივი გაშვება
Desktop shortcut **"AutoCAD + Claude"** (`Start-AutoCAD-Claude.bat`) — ხსნის AutoCAD 2027-ს
და უშვებს `claude --continue`-ს (აგრძელებს ბოლო საუბარს).

---

## 3. დაყენება ნულიდან

```bash
# 1. Node სერვერი
npm install            # საჭიროა NODE_OPTIONS=--use-system-ca
npm run build          # → dist/index.js

# 2. პლაგინი
cd autocad-plugin && dotnet build -c Release
# → bin/Release/net10.0-windows/AutoCAD.MCP.Plugin.dll

# 3. AutoCAD-ში: NETLOAD → აირჩიე DLL (ან bundle თვითონ ჩატვირთავს)
# 4. setx MCP_AUTOCAD_TOKEN "default-secret-token" (გადატვირთე AutoCAD)
# ელოდები: [MCP] Server listening on http://localhost:12345/
```

`.env` (არ აიტვირთება git-ში — `.gitignore`-შია):
```env
AUTOCAD_CONSOLE_PATH="C:\Program Files\Autodesk\AutoCAD 2027\accoreconsole.exe"
AUTOCAD_PLUGIN_URL="http://localhost:12345"
MCP_AUTOCAD_TOKEN="default-secret-token"
```

---

## 4. ხელსაწყოები (~45) — კატეგორიებად

- **გეომეტრია (10):** create_line/circle/arc/polyline/rectangle/ellipse/spline/hatch/mtext/text
- **მოთხოვნა/გაზომვა (6):** query_entities, get_entity_properties, measure_distance,
  measure_area, count_entities, get_drawing_extents
- **მოდიფიკაცია (9):** move/rotate/scale/copy/mirror/offset/erase_entities, change_layer/color
- **ბლოკები (5):** insert_block, list_blocks, list_available_blocks, explode_block, get/set_block_attribute
- **განზომილებები (6):** add_linear/aligned/radial_dimension, create_leader, create_table, update_text
- **ფენები (5):** get_layers, create/delete/set_current_layer, set_layer_properties
- **დოკუმენტი/ექსპორტი (6):** save_drawing, zoom_extents, undo, run_command, export_to_pdf/dxf
- **batch/გენერაცია (3):** execute_script_file, list_available_scripts, generate_house_plan

---

## 5. ფართების დათვლის workflow (სასარგებლო ფართები)

რეალური ამოცანა: გახსნილი შენობის (A8, A3, ბ3...) MText-ებიდან ბინების/კომერციულის/ოფისების
ფართების ამოღება და სტილიზებული Excel ცხრილის აწყობა Desktop-ზე.

**ნაბიჯები:**
1. `query_entities` (type=MText/Text ან ფენით) → დიდი output ავტომატურად ინახება tool-results `.txt`-ში.
2. Node სკრიპტით დაამუშავე ტექსტი (Python არ არის).
3. სტილიზებული Excel → **exceljs**
   (`C:/Users/Dato/AppData/Local/Temp/xlsxgen/node_modules/exceljs`, require აბსოლუტური path-ით).

**MText parsing-ის ხრიკები:**
- ტექსტში **ორმაგი** backslash-ებია (`bina\\P63.3`).
- ბინის ფართი: `{\C1;bina\PXX.X}` → regex `/bina\D*(\d+(?:\.\d+)?)/`.
- ფართის ლეიბლები `XX.X m2` → regex `/(\d+(?:\.\d+)?)\s*m2\b/`.

**სართულის ამოცნობა:** `#N` ნომრების Y-კოორდინატების კლასტერიზაცია ზოლებად (gap > 30000),
ცენტრების დალაგება კლებადობით (index 0 = ზედა სართული).

**მთავარი წესები (user-ის feedback-იდან):**
- აივნები ისე ჩაწერე, **როგორც ნახაზზე ნამდვილად აწერია** — პროპორციულად ნუ გაანაწილებ/გამოიგონებ.
  ბინებს თითო-თითო აქვს მითითებული; კომერციულ/ოფისებს ხშირად მხოლოდ **სართულის ჯამი** აწერია.
- სადარბაზო/კიბის უჯრედი და დამხმარე ფართები **არ შედის** სასარგებლო ფართში.
- ყოველთვის გადაამოწმე ნახაზის საკუთარ შემაჯამებელ ცხრილებთან (ხშირად DWG-ში უკვე წერია
  „sacxovrebeli farTi“, „aivnebi“ და ა.შ. — ეგ არის ავტორიტეტული რიცხვები).

---

## 6. Debugging ხრიკები

**პლაგინის ნამდვილი შეცდომის ნახვა** (MCP სერვერი მხოლოდ „status code 500“-ს აჩვენებს) —
პირდაპირ პლაგინს მიწერე:
```bash
curl -s -X POST http://localhost:12345/ \
  -H "Authorization: Bearer default-secret-token" \
  -H "Content-Type: application/json" \
  -d '{"Command":"count_entities","Args":{}}'
```

**ცნობილი ბაგი (გასწორებული):** `src/index.ts`-ი ხელსაწყოს სახელს PascalCase-ად
(`CountEntities`) აგზავნიდა, პლაგინი კი `.ToLower()`-ით snake_case case-ებზე ამოწმებს →
HTTP 500 „Unknown command“. Fix: გადაეგზავნოს ორიგინალი snake_case `name`.
პლაგინის გადაკომპილების შემდეგ → **Claude-ის გადატვირთვა** (MCP სერვერი ძველ `dist/index.js`-ს
ინახავს ჩატვირთვამდე).

**დიდი ნახაზები:** რეალური gen-plan-ი 72,561 entity-ით. timeout გაზრდილია 5s → 120s
(`AUTOCAD_PLUGIN_TIMEOUT_MS`).

---

## 7. ენა და სამუშაო სტილი

- **პასუხები ქართულად** (ყოველდღიური მომხმარებელი ქართულენოვანია).
- კოდი, ბრძანებები, ფაილების გზები, AutoCAD ბრძანებების სახელები — **ინგლისურად**.
- ახალი AutoCAD workflow/გამოთვლა/preference → ავტომატურად შეინახე `USER.md` / `memory/`-ში.
