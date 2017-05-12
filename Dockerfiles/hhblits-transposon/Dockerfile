FROM ubuntu:14.04

MAINTAINER Rob Syme <rob.syme@gmail.com>
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -qqy hhsuite ffindex samtools
RUN mkdir /databases
WORKDIR /databases

# One of two options here - either download it during docker build
ADD http://downloads.sourceforge.net/project/jamg/databases/transposons.hhblits.tar.bz2 .
# ... or download it yourself next to this Dockerfile and then docker build.
#ADD transposons.hhblits.tar.bz2 .
RUN tar -xvf transposons.hhblits.tar.bz2
