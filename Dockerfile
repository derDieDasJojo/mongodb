FROM mongo:3.2

ADD mongod.conf /etc/mongod.conf
ADD startUp.sh /root/startUp.sh
CMD ["bash","/root/startUp.sh"]
