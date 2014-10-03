# RepeatMasker Container

This simple container is designed to make it easier to run
RepeatMasker on new machines. If you have your own permanent 
[big-ass-server](http://jermdemo.blogspot.ca/2011/06/big-ass-servers-and-myths-of-clusters.html),
you might want to simply install the software as usual and that's OK.
If you are spinning up virtual machines on somebody else's
infrastructure or you don't want to mess up the Sysadmin's server, you
can use this container to get your work done and then leave the system
untouched.

## Building the container

You'll need a copy of the latest
[Repbase-derived RepeatMasker libraries](http://www.girinst.org/server/RepBase/protected/repeatmaskerlibraries/repeatmaskerlibraries-20140131.tar.gz)
(requires registration) and put it in the same directory as the
Dockerfile, renamed as `repeatmaskerlibraries.tar.gz`

```sh
wget --user your_username \
    --password 12345 \
    -O repeatmaskerlibraries.tar.gz \
    http://www.girinst.org/server/RepBase/protected/repeatmaskerlibraries/repeatmaskerlibraries-20140131.tar.gz
```

The Docker images will automatically pull the tarball and decompress
it into the correct location.

To build the container (from this directory)

```sh
docker build -t repeatmasker:lastest .
```

## Using the container

```sh
run -v $PWD:/in -w /in repeatmasker RepeatMasker scaffolds.fasta
```

## Included in the container

The container includes the RMBlast and HMMER sequence search engines.
Cross_Match and ABBlast/WUBlast were not included due to licencing restrictions.

## Modifying the container

You are free to modify the container (perhaps you really want to use
Cross_Match, for example. Simply clone this repository (`git clone
https://github.com/robsyme/nextflow-annotate.git`) and modify the
Dockerfile before building.
