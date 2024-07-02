@echo off

set myType=%~x0

cd /d %~dp0
:start
set filename=%~dpn1
if "" == "%filename%" goto end

title Optimizing %filename%...

set /A origSize=%~z1 / 1024

rem ///////// PngOptimizer

echo.
echo Optimizing PNG using PngOptimizer...
title Optimizing %filename%... by PngOptimizer...
PngOptimizerCL.exe -file:"%filename%.png"

rem ///////// OptiPNG

echo.
echo Optimizing PNG using OptiPNG...
title Optimizing %filename%... by OptiPNG...
optipng.exe -o7 -zm1-9 "%filename%.png"

rem ///////// ZopfliPNG

echo.
echo Compressing PNG using Zopfli...
title Optimizing %filename%... by Zopfli...
zopflipng.exe -y -m --lossy_transparent --lossy_8bit --iterations=15 --filters=01234mepb "%filename%.png" "%filename%.png"

set /A newSize=%~z1 / 1024

echo Compressed file %~nx1 from %origSize%kB to %newSize%kB

rem ///////// Next file...

echo.
shift
echo.
echo -----------------------------------------------
goto start

rem ///////// END of Functions

:end

title Optimizing %filename%... DONE!
if [.cmd] == [%myType%] pause
