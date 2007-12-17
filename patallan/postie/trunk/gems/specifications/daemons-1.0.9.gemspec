Gem::Specification.new do |s|
  s.name = %q{daemons}
  s.version = "1.0.9"

  s.specification_version = 1 if s.respond_to? :specification_version=

  s.required_rubygems_version = nil if s.respond_to? :required_rubygems_version=
  s.authors = ["Thomas Uehlinger"]
  s.autorequire = %q{daemons}
  s.cert_chain = nil
  s.date = %q{2007-10-29}
  s.description = %q{Daemons provides an easy way to wrap existing ruby scripts (for example a self-written server)  to be run as a daemon and to be controlled by simple start/stop/restart commands.  You can also call blocks as daemons and control them from the parent or just daemonize the current process.  Besides this basic functionality, daemons offers many advanced features like exception  backtracing and logging (in case your ruby script crashes) and monitoring and automatic restarting of your processes if they crash.}
  s.email = %q{th.uehlinger@gmx.ch}
  s.extra_rdoc_files = ["README", "Releases", "TODO"]
  s.files = ["Rakefile", "Releases", "TODO", "README", "LICENSE", "setup.rb", "lib/daemons/application.rb", "lib/daemons/application_group.rb", "lib/daemons/cmdline.rb", "lib/daemons/controller.rb", "lib/daemons/daemonize.rb", "lib/daemons/exceptions.rb", "lib/daemons/monitor.rb", "lib/daemons/pid.rb", "lib/daemons/pidfile.rb", "lib/daemons/pidmem.rb", "lib/daemons.rb", "test/call_as_daemon.rb", "test/tc_main.rb", "test/test1.rb", "test/testapp.rb", "test/tmp", "examples/call", "examples/call/call.rb", "examples/call/call_monitor.rb", "examples/daemonize", "examples/daemonize/daemonize.rb", "examples/run", "examples/run/ctrl_crash.rb", "examples/run/ctrl_exec.rb", "examples/run/ctrl_exit.rb", "examples/run/ctrl_monitor.rb", "examples/run/ctrl_multiple.rb", "examples/run/ctrl_normal.rb", "examples/run/ctrl_ontop.rb", "examples/run/ctrl_optionparser.rb", "examples/run/ctrl_proc.rb", "examples/run/ctrl_proc.rb.output", "examples/run/ctrl_proc_simple.rb", "examples/run/myserver.rb", "examples/run/myserver_crashing.rb", "examples/run/myserver_crashing.rb.output", "examples/run/myserver_exiting.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://daemons.rubyforge.org}
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new("> 0.0.0")
  s.rubyforge_project = %q{daemons}
  s.rubygems_version = %q{0.9.5}
  s.summary = %q{A toolkit to create and control daemons in different ways}
  s.test_files = ["test/tc_main.rb"]
end
