FROM centos:centos7
MAINTAINER Raghavendra Prabhu raghavendra.prabhu@percona.com
RUN yum install -y bzr automake gcc  make g++ libtool autoconf pkgconfig gettext  mysql-libs mariadb-devel rsync
RUN bzr branch lp:sysbench
WORKDIR /sysbench 
RUN ./autogen.sh 
RUN ./configure 
RUN make 
RUN make install
RUN rsync -a sysbench/tests/db  /usr/share/doc/sysbench/tests/
