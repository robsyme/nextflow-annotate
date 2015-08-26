FROM ubuntu:14.04

MAINTAINER Rob Syme <rob.syme@gmail.com>

RUN apt-get update && apt-get install -yqq hmmer unzip wget

WORKDIR /opt
RUN wget ftp://ftp.ebi.ac.uk/pub/databases/Pfam/releases/Pfam28.0/Pfam-A.hmm.gz && gunzip *.gz && hmmpress Pfam-A.hmm && rm Pfam-A.hmm

