This is for PXC internal development only!

How to:
============

a) bzr branch lp:percona-xtradb-cluster

b) Run the build - cmake .     -DCMAKE_INSTALL_PREFIX="/tmp/PREFIX"    (you can use other options if you like). 

c) make  &&  make install to /tmp/PREFIX

d) Come to this directory. ./docker-gen.sh /tmp/PREFIX 

e) cd /tmp/PREFIX 

f) fig scale bootstrap=1 members=2      

Your cluster is up now for fun and testing!


Fig Install:
http://www.fig.sh/install.html

Docker install:
https://docs.docker.com/installation/

