# Dockerized JIRA on PostgreSQL

Atlassian [JIRA](https://www.atlassian.com/software/jira), v6.3.x, PostgreSQL and data-volume.

Most of this is based on [HouseOfAgile/docker-jira](https://github.com/HouseOfAgile/docker-jira), but since there were too many issues with MySQL (e.g. `impossible to write to binary log since BINLOG_FORMAT = STATEMENT`), PostgreSQL replaced the DB-backend. Feels faster too.  
Data is stored in a separate data-only container.

## Steps

### 1. Create a data-only container

Create a data-only container from Busybox (very small footprint) and name it "datastore":

    docker run -v /data --name=datastore -d busybox echo "PSQL Data"
    
**NOTE**: data-only containers don't have to run / be active to be used.    

### 2. Create a PostgreSQL-container

Used image is [paintedfox/postgresql](https://registry.hub.docker.com/u/paintedfox/postgresql/), but due to [this bug](https://github.com/Painted-Fox/docker-postgresql/issues/30), I had to rebuild a new image from paintedfox/postgresql, based on `phusion/baseimage:0.9.15`.  
To rebuild, first clone the repository:

    git clone https://github.com/Painted-Fox/docker-postgresql.git

Next, change line 3 `FROM phusion/baseimage:0.9.13` into `FROM phusion/baseimage:0.9.15` and start a build:

    docker build --rm=true -t paintedfox/postgresql .

The new container can be run from here. Remember to use the volume from "datastore". Environment-variables can be changed to whatever you like. 

    docker run -d --name postgresql -e USER="super" -e DB="jiradb" -e PASS="p4ssw0rd" --volumes-from datastore paintedfox/postgresql

### 3. Start the JIRA-container

    docker run -d --name jira -p 8080:8080 --link postgresql:db hbokh/docker-jira-postgresql

## Using Crane to lift containers

I am starting to prefer "[crane](https://github.com/michaelsauter/crane)" over "fig" to start multiple containers.  
Check file `crane.yml` and use `crane lift` to start the containers.

## Next

Connect to `http:// < container IP >:8080/` and setup JIRA.  
With the above set credentials, hostname is "db", database is named "jiradb", user is "super" and password is "p4ssw0rd".

![image](https://raw.githubusercontent.com/hbokh/docker-jira-postgresql/master/JIRA-Set_Up_Database.png)

Finish JIRA's setup (register; get an evaluation-key; etc.).

## Other

Tested with boot2docker on OS X 10.9.5 (Mavericks).