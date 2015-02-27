#!/bin/bash 
# Copyright (C) 2014 paul@marrington.net, see /GPL for license
echo "Usage port=9009 config=[debug|production] debug=false user=Guest"
cd "$(cd $(dirname "$0"); pwd)"
../roaster/go.sh server "$@"
