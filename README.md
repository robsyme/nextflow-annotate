## funannotate-singularity

[![https://www.singularity-hub.org/static/img/hosted-singularity--hub-%23e32929.svg](https://www.singularity-hub.org/static/img/hosted-singularity--hub-%23e32929.svg)](https://singularity-hub.org/collections/3314)

Containers for running funannotate with singularity

### Dockerfile

Fork of Rob Syme's [RepeatMasker Dockerfile](https://github.com/robsyme/nextflow-annotate/tree/master/Dockerfiles/RepeatMasker-onbuild), just using a different base image.

### Singularity.repeatmasker

Builds the image from Docker Hub into a `.sif`

### Singularity.funannotate-base

Adds the funnanotate dependencies that can be installed from `apt`, `pip` and `cpan` to Singularity.repeatmasker

### Singularity.funannotate-deps

Manually installs the remaining dependencies into Singularity.funannotate-deps

### Singularity.funannotate

Adds `funannotate` into Singularity.funannotate-deps and sets up environment

