# Python framework for distributed execution of computational tasks

This framework is used to execute computational tasks on a number of computers. Tasks are executed in parallel. This framework creates one _master_ process and a number of _worker_ processes. Master process is responsible for creating a number of computational tasks (commands) that would be executed by worker processes. 


This framework makes use of [Celery](http://www.celeryproject.org)  with RabbitMQ broker for distributing tasks among workers. [Flower](http://flower.readthedocs.io/en/latest/) can be used for monitoring.


## Contents


- **[TL;DR](#tldr)**
- **[Projects](#projects)**
- **[Infrastructure setup](#infrastructure-setup)**
	- [Requirements](https://github.com/pyotr777/mlframework#requirements)
	- [Usage](https://github.com/pyotr777/mlframework#usage)
		- [Options reuse (configuration file)](https://github.com/pyotr777/mlframework#options-reuse-configuration-file)
		- [Remove infrastructure](https://github.com/pyotr777/mlframework#remove-infrastructure)
		- [Other scripts](https://github.com/pyotr777/mlframework#other-scripts)
	- [NVIDIA GPU support](#nvidia-gpu-support)
- **[Executing ML tasks with a metaparameters set](#executing-ml-tasks-with-a-metaparameters-set)** 
	- [chainer](#chainer)
		- [train task](#train-task)
		- [YAML file format](#yaml-file-format)


&nbsp;

## TL;DR

Start three machines to be used in computations. Make sure you can login to them with ssh. [Docker](https://www.docker.com) must be installed on all machines. Machine number 1 running master process must be accessible from all others and have required ports open (see Requirements section). Provide their addresses (with optional user names: user@hostname) after -a option of `infrainit.sh` command.

Execute the following commands on you local computer in mlframework directory to run sample task testing communication between workers and master processes:

```
./infrainit.sh -a <remote host A>,<remote host B>,<remote host C> -r ML -d chainer -m 1 -w 2,3

```

This command will start master process on host A and worker processes on hosts B and C. <br>
Wait for a few seconds. Check that all two workers started with:

```
./check_celery_status.sh
```

Start the task execution with:

```
./run_tasks.sh test_echo
```

In the terminal window of your local computer you should be able to see output from worker processes.

To stop master and worker processes execute:

```
./infra_clean.sh
```




## Projects

Projects define computational tasks that can be executed with this framework. 

Every project must be placed in its own subdirectory, which could be later provided with -d option of `infrainit.sh` script (See Infrastructure setup section).

Every project must have `tasks.py` file in its directory. This file defines computational tasks. See example projects incuded with this repository for tasks.py samples.


## Infrastructure setup

Use _infrainit.sh_ bash script to start all processes necessary for execution computational tasks, namely Celery master, broker, Celery workers and Flower monitor in Docker containers on local machine and/or remote hosts.

### Requirements

- Host running _master_ and _broker_ must have global IP address accessible from all other computers and the following ports must be open: 22, 4369, 5555, 5671, 5672, 25672.
- [Docker](https://www.docker.com) must be installed on all computers. 

### Usage

The following script can be executed on your local computer to set up infrastructure necessary for executing parallel tasks.

```
infrainit.sh -a <[user@]host1,...> [-f] [-i <ssh key file>] -r <path> -d <dirname> [-m local/N] [-w local,N1,N2...]
Options:
	-a	Remote hosts addresses, comma-separated list.
	-r	Remote path for storing task and framework files relative to home directory.
	-d	Name of directory with task (project) files.
	-m	Master host: start Celery master and broker on local machine or on remote host N (N is the ordinary number of remote hosts in the list of -a option).
	-w	Start workers on specified hosts. N1,N2... - comma-separated numbers of hosts listed in -a. First host has number 1.
	-f	Read all the above options from file config.sh. If -f option not used config.sh will be overwritten with new options provided as arguments to this script.
```

Two sample projects (task definitions) are included with this repository. Use them with option -d. 

#### Sample: 
```
infrainit.sh -a user@hostA,user@hostB \
-i ~/.ssh/id_rsa  \
-r celery_tasks -d task1 \ 
-m 1 -w local,1,2
```	

This command will :

- copy necessary scripts and task files to ~/celery_tasks/ folder on remote hosts hostA and hostB;
- start Celery master, RabbitMQ broker and Flower in Docker containers on hostA (option `-m 1`);
- start Celery workers in Docker containers on localhost, hostA and hostB (option `-w local,1,2` means to start workers on localhost and remote hosts in positions 1 and 2 of the -a option list).

You must be able to connect to remote hosts with ssh using provided ssh key and user name, for example:
`ssh -i ~/.ssh/id_rsa user@hostA` 


#### Options reuse (configuration file)

After you executed infrainit.sh once with options -a, -r, -d, ... , parameters will be saved to configuration file config.sh. 
To reuse these parameters use option -f: `./infrainit.sh -f`.


#### Remove infrastructure

After infrainit.sh script is executed a script for removing infrastructure `infra_clean.sh` is generated. It removes all started Docker containers effectively stopping all processes started with infrainit.sh. Files on remote hosts are not deleted.

#### Other scripts

| Script name | Discription |
|:---|:---|
| `update_files.sh` | Update files on remote hosts. |
| `check_celery_status.sh` | Display Celery master status by executing `celery status` command in master container. |

&nbsp;


### NVIDIA GPU support

To make use of NVIDIA GPUs on worker machines you need to install [nvidia-docker](https://github.com/NVIDIA/nvidia-docker) on these machines. A script for automated installation of nvidia-docker on Ubuntu is included in this repository and is used with the following command:

```
nvdocker_install/install_ubuntu.sh <remote host address>
```
 
   
&nbsp;

&nbsp;



# Executing ML tasks with a metaparameters set

This framework can be used to execute a number of Machine Learning tasks with a set of metaparameters in parallel. 
Two sample projects (tasks definitions) included in this repository: _bowcnn_ and _chainer_. Both use [Chainer](chainer.org) to evaluate metaparameters for training ML models on sample datasets. 

## chainer

There are two tasks defined in `tasks.py` of _chainer_ project: __echo__ and __train__.

__echo__ – sample task to test communication between workers and master processes.<br>
__train__ – a task to train a sample model on  MNIST dataset with the script `chainer/examples/mnist/train_mnist.py`.

To run task __echo__ execute on you local computer in mlframework directory:

```./run_tasks.sh test_echo```

`chainer/test_echo.py` is a script that actually executes __echo__ task defined in `task.py`. 
`chainer/run_training.py` is a script that executes __train__ task.

### _train_ task


```./run_tasks.sh run_training```

__train__ task executes a number of parallel tasks with a set of metaparameters. This set is defined with `chainer/parameters.yml` YAML file as _all possible combinations_ of parameters values. 

### YAML file format

```
parameter_A: values_A
parameter_B: values_B
...
```

Parameters are translated to CLI options for `chainer/examples/mnist/train_mnist.py`. For example, `gpu: 0` will be translated to `train_mnist.py --gpu=0`.

Parameter values can be defined as single values, lists or intervals. 

| Type | Format | Description | Example |
|:---|:---|:---|:---|
| single value | `value` (with or without quotes) | Translates to `--parameter=value` in all dataset combinations. | `gpu: -1` |
| list | `[value1,value2,...]` | All values from the list will be used to produce parameters combinations. |`batchsize: [100, 500]` |
| interval | `!!python/tuple [start,end,step]` | Values from [_start_, _end_) interval with given _step_ will be used to produce parameters combinations. If _step_ is not defined 1 will be used by default. | `epoch: !!python/tuple [5,20,5]` will produce combinations with the following values: 5, 10, 15. |





 









