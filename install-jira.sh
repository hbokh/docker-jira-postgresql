#!/bin/bash -x

# Change this when a newer version is released:
JIRA_VERSION=7.3.0

tmpfile=$(mktemp)
curl -LSs https://www.atlassian.com/software/jira/downloads/binary/atlassian-jira-software-${JIRA_VERSION}.tar.gz -o $tmpfile
mkdir -p /opt/jira
tar zxf $tmpfile --strip=1 -C /opt/jira

useradd --create-home --home-dir /usr/local/jira --shell /bin/bash jira

mkdir -p /opt/jira-home
echo "jira.home = /opt/jira-home" > /opt/jira/atlassian-jira/WEB-INF/classes/jira-application.properties
