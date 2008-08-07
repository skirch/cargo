module Cargo
  module Mixin
    # cargo will associate an external file with an Active Record model. For
    # example, the following class definition will attach two ExternalFiles to
    # each Image object. cargo uses Active Record's <tt>has_one</tt>
    # association, so you can access the associated files just like any other
    # Active Record object.
    #
    #   class Image < ActiveRecord::Base
    #     cargo :original
    #     cargo :thumbnail
    #   end
    #
    # When you create a new Image, you can create the associated file with the
    # <tt>set_associated</tt> shortcut.
    #
    #   @image = Image.new
    #   @image.original                            # => nil
    #   @image.set_original('path/to/image.jpg')   # => true
    #
    #   # the above is a shortcut for:
    #   # @image.build_original
    #   # @image.original.set('path/to/image.jpg')
    #
    #   @image.original                            # => #<Cargo::ExternalFile>
    #   @image.save                                # => true
    #
    def cargo(name)
      Cargo.config.verify!(connection)

      extend Validations

      has_one name, :as => :parent, :conditions => { :name => name.to_s },
        :class_name => 'Cargo::ExternalFile', :dependent => :destroy

      before_save Cargo::CallbackHandler.new(name)
      after_save Cargo::CallbackHandler.new(name)

      define_method("set_#{name}") do |file|
        self.send("build_#{name}") unless self.send(name)
        self.send(name).set(file)
      end
    end
  end
end
