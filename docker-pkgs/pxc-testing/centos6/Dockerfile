FROM ronin/pxc:release
MAINTAINER Raghavendra Prabhu raghavendra.prabhu@percona.com
RUN sed -i -e '31,38s/enabled = 0/enabled = 1/g' /etc/yum.repos.d/percona-release.repo
RUN yum update -y 'Percona*'
EXPOSE 3306 4567 4568
CMD /sbin/service mysql bootstrap-pxc && tailf /dev/null
