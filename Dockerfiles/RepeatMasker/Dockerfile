FROM ubuntu:14.04

MAINTAINER Rob Syme <rob.syme@gmail.com>

RUN apt-get update
RUN apt-get install -qqy build-essential wget expect tree

# Install hmmer
RUN apt-get install -qqy hmmer

# Install TRF
WORKDIR /usr/local/bin
RUN wget http://tandem.bu.edu/trf/downloads/trf407b.linux64 && mv trf*.linux64 trf && chmod +x trf

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
RUN wget http://www.repeatmasker.org/RepeatMasker-open-4-0-5.tar.gz && \
    tar -xzvf RepeatMasker-open*.tar.gz && \
    rm -f RepeatMasker-open*.tar.gz
ADD repeatmaskerlibraries.tar.gz /usr/local/RepeatMasker
WORKDIR /usr/local/RepeatMasker
RUN util/buildRMLibFromEMBL.pl Libraries/RepeatMaskerLib.embl > Libraries/RepeatMasker.lib && \
    makeblastdb -dbtype nucl -in Libraries/RepeatMasker.lib > /dev/null 2>&1 && \
    makeblastdb -dbtype nucl -in Libraries/RepeatPeps.lib > /dev/null 2>&1
RUN perl -i -0pe 's/^#\!.*perl.*/#\!\/usr\/bin\/perl/g' \
     RepeatMasker \
     DateRepeats \
     ProcessRepeats \
     RepeatProteinMask \
     DupMasker \
     util/queryRepeatDatabase.pl \
     util/queryTaxonomyDatabase.pl \
     util/rmOutToGFF3.pl \
     util/rmToUCSCTables.pl
RUN perl -0p -e 's/\/usr\/local\/hmmer/\/usr\/bin/g;' \
         -e 's/\/usr\/local\/rmblast/\/usr\/local\/bin/g;' \
         -e 's/DEFAULT_SEARCH_ENGINE = "crossmatch"/DEFAULT_SEARCH_ENGINE = "ncbi"/g;' \ 
         -e 's/TRF_PRGM = ""/TRF_PRGM = "\/usr\/local\/bin\/trf"/g;' RepeatMaskerConfig.tmpl > RepeatMaskerConfig.pm
ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/RepeatMasker

CMD ["/usr/local/RepeatMasker/RepeatMasker"]