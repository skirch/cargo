module Cargo
  module Validations
    # Validates the existence of the associated file on disk
    #
    # ==== Example
    #
    #   class Image < ActiveRecord::Base
    #     cargo :image
    #
    #     validates_file_exists :image, :on => :create
    #   end
    #
    # ==== Parameters
    #
    # [<tt>name</tt>]
    #   The name of the <tt>cargo</tt> association
    # [<tt>options</tt>]
    #   A hash of options for the validation
    #
    # ==== Options
    #
    # [<tt>:message</tt>]
    #   A custom error message
    # [<tt>:on</tt>]
    #   Specifies when this validation is active (default is :save, other
    #   options :create, :update)
    #
    def validates_file_exists(name, options = {})
      options[:message] ||= 'must be set'
      send(validation_method(options[:on] || :save), options) do |record|
        file = record.send(name)
        record.errors.add(name, options[:message]) if
          !file.is_a?(CargoFile) ||
          (file.new_record? && !file.new_data?) ||
          (!file.new_record? && !File.exist?(file.absolute_filename))
      end
    end

    # Validates the extension of the specified file
    #
    # ==== Example
    #
    #   class Image < ActiveRecord::Base
    #     cargo :image
    #
    #     validates_file_extension_of :image, :in => %w(jpg gif png)
    #   end
    #
    # ==== Parameters
    #
    # [<tt>name</tt>]
    #   The name of the <tt>cargo</tt> association
    # [<tt>options</tt>]
    #   A hash of options for the validation
    #
    # ==== Options
    #
    # [<tt>:in</tt> (required)]
    #   An array of valid file extensions
    # [<tt>:message</tt>]
    #   A custom error message
    # [<tt>:on</tt>]
    #   Specifies when this validation is active (default is :save, other
    #   options :create, :update)
    #
    def validates_file_extension_of(name, options)
      raise(ArgumentError, 'An array of valid types must be specified as :in ' \
        'via the options hash') unless options[:in].is_a?(Array)
      options[:in] = options[:in].flatten.map { |n| n.downcase }
      options[:message] ||= 'does not have a valid file extension'
      send(validation_method(options[:on] || :save), options) do |record|
        file = record.send(name)
        if file.is_a?(CargoFile)
          ext = file.extension
          ext.downcase! unless ext.nil?
          if !options[:in].include?(ext)
            record.errors.add(name, options[:message])
          end
        end
      end
    end
  end
end
