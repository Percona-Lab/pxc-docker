FROM centos:centos7
MAINTAINER Raghavendra Prabhu raghavendra.prabhu@percona.com
RUN yum install -y dnsmasq
RUN echo "user=root" >> /etc/dnsmasq.conf
RUN touch /dnsmasq.res /dnsmasq.hosts
EXPOSE 53
CMD  dnsmasq --dhcp-hostsfile=/dnsmasq.res --dhcp-range=172.17.0.1,172.17.0.253 -H /dnsmasq.hosts && while true;do sleep 1; pkill -HUP dnsmasq;done
# Run like: docker run -p 192.168.0.113:53:53/udp --rm  -t -i -v /tmp/hosts:/dnsmasq.hosts --name Mask testmasq
