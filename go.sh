#!/bin/bash 
# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
cd `dirname "${BASH_SOURCE[0]}"`
if [ -f ext/roaster ]; then
    local/roaster.sh "$@"
else
    ../roaster/go.sh "$@"
fi
#!/bin/bash 
# Copyright (C) 2013 paul@marrington.net, see uSDLC2/GPL for license
cd `dirname "${BASH_SOURCE[0]}"`
if [ -f ext/roaster ]; then
    local/roaster.sh "$@"
else
    ../roaster/go.sh "$@"
fi