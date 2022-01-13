@echo off

:start
set size1=%~z1
set size2=%~z2

if size1 LSS size2 goto del2
goto del1

:del1
echo File %2 is smaller, delete %1 and rename %2 to %3
del %1
if not %2 == %3 ren %2 %3
goto end

:del2
echo File %1 is smaller, delete %2 and rename %1 to %3
del %2
if not %1 == %3 ren %1 %3
goto end

:end