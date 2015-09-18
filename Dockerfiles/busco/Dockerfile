from robsyme/augustus:3.0.3

MAINTAINER Rob Syme <rob.syme@gmail.com>

RUN apt-get update && apt-get install -yqq python ncbi-blast+ hmmer emboss

#Busco
RUN mkdir /opt/busco
WORKDIR /opt/busco
ADD http://busco.ezlab.org/files/BUSCO_v1.0.tar.gz /opt/busco/
RUN tar -xzvf BUSCO_v1.0.tar.gz \
    && rm *.tar.gz \
    && sed -i 's/^#!\/bin\/python/#!\/usr\/bin\/env python/' BUSCO_v1.0.py \
    && chmod +x BUSCO_v1.0.py \
    && ln -s BUSCO_v1.0.py busco
ADD http://busco.ezlab.org/files/fungi_buscos.tar.gz /opt/busco/lineages/
RUN cd /opt/busco/lineages/ && tar -xzf *.tar.gz

# Genometools
WORKDIR /opt/gt
ADD http://genometools.org/pub/binary_distributions/gt-1.5.7-Linux_x86_64-64bit-barebone.tar.gz /opt/gt/
RUN tar -xvf *.tar.gz && rm *.tar.gz && ln -s gt* current

#Samtools
RUN apt-get install samtools

ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/augustus/bin:/opt/augustus/scripts:/opt/busco:/opt/gt/current/bin

ENTRYPOINT ["/bin/bash"]
