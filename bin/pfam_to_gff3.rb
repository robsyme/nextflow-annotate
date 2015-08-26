#!/usr/bin/env ruby

seqid = "dummy_seqid"
orfstart = -1
orfstop = -1
strand = "?"
domainid = "domainid"
domain_description = "domain description"
domain_num = 0
hit_num = 0
num = '\d*\.?\d+([eE][-+]?\d+)?'

while ARGF.gets
  case $_
  when /^#/
    next
  when /^Query:\s+(?<seqid>\S+)_(?<orfnum>\d+)\s+\[L=\d+\]/
    seqid = $~[:seqid]
    orfid = $~[:seqid] + "_" + $~[:orfnum]
  when /Description: \[(?<orfstart>\d+) - (?<orfend>\d+)\] (?<reverse>\(REVERSE SENSE\))?/
    orfstart = $~[:orfstart].to_i
    orfend = $~[:orfend].to_i
    strand = $~[:reverse] ? "-" : "+"
    domain_num = 0
  when /^>>\s+(?<domainid>\S+)\s+(?<domain_description>.*)\n/
    domainid = $~[:domainid]
    domain_description = $~[:domain_description]
    domain_num += 1
  when /\s+(?<hit_num>\d+)\s+[\?\!]\s+(?<score>#{num})\s+(?<bias>#{num})\s+(?<c_evalue>#{num})\s+(?<i_evalue>#{num})\s+(?<hmm_from>\d+)\s+(?<hmm_to>\d+)\s+[\.\[][\.\]]\s+\d+\s+\d+\s+[\.\[][\.\]]\s+(?<domain_start>\d+)\s+(?<domain_end>\d+)/
    domain_from = $~[:domain_start].to_i
    domain_to = $~[:domain_end].to_i
    hit_num = $~[:hit_num]
    domain_position_left = 0
    domain_position_right = 0
    if strand == "+"
      domain_position_left = orfstart + 3 * domain_from
      domain_position_right = orfstart + 3 * domain_to - 1
    else
      domain_position_right = orfstart - 3 * (domain_from - 1)
      domain_position_left = orfstart - 3 * (domain_to - 1) + 1
    end
    
    # Output a new gff annotation
    out = []
    out << seqid
    out << 'pfam'
    out << 'protein_hmm_match'
    out << domain_position_left
    out << domain_position_right
    out << $~[:score]
    out << strand
    out << "."
    attributes = {}
    attributes[:Target] = domainid
    attributes[:description] = domain_description
    attributes[:exon_id] = seqid
    attributes[:orf_id] = orfid
    attributes[:ID] = orfid + "_" + domain_num.to_s + hit_num
    out << attributes.map{|p| p.join('=')}.join(';')
    puts out.join("\t")
  end
end
