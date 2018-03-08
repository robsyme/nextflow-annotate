FROM ubuntu:16.04

MAINTAINER Rob Syme <rob.syme@gmail.com>

RUN apt-get update \
&& apt-get install -qqy \
build-essential \
libbamtools-dev \
libboost-graph-dev \
libboost-iostreams-dev \
libgsl-dev \
liblpsolve55-dev \
libsqlite3-dev \
libsuitesparse-dev \
wget \
zlib1g-dev

WORKDIR /usr/local

# Install Augustus
RUN wget http://bioinf.uni-greifswald.de/augustus/binaries/augustus.current.tar.gz \
&& tar -xvf augustus*.tar.gz \
&& rm augustus*.tar.gz \
&& cd augustus \
&& echo "COMPGENEPRED = true" >> common.mk \
&& make \
&& make install

ENV AUGUSTUS_CONFIG_PATH /usr/local/augustus/config
ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/augustus/bin:/usr/local/augustus/scripts
