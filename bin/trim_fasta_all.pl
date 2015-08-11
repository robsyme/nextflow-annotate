#!/usr/bin/env  perl
package trim_fasta_all;
use strict;
use warnings;

use Data::Dumper;
our $VERSION = '1.0';

#04MAR11: Added GC/AT ratio check as ratio cutoff

=head1 NAME

trim_fasta_all.pl - removes sequences from a FASTA file 

=head1 VERSION

 Version 0.2

=head1 SYNOPSIS

trim_fasta_all.pl [options] <infiles>

removes sequences from a FASTA file. See perldoc for more info.

	'i|fa|fasta=s'    => FASTA file to trim. You can also give multiples as arguments without any -i/-fa option.
	'outfile:s'	=> Optionally, the name of the trimmed outfile
	'blastfile:s'	=> BLASTFILE to retrieve sequences from
	'blastquery'		=> grab BLAST queries 
	'blasthit'       =>  grab BLAST hits
	'evalue=s'	=> Evalue cut-off for blastfile (currently broken)
	'c|character=s' => Characters to look for. If present, remove sequence.
	'le|length=i'   => Number of minimum characters
	'p|proportion'  => Discard sequences for which a mononucleotide frequency exceeds this proportion 
	'ratio'		=> Discard sequences for which the GC or AT frequency exceeds this ratio
	'x'             => Do not include the Xx characters when calculating size of sequence
	xdiscard        => Discard if these many Xs
	'npl'           => Do not include these characters when calculating size: NPLnpl
	'lc|lowercase'  => Do not include lowercase characters when calculating size of sequence (e.g. to not include low quality bases)
	'id|idfile=s'   => A second FASTA file containing IDs to remove from FASTA file. Alternatively a text file with one ID per line
	'descr'		=> For above: search description line instead of primary id.
	'ci'		=> Case insensitivity for above two options
	'invert'	=> Invert match (invert output filenames)
	'log'           => Keep a log file
	'df'            => Do not write discarded sequences (less IO)
	'solq'          => Input is FASTQ (Solexa 1.3-1.4)
	'sanq'          => Input is FASTQ (Sanger)
	'casava18'	=> Input is Fastq from Casava 1.8
	'single'	    => Entire output sequence/quality is in a single line (no BioPerl; good for parsing)
	'ghash'		=> Use a Glib hash table (less memory, slower)

=head1 DESCRIPTION

Processes file (-fa) when certain character(s) are present (-c); or a list of IDs is provided (-id); or a certain length-cut off is not satisfied (-le); or a proportion of nucleotide frequence can be specified (-p) instead. The -log option produces a log file reporting what happened to each sequence 
The option to not include Xs and/or NPLs and/or lower-case characters in the cut-off calculation is forced with -x and/or -npl and/or -lc respectively.
Uses BioPerl. A disk-friendly function (-df) prevents the FASTA file of discarded sequences of being written.

=head1 AUTHORS

 Alexie Papanicolaou 1 2

	1 Max Planck Institute for Chemical Ecology, Germany
	2 Centre for Ecology and Conservation, University of Exeter, UK
	alexie@butterflybase.org

=head1 DISCLAIMER & LICENSE

This software is released under the GNU General Public License version 3 (GPLv3).
It is provided "as is" without warranty of any kind.
You can find the terms and conditions at http://www.opensource.org/licenses/gpl-3.0.html.
Please note that incorporating the whole software or parts of its code in proprietary software
is prohibited under the current license.

=head1 BUGS & LIMITATIONS

None known so far.

