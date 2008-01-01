#!/usr/bin/ruby

require 'lib/bean_counters'
require 'lib/email_templates'

require 'net/smtp'
require 'optparse'
require 'erb'
require 'yaml'
require 'fileutils'


# config defaults
options = { 
  :config => "/etc/beanmonitor.conf"
}

config = {
  :update => true,
  :debug => false,
  :savefile => "~/.user_beancounters_old",
  :beanfile => "/proc/user_beancounters",
  :write => false,
  :email => {}
}

email = {}
actions = []

# parse command line options
OptionParser.new do |opts|
  opts.banner = "Usage: %s [options]" % $0

  opts.separator ""
  opts.separator "General options:"

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
  
  opts.on("-w", "--[no-]write", "Whether or not to save command line config to config file.", "This does only overwrite values which", "you have specified as command line arguments here; it does", "not touch existing values in th config without a new value specified here.") do |v|
    options[:write] = v
  end


  opts.separator ""
  opts.separator "Email mapping options: (use -w/--write or this is kind of worthless)"

  
  opts.on("--email-add UID:ADDRESS", "Add an email address to be notified for a certain", "uid or for all uids if none is specified") do |v|
    m = v.match(/^(\d+):(.*?)$/)
    if m then
      email[:add] = { :uid => m[1].to_i, :email => m[2] }
    else
      email[:add] = { :uid => :all, :email => v }
    end     
  end
  
  opts.on("--email-del ADDRESS", "Remove an email address from the list of recipients. Currently this", "removes all occurences; fix in the near future.") do |v|
    email[:del] = v
  end
  
  opts.on("--email-list", "Dump recipients list in yaml.") do |v|
    email[:list] = true #postpone this until config has been read
  end
  
  
  opts.separator ""
  opts.separator "Actions:"
  
  opts.on("--show", "Show differences between the last known version of user_beancounters and the current", "state of the aforementioned file. Outputs pure yaml if you care to use it in another ruby script.") do
    actions << :show
  end
  
  opts.on("--email", "Sends emails about differences in failcount to all configured recipients.") do
    actions << :email
  end
end.parse!


# load config file; overwrite config file options with command line
# options unless nothing is specified on the command line
config = YAML::load(File.open(options[:config])) if File.exists? options[:config]
config.merge!(options)

# add email if specified
(config[:email][email[:add][:uid]] ||= Array.new) << email[:add][:email] if email.has_key? :add

# delete an email if specified
config[:email].each { |k,v| v.delete(email[:del]); config[:email].delete(k) if v.size == 0 } if email.has_key? :del

# print email listing
y config[:email] if email.has_key? :list

# if specified: write all config changes back to the config file
if options[:write] then
  f = File.open(config[:config], "w")
  
  # these values don't need to be written to the config file for obvious reasons
  config.delete(:write)
  config.delete(:config)
  
  f.write(YAML::dump(config))
  f.close
end


# drop out if we don't actually do  anything
exit if actions.size == 0


# produce counter diff
failures = Hash.new
begin
  FileUtils.touch(config[:beanfile])
  FileUtils.touch(config[:savefile])

  old_bean = BeanCounters.new(config[:savefile])
  failures = old_bean.diff(BeanCounters.new(config[:beanfile])) if old_bean != BeanCounters.new(config[:beanfile])
  
  FileUtils.cp(config[:beanfile], config[:savefile]) if config[:update]
rescue
  puts $!
end


# output to console
y failures if actions.index(:show)


# send emails
if actions.index(:email) then
  begin
    Net::SMTP.start('localhost') do |smtp|
      # per uid emails
      failures.each do |uid,counters|
        next unless config[:email].has_key? uid

        tpl = ERB.new(EmailTemplates.user_template)
        smtp.send_message tpl.result(binding), "root@localhost", config[:email][uid]
      end
  
      # admin emails
      config[:email][:all].each do |email|
        tpl = ERB.new(EmailTemplates.admin_template)
        smtp.send_message tpl.result(binding), "root@localhost", config[:email][:all]
      end
    end
  rescue
    puts $!
  end
end