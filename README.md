## funannotate-singularity

[![https://www.singularity-hub.org/static/img/hosted-singularity--hub-%23e32929.svg](https://www.singularity-hub.org/static/img/hosted-singularity--hub-%23e32929.svg)](https://singularity-hub.org/collections/3314)

Singularity containers for `funannotate`. The version tags on `Singularity.funannotate-base` and `Singularity.funannotate-deps` refer to the version of `funannotate` they were built for rather than the software in the containers.

### Singularity.tetools

New base for funannotate using [Dfam's TE Tools container](https://github.com/Dfam-consortium/TETools).
My singularity recipe pulls the docker image from `dfam/tetools`, adds `trf` and makes the RepeatMasker library directory writeable.

### Singularity.funannotate-base

Adds the funnanotate dependencies that can be installed from `apt`, `pip` and `cpan` to Singularity.tetools

### Singularity.funannotate-deps

Manually installs the remaining dependencies into Singularity.funannotate-base

### Singularity.funannotate

Adds `funannotate` into Singularity.funannotate-deps and sets up environment
