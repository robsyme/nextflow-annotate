FROM ubuntu:14.04

MAINTAINER Rob Syme <rob.syme@gmail.com>

RUN apt-get update && apt-get install -qqy build-essential python ruby curl htop wget htop

WORKDIR /opt

# Samtools
RUN apt-get install -qqy zlib1g-dev libncurses5-dev
ADD http://downloads.sourceforge.net/project/samtools/samtools/1.2/samtools-1.2.tar.bz2 ./
RUN tar -xvf *.tar.bz2 && rm *.tar.bz2 && mv samtools* samtools \
    && cd samtools && make

# NCBI-blast
RUN apt-get install -qqy ncbi-blast+

# Bioruby
RUN gem install bio

# Emboss
RUN apt-get install -qqy emboss

# HMMER
RUN apt-get install -qqy hmmer

# Bedtools
RUN apt-get install -qqy bedtools

# Genome tools
WORKDIR /opt
RUN apt-get install -qqy libcairo2-dev libpango1.0-dev
ADD http://genometools.org/pub/genometools-1.5.6.tar.gz ./
RUN tar -xvf genometools-* && rm -f *.tar.gz && mv genometools* genometools
RUN cd genometools && make 64bit=yes opt=yes universal=no && sudo make install

ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/augustus/bin:/opt/tophat:/opt/samtools
