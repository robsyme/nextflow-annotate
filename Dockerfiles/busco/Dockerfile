from robsyme/augustus:3.0.3

MAINTAINER Rob Syme <rob.syme@gmail.com>

RUN apt-get update && apt-get install -yqq python ncbi-blast+ hmmer emboss

RUN mkdir /opt/busco
WORKDIR /opt/busco
ADD http://busco.ezlab.org/files/BUSCO_v1.0.tar.gz /opt/busco/
RUN tar -xzvf BUSCO_v1.0.tar.gz \
    && rm *.tar.gz \
    && sed -i 's/^#!\/bin\/python/#!\/usr\/bin\/env python/' BUSCO_v1.0.py \
    && chmod +x BUSCO_v1.0.py \
    && ln -s BUSCO_v1.0.py busco
ENTRYPOINT ["/bin/bash"]




