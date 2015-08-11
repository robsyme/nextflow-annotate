# RepeatMasker Container

The RepBase licence prohibits distribution of the libraries, so we
need a two-step process to build the final docker image. The first
step is the installation of the dependencies. This has already been
done inside the `robsyme/repeatmasker-onbuild` image.

The second step is to download and install the RepBase libraries. The
repeatmasker-onbuild image takes care of the installation. It only
requires that you download the repbase images to a file names
'repeatmaskerlibraries.tar.gz' next to the Dockerfile (in this
directory, for example).

The Dockerfile is minimal, containing only:

```
FROM robsyme/repeatmasker-onbuild
```

If you have this tiny Dockerfile and the RepBase libraries, you can
build and use your docker image with:

```sh
docker build -t myrepeatmasker .
cd /path/to/data
docker run -v $PWD:/in -w /in myrepeatmasker RepeatMasker scaffolds.fasta
```

Note that only the current directory (and its children) is mounted
inside the container, so you need to ensure that your scaffolds file
is in the current path tree.
