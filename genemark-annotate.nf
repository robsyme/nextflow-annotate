#!/usr/bin/env nextflow

genome = file(params.genome)
cegmaFile = file(params.cegma)
strainName = genome.getParent().getBaseName()
outFilename = params.out

process cleanGenome {
  input:
  genome

  output:
  stdout into cleanGenome
        
  script:
  """
  awk '/^>/ && !/[.*]/ {print(\$0, "[$strainName]")} /^>/ && /[.*]/ {print \$0} /^[^>]/ {print(toupper(\$0))}' '$genome' | sed "s/\015//"
  """
}

process trainAndCallGenes {
  container 'robsyme/augustus'

  input:
  file trainingGenbank
  file genome from cleanGenome

  output:
  file 'out.gff3' into annotation

  """
  gm_es.pl --min_contig 5000 --BP ON $genome
  gt gtf_to_gff3 -tidy genemark_hmm.gtf | gt gff3 -sort -tidy -o out.gff3
  """
}

trainedFile.subscribe { trained ->
  trained.copyTo(outFilename)
}
