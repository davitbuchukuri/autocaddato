# CLAUDE.md — AutoCAD MCP Project

This file is loaded automatically by Claude Code at the start of every session in this
repo. It tells the agent what this project is and how to remember what it learns from the user.

## Language

**Respond in Georgian (ქართული) by default.** The day-to-day user is a coworker who speaks
Georgian. Write all explanations and chat in Georgian. Keep code, commands, file paths,
AutoCAD command names, and technical identifiers in their original form (Latin / English).
If the user writes in English, you may reply in English.

## What this project is

An MCP integration that lets Claude drive **Autodesk AutoCAD 2027** on this Windows machine.
Dato is building/extending the plugin and uses it for real CAD work and calculations.

Two cooperating pieces:

1. **MCP server** (Node.js / TypeScript) — `src/` → built to `dist/index.js`. Exposes ~45
   AutoCAD tools to MCP clients (Claude Code, Claude Desktop). Started by Claude via the
   registered `autocad` MCP server.
2. **AutoCAD plugin** (C# / .NET) — `autocad-plugin/`. Loaded into a running AutoCAD with
   `NETLOAD`; hosts an HTTP listener on `http://localhost:12345/` that the MCP server calls
   for "live" operations. Headless operations instead shell out to `accoreconsole.exe`.

### Key facts (this machine)
- AutoCAD version: **2027** (repo originally targeted 2026 — adapted).
- Plugin target framework: **net10.0-windows** (AutoCAD 2027 runs on .NET 10).
- Built plugin DLL: `autocad-plugin/bin/Release/net10.0-windows/AutoCAD.MCP.Plugin.dll`
- AutoCAD managed DLLs referenced from `C:\Program Files\Autodesk\AutoCAD 2027\`.
- accoreconsole: `C:\Program Files\Autodesk\AutoCAD 2027\accoreconsole.exe`
- Auth token (server ↔ plugin): `MCP_AUTOCAD_TOKEN=default-secret-token` (user env var).
- Config: `.env` at repo root.
- npm note: this machine has a TLS-intercepting proxy. Use `NODE_OPTIONS=--use-system-ca`
  (or `npm config set strict-ssl false`) if npm fails with `UNABLE_TO_VERIFY_LEAF_SIGNATURE`.

### Project layout
```
src/              MCP server (TypeScript)        →  dist/  (built JS)
autocad-plugin/   C# .NET plugin for AutoCAD
scripts/          Automation scripts (.scr, .lsp)
blocks/           Block library (.dwg) + index.json
semantic_cad/     Python semantic analysis pipeline
rules/            Architecture validation rules
docs/             Project documentation
memory/           Daily/long-term agent notes (see "Memory" below)
```

### Common commands
- Build server: `npm run build`  •  Run server: `npm start`
- Build plugin: `cd autocad-plugin && dotnet build -c Release`
- Load plugin in AutoCAD: run `NETLOAD`, pick the DLL above; wait for
  `[MCP] Server listening on http://localhost:12345/`.

## Memory — save what you learn from Dato (do this automatically)

Dato wants the agent to accumulate knowledge about *how he works* without being asked.
When you learn something durable, **write it down immediately** — don't keep "mental notes".

Save automatically (no need to ask) whenever Dato:
- explains a workflow or habit in AutoCAD (commands, layer conventions, block usage, units);
- shows a **calculation** he does and how (formula, inputs, assumptions, rounding);
- states a preference (naming, output format, drawing standards, what annoys him);
- corrects you, or you discover a project fact worth keeping (paths, versions, gotchas).

Where to write it:
- **`USER.md`** — facts about Dato and his preferences/standards.
- **`memory/YYYY-MM-DD.md`** — dated log of what happened / was learned that day.
- **`MEMORY.md`** — curated long-term distilled knowledge (review periodically).
- **This `CLAUDE.md`** — only for stable project/technical facts future sessions need.

At session start, read `USER.md`, `MEMORY.md`, and today's + yesterday's `memory/` notes
so you resume with full context.
