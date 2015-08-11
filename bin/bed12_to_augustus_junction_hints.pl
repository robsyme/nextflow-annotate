#!/usr/bin/env perl

=pod

=head1 USAGE

 This script will create a hints file for Augustus using junction reads. Junction reads are important because they annotate the introns.
 Give a bed12 file of junction reads (reduced with samtools dedup if possible) to get intron/exon boundary hints. See bedtools bamtobed to create the bed12

 example
  samtools rmdup -S SRR836188.coordSorted.bam - | bedtools bamtobed -bed12 | bed12_to_augustus_junction_hints.pl| ~/software/augustus/scripts/join_mult_hints.pl 

 Options:

 -help              This!
 -exon_min   :i     Minimum exon size (def. 50bp)
 -score_min  :i     Minimum score (def. 30)
 -max_exons  :i     Maximum number of exons that a single can span (def. 3)
 -min_match  :i     Number of min bases for each side of gap (def 20)
 -strandness :i     If RNAseq is directional, provide direction: 0 for unknown (default); or 1 for + strand; -1 for - strand

=head1 FORMATS

 BED12 input format
 
    1 chrom - The name of the chromosome (e.g. chr3, chrY, chr2_random) or scaffold (e.g. scaffold10671).
    2 chromStart - The starting position of the feature in the chromosome or scaffold. 
 NB The first base in a chromosome is numbered 0.
    3 chromEnd - The ending position of the feature in the chromosome or scaffold. The chromEnd base is not included in the display of the feature. For example, the first 100 bases of a chromosome are defined as chromStart=0, chromEnd=100, and span the bases numbered 0-99. 
    4 name - Defines the name of the BED line. This label is displayed to the left of the BED line in the Genome Browser window when the track is open to full display mode or directly to the left of the item in pack mode.
    5 score - A score between 0 and 1000. If the track line useScore attribute is set to 1 for this annotation data set, the score value will determine the level of gray in which this feature is displayed (higher numbers = darker gray). This table shows the Genome Browser's translation of BED score values into shades of gray:
    6 strand - Defines the strand - either '+' or '-'.
    7 thickStart - The starting position at which the feature is drawn thickly (for example, the start codon in gene displays).
    8 thickEnd - The ending position at which the feature is drawn thickly (for example, the stop codon in gene displays).
    9 itemRgb - An RGB value of the form R,G,B (e.g. 255,0,0). If the track line itemRgb attribute is set to "On", this RBG value will determine the display color of the data contained in this BED line. NOTE: It is recommended that a simple color scheme (eight colors or less) be used with this attribute to avoid overwhelming the color resources of the Genome Browser and your Internet browser.
    10 blockCount - The number of blocks (exons) in the BED line.
    11 blockSizes - A comma-separated list of the block sizes. The number of items in this list should correspond to blockCount.
    12 blockStarts - A comma-separated list of block starts. All of the blockStart positions should be calculated relative to chromStart. The number of items in this list should correspond to blockCount. 

 IN example
    scaffold_0      83      514     USI-EAS034_0010:2:97:6859:21372#0/1     40      +       83      514     255,0,0 2       119,6   0,425

 OUT format
  GFF3 with exonpart and intronpart
 scaffold_0      RNASeq        intronpart      1262    1414    .       -       .       src=JR;pri=5;grp=readname

=head1 AUTHORS

 Alexie Papanicolaou

        CSIRO Ecosystem Sciences
        alexie@butterflybase.org

=head1 DISCLAIMER & LICENSE

Copyright 2012-2014 the Commonwealth Scientific and Industrial Research Organization. 
See LICENSE file for license info
It is provided "as is" without warranty of any kind.


=cut

use strict;
use warnings;
use Pod::Usage;
use Getopt::Long;
use FindBin qw($RealBin);
use lib ("$RealBin/../PerlLib");
$ENV{PATH} .= ":$RealBin:$RealBin/../3rd_party/bin/";

my $min_exon_size = 50;
my $min_score     = 30;
my $max_exons     = 3;
my $min_match     = 20;
my ($help);
my $priority    = 5;
my $strandness = int(0);
my $bed_outfile = 'junctions.bed';
pod2usage $! unless &GetOptions(
            'help'        => \$help,
            'exon_min:i'  => \$min_exon_size,
            'score_min:i' => \$min_score,
            'max_exons:i' => \$max_exons,
            'min_match:i' => \$min_match,
            'outfile:s'   => \$bed_outfile,
            'priority:i'  => \$priority,
	    'strandness:i' => \$strandness  
);

pod2usage if $help;

my $strand;
if (!$strandness || $strandness == 0 ){
	$strand = '.';
}elsif ($strandness > 0){
	$strand = '+';
}elsif ($strandness < 1){
	$strand = '-';
}else{
die;
}

open( BEDJUNCTIONS, ">$bed_outfile" );

OUTER: while ( my $ln = <STDIN> ) {
 chomp($ln);
 my @data = split( "\t", $ln );

# too many blocks - i.e. too many exons are being linked... biologically impossible?!
 next if $data[9] > $max_exons;

 #too low score
 next if $data[4] < $min_score;

 # numbering from 1
 $data[1]++;
 $data[2]++;

 #remove any /1 /2 from read name
 $data[3] =~ s/\/[0-2]$//;
 my @blockSizes  = split( ",", $data[10] );
 my @blockStarts = split( ",", $data[11] );
 die unless scalar(@blockSizes) == scalar(@blockStarts);
 for ( my $i = 0 ; $i < @blockStarts ; $i++ ) {
  next OUTER if $blockSizes[$i] < $min_match;
  $blockStarts[$i] += $data[1];
 }
 if ( scalar(@blockSizes) == 1 ) {

  # no intron
  my $type  = 'exonpart';
  my $start = $data[1];
  my $stop  = $data[2];
  print $data[0]
    . "\tRNASeq\t"
    . $type . "\t"
    . $start . "\t"
    . $stop . "\t"
    . $data[4] 
    . "\t$strand\t.\tsrc=JR;pri=$priority;grp="
    . $data[3] . ";\n";
 }
 else {
  print BEDJUNCTIONS $ln . "\n";

  #exons first
  for ( my $i = 0 ; $i < scalar(@blockStarts) ; $i++ ) {
   my $type  = 'exonpart';
   my $start = $blockStarts[$i];
   my $stop  = $start + $blockSizes[$i] - 1;
   print $data[0]
     . "\tRNASeq\t"
     . $type . "\t"
     . $start . "\t"
     . $stop . "\t"
     . $data[4] 
     . "\t$strand\t.\tsrc=JR;pri=$priority;grp="
     . $data[3] . ";\n";
  }

  #introns
  for ( my $i = 1 ; $i < scalar(@blockStarts) ; $i++ ) {
   my $type  = 'intron';
   my $start = ( $blockStarts[ $i - 1 ] + $blockSizes[ $i - 1 ] - 1 ) + 1;
   my $stop  = $blockStarts[$i] - 1;
   print $data[0]
     . "\tRNASeq\t"
     . $type . "\t"
     . $start . "\t"
     . $stop . "\t"
     . $data[4] 
     . "\t$strand\t.\tsrc=JR;pri=$priority;grp="
      . $data[3] . ";\n";
  }
 }
}
close BEDJUNCTIONS;
