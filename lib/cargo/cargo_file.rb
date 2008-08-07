require 'tempfile'

module Cargo
  # CargoFile is an Active Record model that is associated to the model that
  # calls <tt>cargo</tt> via Active Record's <tt>has_one</tt> association.
  #
  # For example, the following class definition will attach two CargoFiles
  # to each Image object.
  #
  #   class Image < ActiveRecord::Base
  #     cargo :original
  #     cargo :thumbnail
  #   end
  #
  # Now you can access <tt>original</tt> and <tt>thumbnail</tt> just like any
  # other <tt>has_one</tt> association.
  #
  #   @image = Image.find(:first)
  #   @image.original                 # => #<Cargo::CargoFile>
  #   @image.original.filename        # => "00_02_bz_myk25s.jpg"
  #
  #   # All the usual has_one methods work too.
  #   @image.thumbnail.destroy
  #
  class CargoFile < ActiveRecord::Base
    belongs_to :parent, :polymorphic => true

    validate_on_create :file_data_exists

    before_save :assign_key

    after_save :save_file_if_new_data

    before_destroy :remove_file_and_empty_directories

    # Combines <tt>absolute_path</tt> and <tt>filename</tt> to return the full
    # path to this file
    #
    # ==== Example
    #
    #   @image = Image.find(:first)
    #   @image.original.absolute_filename
    #   # => "/var/files/images/00/00/00_00_01_4b2xu3.jpg"
    #
    def absolute_filename
      File.join(absolute_path, filename)
    end

    # Returns the path to this file on disk
    #
    # ==== Example
    #
    #   @image = Image.find(:first)
    #   @image.original.absolute_path
    #   # => "/var/files/images/00/00"
    #
    def absolute_path
      File.join(Cargo.config.file_path, subdir)
    end

    # Returns the filename for this file. Filenames are generated automatically
    # based on the model's <tt>id</tt>, <tt>key</tt>, and <tt>extension</tt>
    # fields.
    #
    # The <tt>filename</tt> has three parts:
    #
    # * <tt>id</tt> converted to base 36
    # * <tt>key</tt>
    # * <tt>extension</tt>
    #
    # The model's <tt>id</tt> is converted to base 36, zero-padded to six
    # places, and split into three parts of two characters each. This has the
    # following consequences:
    #
    # * Base 36 keeps directory names and filenames short
    # * Max of "zz" for each part limits each directory to 1295 files
    # * A depth of three directories allows for two billion files
    # * Zero-padding keeps directory listings in numerical order by model's
    #   <tt>id</tt>
    #
    # ==== Example
    #
    #   @image = Image.find(3023)
    #   @image.original.id                 # => 3023
    #   @image.original.key                # => "myk25s"
    #   @image.original.extension          # => "jpg"
    #
    #   # 3023 in base 36 is "2bz"
    #   # zero-padded and split gives 00 02 bz
    #   # the first two parts are used as subdirectories
    #
    #   @image.original.filename           # => "00_02_bz_myk25s.jpg"
    #   @image.original.subdir             # => "images/00/02"
    #   @image.original.absolute_filename
    #   # => "/var/files/images/00/02/00_02_bz_myk25s.jpg"
    #
    def filename
      suffix = extension.blank? ? '' : ".#{extension}"
      suffix = key.blank? ? suffix : "_#{key}#{suffix}"
      "#{base_filename}#{suffix}"
    end

    # Boolean value indicating whether model has unsaved file data
    #
    def new_data?
      @tempfile ? @tempfile.size > 0 : false
    end

    # Generates a relative url for this file based on <tt>config.url_subdir</tt>
    #
    # ==== Example
    #
    #   Cargo.config.url_subdir = '/files'
    #
    #   @image = Image.find(:first)
    #   @image.original.relative_url
    #   # => "/files/images/00/00/00_00_01_4b2xu3.jpg"
    #
    def relative_url
      mtime = File.mtime(absolute_filename).to_i.to_s
      url = []
      url << Cargo.config.url_subdir
      url << subdir.split(File::SEPARATOR)
      url << "#{filename}?#{mtime}"
      url.flatten.map do |s|
        s.ends_with?('/') ? s.chop : s
      end.join('/')
    end

    # Sets the file that will be saved during the Active Record after_save
    # callback. Automatically parses and sets the file extension.
    #
    # ==== Example
    #
    #   @image = Image.new
    #   @image.original                             # => nil
    #   @image.build_original
    #   @image.original.set('path/to/image.jpg')    # => true
    #
    #   # You can use a shortcut for the above to build and set the object in
    #   # one step:
    #   #
    #   # @image.set_original('path/to/image.jpg')
    #
    #   @image.original.extension                   # => "jpg"
    #
    #   file = File.open('path/to/image.png')
    #   @image.original.set(file)                   # => true
    #   @image.original.extension                   # => "png"
    #
    # ==== Parameters
    #
    # [file]
    #   Either a string to specify the filename or a file object
    #
    def set(file)
      @tempfile.close! if @tempfile
      @tempfile = Tempfile.new(self.class.name.demodulize.underscore)
      filename = nil
      case
      when file.is_a?(String)
        filename = file
        File.open(file, 'r') do |f|
          @tempfile.write(f.read)
        end
      when file.is_a?(File)
        filename = file.path
        @tempfile.write(file.read)
      when file.respond_to?(:read) && file.respond_to?(:original_path)
        filename = file.original_path
        @tempfile.write(file.read)
      end
      set_metadata(filename) if new_data?
      return new_data?
    end

    # Returns the subdirectory under <tt>config.file_path</tt> for this file
    #
    # ==== Example
    #
    #   @image = Image.find(:first)
    #   @image.original.subdir
    #   # => "images/00/00"
    #
    def subdir
      id_parts = id_in_base_36_parts
      level1 = id_parts[0]
      level2 = id_parts[1]
      File.join(parent_type.tableize, level1, level2)
    end

    private

    def assign_key
      self.key ||= random_key
    end

    def base_filename
      id_in_base_36_parts.join('_')
    end

    def create_path
      FileUtils.mkdir_p(absolute_path)
    end

    def file_data_exists
      errors.add(:base, 'File must be set') unless new_data?
    end

    # Returns a 3-part array of this object's id in base 36 which is used in
    # the subdir method to organize files such that each directory has a maximum
    # of 1295, or "zz", files.
    #
    # For example, an id of 1947 is "1i3" is base 36 and gives us the result
    # => ["00", "01", "i3"]
    #
    def id_in_base_36_parts
      raise(Errors::CannotGenerateFilename) if id.blank?
      base_36 = id.to_s(36).rjust(6, '0')
      parts = []
      # taking the rightmost two digits first allows for numbers larger than
      # "zzzzzz" by storing extra places in the first element of the array
      parts.unshift(base_36[-2, 2])
      parts.unshift(base_36[-4, 2])
      parts.unshift(base_36[0, base_36.length - 4])
    end

    def random_key(length = 6)
      # letters and numbers except 0, 1, l, O, and vowels
      a = 'bcdfghjkmnpqrstvwxyz23456789'.split(//)
      Array.new(length) { a[rand(a.length)] }.join
    end

    def remove_empty_directories
      dirs = absolute_path.split(File::SEPARATOR)
      subdir.split(File::SEPARATOR).length.times do
        begin
          FileUtils.rmdir(dirs.join(File::SEPARATOR))
          dirs.pop
        rescue Errno::ENOTEMPTY, Errno::ENOENT
          break
        end
      end
    end

    # Look for and delete a file matching this record's id. The key or extension
    # may have changed since this file was originally created, so we use the
    # base_filename to identify the file.
    #
    def remove_existing_file
      existing = Dir[File.join(absolute_path, "#{base_filename}*")].first
      FileUtils.rm_f(existing) unless existing.nil?
    end

    # Deletes the file and removes any empty directories that were created when
    # the file was created
    #
    def remove_file_and_empty_directories
      FileUtils.rm_f(absolute_filename)
      remove_empty_directories
    end

    def save_file_if_new_data
      if new_data?
        create_path
        remove_existing_file
        @tempfile.rewind
        File.open(absolute_filename, 'w') do |f|
          f.write(@tempfile.read)
        end
        @tempfile.close!
        @tempfile = nil
      end
    end

    def set_metadata(filename)
      orig = nil
      if filename =~ /^(?:.*[:\\\/])?(.*)/m
        orig = $1
      else
        orig = File.basename(filename) unless filename.nil?
      end
      self.original_filename_will_change!
      self.original_filename = orig
      ext = File.extname(filename)
      ext = ext.reverse.chop.reverse if ext.starts_with?('.')
      self.extension_will_change!
      self.extension = ext
    end
  end
end
