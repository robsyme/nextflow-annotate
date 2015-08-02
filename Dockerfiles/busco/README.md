# BUSCO in docker

This is a repository that contains the
[BUSCO](http://busco.ezlab.org/) software for 'assessing genome
assembly and annotation completeness with single-copy orthologs'. It
contains preconfigured installations of the BUSCO prerequisites,
including Augustus 3.0, hmmer, ncbi-blast+, and emboss.

## Using the container

Let's say I have my fungal genome `scaffolds.fasta` in the current
directory, I can run busco by first downloading the profiles (in my
case fungi):

    wget http://busco.ezlab.org/files/fungi_buscos.tar.gz
    tar -xzvf fungi_buscos.tar.gz && rm fungi_buscos.tar.gz

I can then run the busco docker container

    docker run --rm -v $PWD:/in -w /in robsyme/busco \
        busco -in scaffolds.fasta -o my_run --lineage fungi

I might consider bundling in the profiles into lineage-specific docker
images, but busco unhelpfully prepends a '`.`' to the lineage path, so
I'd have to create a runner script that links in the profile folder
into the current working directory, which is a bit messy. For the
moment, I'm leaving the profiles to the user.

