#!/bin/bash
set -x
MONGO_LOG="/var/log/mongodb/mongod.log"
MONGO="/usr/bin/mongo"
MONGOD="/usr/bin/mongod"
$MONGOD --fork --replSet fame --noprealloc --smallfiles --logpath $MONGO_LOG
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
 
if [ "$HOSTNAME" == "$MONGO_MASTER" ]
then
	# initiate cluster
	echo "I am The master"
	echo "I initiate the cluster"
	$MONGO --eval "rs.initiate()"
	#checkSlaveStatus $SLAVE1
	#$MONGO --eval "rs.add(\"${SLAVE1}:27017\")"
	#checkSlaveStatus $SLAVE2
	#$MONGO --eval "rs.add(\"${SLAVE2}:27017\")"
	echo "I introduce myself to the config-server"
	$MONGO --host $MONGO_CONFIGSERVER:27019 --eval "sh.addShard(\"rs1/$HOSTNAME:27017\")"
else
	#add self to cluster
	echo "I am a Slave ($HOSTNAME)"
	echo "I join the cluster of $MONGO_MASTER"
	#wait 5 secs to the master has time
	sleep 5
	#check again if the assumed master is really a master
	IS_MASTER=`mongo --host $MONGO_MASTER --eval "printjson(db.isMaster())" | grep 'ismaster'`
	if echo $IS_MASTER | grep "true"; then
		IS_MEMBER=`mongo --host $MONGO_MASTER --eval "printjson(rs.conf())" | grep "$HOSTNAME"`
		if echo $IS_MEMBER | grep "$HOSTNAME"; then
			echo "I am already member of the cluster. So I will do nothing."
		else
			echo "I am not jet member of the cluster. So i will join"
			#if its a master, join the cluster
			echo $MONGO --host $MONGO_MASTER --eval "rs.add(\"${HOSTNAME}:27017\")"	
			$MONGO --host $MONGO_MASTER --eval "rs.add(\"${HOSTNAME}:27017\")"
		fi
	else	
		#if its not a master, something is wrong
		echo "The assumed Master($MONGO_MASTER) is not a master."
		echo "I refuse to enslave myself, if its not a master. I kill myself"
		exit 1 #exit with error
	fi
	
fi
tailf /dev/null

