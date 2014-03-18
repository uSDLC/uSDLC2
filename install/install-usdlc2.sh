#!/bin/bash
# Copyright (C) 2012,14 paul@marrington.net, see GPL license
parent=~/uSDLC2
mkdir $parent 2>/dev/null
cd $parent

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
cat > uSDLC2.sh << EOF
#bin/bash
'$pwd/uSDLC2/go.sh' server
EOF
chmod +x uSDLC2.sh
cat > uSDLC2.bat << EOF
@echo off
PATH=%~dp0\bin;%PATH%
bash /uSDLC2/server.sh
EOF

echo "Just run this script again to upgrade system"
echo
echo "The command below will start the server."
echo
echo "The first time a client is loaded there will be a delay for further libraries"
echo
echo $pwd/uSDLC2.sh
read -p "Start server [Enter]..."
$pwd/uSDLC2.sh
