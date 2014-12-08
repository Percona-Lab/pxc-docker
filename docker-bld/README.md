This is for PXC internal development only!

How to:
============

a) bzr branch lp:percona-xtradb-cluster

b) Run the build - cmake .     -DCMAKE_INSTALL_PREFIX="/tmp/xyz"    (you can use other options if you like). 

c) make  &&  make install to /tmp/xyz

d) Come to this directory. ./docker-gen.sh /tmp/xyz 

e) cd /tmp/xyz 

f) fig scale bootstrap=1 members=2      

Your cluster is up now for fun and testing!
