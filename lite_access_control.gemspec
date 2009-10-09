require 'rubygems'
require 'rake/gempackagetask'

PKG_FILES = FileList[ '[a-zA-Z]*', 'generators/**/*', 'lib/**/*', 'rails/**/*', 'tasks/**/*', 'test/**/*' ]

spec = Gem::Specification.new do |s| 
  s.platform = Gem::Platform::RUBY

  s.name = "lite_access_control"
  s.version = "0.0.1"
  s.summary = "Simple access control"
  
  s.homepage = 'http://github.com/dmitryp/lite_access_control'
  s.author = "Dmitry Penkin"
  s.email = "dr.demax@gmail.com"

  s.files = PKG_FILES.to_a 
  s.require_path = "lib"
  s.has_rdoc = false
  s.extra_rdoc_files = ["README"]

  s.description = <<EOF
Simple access control system
EOF
end

desc 'Turn this plugin into a gem.'
Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end