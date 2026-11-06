# Starts the Firebase emulators, seeds demo data and runs the app in Chrome.
# Usage (from the repo root):  powershell -ExecutionPolicy Bypass -File tool\dev.ps1
# Requires: Flutter, Node.js, firebase-tools (npm i -g firebase-tools), Java 21+.
param([string]$JavaHome = $env:JAVA_HOME)

if ($JavaHome) { $env:JAVA_HOME = $JavaHome; $env:Path = "$JavaHome\bin;$env:Path" }

Write-Host "Starting Firebase emulators (Auth :9099, Firestore :8080, UI :4000)..."
$emu = Start-Process -PassThru -WindowStyle Minimized firebase -ArgumentList "emulators:start","--project","demo-mtalchemy","--only","auth,firestore"

for ($i = 0; $i -lt 60; $i++) {
  try { Invoke-WebRequest -UseBasicParsing http://127.0.0.1:8080 -TimeoutSec 2 | Out-Null; break } catch { Start-Sleep 2 }
}

Push-Location firebase_seed
if (-not (Test-Path node_modules)) { npm install --no-audit --no-fund }
node seed.js --emulator
Pop-Location

Push-Location payments_server
if (-not (Test-Path node_modules)) { npm install --no-audit --no-fund }
if (Test-Path .env) { Start-Process -WindowStyle Minimized node -ArgumentList "--env-file=.env","server.js" }
Pop-Location

$defines = @()
if (Test-Path config\app_env.json) { $defines += "--dart-define-from-file=config/app_env.json" }
flutter run -d chrome @defines
