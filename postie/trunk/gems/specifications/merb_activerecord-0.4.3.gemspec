Gem::Specification.new do |s|
  s.name = %q{merb_activerecord}
  s.version = "0.4.3"

  s.specification_version = 1 if s.respond_to? :specification_version=

  s.required_rubygems_version = nil if s.respond_to? :required_rubygems_version=
  s.authors = ["Duane Johnson"]
  s.autorequire = %q{merb_activerecord}
  s.cert_chain = nil
  s.date = %q{2007-11-12}
  s.description = %q{Merb plugin that provides ActiveRecord support for Merb}
  s.email = %q{canadaduane@gmail.com}
  s.extra_rdoc_files = ["README", "LICENSE", "TODO"]
  s.files = ["LICENSE", "README", "Rakefile", "TODO", "lib/merb", "lib/merb_activerecord.rb", "lib/merb/orms", "lib/merb/session", "lib/merb/orms/active_record", "lib/merb/orms/active_record/connection.rb", "lib/merb/orms/active_record/database.sample.yml", "lib/merb/orms/active_record/tasks", "lib/merb/orms/active_record/tasks/databases.rb", "lib/merb/session/active_record_session.rb", "specs/merb_active_record_spec.rb", "specs/spec_helper.rb", "activerecord_generators/database_sessions_migration", "activerecord_generators/migration", "activerecord_generators/model", "activerecord_generators/resource_controller", "activerecord_generators/database_sessions_migration/database_sessions_migration_generator.rb", "activerecord_generators/database_sessions_migration/templates", "activerecord_generators/database_sessions_migration/USAGE", "activerecord_generators/database_sessions_migration/templates/sessions_migration.erb", "activerecord_generators/migration/migration_generator.rb", "activerecord_generators/migration/templates", "activerecord_generators/migration/USAGE", "activerecord_generators/migration/templates/new_migration.erb", "activerecord_generators/model/model_generator.rb", "activerecord_generators/model/templates", "activerecord_generators/model/USAGE", "activerecord_generators/model/templates/new_model.erb", "activerecord_generators/resource_controller/resource_controller_generator.rb", "activerecord_generators/resource_controller/templates", "activerecord_generators/resource_controller/USAGE", "activerecord_generators/resource_controller/templates/controller.rb", "activerecord_generators/resource_controller/templates/edit.html.erb", "activerecord_generators/resource_controller/templates/helper.rb", "activerecord_generators/resource_controller/templates/index.html.erb", "activerecord_generators/resource_controller/templates/new.html.erb", "activerecord_generators/resource_controller/templates/show.html.erb"]
  s.has_rdoc = true
  s.homepage = %q{http://merbivore.com}
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new("> 0.0.0")
  s.rubygems_version = %q{0.9.5}
  s.summary = %q{Merb plugin that provides ActiveRecord support for Merb}

  s.add_dependency(%q<merb>, [">= 0.4.0"])
end
