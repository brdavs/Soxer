Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.rubygems_version = '1.3.7'

  s.name              = 'soxer'
  s.version           = '0.9.10'
  s.date              = '2011-03-21'
  s.rubyforge_project = 'soxer'

  s.summary     = "Dynamic web site generator engine"
  s.description = "Soxer is a file based dynamic web site creation tool for Sinatra."

  s.authors  = ["Toni Anzlovar"]
  s.email    = 'toni@formalibre.si'
  s.homepage = 'http://soxer.mutsu.org'

  s.require_paths = %w[lib]

  s.rdoc_options = ["--charset=UTF-8"]
  # s.extra_rdoc_files = %w[README.md LICENSE]

  s.add_dependency('sinatra', "~> 1")
  s.add_dependency('haml', "~> 3")
  s.add_dependency('uuid', "~> 2")
  s.add_dependency('hashie', "~> 1.0.0")
  s.add_dependency('sinatra-reloader', "~> 0.5")

  # = MANIFEST =
  s.files = %w[
    soxer.gemspec
    CHANGES
    README.markdown
    LICENSE
    bin/soxer
    lib/soxer.rb
    lib/soxer/main.rb
  ] + Dir.glob("{lib/soxer/views,lib/soxer/skel/**}/**")
  # = MANIFEST =
  
  s.executables = ['soxer']

  s.test_files = s.files.select { |path| path =~ /^test\/test_.*\.rb/ }
end
