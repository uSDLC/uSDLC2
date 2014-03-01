#!/bin/bash
# Copyright (C) 2012,13 paul@marrington.net, see GPL license

parent=${1:-.}
cd $parent
echo "Download roaster installation script"
if hash curl 2>/dev/null; then
  curl -sOL https://raw.github.com/uSDLC/roaster/master/install-roaster.sh
else
  wget -N https://raw.github.com/uSDLC/roaster/master/install-roaster.sh
fi
chmod +x install-roaster.sh
./install-roaster.sh
./install-roaster.sh . uSDLC2

cat > uSDLC2.sh << EOF
#bin/bash
'$(pwd)/uSDLC2/go.sh' server
EOF
chmod +x uSDLC2.sh

echo "Just run this script again to upgrade system"
echo
echo "The command below will start the server."
echo
echo "The first time a client is loaded there will be a delay for further libraries"
echo
echo $(pwd)/uSDLC2.sh
read -p "Start server [Enter]..."
$(pwd)/uSDLC2.sh
