#!/usr/bin/env nextflow

params.reference = 'data/genome.fasta'
params.bamfiles = 'data/bams/*.bam'
params.species = 'fungi'
params.minscaffoldsize = 1000
params.maxintronlength = 1000
params.minintronlength = 10
params.cufflinks_overlap_radius = 10
params.cufflinks_pre_mrna_fraction = 0.25
params.cufflinks_min_isoform_fraction = 0.15

// Remove small contigs.
process remove_small_scaffolds {
  container 'genomicpariscentre/bioperl:1.6.924'
  
  input:
  file 'ref.fasta' from file(params.reference)

  output:
  file 'ref_trimmed.fasta' into ref_trimmed_for_filter_mito

  "trim_fasta_all.pl -i ref.fasta -out ref_trimmed.fasta -length ${params.minscaffoldsize}"
}

// We want to remove any scaffolds that show matches to some known
// mitochondrial sequence. For the moment, the process includes a
// download of the P. nodorum mitochondrial sequence. To make the
// search more comprehensive, simply append other sequences ot the
// 'mitorhondrial.fasta' input file. For the moment, we exclude
// sequences that have mitochondrial blast hits to more than 20% of
// their length.
process filter_mitochondrial {
  container 'robsyme/basics'

  input:
  file 'ref_trimmed.fasta' from ref_trimmed_for_filter_mito

  output:
  file 'nuclear_genome.fasta' into scaffolds_for_repeatmasker
  file 'nuclear_genome.fasta' into scaffolds_for_gff2gb
  file 'mitochondrial_genome.fasta' into scaffolds_mitochondrial

  """
curl 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=NC_009746&rettype=fasta&retmode=text' >> mitochondrial.fasta

makeblastdb -in mitochondrial.fasta -input_type fasta -dbtype nucl
samtools faidx ref_trimmed.fasta

blastn -query ref_trimmed.fasta -db mitochondrial.fasta -evalue 1 -outfmt '6 qseqid qstart qend qlen' -max_target_seqs 1 \
| awk 'BEGIN{OFS=\"\\t\"} {print \$1, \$2-1, \$3, \"hit_id_\" idcount++, \$4}' \
| sort -k1,1 -k2,2n \
| bedtools merge -i - -c 5 -o mean \
| bedtools complement -i - -g ref_trimmed.fasta.fai \
| bedtools genomecov -max 1 -i - -g ref_trimmed.fasta.fai \
| grep -v '^genome' \
| tee coverage.txt \
| awk '\$2 > 0 && \$5 > 0.8 {print \$1}' \
| xargs samtools faidx ref_trimmed.fasta \
> nuclear_genome.fasta

awk '\$2 > 0 && \$5 <= 0.8 {print \$1}' coverage.txt \
| xargs samtools faidx ref_trimmed.fasta \
> mitochondrial_genome.fasta
"""
}

// It's important to mask repetitive sequence before running automated
// gene calling software. Here we use repeatmasker and the Repbase
// database to identify and mask repetitive sequence in the nuclear
// genome.
process repeatmasker {
  container 'registry.robsyme.com/repeatmasker'

  input:
  file 'ref.fasta' from scaffolds_for_repeatmasker

  output:
  file 'ref.fasta.masked' into ref_masked_for_codingquarry

  "RepeatMasker -qq -frag 5000000 -gff -species ${params.species} -no_is ref.fasta"
}

// The user can supply many bam files from many conditions. For the
// purposes of gene calling, I'm going to merge them into one file for
// ease of handling. Differentiating conditions is of no use to this
// pipeline.
process merge_bams {
  container 'robsyme/basics'
  
  input:
  file '*.bam' from Channel.fromPath(params.bamfiles).toList()

  output:
  file 'merged.bam' into bam_for_cufflinks
  
  'samtools merge merged.bam *.bam'
}

