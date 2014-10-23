#!/usr/bin/env ruby

def generate_transcript_line(id, lines)
  minPos = lines.min_by{|line| line[3].to_i}[3]
  maxPos = lines.max_by{|line| line[4].to_i}[4]
  f = lines.first
  [] << f[0] << f[1] << "mRNA" << minPos << maxPos << "." << f[6] << "." << "ID=t.#{id}"
end

def adjust_attributes(id, line)
  line[8] = "ID=c.#{id};Parent=t.#{id}"
  line
end

# Read all lines of the GFF
lines = ARGF
  .map do |line|
  split = line.chomp.split("\t")
  split[2] = "CDS"
  split[3] = split[3].to_i
  split[4] = split[4].to_i
  split
end

## Can we sort numerically rather than alphabetically?

# First we find the longest common prefix for the chromosome/scaffold names
items = lines.map{|line| line[0]}.uniq
prefix = ''
min, max = items.sort.values_at(0, -1)
min.split(//).each_with_index do |c, i|
  break if c != max[i, 1]
  prefix << c
end

# Then make a regular expression that matches the common prefix and then some digits
re = Regexp.new(prefix << "\\d+$")

# If *all* of the chromosome/scaffold names match the regular
# expression, we sort on the trailing digits. Otherwise we sort alphabetically
sort_alphabetical = lambda {|line| [line[0][0], line[3][0]]}
sort_numeric = lambda {|line| [line[0][0].match(/\d+$/)[-1].to_i, line[0][3]]}
match_method = items.all?{|item| item =~ re} ? sort_numeric : sort_alphabetical

lines.sort_by{|split| split[8]}
  .chunk{|line| line[8]}
  .map do |id, lines|
  transcript = generate_transcript_line(id, lines)
  lines
    .map{|line| adjust_attributes(id, line)}
    .unshift(transcript)
end
  .sort_by(&match_method)
  .each do |a|
  puts a.map{|line| line.join("\t")}
end
