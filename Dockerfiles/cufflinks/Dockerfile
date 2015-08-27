FROM robsyme/tophat

MAINTAINER Rob Syme <rob.syme@gmail.com>

WORKDIR /opt
ADD http://cole-trapnell-lab.github.io/cufflinks/assets/downloads/cufflinks-2.2.1.Linux_x86_64.tar.gz ./
RUN tar -xzvf *.tar.gz && rm *.tar.gz && mv cufflinks* cufflinks
ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/augustus/bin:/opt/cufflinks




