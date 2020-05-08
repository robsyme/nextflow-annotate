## funannotate-singularity

[![https://www.singularity-hub.org/static/img/hosted-singularity--hub-%23e32929.svg](https://www.singularity-hub.org/static/img/hosted-singularity--hub-%23e32929.svg)](https://singularity-hub.org/collections/3314)

Singularity containers for `funannotate`. The version tags on `Singularity.funannotate-base` and `Singularity.funannotate-deps` refer to the version of `funannotate` they were built for rather than the software in the containers.

### Usage

By default, funannotate uses the `FUNANNOTATE_DB` environment variable to define the path to the funannotate database. As of [7a3dbf9](https://github.com/TomHarrop/funannotate-singularity/commit/7a3dbf905639fd854f15bf1604630bb6e87068fd), `FUNANNOTATE_DB` is not defined in the container. Provide the path to the database either by defining the variable or using the `-d` argument to funannotate.

The RepeatMasker installation does not include Repbase libraries.

Genemark is installed without a license. You need to get your own license, and bind it to ${HOME}/.gm_key when you run the container.

The following dependencies have issues in 1.7.4:

- `proteinortho` **is not installed**
- `salmon` is installed at `/usr/bin/salmon`, but `funannotate check` doesn't find it
- `signalp` **can't be installed** because of licensing issues

### Singularity.tetools

New base for funannotate using [Dfam's TE Tools container](https://github.com/Dfam-consortium/TETools).
My singularity recipe pulls the docker image from `dfam/tetools`, adds `trf` and makes the RepeatMasker library directory writeable.

### Singularity.funannotate-base

Adds the funnanotate dependencies that can be installed from `apt`, `pip` and `cpan` to Singularity.tetools

### Singularity.funannotate-deps

Manually installs the remaining dependencies into Singularity.funannotate-base

### Singularity.funannotate

Adds `funannotate` into Singularity.funannotate-deps and sets up environment
