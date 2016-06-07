#!/bin/bash
set -x
MONGO_LOG="/var/log/mongodb/mongod.log"
MONGO="/usr/bin/mongo"
MONGOS="/usr/bin/mongos"
STACK_NAME=$(echo $HOSTNAME | cut -f1 -d_)
SERVICE_NAME=$(echo $HOSTNAME | cut -f2 -d_)
MONGO_MASTER=${STACK_NAME}_${SERVICE_NAME}_${MONGO_MASTER_ID}
DBNAME=$STACK_NAME

#start mongos
$MONGOS --fork --logpath $MONGO_LOG -configdb mongo-config-server:27019
#--fork --replSet $MONGO_RS --noprealloc --smallfiles --logpath $MONGO_LOG --config /etc/mongod.conf
sleep 30
 
#$MONGO admin --eval "clusteradminpassword=\"${CLUSTER_ADMIN_PASS}\", adminuser=\"${DB_ADMIN_USER}\", adminpassword=\"${DB_ADMIN_PASS}\"" app/mongo-router-setup.js

#$MONGOS --fork --logpath $MONGO_LOG -configdb mongo-config-server:27019 --config /etc/mongos.conf
#$MONGO admin --eval "clusteradminpassword=\"${CLUSTER_ADMIN_PASS}\", adminuser=\"${DB_ADMIN_USER}\", adminpassword=\"${DB_ADMIN_PASS}\"" app/mongo-router-setup.js

tailf /dev/null

