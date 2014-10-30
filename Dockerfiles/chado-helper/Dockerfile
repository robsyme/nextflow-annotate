FROM ubuntu:14.04

RUN apt-get update && apt-get install -qqy postgresql-client wget build-essential 

WORKDIR /opt
ADD http://downloads.sourceforge.net/project/gmod/gmod/chado-1.23/chado-1.23.tar.gz /opt/
RUN tar -xzvf *.tar.gz && rm *.tar.gz && mv chado-1.23 chado

WORKDIR /opt/chado
ENV GMOD_ROOT /usr/local/gmod
ENV CHADO_DB_USERNAME chadouser
ENV CHADO_DB_NAME chado
ENV CHADO_DB_HOST chado

# Perl bits
RUN apt-get install -qqy libtemplate-perl libxml-simple-perl libdbi-perl libgo-perl libdbd-pg-perl libdbix-dbstag-perl libsql-translator-perl bioperl
RUN sed -i 's/stag-storenode.pl/stag-storenode/' lib/Bio/Chado/Builder.pm
RUN perl Makefile.PL && make && make install