=cut
use Bio::SeqIO;
use Bio::SearchIO;
use Getopt::Long;
#use Tie::GHash;
use Pod::Usage;
$| = 1;
my (
	 $character,    @infiles,     $length_cutoff, $xmask, $xdiscard,
	 $nplmask,      $ci,          $blastfile,     $evalue_cutoff,
	 $lcmask,       $prop_cutoff, @idfiles,       $log,
	 $logfile,      $invert,      $sangerfastq,   $blast_hit,$blast_query,
	 $user_outfile, $df,          %ids,           $help,
	 $convert2uc,   $descr_flag,  $solexafastq,   $search_accession,
	 $seq_search,   $single_line, $ratio_cutoff,  $ghash, $overwrite, $casava
);
&GetOptions(
	'i|fa|fasta=s{,}' => \@infiles,
	'blastfile=s'     => \$blastfile,
	#'evalue=s'	=> \$evalue_cutoff,
	'c|character=s'   => \$character,
	'le|length=i'     => \$length_cutoff,
	'p|proportion=f'  => \$prop_cutoff,
	'ratio=f'	  => \$ratio_cutoff,
	'x'               => \$xmask,
	'uc|uppercase'    => \$convert2uc,
	'npl'             => \$nplmask,
	'lc|lowercase'    => \$lcmask,
	'ids|idfile=s{,}' => \@idfiles,
	'description'     => \$descr_flag,
	'invert'          => \$invert,
	'ci'              => \$ci,
	'log'             => \$log,
	'df'              => \$df,
	'h|help'          => \$help,
	'solq'            => \$solexafastq,
	'sanq'            => \$sangerfastq,
	'seq'             => \$seq_search,
	'outfile:s'       => \$user_outfile,
	'single'          => \$single_line,
	'blastquery'     => \$blast_query,
	'blasthit'       => \$blast_hit,
	'ghash'	=> \$ghash,
	'overwrite' => \$overwrite,
	'casava18'=>\$casava,
	'xdiscard:i' => \$xdiscard,
	  #'accessions'=> \$search_accession,
);
if ($help) { pod2usage; }
@infiles = @ARGV if !@infiles;
unless (@infiles) {
	print "Failed to provide or find input file\n";
	pod2usage;
}
tie %ids,'Tie::GHash' if $ghash;

