FROM phusion/baseimage:0.9.15

MAINTAINER bokh@xs4all.nl

RUN apt-get update -qq && \
    apt-get install -qqy git-core software-properties-common python-software-properties && \
    apt-add-repository ppa:webupd8team/java -y && \
    apt-get update -qq && \
    echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    apt-get install -y oracle-java7-installer && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    mkdir /srv/www

# Install Jira
ADD install-jira.sh /root/install-jira.sh
RUN /root/install-jira.sh

## Install SSH for a specific user (thanks to public key)
ADD ./config/id_rsa.pub /tmp/your_key
RUN cat /tmp/your_key >> /root/.ssh/authorized_keys && rm -f /tmp/your_key

# Add private key in order to get access to private repo
ADD ./config/id_rsa /root/.ssh/id_rsa

# Launching Jira
WORKDIR /opt/jira-home
RUN rm -f /opt/jira-home/.jira-home.lock

# Add start script in my_init.d of phusion baseimage
RUN mkdir -p /etc/my_init.d
ADD ./start-jira.sh /etc/my_init.d/start-jira.sh

CMD  ["/sbin/my_init"]
