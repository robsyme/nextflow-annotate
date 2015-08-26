FROM ubuntu:14.04

MAINTAINER Rob Syme <rob.syme@gmail.com>

RUN apt-get update && apt-get install -yqq build-essential python

WORKDIR /opt
ADD http://downloads.sourceforge.net/project/codingquarry/CodingQuarry_v1.2.tar.gz ./
RUN apt-get install -qqy libopenmpi-dev
RUN tar -xzvf *.tar.gz && rm *.tar.gz && mv CodingQuarry* CodingQuarry && cd CodingQuarry && make
ENV QUARRY_PATH /opt/CodingQuarry/QuarryFiles
ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/CodingQuarry
