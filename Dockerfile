FROM ubuntu:latest
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

# Install other tools
RUN apt-get install -y git curl lsb-release openssh-server

# Install supervisor
RUN apt-get install -y supervisor
RUN mkdir -p /var/run/sshd
RUN mkdir -p /var/log/supervisor

RUN locale-gen en_US en_US.UTF-8

# Bundle app source
ADD . /src
ADD ./etc/env /src/.env

# create supervisord user
RUN /usr/sbin/useradd --create-home --home-dir /usr/local/zodiac --shell /bin/bash zodiac
RUN chown -R zodiac: /src

# Add supervisor config file
ADD ./etc/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# set install script to executable
RUN /bin/chmod 0777 /src/etc/install.sh

#expose the correct ports
EXPOSE 5000 22

# start supervisord when container launches
CMD ["/usr/bin/supervisord"]
