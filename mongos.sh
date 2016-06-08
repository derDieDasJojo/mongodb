#!/bin/bash
set -x
MONGO_LOG="/var/log/mongodb/mongod.log"
MONGO="/usr/bin/mongo"
MONGOS="/usr/bin/mongos"
STACK_NAME=$(echo $HOSTNAME | cut -f1 -d_)
SERVICE_NAME=$(echo $HOSTNAME | cut -f2 -d_)
MONGO_MASTER=${STACK_NAME}_${MONGO_MASTER_NAME}_${MONGO_MASTER_ID}
DBNAME=$STACK_NAME
BACKGROUND = --fork --logpath $MONGO_LOG
MONGO_CONFIG_IPS=$(getent hosts mongo-config | cut -f1 -d\ | tr '\n' ',' | sed 's/\,/\:27017\,/g')
MONGO_CONFIG_IPS=${MONGO_CONFIG_IPS:0:-1}	#remove , at the end

echo "MONGO_CONFIG_IPS: $MONGO_CONFIG_IPS"

waitFor(){
  WAIT_HOST=$1
  WAIT_PORT=$2
  echo "waiting for $WAIT_HOST:$WAIT_PORT to come up .. "
  while ! echo exit | /bin/nc -zv $WAIT_HOST $WAIT_PORT; do sleep 5; done
  echo "Service $WAIT_HOST:$WAIT_PORT reached !"
}
waitFor $MONGO_MASTER 27017 

#start mongos
#$MONGOS $BACKGROUND --configdb ${MONGO_CONFIG_IPS}
#sleep 30

$MONGOS --configdb ${MONGO_CONFIG}:27017 --config /etc/mongos.conf

#$MONGO admin --eval "clusteradminpassword=\"${CLUSTER_ADMIN_PASS}\", adminuser=\"${DB_ADMIN_USER}\", adminpassword=\"${DB_ADMIN_PASS}\"" app/mongo-router-setup.js
#$MONGO admin --eval "clusteradminpassword=\"${CLUSTER_ADMIN_PASS}\", adminuser=\"${DB_ADMIN_USER}\", adminpassword=\"${DB_ADMIN_PASS}\"" app/mongo-router-setup.js
#tailf /dev/null

