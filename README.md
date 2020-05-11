## funannotate-singularity

[![https://www.singularity-hub.org/static/img/hosted-singularity--hub-%23e32929.svg](https://www.singularity-hub.org/static/img/hosted-singularity--hub-%23e32929.svg)](https://singularity-hub.org/collections/3314)

Singularity containers for `funannotate`.

### Usage

**Recommended: use the `funannotate-conda` image**.

To get the conda environment to activate you have to preface all your commands with `bash -c`. For example:

```bash
singularity exec funannotate-conda_1.7.4.sif bash -c 'funannotate check --show-versions'
```

AFAIK this is the only way to use conda in a singularity container, but please open an issue to let me know if there is a better way.

By default, funannotate uses the `FUNANNOTATE_DB` environment variable to define the path to the funannotate database. As of [7a3dbf9](https://github.com/TomHarrop/funannotate-singularity/commit/7a3dbf905639fd854f15bf1604630bb6e87068fd), `FUNANNOTATE_DB` is not set in the container. Provide the path to the database either by defining the variable or using the `-d` argument to funannotate.

Genemark is installed without a license. You need to get your own license, and bind it to ${HOME}/.gm_key when you run the container.

The following dependencies have issues in funannotate-conda_1.7.4:

- `ete3` isn't installed (see [here](https://github.com/nextgenusfs/funannotate/issues/387#issuecomment-593024593)).
- RepeatMasker isn't installed. Use the [Dfam-consortium/TETools](https://github.com/Dfam-consortium/TETools) Docker image or my Singularity version (below) to run RepeatMasker separately.
- `signalp` **can't be installed** because of licensing issues.

### Other containers

The version tags on `Singularity.funannotate-base` and `Singularity.funannotate-deps` refer to the version of `funannotate` they were built for rather than the software in the containers.

#### Singularity.tetools

Base for funannotate using [Dfam's TE Tools container](https://github.com/Dfam-consortium/TETools).
My singularity recipe pulls the docker image from `dfam/tetools`, adds `trf` and makes the RepeatMasker library directory writeable.

#### Singularity.funannotate-base

Adds the funnanotate dependencies that can be installed from `apt`, `pip` and `cpan` to Singularity.tetools

#### Singularity.funannotate-deps

Manually installs the remaining dependencies into Singularity.funannotate-base

#### Singularity.funannotate

Adds `funannotate` into Singularity.funannotate-deps and sets up environment

#### Singularity.interproscan

A container recipe to run `interproscan` outside `funannotate`. Because the container is 9.3 GB it's not hosted on Singularity Hub. Build it locally, and download and expand the Panther 14.1 database. `interproscan` looks for Panther data in /interproscan/data/panther/14.1, so bind the path to your downloaded Panther database into the interproscan as follows:

```bash
singularity exec \
    --writable-tmpfs \
    -B /path/to/panther:/interproscan/data/panther \
    interproscan_5.44-79.0.sif \
    interproscan.sh \
    -i /interproscan/test_proteins.fasta \
    -f tsv -dp \
    --output-dir test \
    --tempdir temp
```
