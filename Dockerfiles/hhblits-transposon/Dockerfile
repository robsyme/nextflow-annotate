FROM robsyme/hhblits:latest

MAINTAINER Rob Syme <rob.syme@gmail.com>

WORKDIR /databases
ADD http://downloads.sourceforge.net/project/jamg/databases/transposons.hhblits.tar.bz2 /databases/
RUN tar -xjvf transposons.hhblits.tar.bz2 && rm transposons.hhblits.tar.bz2
