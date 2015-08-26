#!/usr/bin/env ruby
require 'pp'
require 'bio'
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: exonerage_to_genbank.rb [options]"

  opts.on("-f", "--fasta genome", "Genome fasta file") do |filename|
    options[:fasta] = filename
    #TODO: Check for existance of file.
  end
end.parse!

def to_locations(match)
  puts match.captures.join("\t")
  pos = match[:target_start].to_i
  match[:vulgar]
    .split
    .each_slice(3)
    .chunk{ |type, q, t| case type; when /[MS]/; :coding; when /[5I3]/; :intron; else; :other; end}
    .map{ |cls, a| [cls, a.map{|type, q, t| t.to_i}.inject(:+)] }
    .each{|a| p a}
end

genome = Hash[Bio::FlatFile.open(options[:fasta]).map{|entry| [entry.entry_id,entry.naseq] }]
genes = Hash.new{|h,k| h[k]=[]}

while ARGF.gets
  next unless $_ =~ (/vulgar: (?<query_id>\S+) (?<query_start>\d+) (?<query_end>\d+) (?<query_strand>.) (?<target_id>\S+) (?<target_start>\d+) (?<target_end>\d+) (?<target_strand>.) (?<score>\d+) (?<vulgar>.*)\n/)
  to_locations($~)
end






