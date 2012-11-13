#!/bin/bash

##################################################
# change this as new versions of node are released
##################################################
nodeVersion=v0.8.14

################################################
# Now we download the correct version of node-js
################################################
cd core

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
rm -R node
mv $fileName/* core/node
rm -r $fileName
