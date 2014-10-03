# RepeatMasker Container

This simple container is designed to make it easier to run
RepeatMasker on new machines. If you have your own permanent 
[big-ass-server](http://jermdemo.blogspot.ca/2011/06/big-ass-servers-and-myths-of-clusters.html),
you might want to simply install the software as usual and that's very
sensible.

There are also plenty of situations were you might want to use a
container:

* You are using compute resources on EC2 or GCE and you don't want to
make a new disk image for each step of the annotation pipeline.
* A container described by a Dockerfile also provides complete
documentation of how the results were generated, which makes
replication a little easier.
* You are using a [docker-aware pipeline](http://nextflow.io/).

## Building the container

You'll need a copy of the latest
[Repbase-derived RepeatMasker libraries](http://www.girinst.org/server/RepBase/index.php)
(requires [free registration](http://www.girinst.org/accountservices/register.php)) and put it in the same directory as the
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
docker run -v $PWD:/in -w /in repeatmasker RepeatMasker scaffolds.fasta
```

This runs the container, mounting the current directory (and all
subdirectories) into the container at /in (`-v $PWD/in`). The `w /in`
arguments ensure that the command is run from this new directory. We
then specify that we want to use the `repeatmasker` image we just
created. Inside the container, the command `RepeatMasker
scaffolds.fasta` is run.

## Included in the container

The container includes the RMBlast and HMMER sequence search engines.
Cross_Match and ABBlast/WUBlast were not included due to licencing restrictions.

## Modifying the container

You are free to modify the container (perhaps you really want to use
Cross_Match, for example. Simply clone this repository (`git clone
https://github.com/robsyme/nextflow-annotate.git`) and modify the
Dockerfile before building.
