FROM ubuntu:14.04

MAINTAINER Rob Syme <rob.syme@gmail.com>

RUN apt-get update -qq && apt-get install -qqy build-essential

# Install Gmap
WORKDIR /opt
ADD http://research-pub.gene.com/gmap/src/gmap-gsnap-2015-07-23.tar.gz ./
RUN tar -xvf gmap*.tar.gz && rm gmap*.tar.gz && mv gmap* gmap && cd gmap && ./configure && make
RUN cd gmap && make install

# Install Fasta aligner
RUN apt-get install -qqy zlib1g-dev
ADD http://faculty.virginia.edu/wrpearson/fasta/fasta36/fasta-36.3.8.tar.gz ./
RUN tar -xvf fasta*.tar.gz && rm fasta*.tar.gz && mv fasta* fasta && cd fasta/src && make -f ../make/Makefile.linux64

# Install blat aligner
RUN apt-get install -qqy unzip libpng-dev
ENV MACHTYPE=x86_64
RUN mkdir -p ~/bin/$MACHTYPE
ADD http://hgwdev.cse.ucsc.edu/~kent/src/blatSrc35.zip ./
RUN unzip blat* && rm *.zip && mv blat* blat && cd blat && make

# Install DBD::mysql, etc
RUN apt-get install -qqy liburi-escape-xs-perl liburi-perl mysql-client libdbd-mysql-perl 

# Install PASA
ADD https://github.com/PASApipeline/PASApipeline/archive/v2.0.2.tar.gz ./
RUN tar -xvf *.tar.gz && rm *.tar.gz && mv PASA* pasa && cd pasa && make
ADD conf.txt /opt/pasa/pasa_conf/
ENV PASAHOME=/opt/pasa

# Final PATH
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/fasta/bin:/root/bin/$MACHTYPE:/opt/blat/:/opt/fasta/bin:$PASAHOME/bin:$PASAHOME/scripts:/opt/seqclean


