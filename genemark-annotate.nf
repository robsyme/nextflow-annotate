#!/usr/bin/env nextflow

params.genome = '**/scaffolds.fasta'

(strainNames, genomes) = Channel.fromPath(params.genome).separate(2) { path -> [path.getParent().getBaseName(), path] };
nameAndSequence = strainNames.merge( genomes ) {name, file -> [name, file]}

process cleanGenome {
  input:
    set strainName, 'raw.fasta' from nameAndSequence

  output:
  set strainName, 'genome.fasta' into cleanGenome

  """
  rename-fasta raw.fasta "${strainName}_scaffold" > genome.fasta
  """
}

process trainAndCallGenes {
  input:
  set strainName, 'genome.fasta' from cleanGenome

  output:
  set strainName, 'genemark.gtf', 'genome.fasta' into basicGTF

  """
  gmes_petap.pl --ES --fungus --sequence genome.fasta
  """
}

process gtfToGFF3 {
  input:
  set strainName, 'genemark.gtf' 'genome.fasta' from basicGTF

  output:
  set strainName, 'out.gff3.gz' into renamedAnnotations

  """
  gt gtf_to_gff3 -tidy genemark.gtf \
    | gt gff3 -sort -tidy \
    | rename-gff-ids $strainName > out.gff3
  rename-codons $strainName genemark.gtf >> out.gff3
  sort -k1,1 -k4,4n out.gff3 > tmp && mv tmp out.gff3
  echo "##FASTA" >> out.gff3
  awk '/^>/ {print \$0, "[${strainName}]"} !/^>/ {print \$0}' genome.fasta >> out.gff3
  gzip --best out.gff3
  """
}

renamedAnnotations.subscribe { strainName, gff ->
  gff.copyTo("${strainName}.gff3.gz")
}
