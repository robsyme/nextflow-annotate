FROM ubuntu:14.04

MAINTAINER Rob Syme <rob.syme@gmail.com>

RUN apt-get update && apt-get install -qqy wget python python-biopython

RUN wget https://bootstrap.pypa.io/get-pip.py && python get-pip.py && pip install bcbio-gff 

ADD https://raw.githubusercontent.com/chapmanb/bcbb/master/gff/Scripts/gff/gff_to_genbank.py /usr/local/bin/
RUN chmod +x /usr/local/bin/gff_to_genbank.py

CMD ["/usr/local/bin/gff_to_genbank.py"]
