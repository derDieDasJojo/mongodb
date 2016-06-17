#!/bin/bash
set -x
# initialize variables
MONGO_LOG="/var/log/mongodb/mongod.log"
MONGO="/usr/bin/mongo"
MONGOS="/usr/bin/mongos"
STACK_NAME=$(echo $HOSTNAME | cut -f1 -d_)
SERVICE_NAME=$(echo $HOSTNAME | cut -f2 -d_)
MONGO_MASTER=${STACK_NAME}_${MONGO_MASTER_NAME}_${MONGO_MASTER_ID}
DBNAME=$STACK_NAME
BACKGROUND="--fork --logpath $MONGO_LOG"


# get ip of host 
# 1) get ips adresses. 1 per line 2)replace linefeed with "," 3) replace "," with ":27017," 4) remove last ","
MONGO_CONFIG_IPS=$(getent hosts mongo-config | cut -f1 -d\ | tr '\n' ',' | sed 's/\,/\:27017\,/g')
MONGO_CONFIG_IPS=${MONGO_CONFIG_IPS:0:-1}	#remove , at the end

echo "MONGO_CONFIG_IPS: $MONGO_CONFIG_IPS"

# function: wait for service. waits for TCP service 
# param 1: Host
# param 2: Port
waitFor(){
  WAIT_HOST=$1
  WAIT_PORT=$2
  echo "waiting for $WAIT_HOST:$WAIT_PORT to come up .. "
  while ! echo exit | /bin/nc -zv $WAIT_HOST $WAIT_PORT; do sleep 5; done
  echo "Service $WAIT_HOST:$WAIT_PORT reached !"
}

# wait for mongo-master
waitFor $MONGO_MASTER 27017 

# start mongos router
$MONGOS $BACKGROUND --configdb ${MONGO_CONFIG_IPS} --config /etc/mongos.conf -vvvvv

# wait for mongos router
waitFor localhost 27017 

# add admin accounts
$MONGO admin --eval "clusteradminpassword=\"${CLUSTER_ADMIN_PASS}\", adminuser=\"${DB_ADMIN_USER}\", adminpassword=\"${DB_ADMIN_PASS}\"" app/createClusterAdmin.js
$MONGO -u "clusterAdmin" -p "${CLUSTER_ADMIN_PASS}" --authenticationDatabase=admin $DBNAME --eval "clusteradminpassword=\"${CLUSTER_ADMIN_PASS}\", adminuser=\"${DB_ADMIN_USER}\", adminpassword=\"${DB_ADMIN_PASS}\"" app/createAdmin.js

# show logs in console
tailf /var/log/mongodb/mongod.log
