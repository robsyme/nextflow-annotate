#!/usr/bin/env ruby
counter = 0
while ARGF.gets
  if $_ =~ /^>GG\d\+\|(.*)\n/
    puts ">GG%d|%s" % [counter += 1, $1]
  else
    puts $_
  end
end
