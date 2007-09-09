require 'fileutils'

namespace :thinking_sphinx do
  task :start => :environment do
    environment = ENV['RAILS_ENV'] || "development"
    FileUtils.mkdir_p "#{RAILS_ROOT}/db/sphinx/#{environment}"
    raise RuntimeError, "searchd is already running." if sphinx_running?
    
    Dir["#{RAILS_ROOT}/db/sphinx/*.spl"].each { |file| File.delete(file) }
    
    cmd = "searchd --config #{RAILS_ROOT}/config/#{environment}.sphinx.conf"
    puts cmd
    system cmd
    
    sleep(2)
    
    if sphinx_running?
      puts "Started successfully (pid #{sphinx_pid})."
    else
      puts "Failed to start searchd daemon. Check log/searchd.log."
    end
  end
  
  task :stop => :environment do
    raise RuntimeError, "searchd is not running." unless sphinx_running?
    pid = sphinx_pid
    system "kill #{pid}"
    puts "Stopped search daemon (pid #{pid})."
  end
  
  task :restart => [:environment, :stop, :start]
  
  task :configure => :environment do
    ThinkingSphinx::Configuration.new.build
  end
  
  task :index => [:environment, :configure] do
    environment = ENV['RAILS_ENV'] || "development"
    FileUtils.mkdir_p "#{RAILS_ROOT}/db/sphinx/#{environment}"
    cmd = "indexer --config #{RAILS_ROOT}/config/#{environment}.sphinx.conf --all"
    cmd << " --rotate" if sphinx_running?
    puts cmd
    system cmd
  end
end

namespace :ts do
  task :start   => "thinking_sphinx:start"
  task :stop    => "thinking_sphinx:stop"
  task :in      => "thinking_sphinx:index"
  task :index   => "thinking_sphinx:index"
  task :restart => "thinking_sphinx:restart"
end

def sphinx_pid
  if File.exists?("#{RAILS_ROOT}/log/searchd.pid")
    `cat #{RAILS_ROOT}/log/searchd.pid`[/\d+/]
  else
    nil
  end
end

def sphinx_running?
  sphinx_pid && `ps #{sphinx_pid} | wc -l`.to_i > 1
end