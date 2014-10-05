#!/usr/bin/env nextflow

params.genomes = 'data/**/genome.fasta'
genomes = Channel.fromPath(params.genomes)

process cleanGenome {
        input:
        val genome from genomes

        output:
        set name, stdout into cleanGenomes
        
        script:
        name = genome.getParent().getBaseName()
        """
        awk '/^>/ && !/[.*]/ {print(\$0, "[$name]")} /^>/ && /[.*]/ {print \$0} /^[^>]/ {print(toupper(\$0))}' '$genome'
        sed -ie "s/\015//" $genome
        """
}

process RepeatMasker {
        container 'repeatmasker'
        
        input:
        set name, 'genome' from cleanGenomes

        output:
        set name, 'genome.masked' into maskedGenomes
        
        """
        RepeatMasker $genome
        """
}

process getorf {
        container 'robsyme/emboss'

        input:
        set name, 'maskedGenome' from maskedGenomes

        output:
        file 'orfs.aa.fasta' into orfFiles

        """
        getorf -sequence $maskedGenome -outseq orfs.aa.fasta -minsize 150 -find 1
        """
}

orfFiles.splitFasta(record: [header: true, seqString: true])
        .filter { record ->
             xCount = record.seqString.count('X')
             length = record.seqString.size()
             xCount / length < 0.3
        }
        .map { record ->
             record.seqString = record.seqString.replaceAll('X','')
             record
        }
        .groupBy { record ->
                 record.header.find(/\[.*\]/)
        }
        .subscribe { record ->
                   println record
        }

        

