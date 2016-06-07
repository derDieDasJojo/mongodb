FROM mongo:3.2

ADD mongod.conf /etc/mongod.conf
ADD mongos.conf /etc/mongos.conf
ADD run.sh /app/run.sh
ADD mongos.sh /app/mongos.sh
ADD mongod.sh /app/mongod.sh
ADD createClusterAdmin.js /app/createClusterAdmin.js
ADD createAdmin.js /app/createAdmin.js
CMD ["bash","/app/run.sh"] 
