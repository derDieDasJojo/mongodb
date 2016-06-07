FROM mongo:3.2

ADD mongod.conf /etc/mongod.conf
ADD mongos.conf /etc/mongos.conf
ADD run.sh /app/run.sh
ADD mongos.sh /app/mongos.sh
ADD mongod.sh /app/mongod.sh
ADD mongo-router-setup.js /app/mongo-router-setup.js
CMD ["bash","/app/run.sh"] 
