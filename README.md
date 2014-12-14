# Docker JIRA on PostgreSQL

Containers with the latest Atlassian [JIRA](https://www.atlassian.com/software/jira).  

Most of this is based on [HouseOfAgile/docker-jira](https://github.com/HouseOfAgile/docker-jira), but since there were too many issues with MySQL (e.g. `impossible to write to binary log since BINLOG_FORMAT = STATEMENT`), PostgreSQL replaced the DB-backend. Feels faster too.

## Steps

### 1. Create a data-only container

Create a data-only container from Busybox (very small footprint):

    docker run -v /data --name=datastore -d busybox echo "PSQL Data"
    
Remember, data-only containers don't need to run / be active to be used.    

### 2. Create a PostgreSQL-container

Used image is [paintedfox/postgresql](https://registry.hub.docker.com/u/paintedfox/postgresql/), but due to [this bug](https://github.com/Painted-Fox/docker-postgresql/issues/30), I had to rebuild a new image from paintedfox/postgresql, based on `phusion/baseimage:0.9.15`.

    git clone https://github.com/Painted-Fox/docker-postgresql.git

Change line 3 `FROM phusion/baseimage:0.9.13` into `FROM phusion/baseimage:0.9.15` and start a build:

    docker build --rm=true -t paintedfox/postgresql .

New container can be run from here:

    docker run -d --name postgresql -e USER="super" -e DB="jiradb" -e PASS="p4ssw0rd" --volumes-from datastore paintedfox/postgresql

### 3. Create the JIRA-container

    docker run -d --name jira -p 8080:8080 --link postgresql:db hbokh/docker-jira-postgresql

## Using Crane to lift containers

I am starting to prefer "[crane](https://github.com/michaelsauter/crane)" over "fig" to start multiple containers.  
Check file `crane.yml` and use `crane lift` to start the containers.

## Next

Connect to http:// < container IP >:8080/ and setup JIRA.  
With the above set credentials, database is named "jiradb", user is "super" and password is "p4ssw0rd".

## Other

Tested with boot2docker on OS X 10.9.5 (Mavericks).