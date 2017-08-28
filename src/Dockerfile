# See https://hub.docker.com/r/phusion/baseimage/tags/
FROM phusion/baseimage:0.9.22

# Update the env below to your user ID for download.seafile.com
ENV SEAFILE_PRO_USER_ID=xxxxxxxx

ENV UPDATED_AT=20170820 \
    DEBIAN_FRONTEND=noninteractive \
    SEAFILE_VERSION=6.1.8

# Install our packages
RUN apt-get update -qq && apt-get -qq -y install memcached mariadb-server \
    nginx vim htop net-tools psmisc git wget curl python2.7-dev python-imaging \
    python-ldap python-mysqldb default-jre

# Setup Python Packages
ADD requirements.txt /tmp/requirements.txt
RUN curl -sSL -o /tmp/get-pip.py https://bootstrap.pypa.io/get-pip.py && \
    python /tmp/get-pip.py && \
    rm -rf /tmp/get-pip.py && \
    pip install -U wheel && \
    pip install -r /tmp/requirements.txt

# Clean up for docker squash
# See https://github.com/goldmann/docker-squash
RUN rm -rf \
    /root/.cache \
    /root/.npm \
    /root/.pip \
    /usr/local/share/doc \
    /usr/share/doc \
    /usr/share/man \
    /usr/share/vim/vim74/doc \
    /usr/share/vim/vim74/lang \
    /usr/share/vim/vim74/spell/en* \
    /usr/share/vim/vim74/tutor \
    /var/lib/apt/lists/* \
    /tmp/*

# syslog-ng and syslog-forwarder would mess up the container stdout, not good
# when debugging/upgrading.
RUN sed -i -e 's|\(^exec syslog-ng.*$\)|\1 >>/var/log/syslog-ng.log 2>\&1|g' /etc/service/syslog-ng/run && \
    rm -rf /etc/service/syslog-forwarder

# Download and extract pro server
RUN mkdir -p /opt/seafile/ && \
    curl -sSL -o - "https://download.seafile.com/d/${SEAFILE_PRO_USER_ID}/files/?p=/pro/seafile-pro-server_${SEAFILE_VERSION}_x86-64.tar.gz&dl=1" \
    | tar xzf - -C /opt/seafile/

# Nuke unwanted my_init script
RUN rm /etc/my_init.d/00_regen_ssh_host_keys.sh

# Setup our dirs
RUN mkdir -p /etc/service && \
	mkdir /shared

# Add our init scripts and services
ADD my_init.d /etc/my_init.d/
ADD service /etc/service/
ADD scripts /scripts

# Expose port 80 only. SSL needs to be done upstream by a proxy
EXPOSE 80

WORKDIR /opt/seafile

VOLUME ["/shared/seafile", "/var/lib/mysql"]


CMD ["/sbin/my_init", "--", "/scripts/bootstrap.sh"]
