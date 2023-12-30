@echo off

REM @param %1 = BAK file to compress to 7zip
REM @param %* = Additional file names to process 

:start
title Compressing file %~n1...
echo Compressing file %~n1...

IF NOT EXIST "C:\Program Files\WinRAR\Rar.exe" echo Could not find WinRAR compressor. Please install WinRAR to C:\Program Files\WinRar to automatically compress the backup.
rem -dw  = securely erase original file
IF EXIST "C:\Program Files\WinRAR\Rar.exe" "C:\Program Files\WinRAR\Rar.exe" a -m5 -md1g -ri1 -s -t -tl -dw -y "%~dpn1.rar" "%~dpnx1"

if [] == [%2] goto done
shift
goto start

:done
echo Done
echo.
echo.
echo ------------------------------------------------------
echo.
pause >NUL
