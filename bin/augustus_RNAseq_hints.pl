#!/usr/bin/env perl

=pod

=head1 TODO

merge all rnseq hints at the end. maintain grp
run test with 100 genes, not 390+


=head1 NAME

 augustus_RNAseq_hints.pl

=head1 USAGE

Create hint files for Augustus using RNASeq/EST. One is junction reads (excellent for introns), the other is RNASeq/EST coverage

Mandatory options:

 -bam|in           s  The input BAM file (co-ordinate sorted).
 -genome|fasta     s  The genome assembly FASTA file.

Other options:

 -strandness       i  If RNAseq is directional, provide direction: 0 for unknown (default); or 1 for + strand; -1 for - strand
 -min_score        i  Minimum score for parsing (defaults to 20)
 -window           i  Window size for coverage graph (defaults to 50)
 -background_fold  i  Background (defaults to 4), see perldoc
 -no_hints            Don't create hints file for Augustus, just process junction reads

=head1 DESCRIPTION

Background: The problem of getting the intron boundary correct is that rnaseq doesn't go to 0 at the intron, but continues at a background level.
For that reason, stop if it is -background_fold times lower than a previous 'good' value


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
use Data::Dumper;
use Getopt::Long;
use List::Util qw(sum);
use Pod::Usage;
use File::Basename;
use FindBin qw($RealBin);
use lib ("$RealBin/../PerlLib");
$ENV{PATH} .= ":$RealBin:$RealBin/../3rd_party/bin/";

my ( $samtools_exec, $bedtools_exec, $bed_to_aug_script ) = &check_program( 'samtools', 'bedtools','bed12_to_augustus_junction_hints.pl' );



#Options
my ( @bamfiles, $genome, $help,$no_hints );
my $window           = 50;
my $min_score        = 20;
my $strandness       = int(0);
my $background_level = 4;
pod2usage $! unless &GetOptions(
            'help'              => \$help,
            'bam|in:s{,}'          => \@bamfiles,
            'genome|fasta:s'    => \$genome,
            'min_score:i'       => \$min_score,
            'strandness:i'      => \$strandness,
            'window:i'          => \$window,
            'background_fold:i' => \$background_level,
	    'nohints|no_hints'  => \$no_hints
);

pod2usage if $help;

pod2usage "Cannot find the BAM or genome FASTA file\n"
  unless $bamfiles[0]
   && -s $bamfiles[0]
   && $genome
   && ( -s $genome || -s $genome . '.fai' );

my $strand;
if ( !$strandness || $strandness == 0 ) {
 $strand = '.';
}
elsif ( $strandness > 0 ) {
 $strand = '+';
}
elsif ( $strandness < 1 ) {
 $strand = '-';
}
else {
 die;
}

my $master_bamfile;
if (scalar(@bamfiles == 1)){
  $master_bamfile = $bamfiles[0];
}else{
	foreach my $bamfile (@bamfiles){
		die "Cannot find $bamfile\n" unless -s $bamfile;
	}
	$master_bamfile = 'master_bamfile.bam';
	&process_cmd("$samtools_exec merge -r $master_bamfile ".join(" ",@bamfiles)) unless -s $master_bamfile;
}

&process_cmd("$samtools_exec faidx $genome") unless -s $genome . '.fai';
die "Cannot index genome $genome\n" unless -s $genome . '.fai';

unless (-e "$master_bamfile.junctions.completed"){
 &process_cmd("$samtools_exec rmdup -S $master_bamfile - | $bedtools_exec bamtobed -bed12 | $bed_to_aug_script -prio 7 -out $master_bamfile.junctions.bed > $master_bamfile.junctions.hints" );
 # For JBrowse
 &process_cmd("$bedtools_exec bedtobam -bed12 -g $genome.fai -i $master_bamfile.junctions.bed| $samtools_exec sort -m 1073741824 - $master_bamfile.junctions");
 &process_cmd("$samtools_exec index $master_bamfile.junctions.bam");
 # For Augustus
 &only_keep_intronic("$master_bamfile.junctions.hints");
 &touch("$master_bamfile.junctions.completed");
}

