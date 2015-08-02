FROM ubuntu:14.04

MAINTAINER Rob Syme <rob.syme@gmail.com>

RUN apt-get update && apt-get install -qqy build-essential

ADD http://bioinf.uni-greifswald.de/augustus/binaries/old/augustus-3.0.3.tar.gz /opt/
RUN cd /opt && \
    tar -xzvf augustus* && \
    rm -rf *.tar.gz && \
    mv augustus* augustus && \
    cd augustus && \
    make

ADD fgram_base /opt/augustus/config/species/    
ENV AUGUSTUS_CONFIG_PATH /opt/augustus/config
ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/augustus/bin:/opt/augustus/scripts
ENTRYPOINT ["/opt/augustus/bin/augustus"]
