module Kernel
  
  # does a basic require, and prints the message passed as an optional
  # second parameter if an error occurs.
  
  def rescue_require(sym, message = nil)
    require sym
  rescue LoadError, RuntimeError
    puts message if message
  end
  
  def dependencies(*args)
    args.each do |arg|
      case arg
        when String : dependency(arg)
        when Hash : arg.each { |r,v|  dependency(r, v) }
      end
    end
  end
  
  def dependency(gem, *ver)
    Gem.activate(gem, true, *ver)
  end
  
  # Used in MERB_ROOT/dependencies.yml
  # Tells merb which ORM (Object Relational Mapper) you wish to use.
  # Currently merb has plugins to support ActiveRecord, DataMapper, and Sequel.
  #
  # Example
  #   $ sudo gem install merb_datamapper # or merb_activerecord or merb_sequel
  #   use_orm :datamapper # this line goes in dependencies.yml
  #   $ ruby script/generate model MyModel # will use the appropriate generator for your ORM
  
  def use_orm(orm)
    raise "Don't call use_orm more than once" unless 
      Merb::GENERATOR_SCOPE.delete(:merb_default)
    orm = orm.to_sym
    orm_plugin = orm.to_s.match(/^merb_/) ? orm.to_s : "merb_#{orm}" 
    Merb::GENERATOR_SCOPE.unshift(orm) unless
      Merb::GENERATOR_SCOPE.include?(orm)
    Kernel.dependency(orm_plugin)
  end
  
  # Used in MERB_ROOT/dependencies.yml
  # Tells merb which testing framework to use.
  # Currently merb supports rspec and test_unit for testing
  #
  # Example
  #   $ sudo gem install rspec
  #   use_test :rspec # this line goes in dependencies.yml (or use_test :test_unit)
  #   $ ruby script/generate controller MyController # will use the appropriate generator for tests
  
  def use_test(test_framework)
    test_framework = test_framework.to_sym
    raise "use_test only supports :rspec and :test_unit currently" unless
      [:rspec, :test_unit].include?(test_framework)
    Merb::GENERATOR_SCOPE.delete(:rspec)
    Merb::GENERATOR_SCOPE.delete(:test_unit)
    Merb::GENERATOR_SCOPE.push(test_framework)
  end
  
  # Gives you back the file, line and method of the caller number i
  #
  # Example
  #   __caller_info__(1) # -> ['/usr/lib/ruby/1.8/irb/workspace.rb', '52', 'irb_binding']

  def __caller_info__(i = 1)
    file, line, meth = caller[i].scan(/(.*?):(\d+):in `(.*?)'/).first
  end

  # Gives you some context around a specific line in a file.
  # the size argument works in both directions + the actual line,
  # size = 2 gives you 5 lines of source, the returned array has the
  # following format.
  #   [
  #     line = [
  #              lineno           = Integer,
  #              line             = String, 
  #              is_searched_line = (lineno == initial_lineno)
  #            ],
  #     ...,
  #     ...
  #   ]
  # Example
  #  __caller_lines__('/usr/lib/ruby/1.8/debug.rb', 122, 2) # ->
  #   [
  #     [ 120, "  def check_suspend",                               false ],
  #     [ 121, "    return if Thread.critical",                     false ],
  #     [ 122, "    while (Thread.critical = true; @suspend_next)", true  ],
  #     [ 123, "      DEBUGGER__.waiting.push Thread.current",      false ],
  #     [ 124, "      @suspend_next = false",                       false ]
  #   ]

  def __caller_lines__(file, line, size = 4)
    return [['Template Error!', "problem while rendering", false]] if file =~ /\(erubis\)/
    lines = File.readlines(file)
    current = line.to_i - 1

    first = current - size
    first = first < 0 ? 0 : first

    last = current + size
    last = last > lines.size ? lines.size : last

    log = lines[first..last]

    area = []

    log.each_with_index do |line, index|
      index = index + first + 1
      area << [index, line.chomp, index == current + 1]
    end

    area
  end
  
  # Requires ruby-prof (<tt>sudo gem install ruby-prof</tt>)
  # Takes a block and profiles the results of running the block 100 times.
  # The resulting profile is written out to MERB_ROOT/log/#{name}.html.
  # <tt>min</tt> specifies the minimum percentage of the total time a method must take for it to be included in the result.
  #
  # Example
  #   __profile__("MyProfile", 5) do
  #     30.times { rand(10)**rand(10) }
  #     puts "Profile run"
  #   end
  # Assuming that the total time taken for #puts calls was less than 5% of the total time to run, #puts won't appear
  # in the profilel report.
  
  def __profile__(name, min=1)
    require 'ruby-prof' unless defined?(RubyProf)
    return_result = ''
    result = RubyProf.profile do
      100.times{return_result = yield}
    end
    printer = RubyProf::GraphHtmlPrinter.new(result)
    path = File.join(MERB_ROOT, 'log', "#{name}.html")
    File.open(path, 'w') do |file|
     printer.print(file, {:min_percent => min,
                          :print_file => true})
    end
    return_result
  end  
  
  # Extracts an options hash if it is the last item in the args array
  # Used internally in methods that take *args
  #
  # Example
  #   def render(*args,&blk)
  #     opts = extract_options_from_args!(args) || {}
  
  def extract_options_from_args!(args)
    args.pop if Hash === args.last
  end
  
end