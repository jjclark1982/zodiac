FROM centos:6.4
MAINTAINER Jesse Clark, Aaron Azlant

# Install dependencies and nodejs
RUN rpm -Uvh http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
RUN yum install -y npm

# Install git
RUN yum install -y git-core

# Bundle app source
ADD . /src

# Install app source
RUN cd /src; npm install
RUN cd /src; npm install bluebird # not sure why this needs this line

# Set up environment

RUN echo -e "NODE_ENV=development\nPORT=5000\nRIAK_SERVERS={SERVER}" > /src/.env
RUN export PATH=$PATH:node_modules/.bin
RUN src/node_modules/.bin/bower install --allow-root

# Expose the correct port
EXPOSE  5000

# Fire it up
RUN cd /src; node_modules/.bin/cake develop
