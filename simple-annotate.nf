#!/usr/bin/env nextflow

genome = file(params.genome)
cegmaFile = file(params.cegma)
strainName = genome.getParent().getBaseName()
outFilename = params.out

process cleanGenome {
  input:
  genome

  output:
  stdout into cleanGenomes
        
  script:
  '''
  awk '/^>/ && !/[.*]/ {print(\$0, "[$strainName]")} /^>/ && /[.*]/ {print \$0} /^[^>]/ {print(toupper(\$0))}' '$genome' | sed "s/\015//"
  '''
}

(fastaForGFF, fastaForAug) = cleanGenomes.separate(2){ [it, it] }

process cegmaGFFtoFullerGFF {
  input:
  file 'cegmaFile' from cegmaFile

  output:
  stdout fullGFF

  '''
  fullerCegmaGFF.rb $cegmaFile
  '''
}

process cegmaGFFToGenbank {
  container 'robsyme/augustus'
  
  input:
  file gff from fullGFF
  file fasta from fastaForGFF

  output:
  file 'out.gb' into trainingGenbank
  
  '''
  gff2gbSmallDNA.pl $gff $fasta 5000 out.gb
  '''
}

process trainAndCallGenes {
  container 'robsyme/augustus'

  input:
  file trainingGenbank
  file genome from fastaForAug

  output:
  file 'out.txt' into trainedFile

  '''
  optimize_augustus.pl --species=fusarium_graminearum $trainingGenbank
  etraining --species=fusarium_graminearum $trainingGenbank
  augustus --species=fusarium_graminearum --gff3=on $genome > out.txt
  '''
}

trainedFile.subscribe { trained ->
  trained.copyTo(outFilename)
}

