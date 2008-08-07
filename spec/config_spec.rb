require File.join(File.dirname(__FILE__), 'helper')

describe 'Using cargo without setting config.file_path' do
  it 'should raise FilePathNotSet' do
    old_path = Cargo.config.file_path
    Cargo.config.file_path = nil
    proc do
      class InvalidModel < ActiveRecord::Base
        cargo :file
      end
    end.should raise_error(Cargo::Errors::FilePathNotSet)
    Cargo.config.file_path = old_path
  end
end

describe 'Using cargo with an invalid database' do
  it 'should raise TableDoesNotExist' do
    old_table_name = Cargo.config.table_name
    Cargo.config.table_name = 'nonexistant'
    proc do
      class InvalidModel < ActiveRecord::Base
        cargo :file
      end
    end.should raise_error(Cargo::Errors::TableDoesNotExist)
    Cargo.config.table_name = old_table_name
  end

  it 'should raise MissingRequiredColumn' do
    old_table_name = Cargo.config.table_name
    Cargo.config.table_name = 'cargo_files_missing_columns'
    proc do
      class InvalidModel < ActiveRecord::Base
        cargo :file
      end
    end.should raise_error(Cargo::Errors::MissingRequiredColumn)
    Cargo.config.table_name = old_table_name
  end

  it 'should raise InvalidColumn' do
    old_table_name = Cargo.config.table_name
    Cargo.config.table_name = 'cargo_files_invalid_columns'
    proc do
      class InvalidModel < ActiveRecord::Base
        cargo :file
      end
    end.should raise_error(Cargo::Errors::InvalidColumn)
    Cargo.config.table_name = old_table_name
  end
end
