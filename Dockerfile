FROM ubuntu:14.04

MAINTAINER Rob Syme <rob.syme@gmail.com>

RUN apt-get update && apt-get install -qqy \
    wget \
    hmmer \
    unzip \
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
RUN wget http://www.repeatmasker.org/RepeatMasker-open-4-0-7.tar.gz \
    && tar -xzvf RepeatMasker-open*.tar.gz \
	&& rm -f RepeatMasker-open*.tar.gz \
	&& perl -0p -e 's/\/usr\/local\/hmmer/\/usr\/bin/g;' \
	-e 's/\/usr\/local\/rmblast/\/usr\/local\/bin/g;' \
    -e 's/DEFAULT_SEARCH_ENGINE = "crossmatch"/DEFAULT_SEARCH_ENGINE = "ncbi"/g;' \
    -e 's/TRF_PRGM = ""/TRF_PRGM = "\/usr\/local\/bin\/trf"/g;' RepeatMasker/RepeatMaskerConfig.tmpl > RepeatMasker/RepeatMaskerConfig.pm

# Fix RepeatMasker's strange shebang lines
RUN cd /usr/local/RepeatMasker \
	&& perl -i -0pe 's/^#\!.*perl.*/#\!\/usr\/bin\/env perl/g' \
	RepeatMasker \
    DateRepeats \
    ProcessRepeats \
    RepeatProteinMask \
    DupMasker \
    util/queryRepeatDatabase.pl \
    util/queryTaxonomyDatabase.pl \
    util/rmOutToGFF3.pl \
    util/rmToUCSCTables.pl

# Install RIPcal
RUN wget http://downloads.sourceforge.net/project/ripcal/RIPCAL/RIPCAL_2.0/ripcal2_install.zip \
	&& unzip ripcal*.zip \
	&& rm ripcal*.zip \
	&& mv ripcal* ripcal \
	&& cd ripcal \
	&& chmod +x perl/*

# Install RECON
RUN wget http://www.repeatmasker.org/RepeatModeler/RECON-1.08.tar.gz \
	&& tar -xvf RECON* \
	&& rm RECON*.tar.gz \
	&& mv RECON* recon \
	&& cd recon/src \
	&& make \
	&& make install \
	&& perl -i -0pe 's/\$path = "";/\$path = "\/usr\/local\/RECON-1.08\/bin";/g' ../scripts/\recon.pl

# Install RepeatModeler deps
RUN apt-get install -qqy libjson-perl liburi-perl liblwp-useragent-determined-perl

# Install RepeatModeler
RUN wget http://www.repeatmasker.org/RepeatModeler/RepeatModeler-open-1.0.10.tar.gz \
	&& tar -xvf RepeatModeler-*.tar.gz \
	&& rm RepeatModeler-*.tar.gz \
	&& mv RepeatModeler-*/ RepeatModeler \
	&& cd RepeatModeler \
	&& perl -i -0pe 's/^#\!.*/#\!\/usr\/bin\/env perl/g' \
	configure \
	BuildDatabase \
	Refiner \
	RepeatClassifier \
	RepeatModeler \
	TRFMask \
	util/dfamConsensusTool.pl \
	util/renameIds.pl \
	util/viewMSA.pl \
	&& cat RepModelConfig.pm.tmpl \
	| perl -p -e 's/\$RMBLAST_DIR +=.*;$/\$RMBLAST_DIR = "\/usr\/local\/bin";/g' \
	| perl -p -e 's/\$RECON_DIR +=.*;$/\$RECON_DIR = "\/usr\/local\/recon\/bin";/g' \
	| perl -p -e 's/\$RSCOUT_DIR +=.*;$/\$RSCOUT_DIR = "\/usr\/local\/RepeatScout";/g' \
	> RepModelConfig.pm

# I can't bundle the girinst RepBase libraries with the docker image,
# so you'll need to get them yourself. Download them from
# http://www.girinst.org/server/RepBase/protected/repeatmaskerlibraries/RepBaseRepeatMaskerEdition-20170127.tar.gz

ONBUILD WORKDIR /usr/local/RepeatMasker
ONBUILD ADD repeatmaskerlibraries.tar.gz /usr/local/RepeatMasker
ONBUILD RUN cd /usr/local/RepeatMasker && util/buildRMLibFromEMBL.pl Libraries/RMRBSeqs.embl > Libraries/RepeatMasker.lib \
		&& makeblastdb -dbtype nucl -in Libraries/RepeatMasker.lib > /dev/null 2>&1 \
        && makeblastdb -dbtype prot -in Libraries/RepeatPeps.lib > /dev/null 2>&1

ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/RepeatMasker:/usr/local/RepeatScout:/usr/local/recon/bin:/usr/local/RepeatModeler
#ENTRYPOINT ["/usr/local/RepeatMasker/RepeatMasker"]
