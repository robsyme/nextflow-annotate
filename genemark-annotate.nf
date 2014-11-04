#!/usr/bin/env nextflow

genomeIn = file(params.genome)
strainName = genomeIn.getParent().getBaseName()

process cleanGenome {
  input:
  genomeIn

  output:
  stdout into cleanGenome
        
  script:
  """
  awk '/^>/ {print \$1} !/^>/ {print \$0}' $genomeIn | sed "s/\015//"
  """ 
}

process trainAndCallGenes {
  input:
  file 'genome.fasta' from cleanGenome

  output:
  set 'genome.fasta', 'genemark.gtf' into basicGTF

  """
  gmes_petap.pl --ES --fungus --sequence genome.fasta 
  """ 
}

process cleanup {
  input:
  set 'genome.fasta', 'genemark.gtf' from basicGTF

  output:
  file 'out.gff3.gz' into cleanAnnotations
  
  """
  gt gtf_to_gff3 -tidy genemark.gtf | gt gff3 -sort -tidy -o out.gff3
  echo "##FASTA" >> out.gff3
  awk '/^>/ && !/[.*]/ {print \$0, "[$strainName]"} !/^>/ || /[.*]/ {print \$0}' genome.fasta >> out.gff3
  gzip -c --best out.gff3 > out.gff3.gz
  """
}

cleanAnnotations.subscribe { gff3 ->
  gff3.copyTo(genomeIn.getParent() + "/genemark.gff3.gz")
}
