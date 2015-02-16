#!/bin/bash
# Copyright (C) 2014 paul@marrington.net, see GPL license
cd "$(cd $(dirname "$0"); pwd)"

if [ -d ".git" ]; then
  git pull
  ../roaster/update.sh
  exit
fi
install/install-usdlc2.sh