#!/usr/bin/env nextflow

genome = file(params.genome)
cegmaFile = file(params.cegma)
outFilename = params.out

process cleanGenome {
  input:
  genome

  output:
  set name, stdout into cleanGenomes
        
  script:
  name = genome.getParent().getBaseName()

  println genome.toAbsolutePath()
  """
  awk '/^>/ && !/[.*]/ {print(\$0, "[$name]")} /^>/ && /[.*]/ {print \$0} /^[^>]/ {print(toupper(\$0))}' '$genome'
  sed -i -e "s/\015//" "$genome"
  """
}

process cegmaGFFtoFullerGFF {
  input:
  file 'cegmaFile' from cegmaFile

  output:
  stdout fullGFF

  """
  fullerCegmaGFF.rb $cegmaFile
  """
}

process cegmaGFFToGenbank {
  container 'robsyme/augustus'
  
  input:
  file gff from fullGFF
  file fasta from genome

  output:
  file 'out.gb' into trainingGenbank
  
  """
  gff2gbSmallDNA.pl $gff $fasta 5000 out.gb
  """
}

process trainAndCallGenes {
  container 'robsyme/augustus'

  input:
  file trainingGenbank
  file genome

  output:
  file 'out.txt' into trainedFile

  """
  optimize_augustus.pl --species=fusarium_graminearum $trainingGenbank
  etraining --species=fusarium_graminearum $trainingGenbank
  augustus --species=fusarium_graminearum --gff3=on $genome > out.txt
  """
}

trainedFile.subscribe { trained ->
  trained.copyTo(outFilename)
}
