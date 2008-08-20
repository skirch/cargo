module Cargo
  # We keep our callbacks in this class so we don't pollute the model that
  # calls cargo.
  #
  class CallbackHandler # :nodoc:
    def initialize(name)
      @name = name
    end

    # Set the name attribute in the database to the name of the cargo
    # association. This allows multiple cargo associations with different
    # names to be in the same table.
    #
    def before_save(record)
      file = record.send(@name)
      file.name = @name.to_s if file && !file.frozen?
    end

    # Cargo uses Active Record's has_one association. has_one automatically
    # saves the association when the record is new, but it's up to us after
    # that. This forces any file changes to be saved every time the parent
    # record is saved.
    #
    # One weird thing is that Active Record does validate the has_one
    # association every time, so we don't need to worry about that. Validation
    # errors will automatically be caught before this callback.
    #
    def after_save(record)
      file = record.send(@name)
      file.save if file && file.changed? && !file.frozen?
    end
  end
end
