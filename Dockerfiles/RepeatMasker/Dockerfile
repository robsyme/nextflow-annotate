FROM ubuntu:14.04

MAINTAINER Rob Syme <rob.syme@gmail.com>

RUN apt-get update
RUN apt-get install -qq -y build-essential wget tree

# Install TRF
WORKDIR /usr/local/bin
RUN wget http://tandem.bu.edu/trf/downloads/trf407b.linux64 && mv trf*.linux64 trf

# Install RMBlast
WORKDIR /usr/local
RUN wget ftp://ftp.ncbi.nlm.nih.gov/blast/executables/rmblast/LATEST/ncbi-rmblastn-2.2.28-x64-linux.tar.gz && \
    tar -xzvf ncbi-rmblastn* && \
    rm ncbi-rmblastn*.tar.gz && \
    mv ncbi-rmblastn*/bin/rmblastn bin && \
    rm -rf ncbi-rmblastn    

# Install Blast+
RUN wget ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/ncbi-blast-2.2.29+-x64-linux.tar.gz && \
    tar -xzvf ncbi-blast* && \
    find ncbi-blast* -type f -executable -exec mv {} bin \; && \  
    rm -rf ncbi-blast*
    
# Install RepeatMasker
WORKDIR /usr/local
RUN wget http://www.repeatmasker.org/RepeatMasker-open-4-0-5.tar.gz && \
    tar -xzvf RepeatMasker-open*.tar.gz && \
    rm -f RepeatMasker-open*.tar.gz
    

