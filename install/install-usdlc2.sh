#!/bin/bash
# Copyright (C) 2012,14 paul@marrington.net, see GPL license
cd ~
mkdir uSDLC2 2>/dev/null
cd uSDLC2

echo "Download roaster installation script"
ins=https://raw.github.com/uSDLC/roaster/master/install/install-roaster.sh
if hash curl 2>/dev/null; then
  curl -sOL $ins
else
  wget -N $ins
fi
chmod +x install-roaster.sh
./install-roaster.sh
./install-roaster.sh . uSDLC2

pwd=$(pwd)
if [ "$pwd" = "/" ]; then
  pwd=""
fi

function bash() {
  cat > uSDLC2.sh << EOF
  #bin/bash
  '$pwd/uSDLC2/go.sh' server
EOF
  chmod +x uSDLC2.sh
}

function cmd() {
  cat > uSDLC2.bat << EOF
  @echo off
  PATH %HOMEPATH%\msys-bin;%PATH%
  bash /uSDLC2/uSDLC2/server.sh
EOF
}

function gnome() {
if hash gnome-session 2>/dev/null ||
   hash gnome-about 2>/dev/null ||
   hash gnome-panel 2>/dev/null
then
cat > $HOME/Desktop/uSDLC2.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=uSDLC2
Comment=Unify the Software Development Lifecycle
Exec=$HOME/uSDLC2/uSDLC2.sh
Icon=utilities-terminal
Terminal=true
StartupNotify=false
GenericName=uSDLC2
EOF
fi
}

os=$(uname)
echo $os
case "$os" in
  Darwin)
    bash
    mv uSDLC2.sh uSDLC2.command
    cp uSDLC2.command ../Desktop
    ;;
  MINGW32*)
    cmd
    cp uSDLC2.bat ../Desktop
    ;;
  *)
    bash
    cp uSDLC2.sh ../Desktop
    gnome
    ;;
esac
echo "Just run this script again to upgrade system"
echo
echo "The command below will start the server."
echo
echo "The first time a client is loaded there will be a delay for further libraries"
echo
echo $pwd/uSDLC2.sh
read -p "Start server [Enter]..."
$pwd/uSDLC2.sh