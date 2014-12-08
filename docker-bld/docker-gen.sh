#!/bin/bash



# Not using mktemp -d here since fig doesn't work with capital letter basenames.
branch="$1"

if [[ -z $branch ]];then 
    echo "Please provide branch as first argument"
    echo "Using lp:percona-xtradb-cluster  as default"
    branch="lp:percona-xtradb-cluster"
    echo 
    echo
fi








echo "
FROM centos:centos7
MAINTAINER Raghavendra Prabhu raghavendra.prabhu@percona.com
RUN curl -s http://jenkins.percona.com/dev-repo/percona-dev.repo > /etc/yum.repos.d/percona-dev.repo
RUN yum install -y http://www.percona.com/downloads/percona-release/redhat/0.1-3/percona-release-0.1-3.noarch.rpm
RUN yum install -y which lsof libaio compat-readline5 socat percona-xtrabackup perl-DBD-MySQL perl-DBI rsync openssl098e eatmydata pv qpress gzip openssl
RUN yum install -y bzr automake gcc  make g++ libtool autoconf pkgconfig gettext git scons    boost_req boost-devel
RUN bzr checkout --lightweight $branch
WORKDIR /percona-xtradb-cluster 
RUN cmake -DBUILD_CONFIG=mysql_release -DDEBUG_EXTNAME=OFF -DWITH_ZLIB=system  -DWITH_SSL=system .
RUN make
RUN make install
WORKDIR /
RUN git clone --depth=1 git@github.com:percona/galera.git
WORKDIR /galera
RUN scons -j4 --config=force  libgalera_smm.so
RUN install libgalera_smm.so /usr/lib64/
WORKDIR /
ADD node.cnf /etc/my.cnf
RUN groupadd -r mysql
RUN useradd -M -r -d /var/lib/mysql -s /bin/bash -c \"MySQL server\" -g mysql mysql
EXPOSE 3306 4567 4568
RUN /usr/bin/mysql_install_db --basedir=/usr --user=mysql
CMD  /usr/bin/mysqld --basedir=/usr --wsrep-new-cluster --user=mysql --core-file --skip-grant-tables --wsrep-sst-method=rsync

" > Dockerfile 

echo "Use:> fig scale bootstrap=1 members=2 for a 3 node cluster!"


