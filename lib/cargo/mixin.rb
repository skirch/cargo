module Cargo
  module Mixin
    # cargo will associate an external file with an Active Record model. For
    # example, the following class definition will attach two CargoFiles to
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
    #   @image.original                            # => #<Cargo::CargoFile>
    #   @image.save                                # => true
    #
    def cargo(name)
      Cargo.config.verify!(connection)

      extend Validations

      has_one name,
        :as => :parent,
        :class_name => 'Cargo::CargoFile',
        :conditions => { :"#{Cargo.config.table_name}.name" => name.to_s },
        :dependent => :destroy,
        :validate => true

      before_save Cargo::CallbackHandler.new(name)
      after_save Cargo::CallbackHandler.new(name)

      define_method("set_#{name}") do |file|
        self.send("build_#{name}") unless self.send(name)
        self.send(name).set(file)
      end
    end
  end
end
