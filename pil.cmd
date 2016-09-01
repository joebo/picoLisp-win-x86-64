@echo off

SET libpath=%~dp0
CALL SET libpath=%libpath:\=/%


REM set KILLPIL=1
if defined KILLPIL taskkill /f /im picolisp.exe & taskkill /f /im ptycon

start %~dp0bin\ntctty.exe -e /??/%~dp0bin\ptycon -e /??/%~dp0bin\picolisp.exe %libpath%lib.l @ext.l @win.l @lib/debug.l %* +
