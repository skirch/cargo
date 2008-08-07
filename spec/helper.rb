SPEC_DIR = File.expand_path(File.dirname(__FILE__))
LIB_DIR = File.join(SPEC_DIR, '../lib')

$LOAD_PATH.unshift(LIB_DIR)

require 'fileutils'
require 'cargo'

begin
  require 'ruby-debug'
  Debugger.start
rescue LoadError
end

# initialize directory for generated files and data

GENERATED_DIR = File.join(SPEC_DIR, 'generated')
FileUtils.rm_rf(GENERATED_DIR)
FileUtils.mkdir(GENERATED_DIR)

# configure Cargo path for our test data

Cargo.config.file_path = File.join(GENERATED_DIR, 'test_files')

# configure active record

ActiveRecord::Base.logger = Logger.new(
  File.join(GENERATED_DIR, 'active_record.log'))

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => File.join(GENERATED_DIR, 'test_data.sqlite3'))

# create sqlite database for testing

ActiveRecord::Schema.define(:version => 0) do
  create_table(Cargo.config.table_name) do |t|
    t.integer :parent_id
    t.string :parent_type
    t.string :name
    t.string :key
    t.string :extension
    t.string :original_filename
    t.timestamps
  end

  create_table('cargo_files_invalid_columns') do |t|
    t.string :parent_id
    t.string :parent_type
    t.string :name
    t.string :key
    t.string :extension
    t.string :original_filename
    t.timestamps
  end

  create_table('cargo_files_missing_columns') { }

  create_table(:foos) { }
end

# define Foo active record model for testing

class Foo < ActiveRecord::Base
  cargo :file
  cargo :other
end

# helper method for fixtures

def snail(format = 'jpg')
  File.join(SPEC_DIR, 'fixtures', "snail.#{format}")
end
