# Runs the game with a fresh import and keeps a log (game.log) you can send me if anything breaks.
# Usage (from this folder):   .\run_game.ps1
$godotDir = "C:\Users\fawaz\Desktop\Games\godot"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Host "Importing project (registers new scripts)..."
& "$godotDir\Godot_v4.3-stable_win64.exe" --headless --import --path $here | Out-Null
Write-Host "Starting game. Errors are saved to game.log"
& "$godotDir\Godot_v4.3-stable_win64_console.exe" --path $here 2>&1 | Tee-Object -FilePath "$here\game.log"
