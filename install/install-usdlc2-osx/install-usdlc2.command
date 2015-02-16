#!/bin/bash
# Copyright (C) 2014 paul@marrington.net, see GPL license
cd ~
mkdir uSDLC2 2>/dev/null
cd uSDLC2
curl -sOL https://raw.github.com/uSDLC/uSDLC2/master/install/install-usdlc2.sh
chmod +x install-usdlc2.sh
./install-usdlc2.sh
