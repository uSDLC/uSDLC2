#!/bin/bash
echo "Copyright (C) 2012,13 Paul Marrington (paul@marrington.net), see uSDLC2/GPL for license"

# The go script is in the root directory of uSDLC2
export uSDLC_base=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)
# node require statements will look here
export NODE_PATH=.:$uSDLC_base/server:$uSDLC_base/ext/node_modules
# add scripts and node itself to the path for convenience
export PATH=$uSDLC_base/bin:$uSDLC_base/ext/node/bin:$PATH

# uSDLC expects it to be put in a directory of projects. We start in that directory
cd "$uSDLC_base"
cd ..

# Is this a first-time run - as will happent after install-usdlc-on-nnnn.sh is run
if [ ! -d ext/node ]; then
	echo "First time only install of node.js"
	# fetch a specific version of node
   update-node-on-unix
	# fetch all the node modules uSDLC relies on
	update
fi

echo "usage: go server|debug|update|npm|coffee|node-inspector ..."

if [ $# -lt 1 ]; then
  # no command line options runs a production server
  server
else
  # otherwise run node or one of the scripts from uSDLC2/bin
  $@
fi