# Builds the Android APK on Windows.  Needs: Godot 4.3 (with export templates installed: Editor > Manage Export
# Templates), Android Studio (for the Android SDK) and a JDK 17.
#   .\build_android.ps1 -Godot "C:\Tools\Godot_v4.3-stable_win64.exe"
# The easy alternative: let GitHub build it for you (Actions tab -> "Android APK" -> download the artifact).
param(
    [string]$Godot = "godot",
    [string]$Sdk = "$env:LOCALAPPDATA\Android\Sdk",
    [string]$Jdk = $env:JAVA_HOME
)
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
if (-not (Test-Path $Sdk)) { throw "Android SDK not found at $Sdk. Install Android Studio or pass -Sdk <path>." }
if (-not $Jdk) { throw "Set JAVA_HOME to a JDK 17 or pass -Jdk <path>." }
$key = Join-Path $env:USERPROFILE "riyadhkids-debug.keystore"
if (-not (Test-Path $key)) {
    & "$Jdk\bin\keytool.exe" -genkeypair -keystore $key -alias androiddebugkey -keyalg RSA -keysize 2048 -validity 10000 `
        -storepass android -keypass android -dname "CN=Android Debug,O=Android,C=US"
}
$cfgDir = Join-Path $env:APPDATA "Godot"
New-Item -ItemType Directory -Force $cfgDir | Out-Null
$cfg = Join-Path $cfgDir "editor_settings-4.3.tres"
if (-not (Test-Path $cfg)) {
    $q = { param($p) $p.Replace('\', '/') }
    @"
[gd_resource type="EditorSettings" format=3]

[resource]
export/android/android_sdk_path = "$(& $q $Sdk)"
export/android/java_sdk_path = "$(& $q $Jdk)"
export/android/debug_keystore = "$(& $q $key)"
export/android/debug_keystore_user = "androiddebugkey"
export/android/debug_keystore_pass = "android"
"@ | Set-Content $cfg -Encoding UTF8
    Write-Host "Wrote Godot editor settings: $cfg"
}
New-Item -ItemType Directory -Force build | Out-Null
& $Godot --headless --path . --import
& $Godot --headless --path . --export-debug "Android" build\RiyadhKids-debug.apk
if ($LASTEXITCODE -ne 0) { throw "Export failed (see the messages above)." }
Write-Host "Done: build\RiyadhKids-debug.apk  - copy it to your phone and open it (allow 'install unknown apps')."
