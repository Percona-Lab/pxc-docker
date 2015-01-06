This repo contains all the docker-related code for PXC. Feel free to clone and/or contribute!

 - docker-pkgs contains centos6/7 fig and docker files for PXC from - experimental, testing and release - repos. 

 - dnsmasq contains Dockerfile for dnsmasq container used in tests.
 
 - sysbench contains Dockerfile for sysbench centos7 container.

 - docker-tarball contains config, fig and Dockerfiles for a PXC container using the tarball. It is mostly for jenkins testing.

 - docker-bld contains two scripts (each of which generate the Dockerfile), a fig file and config. This is meant to be used for development and quick testing of PXC trees. 

In addition, all directories have README.md for specific info.

Tests
===

 - chaos-galera is for chaos testing of PXC nodes.

 - galera-bench is for flow control testing of PXC nodes.

 - partition-testing is for partition testing of PXC nodes.

 All three of these use netem and tc among other things.



