apt-get install curl -y
apt-get install git -y
apt-get install python-software-properties python g++ make -y

add-apt-repository ppa:chris-lea/node.js
apt-get update
apt-get install nodejs -y

echo -e "NODE_ENV=development\nPORT=5000\nRIAK_SERVERS={SERVER}" > /src/.env
cd /src; npm install
