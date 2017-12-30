@echo off
setlocal
SET srcdir=%1
SET pcretest=%2
echo Starting runtest.bat
call %srcdir%\RunTest.Bat 1 2 3 8 13 14
if errorlevel 1 exit /b 1
echo RunTest.bat tests successfully completed
