module ThinkingSphinx
  class Configuration
    # Generate the config file for Sphinx. This has the following settings,
    # relative to RAILS_ROOT where relevant:
    #
    # config file path:: config/#{environment}.sphinx.conf
    # searchd log file:: log/searchd.log
    # query log file::   log/searchd.query.log
    # pid file::         log/searchd.pid
    # searchd files::    db/sphinx/#{environment}.*
    # address::          0.0.0.0 (all)
    # port::             3312
    #
    # At this point, if you want to change these settings, bad luck. That may
    # change in the future, though (but if you really want it, request it! Or
    # submit a patch).
    #
    def build(file_path=nil)
      environment = ENV['RAILS_ENV'] || "development"
      load_models
      file_path ||= "#{RAILS_ROOT}/config/#{environment}.sphinx.conf"
      database_conf = YAML.load(File.open("#{RAILS_ROOT}/config/database.yml"))[environment]
      
      open(file_path, "w") do |file|
        file.write <<-CONFIG
indexer
{
  mem_limit = 64M
}

searchd
{
  port = 3312
  log = #{RAILS_ROOT}/log/searchd.log
  query_log = #{RAILS_ROOT}/log/searchd.query.log
  read_timeout = 5
  max_children = 30
  pid_file = #{RAILS_ROOT}/log/searchd.pid
}
        CONFIG
        
        sources = []
        ThinkingSphinx.indexed_models.each do |model|
          model.indexes.each_with_index do |index, i|
            file.write <<-SOURCE

source #{model.name.downcase}_#{i}
{
  type = mysql
  sql_host = #{database_conf["host"] || "localhost"}
  sql_user = #{database_conf["username"]}
  sql_pass = #{database_conf["password"]}
  sql_db   = #{database_conf["database"]}

  sql_query        = #{index.to_sql}
  sql_query_range  = #{index.sql_query_range}
  sql_query_info   = #{index.sql_query_info}
}
            SOURCE
            sources << "#{model.name.downcase}_#{i}"
          end
        end
        
        source_list = sources.collect { |s| "source = #{s}"}.join("\n")
        file.write <<-INDEX

index #{environment}
{
  #{source_list}
  morphology = stem_en
  path = #{RAILS_ROOT}/db/sphinx/#{environment}
  charset_type = utf-8
}
        INDEX
      end
    end
    
    private
    
    # Make sure all models are loaded
    def load_models
      Dir[RAILS_ROOT + "/app/models/**/*.rb"].each do |file|
        model_name = file.gsub(/^.*\/([\w_]+)\.rb/, '\1')
        next if model_name.nil?
        begin
          model_name.camelize.constantize
        rescue NameError
          next
        end
      end
    end
  end
end