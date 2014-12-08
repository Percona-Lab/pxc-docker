#!/bin/bash

# Root is where you installed PXC with make install in source tree. Make sure to provide full path

root=$1
if [[ -z $root ]];then 
    echo "Please provide tree where PXC is installed"
    exit 1
fi

# Not using mktemp -d here since fig doesn't work with capital letter basenames.
tmpdir="/tmp/docker-$RANDOM"

if [[ -d $tmpdir ]];then 
    echo "$tmpdir already exists"
    exit 1
fi

mkdir -p $tmpdir 


echo "
FROM centos:centos7
MAINTAINER Raghavendra Prabhu raghavendra.prabhu@percona.com
RUN curl -s http://jenkins.percona.com/dev-repo/percona-dev.repo > /etc/yum.repos.d/percona-dev.repo
RUN yum install -y http://www.percona.com/downloads/percona-release/redhat/0.1-3/percona-release-0.1-3.noarch.rpm
RUN yum install -y which lsof libaio compat-readline5 socat percona-xtrabackup perl-DBD-MySQL perl-DBI rsync openssl098e eatmydata pv qpress gzip
ADD $root /pxc
RUN mkdir -p /pxc/datadir
ADD node.cnf /etc/my.cnf
RUN groupadd -r mysql
RUN useradd -M -r -d /pxc/datadir -s /bin/bash -c \"MySQL server\" -g mysql mysql
EXPOSE 3306 4567 4568
RUN /pxc/scripts/mysql_install_db --basedir=/pxc --user=mysql
CMD  /pxc/bin/mysqld --basedir=/pxc --wsrep-new-cluster --user=mysql --core-file --skip-grant-tables --wsrep-sst-method=rsync

" > $tmpdir/Dockerfile 


cp -a node.cnf fig.yml  $tmpdir/


echo "Environment prepared for fig in $tmpdir!"


