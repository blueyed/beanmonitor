= Beanmonitor - monitoring of OpenVZ user_beancounters ==

* https://github.com/hm2k/beanmonitor

=== Description ===
Basically, the software you can acquire here allows you to easily monitor user_beancounters used by OpenVZ to limit resources per vps. Now I know that usually you are not too interested in how often your users try to violate the limits you impose on them but in my environment, a machine "split" into several instances using OpenVZ, it's pretty critical to know when the assigned resources aren't enough anymore.

On that note, I'm planning on adding a way of seeing which limits are about to be breached by a vps so you can decide whether to raise the barrier or to wait for it to fail.

=== Features ===
  * emails failures on a per vps or catchall basis (check wiki)
  * compares to set of counter files and writes differences to the console in an ordered manner

=== Status ===
  * Parsing files works
  * Config file works; can be created and modified using the command line
  * Ruby source can be "compiled" into one single file to minimize deployment effort
  * Counter differences are currently simply dumped to console in YAML
  * Emailing works per vps and for administrators (all errors)
  * Email templates are available but currently hardcoded

=== Roadmap ===
  * Display vps which are close to a beancounter barrier (let's call this "early warning system"
  * possibly auto increase limit if close to barrier
  * disk quota reporting
  * add svn code documentation (check out Rakefile / :compile task)

=== Feature requests? ===
Best would be to add a feature request to the issue tracker so it can be commented on in an ordered manner :-)
