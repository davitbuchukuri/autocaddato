# deploy.ps1 — rebuild the AutoCAD plugin and copy it where AutoCAD loads it.
#
# Usage:  powershell -ExecutionPolicy Bypass -File .\deploy.ps1
#         (run from anywhere; paths are resolved relative to this script)
#
# After running, restart AutoCAD (or it picks up the new DLL on next launch).

$ErrorActionPreference = "Stop"

$repo     = $PSScriptRoot
$proj     = Join-Path $repo "autocad-plugin\AutoCAD.MCP.Plugin.csproj"
$outDir   = Join-Path $repo "autocad-plugin\bin\Release\net10.0-windows"
$bundle   = Join-Path $env:APPDATA "Autodesk\ApplicationPlugins\AutoCADMCP.bundle\Contents"
$desktop  = Join-Path ([Environment]::GetFolderPath("Desktop")) "AutoCAD-MCP-Plugin"

$files = @(
    "AutoCAD.MCP.Plugin.dll",
    "Newtonsoft.Json.dll",
    "AutoCAD.MCP.Plugin.deps.json"
)

Write-Host "[deploy] Building plugin (Release)..." -ForegroundColor Cyan
dotnet build $proj -c Release
if ($LASTEXITCODE -ne 0) { throw "Build failed (exit $LASTEXITCODE)." }

foreach ($dest in @($bundle, $desktop)) {
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    foreach ($f in $files) {
        Copy-Item (Join-Path $outDir $f) -Destination $dest -Force
    }
    Write-Host "[deploy] Copied to $dest" -ForegroundColor Green
}

Write-Host "[deploy] Done. Restart AutoCAD to load the new build." -ForegroundColor Cyan
