FROM ubuntu:14.04

MAINTAINER Rob Syme <rob.syme@gmail.com>

RUN apt-get update && apt-get install -qqy \
    wget \
    hmmer \
    build-essential

# Install TRF (for RepeatScout)
WORKDIR /usr/local/bin
RUN wget http://tandem.bu.edu/trf/downloads/trf407b.linux64 && mv trf*.linux64 trf && chmod +x trf

# Basic workdir
WORKDIR /usr/local

# Install nseg (for RepeatScout)
RUN mkdir nseg && \
    cd nseg && \
    wget ftp://ftp.ncbi.nih.gov/pub/seg/nseg/* && \
    make && \
    mv nseg ../bin && \
    mv nmerge ../bin

# Install RepeatScout
RUN wget http://bix.ucsd.edu/repeatscout/RepeatScout-1.0.5.tar.gz && \
    tar -xvf RepeatScout* && \
    rm RepeatScout*.tar.gz && \
    mv RepeatScout* RepeatScout && \
    cd RepeatScout && \
    make	

# Install RMBlast
RUN wget ftp://ftp.ncbi.nlm.nih.gov/blast/executables/rmblast/2.2.28/ncbi-rmblastn-2.2.28-x64-linux.tar.gz && \
    tar -xzvf ncbi-rmblastn* && \
    rm ncbi-rmblastn*.tar.gz && \
    mv ncbi-rmblastn*/bin/rmblastn bin && \
    rm -rf ncbi-rmblastn    

# Install Blast+
RUN wget ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.6.0/ncbi-blast-2.6.0+-x64-linux.tar.gz && \
    tar -xzvf ncbi-blast* && \
    find ncbi-blast* -type f -executable -exec mv {} bin \; && \  
    rm -rf ncbi-blast*
    
# Install RepeatMasker
RUN wget http://www.repeatmasker.org/RepeatMasker-open-4-0-7.tar.gz && \
    tar -xzvf RepeatMasker-open*.tar.gz && \
    rm -f RepeatMasker-open*.tar.gz

# I can't bundle the girinst RepBase libraries with the docker image,
# so you'll need to get them yourself. Download them from
# http://www.girinst.org/server/RepBase/protected/repeatmaskerlibraries/repeatmaskerlibraries-20140131.tar.gz
ONBUILD ADD repeatmaskerlibraries.tar.gz /usr/local/RepeatMasker
ONBUILD WORKDIR /usr/local/RepeatMasker
ONBUILD RUN util/buildRMLibFromEMBL.pl Libraries/RMRBSeqs.embl > Libraries/RepeatMasker.lib && \
        makeblastdb -dbtype nucl -in Libraries/RepeatMasker.lib > /dev/null 2>&1 && \
        makeblastdb -dbtype prot -in Libraries/RepeatPeps.lib > /dev/null 2>&1
ONBUILD RUN perl -i -0pe 's/^#\!.*perl.*/#\!\/usr\/bin\/perl/g' \
        RepeatMasker \
        DateRepeats \
        ProcessRepeats \
        RepeatProteinMask \
        DupMasker \
        util/queryRepeatDatabase.pl \
        util/queryTaxonomyDatabase.pl \
        util/rmOutToGFF3.pl \
        util/rmToUCSCTables.pl
ONBUILD RUN perl -0p -e 's/\/usr\/local\/hmmer/\/usr\/bin/g;' \
        -e 's/\/usr\/local\/rmblast/\/usr\/local\/bin/g;' \
        -e 's/DEFAULT_SEARCH_ENGINE = "crossmatch"/DEFAULT_SEARCH_ENGINE = "ncbi"/g;' \ 
        -e 's/TRF_PRGM = ""/TRF_PRGM = "\/usr\/local\/bin\/trf"/g;' RepeatMaskerConfig.tmpl > RepeatMaskerConfig.pm

ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/RepeatMasker:/usr/local/RepeatScout
#ENTRYPOINT ["/usr/local/RepeatMasker/RepeatMasker"]
