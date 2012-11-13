#!/bin/bash

##################################################
# change this as new versions of node are released
##################################################
nodeVersion=v0.8.14

###############################################
# enforce a target directory to reduce surprise
###############################################
if [ $# -lt 1 ]
then
	echo "Usage: $0 target-directory for uSDLC2"
	exit
fi
###############################
# Set up our target directories
###############################
base=$1
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
release/install-node-on-unix.sh
release/update-node-modules.sh

################################################
# Now we download the correct version of node-js
################################################

os="`uname`-`uname -m`"
case $os in
	Darwin-x86_64) os=darwin-x64 ;;
	Darwin-i386) os=darwin-x86 ;;
	Linux-x86-64) os=linux-x64 ;;
	Linux-i386) os=linux-x86 ;;
	*) echo "Unknown OS version - '$os'"
	   echo "Compile from source at 'http://nodejs.org/dist/$nodeVersion/node-$nodeVersion.tar.gz'"
	   exit
esac
fileName=node-$nodeVersion-$os

exit
curl -OL http://nodejs.org/dist/v0.8.14/$fileName.tar.gz
tar -xzf $fileName.tar.gz
rm $fileName.tar.gz
rm -R $core/$node
mv $fileName $core/$node

#########################################################################
# Next is uSDLC2 as it includes scripts needed to finish the installation
#########################################################################
curl -OL https://github.com/uSDLC/uSDLC2/archive/master.zip
