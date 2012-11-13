#!/bin/bash
export uSDLC_base=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd) 
export NODE_PATH=$uSDLC_base/server:$uSDLC_base/core/node/lib/node_modules
export PATH=$uSDLC_base/core/node/bin:$PATH

cd $uSDLC_base

if [! -d core/node ]
	release/install-node-on-unix.sh
	release/update-node-modules.sh
fi

node -e "require('coffee-script/lib/coffee-script/command').run()" src/server/server.coffee