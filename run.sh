#!/bin/bash

if [ "$1" = 'mongod' ]; then
  echo "starting mongod.sh .. "
  /app/mongod.sh
else
  echo "starting mongos.sh .."
  /app/mongos.sh
fi
