#!/usr/bin/env nextflow

f1 = Channel.fromPath(params.fasta)

process indexGenomes {
  container 'robsyme/proteinortho'
  storeDir 'dbdir'
  
  input: 
  file '*' from f1.tap{ f2 }.toList()

  output:
  file '*' into db1
  
  "proteinortho5.pl -step=1 *.fasta"
}

def list = []
f2.eachWithIndex{ unit, idx -> list.add(idx) }

process runBlasts {
  container 'robsyme/proteinortho'
  storeDir 'dbdir'

  input:
  file '*' from db1.tap{ db2 }
  file "*" from f2.tap{ f3 }.toList()
  each index from list[0..-3]

  output:
  'myproject.*'

  "proteinortho5.pl -step=2 -startat=$index -stopat=$index -cpus=2 *.fasta"
}

process performClustering {
  container 'robsyme/proteinortho'
  storeDir 'dbdir'

  input:
  file '*' from db2
  file '*' from f3

  output:
  '*' into debug

  "proteinortho5.pl -step=2 -startat=$index -stopat=$index -cpus=2 *.fasta"
}

debug.view()





