FROM centos:centos6
MAINTAINER Raghavendra Prabhu raghavendra.prabhu@percona.com
RUN yum install -y http://www.percona.com/downloads/percona-release/percona-release-0.0-1.x86_64.rpm
RUN yum install -y http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
ADD node1.cnf /etc/my.cnf 
RUN yum install -y which
RUN yum install -y Percona-XtraDB-Cluster-56
EXPOSE 3306 4567 4568
CMD /sbin/service mysql bootstrap-pxc && tailf /dev/null

