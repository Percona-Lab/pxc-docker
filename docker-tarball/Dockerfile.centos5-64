FROM centos:centos5
MAINTAINER Raghavendra Prabhu raghavendra.prabhu@percona.com
RUN yum install -y curl
RUN curl -s http://jenkins.percona.com/yum-repo/percona-dev.repo > /etc/yum.repos.d/percona-dev.repo
RUN curl -sL http://www.percona.com/downloads/percona-release/redhat/0.1-3/percona-release-0.1-3.noarch.rpm > /tmp/percona-release-0.1-3.noarch.rpm 
RUN curl -s http://www.mirrorservice.org/sites/dl.fedoraproject.org/pub/epel/5/i386/epel-release-5-4.noarch.rpm > /tmp/epel-release-5-4.noarch.rpm 
RUN yum install -y --nogpgcheck /tmp/percona-release-0.1-3.noarch.rpm 
RUN yum install -y --nogpgcheck /tmp/epel-release-5-4.noarch.rpm 
RUN yum install -y which lsof libaio socat percona-xtrabackup perl-DBD-MySQL perl-DBI rsync eatmydata pv qpress gzip gdb hostname
ADD Percona-XtraDB-Cluster /pxc
RUN mkdir -p /pxc/datadir
ADD node.cnf /etc/my.cnf
ADD backtrace.gdb /backtrace.gdb
RUN groupadd -r mysql
RUN useradd -M -r -d /pxc/datadir -s /bin/bash -c "MySQL server" -g mysql mysql
EXPOSE 3306 4567 4568
RUN /pxc/scripts/mysql_install_db --basedir=/pxc --user=mysql
CMD  /pxc/bin/mysqld --basedir=/pxc --wsrep-new-cluster --user=mysql --core-file --skip-grant-tables --wsrep-sst-method=rsync
