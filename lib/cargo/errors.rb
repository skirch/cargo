module Cargo
  module Errors # :nodoc:
    class CargoError < StandardError # :nodoc:
    end

    # Since filenames rely on the Active Record's <tt>id</tt>, they can't be
    # generated until after the Active Record is saved
    #
    class CannotGenerateFilename < CargoError
      def initialize # :nodoc:
        super('Record must be saved before a filename can be generated')
      end
    end

    # Raised when cargo is used before <tt>Cargo.config.file_path</tt> has
    # been set
    #
    class FilePathNotSet < CargoError
      def initialize # :nodoc:
        super('You must specify Cargo.config.file_path')
      end
    end

    # Raised when the table has an invalid column
    #
    class InvalidColumn < CargoError
      def initialize(column_name, invalid_type, valid_type) # :nodoc:
        super("Invalid column \"#{Cargo.config.table_name}.#{column_name}\" " \
          "(found \"#{invalid_type}\", should be \"#{valid_type}\")")
      end
    end

    # Raised when the table is missing a required column
    #
    class MissingRequiredColumn < CargoError
      def initialize(column_name) # :nodoc:
        super("Missing column \"#{Cargo.config.table_name}.#{column_name}\"")
      end
    end

    # Raised if <tt>Cargo.config.table_name</tt> does not exist in the db
    #
    class TableDoesNotExist < CargoError
      def initialize # :nodoc:
        super("The table \"#{Cargo.config.table_name}\" does not exist")
      end
    end

    # Raised if Cargo.config.url_subdir is used before it's been initialized
    #
    class UrlSubdirNotSet < CargoError
      def initialize # :nodoc:
        super('Cargo.config.url_subdir has not been set')
      end
    end
  end
end
