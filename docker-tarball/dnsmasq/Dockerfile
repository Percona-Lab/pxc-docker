FROM centos:centos6
MAINTAINER Raghavendra Prabhu raghavendra.prabhu@percona.com
RUN yum install -y dnsmasq
RUN echo "user=root" >> /etc/dnsmasq.conf
EXPOSE 53
CMD  dnsmasq -H /dnsmasq.hosts && while true;do sleep 1; pkill -HUP dnsmasq;done
# Run like: docker run -p 192.168.0.113:53:53/udp --rm  -t -i -v /tmp/hosts:/dnsmasq.hosts --name Mask testmasq
