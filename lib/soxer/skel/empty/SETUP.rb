def initSkel dest
  %w[bin log public].each {|d| Dir.mkdir "#{dest}/#{d}" unless Dir.exists? "#{dest}/#{d}" }
end
