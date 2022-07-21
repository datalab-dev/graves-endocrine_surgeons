# Docker

Arthur Koehl
07/21/2022

This notes document walks through installing Docker on CentOS 7 and some useful Docker commands to be aware of.

## Why Docker?

Docker provides containers, which are a way of managing environments for software development. Containers standardize software environments so that the same software can be run in the same conditions on any machine. This simplifies development workflows and helps solve the 'it works on my machine' problem. 

## Docker installation notes CentOS 7

Docker has two main products - Docker Engine and Docker Desktop. Docker Desktop contains a GUI that allows you to manage your docker container environments. Docker Engine contains a system daemon process `dockerd` and a command line tool called `docker` that will allow you to pull, build, and run docker containers.  For working on a server, we only need Docker Engine. 

Install the Docker Engine by following the instructions from [docker’s documentation](https://docs.docker.com/engine/install/centos/#install-using-the-repository). For CentOS the easiest way is to set up Docker’s repositories to work through `yum` CentoOS’s package manager. The steps as of July 2022 are listed below:

### Uninstall Old Versions

First, uninstall old versions:

```bash
sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine
```

### Install Docker Engines

Next install `yum-utils`:

```bash
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
```

Finally, install Docker Engine:

```bash
sudo yum install docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

After Docker Engine is installed, start the system process and verify its installation

```bash
sudo systemctl start docker
sudo docker run hello-world
```

To **uninstall** docker:

```bash
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
```

### Post Install Configuration

These notes are adapted from the [linux post install documentation page](https://docs.docker.com/engine/install/linux-postinstall/). The basic idea for these steps is to make it more convenient to run docker commands. 

**Create the `docker` group so that commands don’t need to be run with sudo:**

Because of how docker works, it needs to be run as sudo. However, with configuration, we can make it so that docker can work without the sudo prefix by creating a `docker` user group on the system. Its important to note that users in the `docker` group have privileges that are equivalent to root (sudo) so this is really for convenience rather than security. 

```bash
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
docker run hello-world
```

**Start Docker on Boot:**

```bash
sudo systemctl enable docker.service
sudo systemctl enable containerd.service
```

## Useful Docker commands:

This [towardsdatascience article](https://towardsdatascience.com/15-docker-commands-you-should-know-970ea5203421) seems to be a good place to understand common docker commands. Here are the most important ones that I have found I use often. 

```bash
docker version
docker image ls
docker container ls
docker container prune
docker ps
docker ps -a
sudo systemctl restart docker
```

## Docker Log Files

Docker keeps log files for each container. This is really useful when the software that you are trying to run has some tricky configuration and you need to see its logs. To find the log files for the container, look for the directory containing the log file for your container. In CentOS the path is `/var/lib/docker/containers`. On Windows it seems to be `C:\ProgramData\Docker\containers\`. 

This command prints out the path of the log file for a given container on any OS: 

`docker inspect <containername> | grep log`
