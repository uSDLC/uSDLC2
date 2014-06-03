@echo off
cd "%HOMEPATH%"
mkdir bin 2>nul
copy /Y "%~dp0\*.*" bin >nul
PATH=%HOMEPATH%\bin;%PATH%
mkdir uSDLC2 2>nul
cd uSDLC2
curl -sOL https://raw.github.com/uSDLC/uSDLC2/master/install/install-usdlc2.sh
bash install-usdlc2.sh
