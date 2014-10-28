FROM ubuntu:14.04

MAINTAINER Rob Syme <rob.syme@gmail.com>

RUN apt-get update && apt-get install -y default-jre wget coreutils
RUN mkdir -p /opt/interproscan && \
    cd /opt/interproscan && \
    wget ftp://ftp.ebi.ac.uk/pub/software/unix/iprscan/5/5.7-48.0/interproscan-5.7-48.0-64-bit.tar.gz* && \
    md5sum -c interproscan*.md5 && \
    rm *.md5 && \
    tar -pxvzf interproscan*.tar.gz && \
    rm *.tar.gz
RUN ln -s /opt/interproscan/interproscan-5.7-48.0 /opt/interproscan/current
WORKDIR /opt/interproscan/current
RUN apt-get install -qqy ncoils blast2
ADD interproscan.properties /opt/interproscan/current/
ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/interproscan/current
