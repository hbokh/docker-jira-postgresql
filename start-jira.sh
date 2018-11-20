#!/bin/bash

PROXY_PORT=${PROXY_PORT:-80}
PROXY_SCHEME=${PROXY_SCHEME:-http}
PROXY_SECURED=${PROXY_SECURED:-false}

pre_start_action() {
  if [ ! -z "$VIRTUAL_HOST" ]; then
    if [ ! -e "/opt/jira/conf/server.xml.replaced" ]; then
      cp /opt/jira/conf/server.xml /opt/jira/conf/server.xml.original
    fi
    cat /opt/jira/conf/server.xml.original | sed -e "s/<Connector port=\"8080\"/<Connector port=\"8080\"\n\nproxyName=\"${VIRTUAL_HOST}\"\nproxyPort=\"${PROXY_PORT}\"\nscheme=\"${PROXY_SCHEME}\"\nsecured=\"${PROXY_SECURED}\"/g" > /opt/jira/conf/server.xml.proxed
    cp /opt/jira/conf/server.xml.proxed /opt/jira/conf/server.xml
    touch /opt/jira/conf/server.xml.replaced
  else
    if [ -e "/opt/jira/conf/server.xml.original" ]; then
      mv /opt/jira/conf/server.xml.original /opt/jira/conf/server.xml
      rm /opt/jira/conf/server.xml.replaced
    fi
  fi
}

pre_start_action

# Ugly workaround after unclean shutdown...
if [ -f /opt/jira/work/catalina.pid ] ; then
  rm -f /opt/jira/work/catalina.pid
fi  

cd /opt/jira/bin
./start-jira.sh