unless (-e "$master_bamfile.coverage.bg.completed"){
 # For JBrowse
 &process_cmd("$bedtools_exec genomecov -split -bg -g $genome.fai -ibam $master_bamfile| sort -S 1G -k1,1 -k2,2n > $master_bamfile.coverage.bg");
 &process_cmd("bedGraphToBigWig $master_bamfile.coverage.bg $genome.fai $master_bamfile.coverage.bw") if `which bedGraphToBigWig`; 
 &touch("$master_bamfile.coverage.bg.completed");
}

unless (-e "$master_bamfile.coverage.hints.completed" && !$no_hints){
 &bg2hints("$master_bamfile.coverage.bg") ;
 &merge_hints("$master_bamfile.coverage.hints");
 &touch("$master_bamfile.coverage.hints.completed");
}

if (    -e "$master_bamfile.junctions.completed"
     && -e "$master_bamfile.coverage.hints.completed" )
{
 unless (-e "$master_bamfile.rnaseq.completed"){
  my $augustus_script_exec = $RealBin.'/../3rd_party/augustus/scripts/join_mult_hints.pl';
  if (-s $augustus_script_exec){
  	&process_cmd("cat $master_bamfile.junctions.hints.intronic $master_bamfile.coverage.hints| sort -S 1G -n -k 4,4 | sort -S 1G -s -n -k 5,5 | sort -S 1G -s -n -k 3,3 | sort -S 1G -s -k 1,1| $augustus_script_exec > $master_bamfile.rnaseq.hints" );
	  &touch("$master_bamfile.rnaseq.completed");
  }
 }
 print "Done!\n";
}
elsif (!$no_hints) {
 die "Something went wrong....\n";
}else{
  print "Done, no hints were processed as requested\n";
}
###
sub check_program() {
 my @paths;
 foreach my $prog (@_) {
  my $path = `which $prog`;
  pod2usage "Error, path to a required program ($prog) cannot be found\n\n"
    unless $path =~ /^\//;
  chomp($path);
  $path = readlink($path) if -l $path;
  push( @paths, $path );
 }
 return @paths;
}
###
sub process_cmd {
 my ($cmd) = @_;
 print "CMD: $cmd\n";
 my $ret = system($cmd);
 if ( $ret && $ret != 256 ) {
  die "Error, cmd died with ret $ret\n";
 }
 return $ret;
}

sub bg2hints() {
 my $bg      = shift;
 my $outfile = $bg;
 $outfile =~ s/.bg$/.hints/;
 open( IN, $bg );
 my ( @array, %area );
 while ( my $ln = <IN> ) {
  chomp($ln);
  my @data = split( "\t", $ln );
  next unless $data[3] >= $min_score;
  # store data in an array
  for ( my $i = $data[1] ; $i <= $data[2] ; $i++ ) {
   # co-ords in bg are 0-based; hints/gff is 1-based
   $area{ $data[0] }{$i+1} = $data[3];
  }
 }

 # print final area
#TODO: NB this is still wrong.
#~/workspace/transcripts4community/jamg/test_suite 
#rm -f gsnap.drosoph_50M_vs_droso_opt_temp.concordant_uniq.bam.coverage.hints.completed gsnap.drosoph_50M_vs_droso_opt_temp.concordant_uniq.bam.coverage.hints ; ../bin/augustus_RNAseq_hints.pl -dir ../3rd_party/augustus.2.7 -bam gsnap.drosoph_50M_vs_droso_opt_temp.concordant_uniq.bam -genome optimization.fasta; less gsnap.drosoph_50M_vs_droso_opt_temp.concordant_uniq.bam.coverage.hints
 open( OUT, ">$outfile" );
 foreach my $ref ( sort { $a cmp $b } keys %area ) {
  my @coords = sort { $a <=> $b } ( keys %{ $area{$ref} } );
  for ( my $i = $coords[0] ; $i < @coords ; $i++ ) {
   next if ( !$area{$ref}{$i} );
   my $k = $i + $window;
   $k-- while ( !$area{$ref}{$k} );
   next if $k == $i;
   my @splice;
   
   for ( my $v = $i ; $v <= $k ; $v++ ) {
    my $level = $area{$ref}{$v};
    my $previous_level = $v eq $i ? int(0) : $area{$ref}{$v-1};
    my $next_level = $v eq $k ? 1e6 : $area{$ref}{$v+1};
    # the problem of getting the intron boundary correct is that
    # rnaseq doesn't go to 0 at the intron, but continues at a
    # background level. stop if it is 4 times lower than a previous 'good' value
    if (
    !$level ||
     ( $previous_level  && ( $previous_level > ( $level * $background_level ) ))
     || $next_level && ($level > ( $next_level * $background_level ))
     )
    {
     $k = $v - 1;
     last;
    }
    push( @splice, $level );
   }
#   next if scalar(@splice) < ( $window / 2 );
   my $median = &median( \@splice );
   $median = $splice[0] if !$median;
   next unless $median && $median >= $min_score;
   print OUT $ref
     . "\tRNASeq\texonpart\t"
     . $i . "\t"
     . $k . "\t"
     . $median
     . "\t$strand\t.\tsrc=R;pri=4\n";
   $i +=  $window ;
  }
 }

 close OUT;
 close IN;
 return $outfile;
}

