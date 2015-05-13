This is for PXC internal development only!

How to:
============

a) ./docker-gen.sh lp:percona-xtradb-cluster     (docker-gen.sh takes a PXC branch as argument)

b) Optional: docker-compose build (if you see it is not updating with changes).

c) docker-compose scale bootstrap=1 members=2      for a 3 node cluster

Your cluster is up now for fun and testing!


docker-compose install:
https://docs.docker.com/compose/install/

Docker install:
https://docs.docker.com/installation/


docker-gen-local.sh is same except it takes a local tree as argument than a branch. 
