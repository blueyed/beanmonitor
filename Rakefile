task :default => :compile

task :clean do
	sh "rm -rf doc/*"
	sh "rm -rf ._*"
	sh "rm -f beanmonitor *.tar.bz2"
end

task :compile => [:clean] do
  sh "ruby ./utils/compose.rb beanmonitor.rb lib/* > beanmonitor"
  sh "chmod 755 beanmonitor"
end

task :binary => [:clean] do
  sh "rubyscript2exe beanmonitor.rb"
end

task :source_package => [:clean] do
  sh "mkdir beanmonitor"
  sh "cp -rf lib doc utils LICENSE Rakefile *.rb beanmonitor"
  sh "tar cfj beanmonitor-src-#{ENV['VERSION']}.tar.bz2 beanmonitor"
  sh "rm -rf beanmonitor"
end

task :compile_package => [:clean, :compile] do
  sh "tar cfj beanmonitor-singlesource-#{ENV['VERSION']}.tar.bz2 LICENSE beanmonitor"
  sh "rm beanmonitor"
end

task :binary_package => [:binary, :compile] do
  sh "rm -f beanmonitor"
  sh "mv beanmonitor_linux beanmonitor"
  sh "tar cfj beanmonitor-binary-#{ENV['VERSION']}.tar.bz2 LICENSE beanmonitor"
  sh "rm beanmonitor"
end

task :deploy => [:source_package, :compile_package, :binary_package] do
end 
