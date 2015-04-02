# RepeatMasker-onbuild Container

This simple container is designed to make it easier to run
RepeatMasker on new machines. If you have your own permanent 
[big-ass-server](http://jermdemo.blogspot.ca/2011/06/big-ass-servers-and-myths-of-clusters.html),
you might want to simply install the software as usual and that's very
sensible.

There are also plenty of situations were you might want to use a
container:

* You are using compute resources on EC2 or GCE and you don't want to
make a new disk image for each step of the annotation pipeline (and
you don't want the hastle of cloud orchestration tools and scripts.
* A container described by a Dockerfile also provides complete
documentation of how the results were generated, which makes
replication a little easier.
* You are using a [docker-aware pipeline](http://nextflow.io/).

## What Does the Image Contain?

This images contains the RepeatMasker binary and its prerequisites
hmmer, rmblast, blast+ and trf. It *does not* contain the RepBase
database. You will need to register and downlod this yourself and then
build a new image based on this one. It also does not contain the
search engines Cross_Match and ABBlast/WUBlast because of licencing
restrictions.

## Running RepeatMasker from inside a container

You'll need a copy of the latest
[Repbase-derived RepeatMasker libraries](http://www.girinst.org/server/RepBase/index.php)
(requires
[free registration](http://www.girinst.org/accountservices/register.php)),
renamed as `repeatmaskerlibraries.tar.gz`. We then create a new
Dockerfile and generate our new image

```sh
wget --user your_username \
    --password 12345 \
    -O repeatmaskerlibraries.tar.gz \
    http://www.girinst.org/server/RepBase/protected/repeatmaskerlibraries/repeatmaskerlibraries-20140131.tar.gz
echo "FROM robsyme/repeatmasker-onbuild" > Dockerfile
docker build -t myrepeatmasker .
```

We can then run RepeatMasker:

```sh
docker run -v $PWD:/in -w /in myrepeatmasker RepeatMasker scaffolds.fasta
```

This runs the container, mounting the host's current directory (and
all subdirectories) inside the container at `/in` (`-v $PWD/in`). The `w
/in` arguments ensure that the command is run from this new
directory. We then specify that we want to use the `myrepeatmasker`
image we just created. Inside the container, the command `RepeatMasker
scaffolds.fasta` is run.

## Modifying the container

You are free to modify the container (perhaps you really want to use
Cross_Match, for example. Simply clone this repository (`git clone
https://github.com/robsyme/nextflow-annotate.git`) and modify the
Dockerfile before building.
