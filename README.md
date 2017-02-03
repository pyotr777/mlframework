# Python framework for distributed execution of computational tasks

This framework helps execute computational tasks on a number of computers. Tasks are executed in parallel. This framework creates one _master_ process and a number of _worker_ processes. Master process is responsible for creating a number of computations tasks (commands) that would be executed by worker processes. 


This framework makes use of [Celery](http://www.celeryproject.org)  with RabbitMQ broker for distributing tasks among workers. [Flower](http://flower.readthedocs.io/en/latest/) is used for monitoring.


## Infrastructure setup

Use _infrainit.sh_ bash script to start Celery master, broker, Celery workers and Flower monitor in Docker container on local and a number of remote hosts.

### Requirements

- Computer running _master_ and _broker_ must have global IP address accessible from all other computers and the following ports must be open: 22, 4369, 5555, 5671, 5672, 25672.
- [Docker](http://docker.io) must be installed on all computers. 

### Usage

```
./infrainit.sh -a <[user@]host1,[user@]host2...> [-f] [-i <ssh key file>] -r <path> -d <dirname> [-b <broker address>] [-m local/N] [-w local,N1,N2...]
Options:
	-a	Remote hosts addresses, comma-separated list.
	-r	Remote path for storing task and framework files relative to home directory.
	-d	Name of directory with task (project) files.
	-b	External address of the machine with Master and Broker containers.
	-m	Start Celery master and broker on local machine or on host N (N is a number).
	-w	Start workers on specified hosts. N1,N2... - comma separated numbers of hosts, listed in -a. First host has number 1.
	-f	Read all the above options from file config.sh. If -f option not used config.sh will be overwritten with new options provided as arguments to this script.
```

Sample: 
```
infrainit.sh -a user@host1,user@host2 -i ~/.ssh/id_rsa -r celery_tasks/ -d task1 -m 1 -w local,1,2
```	

This command will :

- copy necessary scripts and task files to ~/celery_tasks/ folder on remote hosts host1 and host2;
- start Celery master, RabbitMQ broker and Flower in Docker containers on host 1 (option `-m 1`);
- start Celery workers in Docker containers on localhost, host1 and host2 (option `-w local,1,2` means to start workers on localhost and remote hosts in positions 1 and 2 of -a option).

You must be able to connect to remote hosts with ssh using provided ssh key and user name, for example:
`ssh -i ~/.ssh/id_rsa user@host1` 


#### Options reuse (configuration file)

After you executed infrainit.sh once with options -a, -r, -d, ... , options will be saved to configuration file config.sh. 
To reuse these options use -f flag: `./infrainit.sh -f`.


#### Remove infrastructure

After infrainit.sh script is executed a script for removing infrastructure `infra_clean.sh` is generated. It removes all started Docker containers effectively stopping all processes started with infrainit.sh. Files on remote hosts are not deleted.









