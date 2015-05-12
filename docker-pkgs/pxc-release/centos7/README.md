You can either run with docker-compose.yml or with docker-compose-build.yml as:

docker-compose.yml
---

docker-compose scale bootstrap=1 members=<N>     where N is a number.


docker-compose-build.yml
---
COMPOSE_FILE=docker-compose-build.yml docker-compose scale bootstrap=1 members=<N>


The difference between docker-compose.yml and docker-compose-build.yml being that with former ronin/pxc:centos7 image is used, while with latter the image is built.
