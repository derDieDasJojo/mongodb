#!/bin/bash
set -x
MONGO_LOG="/var/log/mongodb/mongod.log"
MONGO="/usr/bin/mongo"
MONGOD="/usr/bin/mongod"
STACK_NAME=$(echo $HOSTNAME | cut -f1 -d_)
SERVICE_NAME=$(echo $HOSTNAME | cut -f2 -d_)
MONGO_MASTER=${STACK_NAME}_${MONGO_MASTER_NAME}_${MONGO_MASTER_ID}
DBNAME=$STACK_NAME
DBAUTH="-u clusterAdmin -p ${CLUSTER_ADMIN_PASS} --authenticationDatabase admin"
BACKGROUND="--fork --logpath $MONGO_LOG" 

#start mongod
#$MONGOD $BACKGROUND --configsvr --smallfiles 
#sleep 30
 
checkSlaveStatus(){
	SLAVE=$1
	$MONGO --host $SLAVE --eval db
	while [ "$?" -ne 0 ]
	do
		echo "Waiting for slave to come up..."
		sleep 15
		$MONGO --host $SLAVE --eval db
	done
}

waitFor(){
  WAIT_HOST=$1
  WAIT_PORT=$2
  echo "waiting for $WAIT_HOST:$WAIT_PORT to come up .. "
  while ! echo exit | /bin/nc -zv $WAIT_HOST $WAIT_PORT; do sleep 5; done
  echo "Service $WAIT_HOST:$WAIT_PORT reached !"
}
#waitFor $MONGO_MASTER 27017 

#start mongod
$MONGOD --configsvr --smallfiles --config /etc/mongoc.conf

tailf /dev/null

