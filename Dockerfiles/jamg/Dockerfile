FROM ubuntu:14.04

MAINTAINER Rob Syme <rob.syme@gmail.com>

RUN apt-get update && apt-get install -qqy build-essential cdbfasta ncbi-blast+ snap git

# Insall Augustus
ADD http://bioinf.uni-greifswald.de/augustus/binaries/augustus-3.1.tar.gz /opt/
RUN cd /opt && \
    tar -xzvf augustus* && \
    rm -rf *.tar.gz && \
    mv augustus* augustus && \
    cd augustus && \
    make

ENV AUGUSTUS_CONFIG_PATH /opt/augustus/config

ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/augustus/bin:/opt/augustus/scripts

WORKDIR /opt
RUN apt-get install zlib1g-dev wget
RUN git clone https://github.com/genomecuration/JAMg.git jamg 
# && cd jamg \
# && make all


# gmap

# augustus

# gff2gbSmallDNA.pl

# etraining

# filterGenes.pl
