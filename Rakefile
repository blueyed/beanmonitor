task :default => :compile

task :clean do
	sh "rm -rf doc/*"
	sh "rm -rf ._*"
	sh "rm -f beanmonitor"
end

task :compile => [:clean] do
  sh "ruby ./utils/compose.rb beanmonitor.rb lib/* > beanmonitor"
  sh "chmod 755 beanmonitor"
end

task :binary => [:clean] do
  sh "rubyscript2exe beanmonitor.rb"
  sh "mv beanmonitor_linux beanmonitor"
end