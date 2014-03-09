#!/bin/bash 
# Copyright (C) 2013 paul@marrington.net, see /GPL for license
cd "$(cd $(dirname "$0"); pwd)"
../roaster/go.sh "$@"
