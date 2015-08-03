FROM ubuntu:14.04

MAINTAINER Rob Syme <rob.syme@gmail.com>

RUN apt-get update && apt-get install -qqy build-essential ncbi-blast+ python perl tree

ADD http://www.bioinf.uni-leipzig.de/Software/proteinortho/proteinortho_v5.11.tar.gz /opt/
RUN cd /opt && \
    tar -xzvf proteinortho_*.tar.gz && \
    rm -rf *.tar.gz && \
    mv proteinortho_v5.11 proteinortho
RUN cd /usr/local/bin && find /opt/proteinortho -type f -executable | xargs -I{} ln -s {} .

CMD ["/opt/proteinortho/proteinortho5.pl"]
