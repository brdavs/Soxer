def initSkel dest
  %w[bin log public].each {|d| Dir.mkdir "#{dest}/#{d}" unless Dir.exists? "#{dest}/#{d}" }
  
  Dir.chdir dest+'/content/categories'
  %w[rants recipes tutorials].each {|l| File.symlink 'index.yaml', l+'.yaml' }
  Dir.chdir dest
end
