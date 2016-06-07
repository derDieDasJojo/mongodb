#!/bin/bash
set -x
MONGO_LOG="/var/log/mongodb/mongod.log"
MONGO="/usr/bin/mongo"
MONGOD="/usr/bin/mongod"
STACK_NAME=$(echo $HOSTNAME | cut -f1 -d_)
SERVICE_NAME=$(echo $HOSTNAME | cut -f2 -d_)
MONGO_MASTER=${STACK_NAME}_${SERVICE_NAME}_${MONGO_MASTER_ID}
DBNAME=$STACK_NAME
DBAUTH="-u clusterAdmin -p ${CLUSTER_ADMIN_PASS} --authenticationDatabase admin"

#start mongod
$MONGOD --fork --replSet $MONGO_RS --noprealloc --smallfiles --logpath $MONGO_LOG --config /etc/mongod.conf
sleep 30
 
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
echo "hostname: ${HOSTNAME}"
echo "mongo_master: ${MONGO_MASTER}" 
if [[ "$HOSTNAME" == "$MONGO_MASTER" ]]
then
        # initiate cluster
	echo "I am The master"
	echo "I initiate the cluster"
	$MONGO --eval "rs.initiate()"
	$MONGO  --eval "rs.status()"
	
        echo "I introduce myself to the config-server"
	$MONGO $MONGO_ROUTER:27017 --eval "sh.addShard(\"rs1/$HOSTNAME:27017\")"
	#$MONGO -u clusterAdmin -p ${CLUSTER_ADMIN_PASS} --authenticationDatabase admin $MONGO_ROUTER:27017 --eval "sh.addShard(\"rs1/$HOSTNAME:27017\")"
        
        echo "Set up authentication and restart mongod"
        $MONGO admin --eval "clusteradminpassword=\"${CLUSTER_ADMIN_PASS}\"" app/createClusterAdmin.js
        $MONGO admin --eval "adminuser=\"${DB_ADMIN_USER}\", adminpassword=\"${DB_ADMIN_PASS}\"" app/createAdmin.js
        $MONGOD --fork --replSet $MONGO_RS --noprealloc --smallfiles --logpath $MONGO_LOG --auth --config /etc/mongod.conf

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

