#!/bin/bash

waitFor(){
  HOST=$1
  echo "waiting for $HOST:"
  until $(curl --output /dev/null --silent --head --fail http://${HOST}); do
    printf '.'
    sleep 5
  done
}

waitFor www.google.de
echo "ok"
