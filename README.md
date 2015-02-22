# Dockerized JIRA on PostgreSQL

Atlassian [JIRA](https://www.atlassian.com/software/jira), v6.3.x, with PostgreSQL and data-volume.

Most of this is based on [HouseOfAgile/docker-jira](https://github.com/HouseOfAgile/docker-jira), but since there were too many issues with MySQL (e.g. `impossible to write to binary log since BINLOG_FORMAT = STATEMENT`), PostgreSQL replaced the DB-backend. Feels faster too.  
Data is stored in a separate data-only container.

## Steps

### 1. Create a data-only container

Create a data-only container from Busybox (very small footprint) and name it "jira\_datastore":

    docker run -v /data --name=jira\_datastore -d busybox echo "PSQL Data"

**NOTE**: data-only containers don't have to run / be active to be used.

### 2. Create a PostgreSQL-container

Used image is [paintedfox/postgresql](https://registry.hub.docker.com/u/paintedfox/postgresql/), but due to [this bug](https://github.com/Painted-Fox/docker-postgresql/issues/30), I had to rebuild a new image from paintedfox/postgresql, based on `phusion/baseimage:0.9.15`.  
To rebuild, first clone the repository:

    git clone https://github.com/Painted-Fox/docker-postgresql.git

Next, in file `Dockerfile` change line 3 `FROM phusion/baseimage:0.9.13` into `FROM phusion/baseimage:0.9.15` and start a build:

    docker build --rm=true -t paintedfox/postgresql .

The new container can be run from here. Remember to use the volume from "jira\_datastore". Environment-variables can be changed to whatever you like.

    docker run -d --name postgresql -e USER="super" -e DB="jiradb" -e PASS="p4ssw0rd" --volumes-from jira\_datastore paintedfox/postgresql

### 3. Start the JIRA-container

    docker run -d --name jira -p 8080:8080 --link postgresql:db hbokh/docker-jira-postgresql

## Build from source

```
git clone https://github.com/hbokh/docker-jira-postgresql.git
docker build --rm=true -t hbokh/docker-jira-postgresql .
```

## Using Crane to lift containers

I prefer "[crane](https://github.com/michaelsauter/crane)" over "fig" to start multiple containers.  
Check file `crane.yml` and use `crane lift` to start the containers.

## Next

Connect to `http:// < container IP >:8080/` and setup JIRA.  
With the above set credentials, hostname is "db", database is named "jiradb", user is "super" and password is "p4ssw0rd".

![image](https://raw.githubusercontent.com/hbokh/docker-jira-postgresql/master/JIRA-Set_Up_Database.png)

Finish JIRA's setup (register; get an evaluation-key; etc.).

## Running behind a proxy

In production environments is a best practice run the container on port 80 and use a appropriated name like http://jira.company.com

In this cases you could also need to run Jira behind a proxy, so you can run other applications in the same host, like confluence or any other.

![image](https://raw.githubusercontent.com/hbokh/docker-jira-postgresql/master/subdomains_and_docker-650x352.png)

To make this easy you could run this container with a environment variable called *VIRTUAL_HOST* this variable will change the tomcat server configuration
to proxy the request.

You just need to run the container with the command:

```
docker run -d --name jira -e VIRTUAL_HOST=jira.company.com \
-e PROXY_SCHEME=https -e PROXY_PORT=443 -e PROXY_SECURED=true \
--volumes-from jira\_home -p 8080 --link postgresql:db hbokh/docker-jira-postgresql
```

In this example we are setting the VIRTUAL_HOST to **jira.company.com** and using SSL. In cases where you need SSL you **MUST** configure **PROXY_SCHEME** to *https*, **PROXY_PORT** to *443* (or other you proxy use) and **PROXY_SECURED** to *true*. The defaults are respectively: *http*, *80*, *false*

To create the proxy we high recommend the use of [nginx-proxy](https://registry.hub.docker.com/u/jwilder/nginx-proxy/) container  because it will do a little of magic and configure the proxy automatically when the container starts.
The nginx-proxy container works by listen to docker events to know if a container start or stop, them it will inspect the container for the **VIRTUAL_HOST** environment variable and the create the proxy configuration automagically ;-)

As a example:

```
docker run -d --name nginx -p 80:80 -p 443:443 -v \
/var/run/docker.sock:/tmp/docker.sock -v /opt/certs:/etc/nginx/certs -t jwilder/nginx-proxy

docker run -d --name jira -e VIRTUAL_HOST=jira.company.com \
-e PROXY_SCHEME=https -e PROXY_PORT=443 -e PROXY_SECURED=true \
--volumes-from jira\_home -p 8080 --link postgresql:db hbokh/docker-jira-postgresql
```

Now you just need to put your certification in */opt/certs* with the names *jira.company.com.crt* and *jira.company.com.key* and point you DNS to the nginx instance (the docker host).

Now every application that needs to run behind the proxy just need the VIRTUAL_HOST variable. A similar approach could be used to run atlassian confluence.

Check out the project https://registry.hub.docker.com/u/giovannicandido/docker-confluence-postgresql for a confluence container based on this Jira container that offers the same facility

If you want to know how to configure the container by hand see the documentation in https://confluence.atlassian.com/display/JIRAKB/Integrating+JIRA+with+nginx and https://confluence.atlassian.com/display/JIRA/Integrating+JIRA+with+Apache

See more options in the project page https://registry.hub.docker.com/u/jwilder/nginx-proxy/

## Other

Tested with boot2docker on OS X 10.9.5 (Mavericks).
