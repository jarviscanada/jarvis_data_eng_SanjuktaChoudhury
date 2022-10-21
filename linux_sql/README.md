# Linux Cluster Monitoring Agent

# Introduction
The Jarvis Linux Cluster Administration (LCA) team manages a Linux cluster of 10 nodes/servers running CentOS 7. These servers are internally connected through a switch and able to communicate through internal IPv4 addresses.The LCA team needs to record the hardware specifications of each node and monitor node resource usage (e.g. CPU, memory) in real-time (see appendix A). The collected data should be stored in an RDBMS. The LCA team will use the data to generate reports for future resource planning purposes (e.g. add or remove servers).

For this Project we are responsible for designing and implementing an [MVP](https://en.wikipedia.org/wiki/Minimum_viable_product) that helps the LCA team to meet their business needs. We need to record the hardware information and the usage of the memory and CPU in RDBMS.

The technologies used for this project are
 . LINUX (Centos 7)
 . Git/Github
 . Bash Script
 . Docker
 . Postgres SQL
 . Crontab

# Quick Start
 1. Implement a script to create, start and stop the psql container
 
```
    psql -h HOST_NAME -p 5432 -U USER_NAME -d DB_NAME
   
   ## create a psql docker container with the given username and password.
   ./scripts/psql_docker.sh create db_username db_password
   
   ## start the stoped psql docker container
   ## print error message if the container is not created
   ./scripts/psql_docker.sh start

  ## stop the running psql docker container
  ## print error message if the container is not created
  ./scripts/psql_docker.sh stop 
  
```
 2. Create tables using ddl.sql

```
psql -h localhost -U postgres -d host_agent -f sql/ddl.sql

```
 3. Insert hardware specs data into the DB using host_info.sh

```
./scripts/host_info.sh psql_host psql_port db_name psql_user psql_password

# Example
./scripts/host_info.sh localhost 5432 host_agent postgres password

```
 4. Insert hardware usage data into the DB using host_usage.sh

```
bash scripts/host_usage.sh psql_host psql_port db_name psql_user psql_password

# Example
bash scripts/host_usage.sh localhost 5432 host_agent postgres password

```
 5. Crontab Setup

```
bash> crontab -e

#add this to crontab
* * * * * bash /home/centos/dev/jrvs/bootcamp/linux_sql/host_agent/scripts/host_usage.sh localhost 5432 host_agent postgres password > /tmp/host_usage.log

```
# Implementation

To implement this project we did the following

1. Created a bash script psql_docker.sh to create, start and stop the docker instance
2. Collected hardware information and resource usage using bash cmds which will help to implement the monitoring agent scripts later
3. Create hosi_info and host_usage table and execute ddl.sql script on the host_agent database against the psql instance
4. Implement monitoring agent by writing two scripts - host_info.sh and host_usage.sh. host_usage.sh wii be executed every minute using crontab.

# Architecture

 A `psql` instance is used to persist all the data
 The `bash agent` gathers server usage data, and then insert into the psql instance. The `agent` will be installed on every host/server/node. The `agent` consists of two bash scripts
  - `host_info.sh` collects the host hardware info and insert it into the database. It will be run only once at the installation time.
  - `host_usage.sh` collects the current host usage (CPU and Memory) and then insert into the database. It will be triggered by the `cron` job every minute.


# Scripts

. psql_docker.sh

```
# script usage
./scripts/psql_docker.sh start|stop|create [db_username][db_password]

# examples
## create a psql docker container with the given username and password.
## print error message if username or password is not given
## print error message if the container is already created
./scripts/psql_docker.sh create db_username db_password

## start the stoped psql docker container
## print error message if the container is not created
./scripts/psql_docker.sh start

## stop the running psql docker container
## print error message if the container is not created
./scripts/psql_docker.sh stop

```
. ddl.sql

```
# connect to the psql instance
psql -h localhost -U postgres -W

# list all database
postgres=# \l

# create a database
postgres=# CREATE DATABASE host_agent;

# connect to the new database;
postgres=# \c host_agent;

# Execute ddl.sql script on the host_agent database againse the psql instance
psql -h localhost -U postgres -d host_agent -f sql/ddl.sql

```
. host_info.sh : collect and store the host's hardware information. (executed only once)

```
lscpu         # CPU-related information
vmstat        # Process, memory and disk information
hostname -f   # Fully Qualified Domain Name
grep          # Search plain text data sets
awk           # Process and manipulate text
xargs         # Trim white space

```
. host_usage.sh : collect and store the host's resource usage. (executed every minute by crontab)

```
# Script usage
bash scripts/host_usage.sh psql_host psql_port db_name psql_user psql_password

# Example
bash scripts/host_usage.sh localhost 5432 host_agent postgres password

#pseudo code
- parse server CPU and memory usage data using bash scripts
- construct the INSERT statement. (hint: use a subquery to get id by hostname)
- execute the INSERT statement

```
. crontab : schedule a job for a specific time. In our case, it runs host_usage.sh every minute.

# Database Modeling
Schemas used for the host_info and host_usage table

* host_info

 | Column | type | constraint |
 | ------ | ---- | ---------- |
 | id     | Integer | Primary key |
 | hostname | varchar | Unique, Not Null |
 |cpu_number | Integer | Not Null |
 |cpu_architecture | varchar | Not Null |
 | cpu_model | varchar | Not Null |
 | cpu_mhz | Numeric | Not Null|
 | l2_cache | Integer | Not Null |
 | total_mem | Integer | Not Null |
 | timestamp | Timestamp | Not Null |

* host_usage

 | Column      | type | constraint |
 | -------------| ------ | ---- | 
 | timestamp   | Timestamp | Not Null |
 | host_id     | Integer | Foreign key: host_info(id) |
 | memory_free | Integer | Not Null |
 | cpu_idle | Integer | Not Null |
 | cpu_kernel | Integer | Not Null |
 | disk_io | Integer | Not Null |
 | disk_available | Integer | Not Null |

# Test

 * Test the psql_docker.sh
  ```
  #check if the container `jrvs-psql` is created or not
  docker container ls -a -f name=jrvs-psql

  #check if `jrvs-psql` container is running
  docker ps -f name=jrvs-psql

  ```
 * Test the ddl.sql

   Run psql -h localhost -U postgres -d host_agent -f sql/ddl.sql then \l to see if the table host_info and host_usage are created.

 
 * Test the host_info.sh
   ```
   psql -h localhost -U postgres -d host_agent -c "SELECT * FROM host_info i JOIN host_usage u ON i.id=u.host_id WHERE hostname='YOUR_HOST_NAME'"

   ```
 * Test the host_usage.sh
  ```
  psql -h localhost -U postgres -d host_agent -c "SELECT * FROM host_info WHERE hostname='YOUR_HOST_NAME'"

  ```
# Deployment
GitHub is used as a version control tool for this project. We used crontab to collect the host resource usage data regularly, and Docker to provision our psql instance.