FROM ubuntu:14.04

MAINTAINER Rob Syme <rob.syme@gmail.com>

RUN apt-get update && apt-get install -yqq hmmer unzip wget

WORKDIR /opt
RUN wget ftp://ftp.ebi.ac.uk/pub/databases/Pfam/current_release/Pfam-A.hmm.gz && gunzip *.gz && hmmpress Pfam-A.hmm && rm Pfam-A.hmm

