FROM ubuntu
MAINTAINER Jesse Clark, Aaron Azlant

# Install dependencies and nodejs
RUN apt-get update
RUN apt-get install -y python-software-properties python g++ make
RUN add-apt-repository ppa:chris-lea/node.js
RUN apt-get update
RUN apt-get install -y nodejs

# Install git
RUN apt-get install -y git

# Bundle app source
ADD . /src

#Create a nonroot user, and switch to it
RUN /usr/sbin/useradd --create-home --home-dir /usr/local/nonroot --shell /bin/bash nonroot
RUN /bin/chown -R nonroot: /src

RUN /bin/su nonroot

# Install app source
RUN cd /src; npm install
