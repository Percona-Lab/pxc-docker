You can either run with fig.yml or with fig-build.yml as:

fig.yml
---

fig scale bootstrap=1 members=<N>     where N is a number.


fig-build.yml
---
FIG_FILE=fig-build.yml fig scale bootstrap=1 members=<N>


The difference between fig.yml and fig-build.yml being that with former ronin/pxc:centos7 image is used, while with latter the image is built.
