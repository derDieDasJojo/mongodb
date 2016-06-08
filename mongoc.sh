#!/bin/bash
set -x

# initialize variables
MONGO_LOG="/var/log/mongodb/mongod.log"
MONGO="/usr/bin/mongo"
MONGOD="/usr/bin/mongod"
STACK_NAME=$(echo $HOSTNAME | cut -f1 -d_)
SERVICE_NAME=$(echo $HOSTNAME | cut -f2 -d_)
MONGO_MASTER=${STACK_NAME}_${MONGO_MASTER_NAME}_${MONGO_MASTER_ID}
DBNAME=$STACK_NAME
DBAUTH="-u clusterAdmin -p ${CLUSTER_ADMIN_PASS} --authenticationDatabase admin"
BACKGROUND="--fork --logpath $MONGO_LOG" 

# start mongod config server
$MONGOD --configsvr --smallfiles --config /etc/mongoc.conf

