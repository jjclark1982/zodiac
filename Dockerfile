FROM ubuntu
MAINTAINER Jesse Clark, Aaron Azlant

# Install docker basics
RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list
RUN apt-get update
RUN apt-get upgrade -y

# Install dependencies and nodejs
RUN apt-get install -y python-software-properties python g++ make
RUN add-apt-repository ppa:chris-lea/node.js
RUN apt-get update
RUN apt-get install -y nodejs

# Install git
RUN apt-get install -y git

# Install supervisor
RUN apt-get install -y supervisor
RUN mkdir -p /var/log/supervisor

# Add supervisor config file
ADD ./etc/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Bundle app source
ADD . /src

# create supervisord user
RUN /usr/sbin/useradd --create-home --home-dir /usr/local/zodiac --shell /bin/bash zodiac
RUN chown -R zodiac: /src

# set install script to executable
RUN /bin/chmod 777 /src/etc/install.sh

#set up .env file
RUN echo "NODE_ENV=development\nPORT=5000\nRIAK_SERVERS={SERVER}" > /src/.env

#expose the correct port
EXPOSE 5000

# start supervisord when container launches
CMD ["/usr/bin/supervisord"]
