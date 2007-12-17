require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../spec_generator_helper'

module Kernel
  undef dependency
end

describe "an app generator" do
  include RubiGen::GeneratorTestHelper
  
  before do
    @generator =  build_generator('merb', [APP_ROOT], sources, {})
  end
  
  after do
    bare_teardown  # Cleans up the temporary application directory that gets created as part of the test.
  end

  it "should be get created" do
    @generator.should_not be_nil
  end
  
  it "should be a MerbGenerator" do
    @generator.should be_an_instance_of(MerbGenerator)
  end
  
  it "should create directory structure" do
    silence_generator do
      @generator.command(:create).invoke!
    end
    %w{
      app
      app/controllers
      app/helpers
      app/mailers
      app/mailers/helpers
      app/mailers/views/layout
      app/mailers/views
      app/models
      app/views
      app/views/layout
      config
      config/environments
      lib
      log
      public
      public/images
      public/javascripts
      public/stylesheets
      script
      test
    }.each{|dir| directory_should_be_created(dir)}    
  end
    
  it "should create files from templates" do
    silence_generator do
      @generator.command(:create).invoke!
    end
    %w{
      app/controllers/application.rb
      app/helpers/global_helper.rb
      app/mailers/views/layout/application.html.erb
      app/views/layout/application.html.erb
      config/environments/development.rb
      config/environments/production.rb
      config/environments/test.rb
      config/merb.yml
      config/merb_init.rb
      config/router.rb
      config/dependencies.rb
      config/upload.conf
      Rakefile
      script/stop_merb
      script/generate
      script/destroy
    }.each{|file| file_should_be_created(file)}
  end
  
  it "should create files from rubigen dependency" do
    silence_generator do
      @generator.command(:create).invoke!
    end
    %w{
      script/generate
      script/destroy
    }.each{|file| file_should_be_created(file)}
  end
  
  it "should make script files executable" do
    silence_generator do
      @generator.command(:create).invoke!
    end
    
    %w{
      script/stop_merb
      script/generate
      script/destroy
    }.each{|file| file_should_be_executable(file)}
  end
    
  
  
  
  
  def directory_should_be_created(directory)
    File.should be_exist(File.join(APP_ROOT, directory))
    File.should be_directory(File.join(APP_ROOT, directory))
  end

  def file_should_be_created(file)
    File.should be_exist(File.join(APP_ROOT, file))
    File.should be_file(File.join(APP_ROOT, file))
  end

  def file_should_be_executable(file)
    File.should be_executable(File.join(APP_ROOT, file))
  end
    
  
  def sources
    [RubiGen::PathSource.new(:test, File.join(File.dirname(__FILE__),"../../", generator_path))
    ]
  end
  
  def generator_path
    "app_generators"
  end
  
end