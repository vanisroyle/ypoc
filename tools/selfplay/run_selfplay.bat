@echo off
rem Genera duelos CPU-CPU y destila ai_policy.json (self-play).
rem Requisitos: Godot 4.7 en PATH (o GODOT=...) y Python 3 en PATH.
rem Uso: run_selfplay.bat [partidas]   (por defecto 100)
setlocal
cd /d "%~dp0..\.."
if "%GODOT%"=="" set GODOT=godot
set GAMES=%1
if "%GAMES%"=="" set GAMES=100

"%GODOT%" --headless --path game -- --selfplay=%GAMES% --selfplay-out="PoC Data\selfplay.jsonl"
if errorlevel 1 (echo selfplay fallo & exit /b 1)
python tools\selfplay\train.py "PoC Data\selfplay.jsonl" -o "PoC Data\ai_policy.json"
if errorlevel 1 (echo entrenamiento fallo & exit /b 1)
echo ai_policy.json listo en "PoC Data" — el juego lo usa la proxima vez que arranque.
endlocal
