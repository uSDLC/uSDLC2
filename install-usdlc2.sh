#!/bin/bash
# Copyright (C) 2012,13 paul@marrington.net, see GPL license

parent=${1:-.}
cd $parent
echo "Download roaster installation script"
curl -sOL https://raw.github.com/uSDLC/roaster/master/install-roaster.sh
chmod +x install-roaster.sh
./install-roaster.sh
./install-roaster.sh . uSDLC2
cat > uSDLC2.sh << EOF
#bin/bash
'$(pwd)/uSDLC2/go.sh' server
EOF
echo "Just run this script again to upgrade system"
chmod +x uSDLC2.sh
echo $(pwd)/uSDLC2.sh
$(pwd)/uSDLC2.sh
#!/bin/bash
# Copyright (C) 2012,13 paul@marrington.net, see GPL license

parent=${1:-.}
cd $parent
echo "Download roaster installation script"
curl -sOL https://raw.github.com/uSDLC/roaster/master/install-roaster.sh
chmod +x install-roaster.sh
./install-roaster.sh
./install-roaster.sh . uSDLC2