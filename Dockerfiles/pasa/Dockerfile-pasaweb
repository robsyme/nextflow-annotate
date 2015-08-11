FROM ubuntu:14.04

MAINTAINER Rob Syme <rob.syme@gmail.com>

RUN apt-get update -qq

# Install DBD::mysql and apache
RUN apt-get install -qqy liburi-escape-xs-perl liburi-perl mysql-client libdbd-mysql-perl build-essential zlib1g-dev libgd-perl apache2 libgd-graph-perl

# Install PASA
WORKDIR /usr/lib/cgi-bin
ADD https://github.com/PASApipeline/PASApipeline/archive/v2.0.2.tar.gz ./
RUN tar -xvf *.tar.gz && rm *.tar.gz && mv PASA* pasa && cd pasa && make && chmod -R 755 .
ADD conf.txt /usr/lib/cgi-bin/pasa/pasa_conf/
ENV PASAHOME=/usr/lib/cgi-bin/pasa

# Final PATH
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PASAHOME/bin

ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_PID_FILE /var/run/apache2/apache2.pid
ENV APACHE_RUN_DIR /var/run/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_LOG_DIR /var/log/apache2

RUN a2enmod cgi

EXPOSE 80

CMD ["apache2", "-DFOREGROUND"]


