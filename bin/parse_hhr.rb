#!/usr/bin/env ruby
require 'optparse'

options = {}
options[:homology_prob_cut] = 70
options[:eval_cut] = 0.001
options[:pval_cut] = 0.000001
options[:score_cut] = 100
options[:align_col_cut] = 50 
options[:template_aln_size_cut] = 30
options[:repeat] = false

OptionParser.new do |opts|
  opts.banner = "Usage: parse_hhr.rb [options] input.hhr"

  opts.on("-o [N]", Float, "--homology_cutoff", "Minimum homology probability (70)") do |f|
    options[:homology_prob_cut] = f
  end
  
  opts.on("-e [N]", Float, "--evalue_cutoff", "Maximum evalue (1e-3)") do |f|
    options[:eval_cut] = f
  end

  opts.on("-p [N]", Float, "--pvalue_cutoff", "Maximum pvalue (1e-6)") do |f|
    options[:pval_cut] = f
  end

  opts.on("-s [N]", Float, "--score_cutoff", "Minimum score (100)") do |f|
    options[:pval_cut] = f
  end

  opts.on("-a [N]", Float, "--align_length_cutoff", "Minimum length of amino acids in match for query (50)") do |f|
    options[:align_col_cut] = f
  end

  opts.on("-t [N]", Float, "--template_length_cutoff", "Minimum length of amino acids in match for template (30)") do |f|
    options[:template_aln_size_cut] = f
  end 

  opts.on("-r", "--repeat", "Input file is generated from repeat sequence rather than coding sequence") do |r|
    options[:repeat] = r
  end
  
  opts.on("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

infile = File.open(ARGV.shift)

homology_prob_cut = 70

gff3 = File.open('out.gff3', 'w')
hints = File.open('out.hints', 'w')
geneid = File.open('out.geneid', 'w')
glimmer = File.open('out.glimmer', 'w')

uid_counter = Hash.new(0)

while infile.gets
  case $_
  when /^\W*Query\s+(?<scaffold_id>\S+)_(?<scaffold_hit_num>\d+) \[(?<orf_start>\d+) - (?<orf_end>\d+)\](?<rev> \(REVERSE SENSE\))?/
    scaffold_id = $~[:scaffold_id]
    scaffold_hit_num = $~[:scaffold_hit_num].to_i
    reverse = ! $~[:rev].nil?
    orf_start = $~[:orf_start].to_i
    orf_stop = $~[:orf_end].to_i
  when /^\s*1 (?<hit_desc>.{30})\s+(?<prob>\d+\.?\d*)\s+(?<evalue>\d+\.?\d*E?-?\d*)\s+(?<pvalue>\d+\.?\d*E?-?\d*)\s+(?<score>\d+\.?\d*)\s+(?<structure_score>\d+\.?\d*)\s+(?<alignment_length>\d+)\s+(?<aa_start>\d+)-(?<aa_stop>\d+)\s+(?<hit_start>\d+)-(?<hit_stop>\d+)\s+\((?<template_size>\d+)\)/
    next if options[:homology_prob_cut] > $~[:prob].to_f
    next if options[:eval_cut] < $~[:evalue].to_f
    next if options[:pval_cut] < $~[:pvalue].to_f
    next if options[:score_cut] > $~[:score].to_f
    next if options[:align_col_cut] > $~[:alignment_length].to_i
    next if options[:template_aln_size_cut] > ($~[:hit_start].to_i - $~[:hit_stop].to_i).abs
    
    hit_id = $~[:hit_desc].split.first
    hit_desc = $~[:hit_desc].split[1..-1].join(' ')

    uid = "%s.s%s.e%s" % [hit_id, $~[:hit_start], $~[:hit_stop]]
    hit_count = uid_counter[uid] += 1
    uid += ".n%d" % hit_count

    strand = reverse ? '-' : '+'
    gff_start = reverse ? (orf_start - (3 * $~[:aa_start].to_i)) : (orf_start + (3 * $~[:aa_start].to_i))
    gff_end = reverse ? (orf_start - (3 * $~[:aa_stop].to_i) + 1) : (orf_start + (3 * $~[:aa_stop].to_i) - 1)
    type = options[:repeat] ? 'nonexonpart' : 'CDSpart'

    attributes = {}
    attributes[:ID] = uid
    attributes[:Name] = hit_id + "(%s)" % hit_desc
    attributes[:Target] = "%s %s %s [+]" % [hit_id, $~[:hit_start], $~[:hit_stop]]
    
    gff3.puts [scaffold_id, 'hhblits', 'protein_match', gff_start, gff_end, $~[:score], strand, '.', attributes.map{|a| a.join('=')}.join(";")].join("\t")

    attributes = {}
    attributes[:src] = options[:repeat] ? 'RM' : 'HU'
    attributes[:grp] = hit_id
    attributes[:pri] = options[:repeat] ? 6 : 5
    hints.puts [scaffold_id, 'protein_match', type, gff_start, gff_end, $~[:score], strand, '.', attributes.map{|a| a.join('=')}.join(";")].join("\t")
    
    geneid.puts [scaffold_id, 'hhblits', 'sr', gff_start, gff_end, $~[:score], strand, '.'].join("\t")
    
    if reverse
      glimmer.puts [scaffold_id, gff_end, gff_start, $~[:score], $~[:evalue], "\n\n"].join(" ")
    else
      glimmer.puts [scaffold_id, gff_start, gff_end, $~[:score], $~[:evalue], "\n\n"].join(" ")
    end
  end
end
