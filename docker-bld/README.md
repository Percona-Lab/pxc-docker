This is for PXC internal development only!

How to:
============

a) ./docker-gen.sh lp:percona-xtradb-cluster
b) fig scale bootstrap=1 members=2      

Your cluster is up now for fun and testing!


Fig Install:
http://www.fig.sh/install.html

Docker install:
https://docs.docker.com/installation/


Tips
=========
To make it a bit faster, do

Replace:

%%%%%%%%%%%%%%
members:
  build: .
%%%%%%%%%%%%%

with

%%%%%%%%%%%%%
members:
  image: dockertest_bootstrap
%%%%%%%%%%%%%

where dockertest is given as follows:

FIG_PROJECT_NAME=dockertest fig scale bootstrap=1 members=2
