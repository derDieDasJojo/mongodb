#!/bin/bash
set -x
MONGO_LOG="/var/log/mongodb/mongod.log"
MONGO="/usr/bin/mongo"
MONGOS="/usr/bin/mongos"
STACK_NAME=$(echo $HOSTNAME | cut -f1 -d_)
SERVICE_NAME=$(echo $HOSTNAME | cut -f2 -d_)
MONGO_MASTER=${STACK_NAME}_${SERVICE_NAME}_${MONGO_MASTER_ID}

#start mongos
$MONGOS -configdb mongo-config-server:27019
#--fork --replSet $MONGO_RS --noprealloc --smallfiles --logpath $MONGO_LOG --config /etc/mongod.conf
sleep 30
 
$MONGO --eval "var stackname=${STACK_NAME}, admin-user=${ADMIN_USER}, admin-password=${ADMIN_PASS}" mongo-router-setup.js

tailf /dev/null

