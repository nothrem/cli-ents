@echo off

set myType=%~x0

cd /d %~dp0
:start
set filename=%~dpn1
if "" == "%filename%" goto end

title Optimizing %filename%...
echo.
echo Converting %filename%
echo.

rem ///////// PngOptimizer

echo.
echo Optimizing original file...
PngOptimizerCL.exe -file:"%filename%.png"

rem ///////// APNGASM (Animated PNG)

rem filename for apngasm must end with number -> create copy for conversion ending with number
title Optimizing %filename%... Preparing fake animation
echo Creating fake animation sequence...
copy "%filename%.png" "%filename%.tmp01.png"

echo.
echo Converting file into animation...
apngasm.exe "%filename%.anim.png" "%filename%.tmp01.png"
del "%filename%.tmp01.png"

rem ///////// APNGOPT

title Optimizing %filename%... Optimizing animated file
echo.
echo Optimizing animated file...
apngopt.exe "%filename%.anim.png" "%filename%.opt.png"

title Optimizing %filename%...
echo.
echo Finilizing converted images...
title Optimizing %filename%... Using PngOptimizer on original file
PngOptimizerCL.exe -file:"%filename%.anim.png"
title Optimizing %filename%... Using PngOptimized on animated file
PngOptimizerCL.exe -file:"%filename%.opt.png"

call :smaller "%filename%.anim.png" "%filename%.opt.png" "%filename%.anim.png"

rem ///////// OptiPNG

echo.
echo Optimizing PNG using OptiPNG...
title Optimizing %filename%... Trying OptiPNG on original file
optipng.exe -o7 -zm1-9 "%filename%.png"
title Optimizing %filename%... Trying OptiPNG on animated file
optipng.exe -o7 -zm1-9 "%filename%.anim.png"

rem ///////// ZopfliPNG

echo.
echo Compressing PNG using Zopfli...
title Optimizing %filename%... Trying Zopfli on original file
zopflipng.exe -y -m --lossy_transparent --lossy_8bit --iterations=15 --filters=01234mepb "%filename%.png" "%filename%.png"
title Optimizing %filename%... Trying Zopfli on animated file
zopflipng.exe -y -m --lossy_transparent --lossy_8bit --iterations=15 --filters=01234mepb "%filename%.anim.png" "%filename%.anim.png"

call :smaller "%filename%.png" "%filename%.anim.png" "%filename%.png"

rem ///////// Next file...

echo.
shift
echo.
echo -----------------------------------------------
goto start
goto end

rem ///////// Functions
:smaller
set size1=%~z1
set size2=%~z2

if size1 LSS size2 goto del2
goto del1

:del1
echo File %2 is smaller, delete %1 and rename %2 to %3
del %1
if not %2 == %3 ren %2 %3
goto :EOF

:del2
echo File %1 is smaller, delete %2 and rename %1 to %3
del %2
if not %1 == %3 ren %1 %3
goto :EOF

rem ///////// END of Functions

:end
title Optimizing %filename%... DONE!
if [.cmd] == [%myType%] pause
