FROM ubuntu:14.04

MAINTAINER Rob Syme <rob.syme@gmail.com>

RUN apt-get update -qq && apt-get install -qqy build-essential zlib1g-dev libncurses5-dev

WORKDIR /opt/
ADD http://downloads.sourceforge.net/project/samtools/samtools/0.1.19/samtools-0.1.19.tar.bz2 /opt/
RUN tar -xvf samtools* && rm *.bz2 && mv samtools* samtools && cd samtools && make

RUN apt-get install -qqy unzip
ADD http://downloads.sourceforge.net/project/bowtie-bio/bowtie/1.1.2/bowtie-1.1.2-linux-x86_64.zip /opt/
RUN unzip bowtie* && rm *.zip && mv bowtie* bowtie


RUN apt-get install -qqy curl openjdk-7-jre
ADD https://github.com/trinityrnaseq/trinityrnaseq/archive/v2.0.6.tar.gz /opt/
RUN tar -xvf *.tar.gz && rm *.tar.gz && mv trinity* trinity && cd trinity && make

ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/trinity:/opt/samtools:/opt/bowtie

