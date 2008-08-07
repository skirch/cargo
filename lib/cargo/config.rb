module Cargo
  class Config
    # The path where files will be stored on disk
    attr_accessor :file_path

    # The name of the table that will store file metadata in the database
    attr_accessor :table_name

    # Used to specify the subdirectory for <tt>ExternalFile.relative_url</tt>
    attr_accessor :url_subdir

    # Sets the default value for <tt>table_name</tt> and assigns itself to
    # <tt>Cargo.config</tt>. It also yields itself if a block is provided.
    #
    #   Cargo::Config.new |config|
    #     config.table_name = 'files'
    #     config.file_path = '/var/files'
    #     config.url_subdir = '/path/to/files/online'
    #   end
    #
    def initialize
      @table_name = 'external_files'
      @table_columns = {
        :parent_id => :integer,
        :parent_type => :string,
        :name => :string,
        :key => :string,
        :extension => :string,
        :original_filename => :string,
        :created_at => :datetime,
        :updated_at => :datetime
      }
      yield(self) if block_given?
      Cargo.config = self
    end

    def url_subdir # :nodoc:
      @url_subdir || raise(Errors::UrlSubdirNotSet)
    end

    # This method is called whenever <tt>cargo</tt> is used in an Active
    # Record model. It checks the current database to verify that
    # <tt>table_name</tt> exists and has the correct columns.
    #
    # ==== Raises
    #
    # [Errors::TableDoesNotExist]
    #   Raised when the table specified by <tt>table_name</tt> does not exist
    #
    # [Errors::FilePathNotSet]
    #   Raised when <tt>cargo</tt> is used before <tt>file_path</tt> is set
    #
    def verify!(connection)
      raise(Errors::TableDoesNotExist) if !connection.table_exists?(@table_name)
      verify_columns(connection.columns(@table_name))
      raise(Errors::FilePathNotSet) if @file_path.blank?
    end

    private

    def verify_columns(columns)
      columns_hash = hashify_columns(columns)
      @table_columns.each do |column, type|
        if !columns_hash.has_key?(column)
          raise(Errors::MissingRequiredColumn, column)
        end
        if columns_hash[column] != type
          raise(Errors::InvalidColumn.new(column, columns_hash[column], type))
        end
      end
    end

    def hashify_columns(columns)
      Hash[*columns.map { |column| [column.name.to_sym, column.type] }.flatten]
    end
  end

  mattr_accessor :config
  Config.new
end
