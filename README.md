# nextflow-annotate

This is a push to gather together some tools that are helpful for
genome annotation, and serve as a forkable, version-controlled,
reusable, and citable record of our pipeline. The steps use nextflow
as a workflow engine so we can abstract the individual steps from
their execution environment (SGE, MPI or simple local multithreading).

This is not a push-button solution, but it can serve as a starting
point for annotating your new genome.

## Prerequisites

The minimum prerequisites are [docker](http://docker.io) and
[nextflow](http://nextflow.io), and a fasta file (henceforth
`scaffolds.fasta`) of your genome assembly.

Some steps require software or data with licences that restrict
distribution, but I've kept them to a minimum and will make it clear
when those pieces are necessary.

## Steps

Each of these steps corresponds to one of the nextflow recipes
provided by this repository.

### Transposon Identification

Taking cues from [jamg](http://jamg.sourceforge.net), we transcribe
all of the open reading frames and then use hhblit to match against a
database of known transposons. A GFF file is produced that describes
to position of the transposons that we find.

This uses two docker images, which will be pulled automatically from
the docker registry as needed.

### Finding Repeats
Repeats are an important part of the final genome annotation. I
recommend a two-step process:

1. Find denovo repeats with RepeatScout.
2. Use the RepeatScout output in conjuctions with the latest RepBase
library as input to RepeatMasker

I've taken care of the RepeatScout and RepeatMasker installation by
bundling them as docker images. The only hiccup is that RepBase
requires registration.
