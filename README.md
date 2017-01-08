# Dockerized JIRA on PostgreSQL

Atlassian [JIRA](https://www.atlassian.com/software/jira), v7.3.x, with PostgreSQL and DOC (Data-Only Container).

Most of the stuff here is based on [HouseOfAgile/docker-jira](https://github.com/HouseOfAgile/docker-jira), but since I had too many issues with MySQL (e.g. `impossible to write to binary log since BINLOG_FORMAT = STATEMENT`), PostgreSQL replaced the DB-backend. It feels faster too.  
Data is stored in a separate data-only container.

## Get started

### Lift the containers

When "docker-compose" was still known as "fig", I prefered to use "[crane](https://github.com/michaelsauter/crane)" over "fig" to start multiple containers.  

Today, "docker-compose" is preferred, hence the `docker-compose.yml`.  
Use `docker-compuse up` to start the stack.

If you still want to use "crane", use `crane lift` to start the containers.

## Manual

### 1. Create a data-only container

Create a data-only container from Busybox (very small footprint) and name it "jira\_datastore":

    docker run -v /data --name=jira_datastore -d busybox echo "PSQL Data"

**NOTE**: data-only containers don't have to run / be active to be used.

### 2. Create a PostgreSQL-container

**NOTE**: the issue below was not reproducable in January 2015. 

Used image is [paintedfox/postgresql](https://registry.hub.docker.com/u/paintedfox/postgresql/), but due to [this bug](https://github.com/Painted-Fox/docker-postgresql/issues/30), I had to rebuild a new image from paintedfox/postgresql, based on `phusion/baseimage:0.9.15`.  
To rebuild, first clone the repository:

    git clone https://github.com/Painted-Fox/docker-postgresql.git

Next, in file `Dockerfile` change line 3 `FROM phusion/baseimage:0.9.13` into `FROM phusion/baseimage:latest` and start a build:

    docker build --rm=true -t paintedfox/postgresql .

The new container can be run from here. Remember to use the volume from "jira\_datastore". Environment-variables can be changed to whatever you like.

    docker run -d --name postgresql -e USER="super" -e DB="jiradb" -e PASS="p4ssw0rd" --volumes-from jira_datastore paintedfox/postgresql

### 3. Start the JIRA-container

    docker run -d --name jira -p 8080:8080 --link postgresql:db hbokh/docker-jira-postgresql

## Build from source

```
git clone https://github.com/hbokh/docker-jira-postgresql.git
docker build --rm=true -t hbokh/docker-jira-postgresql .
```

## Next

Connect to `http:// < container IP >:8080/` and setup JIRA.  
With the above set credentials, hostname is "db", database is named "jiradb", user is "super" and password is "p4ssw0rd".

![image](https://raw.githubusercontent.com/hbokh/docker-jira-postgresql/master/JIRA-Set_Up_Database.png)

Finish JIRA's setup (register; get an evaluation-key; etc.).

## Running behind a proxy

In production environments it is a common practice to run the container on port 80 and use an appropriated name like http://jira.company.com

You can run Jira behind a proxy and you can run other applications on the same Docker host, like Confluence.

![image](https://raw.githubusercontent.com/hbokh/docker-jira-postgresql/master/subdomains_and_docker-650x352.png)

To make this easier you could run this container with an environment variable called *VIRTUAL_HOST*. This variable will change the Tomcat server configuration
to proxy the request.

You just need to run the container with the command:

```
docker run -d --name jira -e VIRTUAL_HOST=jira.company.com \
-e PROXY_SCHEME=https -e PROXY_PORT=443 -e PROXY_SECURED=true \
--volumes-from jira\_home -p 8080 --link postgresql:db hbokh/docker-jira-postgresql
```

Here we are setting the VIRTUAL_HOST to **jira.company.com** and use SSL.  
In cases where you need SSL you **MUST** configure **PROXY_SCHEME** to *https*, **PROXY_PORT** to *443* (or other you proxy use) and **PROXY_SECURED** to *true*. The defaults are respectively: *http*, *80*, *false*

To create the proxy it is highly recommended to use the  [nginx-proxy](https://registry.hub.docker.com/u/jwilder/nginx-proxy/) container.  It will do a little bit of magic and configure the proxy automatically when the container starts.
The nginx-proxy container works by listening to Docker events to check if a container starts or stops, then it will inspect the container for the **VIRTUAL_HOST** environment variable and then create the proxy configuration automagically.

An example:

```
docker run -d --name nginx -p 80:80 -p 443:443 -v \
/var/run/docker.sock:/tmp/docker.sock -v /opt/certs:/etc/nginx/certs -t jwilder/nginx-proxy

docker run -d --name jira -e VIRTUAL_HOST=jira.company.com \
-e PROXY_SCHEME=https -e PROXY_PORT=443 -e PROXY_SECURED=true \
--volumes-from jira\_home -p 8080 --link postgresql:db hbokh/docker-jira-postgresql
```

Now you just need to put your certificate-files in */opt/certs* with the names *jira.company.com.crt* and *jira.company.com.key* and point your DNS to the nginx instance (the Docker host).

Every application that needs to be run behind the proxy needs the VIRTUAL_HOST variable. A similar approach could be used to run Confluence.

If you want to know how to configure the container by hand see the documentation in https://confluence.atlassian.com/display/JIRAKB/Integrating+JIRA+with+nginx and https://confluence.atlassian.com/display/JIRA/Integrating+JIRA+with+Apache

See more options in the project page https://registry.hub.docker.com/u/jwilder/nginx-proxy/

## Other

2017: Tested with Docker for Mac on macOS Sierra 10.12.2.  
2015: Tested with boot2docker on OS X 10.9.5 (Mavericks).
