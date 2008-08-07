require File.join(File.dirname(__FILE__), 'helper')

describe 'validates_file_extension' do
  it 'should raise ArgumentError when :in is not in options' do
    proc do
      class InvalidModel < ActiveRecord::Base
        set_table_name 'foos'
        cargo :file
        validates_file_extension_of :file, :on => :create
      end
      i = InvalidModel.new
      i.set_file(snail)
      i.save
    end.should raise_error(ArgumentError)
  end

  it 'should validate based on :in' do
    class InvalidModel < ActiveRecord::Base
      set_table_name 'foos'
      cargo :file
      validates_file_extension_of :file, :in => %w(jpg)
    end
    i = InvalidModel.new
    i.set_file(snail)
    i.valid?.should be_true
    i.set_file(snail('png'))
    i.valid?.should be_false
    i.errors.full_messages.should include('File does not have a valid file extension')
  end
end

describe 'validates_file_exists' do
  it 'should only validate existence if specified' do
    class InvalidModel < ActiveRecord::Base
      set_table_name 'foos'
      cargo :file
      validates_file_exists :file
    end
    i = InvalidModel.new
    i.file.should be_nil
    i.valid?.should be_false
    i.errors.full_messages.should include('File must be set')
    i.set_file(snail)
    i.valid?.should be_true
  end
end
