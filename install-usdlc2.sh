#!/bin/bash
# Copyright (C) 2012,13 paul@marrington.net, see GPL license

parent=${1:-.}
cd $parent
echo "Download roaster installation script"
curl -sOL https://raw.github.com/uSDLC/roaster/master/install-roaster.sh
chmod +x install-roaster.sh
./install-roaster.sh
./install-roaster.sh . uSDLC2
#!/bin/bash
# Copyright (C) 2012,13 paul@marrington.net, see GPL license

parent=${1:-.}
cd $parent
echo "Download roaster installation script"
curl -sOL https://raw.github.com/uSDLC/roaster/master/install-roaster.sh
chmod +x install-roaster.sh
./install-roaster.sh
./install-roaster.sh . uSDLC2
#!/bin/bash
# Copyright (C) 2012,13 paul@marrington.net, see GPL license

parent=${1:-.}
cd $parent
echo "Download roaster installation script"
curl -sOL https://raw.github.com/uSDLC/roaster/legacy/install-roaster.sh
chmod +x install-roaster.sh
./install-roaster.sh
./install-roaster.sh . uSDLC2