// We would like to identify potential transcripts using cufflinks 
process cufflinks {
  container 'robsyme/cufflinks'

  input:
  file 'merged.bam' from bam_for_cufflinks

  output:
  file 'transcripts.gtf' into transcripts_gtf_for_codingquarry
  file 'transcripts.gtf' into transcripts_gtf_for_orf_extraction

  "cufflinks --overlap-radius ${params.cufflinks_overlap_radius} --pre-mrna-fraction ${params.cufflinks_pre_mrna_fraction} --min-isoform-fraction ${params.cufflinks_min_isoform_fraction} --min-intron-length ${params.minintronlength} --max-intron-length ${params.maxintronlength} merged.bam"
}

// The CodingQuarry denovo gene predictor uses intron/exon boundary
// information to improve the accuracy of gene annotation.
process codingquarry {
  container 'robsyme/codingquarry:1.2'

  input:
  file 'ref.fasta' from ref_masked_for_codingquarry
  file 'transcripts.gtf' from transcripts_gtf_for_codingquarry

  output:
  file 'out/PredictedPass.gff3' into codingquarry_gff_for_gff2gb

  '''
CufflinksGTF_to_CodingQuarryGFF3.py transcripts.gtf > transcripts.gff
CodingQuarry -f ref.fasta -t transcripts.gff
'''
}

process extract_cufflinks_transcripts {
  container 'robsyme/basics:0.7'

  input:
  file 'ref.fasta' from file(params.reference)
  file 'transcripts.gtf' from transcripts_gtf_for_orf_extraction

  output:
  file 'transcripts.fasta' into cufflinks_transcripts
  file 'transcripts.gff3' into cufflinks_transcripts_gff

  """
gt gtf_to_gff3 -tidy transcripts.gtf > transcripts_unsorted.gff3
gt gff3 -sort -tidy transcripts_unsorted.gff3 > transcripts.gff3
gt extractfeat -type exon -join -seqfile ref.fasta -matchdescstart transcripts.gff3 > transcripts.fasta
"""
}

// Generate a fasta file of open reading frames.
process identify_orfs {
  container 'robsyme/emboss:6.6.0'
  
  input: 
  file 'transcripts.fasta' from cufflinks_transcripts

  output:
  file 'transcript_orfs.fasta' into orfs_fasta
  
  "getorf -sequence transcripts.fasta -outseq transcript_orfs.fasta -minsize 100 -find 0"
}

process find_pfam_domains_in_transcript_orfs {
  container 'robsyme/pfam:28.0'

  input:
  file 'orfs.fasta' from orfs_fasta.splitFasta(by: 1000)

  output:
  file 'orf.domains' into transcript_orf_domains

  """
hmmscan -E 1e-5 -o orf.domains /opt/Pfam-A.hmm orfs.fasta
"""
}

process pfam_output_to_gff {
  container 'robsyme/basics:0.7'
  
  input:
  file 'orf.domains' from transcript_orf_domains
  file 'transcripts.gff3' from cufflinks_transcripts_gff

  output:
  file 'domains.gff3' into pfam_gff_hints

  """
pfam_to_gff3.rb < orf.domains > orf_domains.gff3
gff_transpose.rb --from orf_domains.gff3 --to transcripts.gff3 > domains.gff3
"""
}

// The training set for augustus requires that we supply short
// snippets of 'golden' genes which are used for training. Everything
// that is *not* identified as conding sequence is assumed to be
// non-coding. Here we take extract each of the genes +- 200 bp into
// their own genbank file. In cases where genes are separated by less
// than 200 bp, some coding sequence will be included in the neighbor,
// and will be interpreted as 'non-coding' sequence by the augustus
// training algorithm. A more sensible approach would be to divide the 
process gff_to_genbank {
  container 'robsyme/augustus:3.1'

  input:
  file 'genome.fasta' from scaffolds_for_gff2gb
  file 'full_length_genes.gff' from codingquarry_gff_for_gff2gb

  output:
  file 'out.gb' into golden_genbank_for_training

  script:
  "gff2gbSmallDNA.pl full_length_genes.gff genome.fasta 200 out.gb"
}























