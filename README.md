## funannotate-singularity

[![https://www.singularity-hub.org/static/img/hosted-singularity--hub-%23e32929.svg](https://www.singularity-hub.org/static/img/hosted-singularity--hub-%23e32929.svg)](https://singularity-hub.org/collections/3314)

Singularity containers for `funannotate`. The version tags on `Singularity.funannotate-base` and `Singularity.funannotate-deps` refer to the version of `funannotate` they were built for rather than the software in the containers.

### Dockerfile

Fork of Rob Syme's [RepeatMasker Dockerfile](https://github.com/robsyme/nextflow-annotate/tree/master/Dockerfiles/RepeatMasker-onbuild), just using a different base image.

Note to self: push a new tag to get Docker Hub to build a new container from the Dockerfile.

### Singularity.repeatmasker

Builds [the image from Docker Hub](https://hub.docker.com/r/tomharrop/funannotate-singularity) into a `.sif`

### Singularity.funannotate-base

Adds the funnanotate dependencies that can be installed from `apt`, `pip` and `cpan` to Singularity.repeatmasker

### Singularity.funannotate-deps

Manually installs the remaining dependencies into Singularity.funannotate-base

### Singularity.funannotate

Adds `funannotate` into Singularity.funannotate-deps and sets up environment

