#!/bin/bash
set -x
MONGO_LOG="/var/log/mongodb/mongod.log"
MONGO="/usr/bin/mongo"
MONGOD="/usr/bin/mongod"
STACK_NAME=$(echo $HOSTNAME | cut -f1 -d_)
SERVICE_NAME=$(echo $HOSTNAME | cut -f2 -d_)
MONGO_MASTER=${STACK_NAME}_${SERVICE_NAME}_${MONGO_MASTER_ID}
DBNAME=$STACK_NAME
DBAUTH=""
#DBAUTH="-u clusterAdmin -p ${CLUSTER_ADMIN_PASS} --authenticationDatabase admin"
BACKGROUND="--fork --logpath $MONGO_LOG" 

#start mongod
#$MONGOD $BACKGROUND --replSet $MONGO_RS --smallfiles 
$MONGOD $BACKGROUND --replSet $MONGO_RS --smallfiles --config /etc/mongod.conf
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
waitFor $MONGO_MASTER 27017 

echo "hostname: ${HOSTNAME}"
echo "mongo_master: ${MONGO_MASTER}" 
if [[ "$HOSTNAME" == "$MONGO_MASTER" ]]
then
        # initiate cluster
	echo "I am The master"
	echo "I initiate the cluster"
	$MONGO --eval "rs.initiate()"
	$MONGO  --eval "rs.status()"
        
        echo "Set up authentication and restart mongod"
        sleep 3
        $MONGO admin --eval "clusteradminpassword=\"${CLUSTER_ADMIN_PASS}\"" app/createClusterAdmin.js
        $MONGO $DBNAME --eval "adminuser=\"${DB_ADMIN_USER}\", adminpassword=\"${DB_ADMIN_PASS}\"" app/createAdmin.js
        #$MONGO -u "clusterAdmin" -p "${CLUSTER_ADMIN_PASS}" $DBNAME --eval "adminuser=\"${DB_ADMIN_USER}\", adminpassword=\"${DB_ADMIN_PASS}\"" app/createAdmin.js
        $MONGOD $BACKGROUND --replSet $MONGO_RS --smallfiles --config /etc/mongod.conf
        
        echo "I introduce myself to the config-server"
	waitFor $MONGO_ROUTER 27017
	#$MONGO $MONGO_ROUTER:27017 --eval "sh.addShard(\"rs1/$HOSTNAME:27017\")"
	$MONGO -u clusterAdmin -p ${CLUSTER_ADMIN_PASS} --authenticationDatabase admin $MONGO_ROUTER:27017 --eval "sh.addShard(\"rs1/$HOSTNAME:27017\")"

else
	#add self to cluster
	echo "I am a Slave ${HOSTNAME}"
	echo "I join the cluster of $MONGO_MASTER"
	#wait 5 secs to the master has time
	sleep 5
	#check again if the assumed master is really a master
        #echo $MONGO $DBAUTH ${MONGO_MASTER}/admin -- eval "printjson(db.isMaster())"   
	IS_MASTER=`mongo $DBAUTH ${MONGO_MASTER}/admin --eval "printjson(db.isMaster())" | grep 'ismaster'`
	if echo $IS_MASTER | grep "true"; then
		IS_MEMBER=`mongo $DBAUTH ${MONGO_MASTER}/admin --eval "printjson(rs.conf())" | grep "$HOSTNAME"`
		if echo $IS_MEMBER | grep "$HOSTNAME"; then
			echo "I am already member of the cluster. So I will do nothing."
		else
			echo "I am not jet member of the cluster. So i will join"
			#if its a master, join the cluster
			echo $MONGO $DBAUTH ${MONGO_MASTER}/admin --eval "rs.add(\"${HOSTNAME}:27017\")"	
			$MONGO $DBAUTH ${MONGO_MASTER}/admin --eval "rs.add(\"${HOSTNAME}:27017\")"
			$MONGO $DBAUTH ${MONGO_MASTER}/admin --eval "rs.status()"
		fi
	else	
		#if its not a master, something is wrong
		echo "The assumed Master($MONGO_MASTER) is not a master."
		echo "I refuse to enslave myself, if its not a master. I kill myself"
		exit 1 #exit with error
	fi
	
fi
tailf /dev/null

