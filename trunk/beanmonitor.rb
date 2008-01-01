#!/usr/bin/ruby

require 'lib/bean_counters'
require 'optparse'
require 'yaml'
require 'fileutils'


# config defaults
options = { 
  :config => "/etc/beanmonitor.conf"
}

config = {
  :update => true,
  :debug => false,
  :savefile => "/tmp/user_beancounters_old",
  :beanfile => "/proc/user_beancounters",
  :write => false
}


# parse command line options
OptionParser.new do |opts|
  opts.banner = "Usage: beanmonitor [options]"

  opts.on("-c", "--config CONFIGFILE", "Load CONFIGFILE instead of /etc/beanmonitor.conf") do |v| 
    options[:config] = v 
  end

  opts.on("-d", "--[no-]debug", "Enable/disable debug mode (spam a lot of uninformative messages)") do |v| 
    options[:debug] = v 
  end
  
  opts.on("-b", "--beanfile FILENAME", "Load current beancounter values from FILENAME", "instead of file specified in the config.") do |v|
    options[:beanfile] = v
  end
  
  opts.on("-s", "--savefile FILENAME", "Save current values to FILENAME instead", "of what's specified in the config file") do |v|
    options[:savefile] = v
  end
  
  opts.on("-u", "--[no-]update", "Save current values to savefile to check for differences", "in the future") do |v|
    options[:update] = v
  end
  
  opts.on("-w", "--[no-]write", "Wether or not to save command line config to config file.", "This does only overwrite values which", "you have specified as command line arguments here; it does", "not touch existing values in th config without a new value specified here.") do |v|
    options[:write] = v
  end
end.parse!


# load config file; overwrite config file options with command line
# options unless nothing is specified on the command line
config = YAML::load(File.open(options[:config])) if File.exists? options[:config]
config.merge!(options)


# if specified: write all config changes back to the config file
if options[:write] then
  f = File.open(config[:config], "w")
  
  # these values don't need to be written to the config file for obvious reasons
  config.delete(:write)
  config.delete(:config)
  
  f.write(YAML::dump(config))
  f.close
end


# do the actual diffing; for first release we'll just compare, update and output
# the diff as yaml
begin
  old_bean = BeanCounters.new(config[:savefile])
  y old_bean.diff(BeanCounters.new(config[:beanfile])) if old_bean != BeanCounters.new(config[:beanfile])
  
  FileUtils.cp(config[:beanfile], config[:savefile]) if config[:update]
rescue
  puts $!
end

