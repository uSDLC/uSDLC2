#!/bin/bash

####################################################
# Install where commanded or to the default location
####################################################
base = $1
: ${base:="~/uSDLC2"}
echo "Installing uSDLC2 to '$base' (move it afterwards if you like)"
###############################
# Set up our target directories
###############################
core=$base/core
mkdir -p $core 2>/dev/null

##########################################################################
# First is uSDLC2 as it includes scripts needed to finish the installation
##########################################################################
curl -OL https://github.com/uSDLC/uSDLC2/archive/master.zip
unzip -q master.zip
rm master.zip
rsync -qrulpt uSDLC-master $base
rm -rf uSDLC-master

################################################################
# Now we can run packages stuff to install Node and node-modules
################################################################
cd $base
./go.sh