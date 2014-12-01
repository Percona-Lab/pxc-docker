FROM centos:centos7
MAINTAINER Raghavendra Prabhu raghavendra.prabhu@percona.com
RUN yum install -y http://www.percona.com/downloads/percona-release/redhat/0.1-3/percona-release-0.1-3.noarch.rpm
ADD node.cnf /etc/my.cnf 
RUN yum install -y which
RUN yum install -y Percona-XtraDB-Cluster-56
EXPOSE 3306 4567 4568
ONBUILD RUN yum update -y
CMD /usr/sbin/mysqld --basedir=/usr --user=mysql --wsrep-new-cluster

