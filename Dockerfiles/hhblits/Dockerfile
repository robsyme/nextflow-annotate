FROM ubuntu:14.04

MAINTAINER Rob Syme <rob.syme@gmail.com>
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get install -qqy build-essential wget expect tree

RUN apt-get install -qqy hhsuite ffindex

RUN mkdir /databases
WORKDIR /databases
ADD http://downloads.sourceforge.net/project/jamg/databases/transposons.hhblits.tar.bz2 /databases/
RUN tar -xjvf transposons.hhblits.tar.bz2 && rm transposons.hhblits.tar.bz2