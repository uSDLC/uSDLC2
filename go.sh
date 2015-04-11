#!/bin/bash 
# Copyright (C) 2013-5 paul@marrington.net, see /GPL for license
cd "$(cd $(dirname "$0"); pwd)"
cl=${@:-server}
../roaster/go.sh "$cl"
