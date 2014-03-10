FROM ubuntu
MAINTAINER Jesse Clark, Aaron Azlant

# Install docker basics
RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list
RUN apt-get update
RUN apt-get upgrade -y

# Install supervisor
RUN apt-get install -y supervisor
RUN mkdir -p /var/log/supervisor

# Add supervisor config file
ADD ./setup/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Bundle app source
ADD . /src

# create supervisord user
RUN /usr/sbin/useradd --create-home --home-dir /usr/local/zodiac --shell /bin/bash zodiac

# Expose required ports and start supervisord when container launches
CMD ["/usr/bin/supervisord"]
