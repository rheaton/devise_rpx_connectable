puts "Removing old database..."
FileUtils.rm File.expand_path("../../rails_app/db/development.sqlite3", __FILE__), :force => true
FileUtils.rm File.expand_path("../../rails_app/db/test.sqlite3", __FILE__), :force => true
ActiveRecord::Base.logger = Logger.new(nil)
ActiveRecord::Migration.verbose = false
ActiveRecord::Migrator.migrate(File.expand_path("../../rails_app/db/migrate/", __FILE__))
class ActiveSupport::TestCase
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false
end

