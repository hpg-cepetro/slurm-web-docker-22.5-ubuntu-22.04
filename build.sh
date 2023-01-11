#!/bin/bash

docker run --rm -ti -v $PWD:/build phusion/baseimage:focal-1.2.0 /bin/bash /build/slurm-web/build_debs.sh

docker build -t slurm-web:slurm22.5_ubuntu22.04 .
