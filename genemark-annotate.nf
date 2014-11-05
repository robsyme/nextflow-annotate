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
  awk '/^>/ {print \$1} !/^>/ {print toupper(\$0)}' raw.fasta | sed "s/\015//" > genome.fasta
  """
}

process trainAndCallGenes {
  maxForks 7
  
  input:
  set strainName, 'genome.fasta' from cleanGenome

  output:
  set strainName, 'genemark.gtf' into basicGTF

  """
  gmes_petap.pl --ES --fungus --sequence genome.fasta
  """
}

process gtfToGFF3 {
  input:
  set 'genome.fasta', 'genemark.gtf' from basicGTF

  output:
  set strainName, 'out.gff3' into cleanAnnotations

  """
  gt gtf_to_gff3 -tidy genemark.gtf | gt gff3 -sort -tidy -o out.gff3
  """
}

process renameIDs {
  input:
  set strainName, 'in.gff3' from cleanAnnotations

  output:
  set strainName, 'out.gff3' into renamedAnnotations

  """
  rename-gff-ids $strainName in.gff3 > out.gff3
  """
}

renamedAnnotations.subscribe { strainName, gff ->
  gff.copyTo("$strainName.noseq.gff3")
}
