#!/bin/bash
echo "generating keyfile .."
KEYFILE="keyfile" # keyfile    or:  /app/keyfiles/keyfile
/usr/bin/openssl rand -base64 741 > $KEYFILE
chmod 600 $KEYFILE
echo "done"
