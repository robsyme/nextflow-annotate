#!/usr/bin/env nextflow

(f1, f2, f3) = Channel.fromPath(params.fasta).separate(3){ [it,it,it] }

params.cpus = 1
params.outdir = 'proteinortho_out'
outdir = file(params.outdir)
outdir.mkdirs()


process indexGenomes {
  container 'robsyme/proteinortho'
  storeDir outdir
  
  input: 
  file '*' from f1.toList()

  output:
  file '*' into db1
  file '*' into db2
  
  "proteinortho5.pl -step=1 *.fasta"
}

def list = []
f2.eachWithIndex{ unit, idx -> list.add(idx) }

process runBlasts {
  container 'robsyme/proteinortho'
  storeDir outdir

  input:
  file '*' from db1
  file "*" from f2.toList()
  each index from list[0..-3]

  output:
  file 'myproject.*' into blastresults

  "proteinortho5.pl -verbose -step=2 -startat=$index -stopat=$index -cpus=${params.cpus} *.fasta"
}

process performClustering {
  container 'robsyme/proteinortho'
  storeDir outdir

  input:
  file '*' from blastresults
  file '*' from db2
  file '*' from f3.toList()

  output:
  file 'myproject.*' into proteinortho_out
  
  "proteinortho5.pl -step=3 -singles -verbose *.fasta"
}

proteinortho_out.flatten().subscribe{ println("Proteinortho output file: $it") }