unless (    $character
		 || $length_cutoff
		 || $prop_cutoff || $ratio_cutoff || $xdiscard
		 || @idfiles
		 || $blastfile )
{
	die("Nothing to do!\n");
}
unless ($evalue_cutoff) { $evalue_cutoff = 1; }
my $counter = int(0);
if ($casava){
	$sangerfastq=1;
	undef($solexafastq);	
}
foreach my $idfile (@idfiles) {
	if ( $idfile && -s $idfile ) {
		my $pattern;
		if   ($descr_flag) { $pattern = '^\s*\S+\s+(.+)$'; }
		else               { $pattern = '^[>@]?\s*(\S+)\s*'; }
		my @test_lines = `head $idfile`;
		foreach my $test (@test_lines) {
			if ( $test =~ /^>/ ) { $pattern = "Bio::SeqIO"; }
		}
#		my $number = `wc -l < $idfile`;
#		chomp($number);
#		$number /= 2 if $pattern eq "Bio::SeqIO";
		print "Building hash from $idfile with $pattern\n";
		my $flag;

		if ( $pattern eq "Bio::SeqIO" ) {
			my $id_obj = new Bio::SeqIO( -file => $idfile, -format => "fasta" );
			while ( my $object = $id_obj->next_seq() ) {
				$counter+=length($object->seq().$object->description().' '.$object->id()) if $object->seq();
				$counter+=length($object->description().' '.$object->id()) if !$object->seq();
				if    ($seq_search) { $ids{ $object->seq() }         = 1; }
				elsif ($descr_flag) { $ids{ $object->description() } = 1; }
				else                { $ids{ $object->id() }          = 1; }
				$flag = 1 if !$flag;
			}
		} else {
			open( IN, $idfile ) || die();
			while ( my $line = <IN> ) {
				$counter+=length($line);
				if ($ci) {
					if ( $line =~ /$pattern/i ) {
						$ids{$1} = 1;
						$flag = 1 if !$flag;
					}
				} else {
					if ( $line =~ /$pattern/ ) {
						$ids{$1} = 1;
						$flag = 1 if !$flag;
					}
				}
			}
			close(IN);
		}
		if ( !$flag ) { die "Failed to get list of IDs to extract...\n"; }
		else {
			print "Hash presence of $idfile verified\n";
		}
	} elsif ($idfile) {
		warn "File $idfile is empty or does not exist!\n";
	}
}
if ( $blastfile && -s $blastfile ) {
    if ($blast_hit){
	 print "Building HASH for queries and hits from $blastfile...\n";
	 my @blast_hits = `grep '^>' $blastfile`;
      chomp(@blast_hits);
      foreach my $blast (@blast_hits) {
      #next if $blast=~/^Sbjct|^Query|^Number|^Matrix:|^Gap penalties|^Length|^Database|^BLASTN|^Jinghui|^Database|^programs/i;
        $counter++;
        $blast =~ /^>(\S+)/;
        $ids{$1} = 1;
      }
      print "Found $counter significant results\n";
    }elsif($blast_query){
	print "Building HASH for queries from $blastfile...\n";
	my @blast_queries = `grep -B 18 '^Sequences producing' $blastfile |grep '^Query='`;
	
	chomp(@blast_queries);
	foreach (@blast_queries) {
	  next if $_=~/^Sbjct|^Query|^Number|^Matrix:|^Gap penalties|^Length/i;
		$counter++;
		$_ =~ s/^Query=\s+//;
		$ids{$_} = 1;
	}
	print "Found $counter significant results\n";
    }else{
      die "Please provide -blasthit and/or -blastquery\n";
    }
}
foreach my $file (@infiles) {
	&process($file);
}
#####################################################
sub process ($) {
	my $fastafile = shift;
	my $fsize = -s $fastafile;
	my ( $filein, $fileout, $fileout2);
	my $fastafiletrim = "$fastafile.trim";
	$fastafiletrim = $user_outfile if $user_outfile;
	my $fastafilediscard = "$fastafile.discard";
	print "Processing... $fastafile as $fastafiletrim  && $fastafilediscard\n";
	$fastafilediscard = $user_outfile . ".discard" if $user_outfile;
	if (!-s $fastafile){
		warn "File not found, skipping\n";
		return;
	}if (-s $fastafiletrim){
		warn "Output file $fastafiletrim already exists\n";
		return unless $overwrite;
	}
	if ($solexafastq) {
		if ($single_line){
			open( IN,   $fastafile )           if $single_line;
			open( OUT1, ">$fastafiletrim" )    if $single_line;
			open( OUT2, ">$fastafilediscard" ) if $single_line;
		}else{
		$filein = new Bio::SeqIO( -file => $fastafile, -format => "fastq-solexa" );
		$fileout = new Bio::SeqIO( -file => ">$fastafiletrim", -format => "fastq-solexa" );
		$fileout2 = new Bio::SeqIO(
					-file   => ">$fastafilediscard",
					-format => "fastq-solexa"
			);
		}
	} elsif ($sangerfastq) {
		if ($single_line){
			open( IN,   $fastafile );
			open( OUT1, ">$fastafiletrim" );
			open( OUT2, ">$fastafilediscard" );
		}else{
			$filein = new Bio::SeqIO( -file => $fastafile, -format => "fastq" );
			$fileout =  new Bio::SeqIO( -file => ">$fastafiletrim", -format => "fastq" );
			$fileout2 =  new Bio::SeqIO( -file => ">$fastafilediscard", -format => "fastq" );
		}
	} else {
		if ($single_line){
			open( IN,   $fastafile ) ||die("Cannot open $fastafile\n");
			open( OUT1, ">$fastafiletrim" );
			open( OUT2, ">$fastafilediscard" );
		}else{
			$filein = new Bio::SeqIO( -file => $fastafile, -format => "fasta" );
			$fileout =  new Bio::SeqIO( -file => ">$fastafiletrim", -format => "fasta" );
			$fileout2 =  new Bio::SeqIO( -file => ">$fastafilediscard", -format => "fasta" );
		}
	}
	if ($log) {
		$logfile = $fastafile . ".trim.log";
		open( LOG, ">$logfile" );
	}
	my ( $empty, $discard, $trim );
	$counter = 0;
	if ($single_line){
		print "Processing  as single line FASTA/Q\n";
	}else{
		my $number=($sangerfastq || $solexafastq) ? `grep -c "^@" $fastafile` : `grep -c "^>" $fastafile`;
		chomp($number);		
		print "$number sequences\n";
	}
	my $errors = int(0);
	while ( my $object = $single_line ? <IN> : $filein->next_seq() ) {
	        next if !$object;
		$counter=$single_line ? $counter+length($object) : $counter+1;
       		next if $single_line && $object=~/^\s*$/;
		my ( $id, $sequence, $description, $qual, $prefix);
		if ($single_line) {
			chomp($object);
			$object =~ /^(\S)(\S+)\s*(.*)/;
			$prefix = $1;
			$id          = $2;
			$description = $3;
			if (($casava) && $description=~/(\d)\:[A-Z]\:/){
				$id.='/'.$1;
			}
			$sequence    = <IN>;
			$counter+=length($sequence);
			chomp($sequence);
			my $ok = ($prefix eq '>'||$prefix eq '@' || $prefix eq '+') ? 1 : int(0);
			while ($ok != 1){
				$errors++;
				warn "Sequence $counter has a header which starts with $1. This does not seem to be right...\n$object\n$sequence\n\nSkipping...\n";
				die "\nToo many errors found\n" if $errors > 20;
				$object          = $sequence;
				chomp($object);
				$sequence    = <IN>;
				$object =~ /^(\S)(\S+)\s*(\S*)/;
				$prefix = $1;
		                $id          = $2;
        	                $description = $3;
				$ok = ($prefix eq '>'||$prefix eq '@' || $prefix eq '+') ? 1 : int(0);
			}
			if ( $solexafastq || $sangerfastq ) {
				$qual = <IN> . <IN>;
				$counter+=length($qual);
				chomp($qual);
			}
		} else {
			$id          = $object->id();
			$sequence    = $object->seq() if ($seq_search);
			$description = $object->description() ? $object->description() : '';
		}

		# trim if given an ID file
		if ( @idfiles || $blastfile ) {
			if ( $sequence && $seq_search ) {
				if ( $ids{$sequence} ) {
						unless ( $df && !$invert ) {
							if ($single_line) {
								if ($qual) {
									print OUT2 "@" . "$id\n$sequence\n$qual\n";
								} else {
									print OUT2 ">$id";
									print OUT2 " $description" if $description;
									print OUT2 "\n";
									print OUT2 "$sequence\n";
								}
							} else {
								$fileout2->write_seq($object);
							}
						}
						$discard++;
						if ($log) {
							print LOG "Sequence $id discarded because the Sequence was found in idfiles\n";
						}
						#DO get it more than once
						#delete($ids{$sequence});
						next;
				} else {
					next;
				}
			} elsif ( exists $ids{$id} && $ids{$id}==1) {
				unless ( $df && !$invert ) {
					if ($single_line) {
						if ($qual) {
							print OUT2 "@" . "$id\n$sequence\n$qual\n";
						} else {
							print OUT2 ">$id";
							print OUT2 " $description" if $description;
							print OUT2 "\n";
							print OUT2 "$sequence\n";
						}
					} else {
						$fileout2->write_seq($object);
					}
				}
				$discard++;
				if ($log) {
					print LOG "Sequence $id discarded because the ID was found in idfiles\n";
				}

				#make sure we don't get it twice
				$ids{$id}=2;
				next;
		    } elsif ( exists $ids{$id}) {
		    	next;
				# if id exists multiple times don't write it in any file.
			} elsif ( exists $ids{ $id . ' ' . $description } && $ids{ $id . ' ' . $description }==1) {
				unless ( $df && !$invert ) {
					if ($single_line) {
						if ($qual) {
							print OUT2 "@" 
							  . $id
							  . $description
							  . "\n$sequence\n$qual\n";
						} else {
							print OUT2 ">" 
							  . $id
							  . $description
							  . "\n$sequence\n";
						}
					} else {
						$fileout2->write_seq($object);
					}
				}
				$discard++;
				if ($log) {
					print LOG "Sequence $id.$description discarded because the ID was found in idfiles\n";
				}

				#make sure we don't get it twice
				$ids{ $id . ' ' . $description } =2;
				next;
			} elsif ( exists $ids{ $id . ' ' . $description }) {
				 next;
			}
		}
		$sequence = $object->seq() if !$sequence;
		if ($sequence) {
			my $seq2 = $sequence;
			if ($xmask)   { $seq2 =~ s/[X]//ig; }
			if ($nplmask) { $seq2 =~ s/[NPL]//ig; }
			if ($lcmask)  { $seq2 =~ s/[a-z]//g; }
			my $length = length($seq2);

			# trim if given a character(s)
			if ($character) {
				if ( $sequence =~ /[$character]/ ) {
					unless ( $df && !$invert ) {
						if ($single_line) {
							if ($qual) {
								print OUT2 "@" . "$id\n$sequence\n$qual\n";
							} else {
								print OUT2 ">$id $description\n$sequence\n";

							}
						} else {
							$fileout2->write_seq($object);
						}
					}
					$discard++;
					if ($log) {
						print LOG
"Sequence $id discarded because character $character was found\n";
					}
					next;
				}
			}

			#trim if given a length cutoff
			if ($length_cutoff) {
				if ( !$length || $length < $length_cutoff ) {
					unless ( $df && !$invert ) {
						if ($single_line) {
							if ($qual) {
								print OUT2 "@" . "$id\n$sequence\n$qual\n";
							} else {
								print OUT2 ">$id $description\n$sequence\n";
							}
						} else {
							$fileout2->write_seq($object);
						}
					}
					$discard++;
					if ($log) {
						print LOG "Sequence $id discarded because length $length was smaller than cutoff $length_cutoff\n";
					}
					next;
				}
			}
			# trim if xdiscard
			if ($xdiscard){
				my $Xs = ( $sequence =~ tr/X// );
				if ($Xs >= $xdiscard){
					unless ( $df && !$invert ) {
						if ($single_line) {
							if ($qual) {
								print OUT2 "@" . "$id\n$sequence\n$qual\n";
							} else {
								print OUT2 ">$id $description\n$sequence\n";
							}
						} else {
							$fileout2->write_seq($object);
						}
					}
					$discard++;
					print LOG "Sequence $id discarded more Xs ($Xs) than allowed ($xdiscard).\n" if $log;
					next;
				}
			}
			#trim if given a proportion of A/T/C/G
			if ($prop_cutoff || $ratio_cutoff) {
				my $As = ( $sequence =~ tr/A// );
				my $Ts = ( $sequence =~ tr/T// );
				my $Cs = ( $sequence =~ tr/C// );
				my $Gs = ( $sequence =~ tr/G// );
				my $Xs = ( $sequence =~ tr/X// );
				my $Ns = ( $sequence =~ tr/N// );
				my $propA   = ( $As / $length );
				my $propT   = ( $Ts / $length );
				my $propC   = ( $Cs / $length );
				my $propG   = ( $Gs / $length );
				my $propX   = ( $Xs / $length );
				my $propN   = ( $Ns / $length );
				my $GCratio = $propG + $propC if $ratio_cutoff;
				my $ATratio = 1 - $GCratio if $ratio_cutoff;
				if (  $prop_cutoff &&( 
					 $propA > $prop_cutoff
					 || $propT > $prop_cutoff
					 || $propX > $prop_cutoff
					 || $propN > $prop_cutoff
					 || $propG > $prop_cutoff
					 || $propC > $prop_cutoff )
				   || $ratio_cutoff && (
					 $ATratio > $ratio_cutoff
					 || $GCratio > $ratio_cutoff )
				   )
				{

					unless ( $df && !$invert ) {
						if ($single_line) {
							if ($qual) {
								print OUT2 "@" . "$id\n$sequence\n$qual\n";
							} else {
								print OUT2 ">$id $description\n$sequence\n";
							}
						} else {
							$fileout2->write_seq($object);
						}
					}
					$discard++;
					if ($log) {
						print LOG "Sequence $id discarded because of one nucleotide proportion (A:$propA; T:$propT; G:$propG; C:$propC higher than cutoff $prop_cutoff or GC/AT higher than $ratio_cutoff\n" if $ratio_cutoff && $prop_cutoff;
						print LOG "Sequence $id discarded because of GC/AT proportion (A:$propA; T:$propT; G:$propG; C:$propC) higher than $ratio_cutoff\n" if $ratio_cutoff;
						print LOG "Sequence $id discarded because of one nucleotide proportion (A:$propA; T:$propT; G:$propG; C:$propC higher than cutoff $prop_cutoff\n" if $prop_cutoff;
					}
					next;
				}
			}

			#next has taken care of discards.
			$trim++;
			if ($convert2uc) {
				$object->seq( uc($sequence) ) if !$single_line;
				$sequence = uc($sequence) if $single_line;
			}
			unless ( $df && $invert ) {
				if ($single_line) {
					if ($qual) {
						print OUT1 "@" . "$id\n$sequence\n$qual\n";
					} else {
						print OUT1 ">$id $description\n$sequence\n";
					}
				} else {
					$fileout->write_seq($object);
				}
			}
		}    #end if $sequence
		else {
			$empty++;
			if ($log) {
				print LOG "Sequence $id discard because it was empty\n";
			}
			next;
		}
	}
	if ( !$empty )   { $empty   = int(0); }
	if ( !$discard ) { $discard = int(0); }
	if ( !$trim )    { $trim    = int(0); }
	if ($invert) {
		system("mv -i $fastafiletrim tmpfile");
		system("mv $fastafilediscard $fastafiletrim");
		system("mv tmpfile $fastafilediscard");
		my $temp = $trim;
		$trim    = $discard;
		$discard = $temp;
	}
	unless ( -s "$fastafilediscard" ) { unlink "$fastafilediscard"; }
	if ($log) { print LOG "FASTA $fastafile contained ".($empty+$discard+$trim)." sequences\n"; }
	print "\nDone, $empty were empty and an additional $discard were discarded. Kept $trim as $fastafiletrim\n";
	if ($log) {	print LOG "\n$empty were empty and an additional $discard were discarded. Kept $trim as $fastafiletrim\n";
	}
	close(LOG);
}
print "\n";
