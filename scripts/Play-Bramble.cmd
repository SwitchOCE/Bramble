@echo off
rem Play-Bramble: unpacks the newest Bramble build in your Downloads folder and starts it.
rem New builds arrive in Downloads as Bramble-windows-*.zip. This file can live anywhere.
rem It deletes two things only: %USERPROFILE%\Bramble\current (the build it unpacked last) and,
rem once a build is unpacked and checked, the Bramble-windows-*.zip files in Downloads.
setlocal
set "DL=%USERPROFILE%\Downloads"
set "ROOT=%USERPROFILE%\Bramble"
set "DEST=%ROOT%\current"
set "MARK=%ROOT%\installed.txt"

set "NEWEST="
for /f "delims=" %%F in ('dir /b /a-d /o-d "%DL%\Bramble-windows-*.zip" 2^>nul') do if not defined NEWEST set "NEWEST=%%F"
if not defined NEWEST goto run

set "HAVE="
if exist "%MARK%" set /p HAVE=<"%MARK%"
if /i "%HAVE%"=="%NEWEST%" if exist "%DEST%\bramble.exe" goto run

echo Unpacking %NEWEST% ...
if exist "%DEST%" rmdir /s /q "%DEST%"
if exist "%DEST%" goto failed
mkdir "%DEST%"
"%SystemRoot%\System32\tar.exe" -xf "%DL%\%NEWEST%" -C "%DEST%" --strip-components=1
if errorlevel 1 goto failed
if not exist "%DEST%\bramble.exe" goto failed
>"%MARK%" echo %NEWEST%
del /q "%DL%\Bramble-windows-*.zip"

:run
if not exist "%DEST%\bramble.exe" goto none
start "" "%DEST%\bramble.exe"
exit /b 0

:none
echo No Bramble build found. Looked for Bramble-windows-*.zip in %DL%
pause
exit /b 1

:failed
echo Could not unpack %DL%\%NEWEST%
echo If Bramble is still running, close it and try again.
pause
exit /b 1