sub only_keep_intronic(){
 my $file = shift;
 my %hash;
 open (IN,$file);
 while (my $ln=<IN>){
  next unless $ln=~/\tintron\t/;
  if ($ln=~/grp=([^;]+)/){
   $hash{$1}++;
  }
 }
 close IN;
 open (IN,$file);
 open (OUT,">".$file.".intronic");
 while (my $ln=<IN>){
  if ($ln=~/\tintron\t/){
   print OUT $ln ;
  }
  elsif ($ln=~/grp=([^;]+)/){
   print OUT $ln if $hash{$1};
  }
 }
 close IN;
 close OUT;
}

sub merge_hints(){
 my $file = shift;
 open (IN,$file);
 open (OUT,">$file.merged");
 my (@current_line,@previous_line);
while (<IN>) {
    @current_line = split /\t/;
    if (!@previous_line){
        @previous_line = @current_line;
    }elsif(($current_line[0] eq $previous_line[0]) && ($current_line[2] eq $previous_line[2]) && 
    (($current_line[3] >= $previous_line[3]) && ($current_line[4] <= $previous_line[4]))
      && ($current_line[6] eq $previous_line[6])){
     # update previous_line by adding current to it
        chomp($previous_line[8]);
        $previous_line[8] =~ s/(grp=[^;]*);*//;
        my $grp = $1;
        $grp .= ';' if $grp;
        $grp = '' if !$grp;
        my ($lm,$m)=(1,1);
        if ($previous_line[8] =~ /mult=(\d+);/){
            $lm = $1;
            $previous_line[8] =~ s/mult=\d+;//;
        }
        if ($current_line[8] =~ /mult=(\d+);/){
            $m = $1;
        }
        $previous_line[8] = "mult=" . ($lm+$m) . ";$grp" . $previous_line[8]."\n";
     
    }elsif (
    !(($current_line[0] eq $previous_line[0]) && ($current_line[2] eq $previous_line[2]) && ($current_line[3] == $previous_line[3]) && ($current_line[4] == $previous_line[4])  && ($current_line[6] eq $previous_line[6]))
    ){
        print OUT join("\t",@previous_line);
        @previous_line = @current_line;
    }
    
     else {
        # update previous_line by adding current to it
        chomp($previous_line[8]);
        $previous_line[8] =~ s/(grp=[^;]*);*//;
        my $grp = $1;
        $grp .= ';' if $grp;
        $grp = '' if !$grp;
        my ($lm,$m)=(1,1);
        if ($previous_line[8] =~ /mult=(\d+);/){
            $lm = $1;
            $previous_line[8] =~ s/mult=\d+;//;
        }
        if ($current_line[8] =~ /mult=(\d+);/){
            $m = $1;
        }
        $previous_line[8] = "mult=" . ($lm+$m) . ";$grp" . $previous_line[8]."\n";
    }
 }
  print OUT join("\t",@previous_line) if (@previous_line);
  close IN;
  close OUT;
  unlink($file);
  rename($file.'.merged',$file);
}

sub touch() {
 my $file = shift;
 system("touch $file");
}

sub mean() {
 return sum(@_) / @_;
}

sub median() {
 my $array_ref = shift;
 my @sorted = sort { $a <=> $b } @{$array_ref};
 return $sorted[ int( @sorted / 2 ) ];
}
