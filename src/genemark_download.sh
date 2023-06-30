#!/usr/bin/env bash

wget \
        --post-data='program=gmet&os=linux64&name=https://bit.ly/2GAQMGz&institution=na&country=na&email=na@na.com&submit=I+agree+to+the+terms+of+this+license+agreement' \
        http://exon.gatech.edu/GeneMark/license_download.cgi
    bin_url="$(grep -o 'http://[^ ]*linux_64\.tar\.gz' license_download.cgi)"
    url32="$(grep -o 'http://[^ ]*gm_key_32\.gz' license_download.cgi)"
    url64="${url32/gm_key_32/gm_key_64}"
    wget -O "genemark.tar.gz" "${bin_url}"
    mkdir genemark
    tar -zxf genemark.tar.gz \
        -C genemark \
        --strip-components 1
    rm -f genemark.tar.gz
    cd genemark || exit 1
    wget "${url32}"
    wget "${url64}"
    gunzip *.gz
    cd .. || exit 1
    rm license_download.cgi
