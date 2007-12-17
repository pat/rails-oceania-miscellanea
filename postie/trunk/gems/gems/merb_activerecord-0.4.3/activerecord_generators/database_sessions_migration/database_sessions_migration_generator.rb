require 'merb'
class DatabaseSessionsMigrationGenerator < RubiGen::Base
  
  default_options :author => nil

  def initialize(runtime_args, runtime_options = {})
    super
    @name = 'database_sessions'
  end

  def manifest
    record do |m|
    # Ensure appropriate folder(s) exists
    m.directory 'schema/migrations'

    # Create stubs
    highest_migration = Dir[Dir.pwd+'/schema/migrations/*'].map{|f| File.basename(f) =~ /^(\d+)/; $1}.max
    filename = format("%03d_%s", (highest_migration.to_i+1), @name.snake_case)
    m.template "sessions_migration.erb", "schema/migrations/#{filename}.rb"
    puts banner

    end
  end

  protected
    def banner
      <<-EOS
A migration to add sessions to your database has been created.
Run 'rake db:migrate' to add the sessions migration to your database.

EOS
    end

    def add_options!(opts)
      # opts.separator ''
      # opts.separator 'Options:'
      # For each option below, place the default
      # at the top of the file next to "default_options"
      # opts.on("-a", "--author=\"Your Name\"", String,
      #         "Some comment about this option",
      #         "Default: none") { |options[:author]| }
      # opts.on("-v", "--version", "Show the #{File.basename($0)} version number and quit.")
    end
    
    def extract_options
      # for each option, extract it into a local variable (and create an "attr_reader :author" at the top)
      # Templates can access these value via the attr_reader-generated methods, but not the
      # raw instance variable value.
      # @author = options[:author]
    end
end