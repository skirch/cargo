require File.join(File.dirname(__FILE__), 'helper')

describe 'A model using cargo' do
  def file_count(path)
    (Dir.entries(path) - ['.', '..']).length
  end

  before do
    @model = Foo.new
    @model.set_file(snail)
  end

  after do
    @model.destroy unless @model.new_record?
  end

  it 'should be assigned a key when saving new data' do
    @model.file.new_data?.should be_true
    @model.file.key = nil
    @model.save.should be_true
    @model.file.key.should_not be_nil
  end

  it 'should be valid without an extension' do
    @model.file.extension = nil
    @model.file.should be_valid
  end

  it 'should save file on save' do
    @model.save.should be_true
    File.exist?(@model.file.path).should be_true
  end

  it 'should destroy file on destroy' do
    @model.save.should be_true
    File.exist?(@model.file.path).should be_true
    @model.destroy
    File.exist?(@model.file.path).should be_false
  end

  it 'should remove empty directories on destroy' do
    @model.save.should be_true
    file_count(@model.file.dirname).should equal(1)
    @model.destroy
    File.exist?(@model.file.dirname).should be_false
  end

  it 'should not remove non-empty directories on destroy' do
    @model.save.should be_true
    other = File.join(@model.file.dirname, 'other_file')
    FileUtils.touch(other)
    file_count(@model.file.dirname).should equal(2)
    @model.destroy
    file_count(@model.file.dirname).should equal(1)
    FileUtils.rm(other)
  end

  it 'should clear @tempfile after save' do
    @model.file.send(:instance_variable_get, :@tempfile).should_not be_nil
    @model.save.should be_true
    @model.file.send(:instance_variable_get, :@tempfile).should be_nil
  end

  it 'should raise CannotGenerateFilename for filename methods when new_record?' do
    @model.new_record?.should be_true
    proc do
      @model.file.filename
    end.should raise_error(Cargo::Errors::CannotGenerateFilename)
    proc do
      @model.file.subdir
    end.should raise_error(Cargo::Errors::CannotGenerateFilename)
    proc do
      @model.file.path
    end.should raise_error(Cargo::Errors::CannotGenerateFilename)
    proc do
      @model.file.dirname
    end.should raise_error(Cargo::Errors::CannotGenerateFilename)
  end

  it 'should not create without file data' do
    @model = Foo.new
    @model.build_file
    @model.file.new_data?.should be_false
    @model.save.should be_false
    @model.file.errors.full_messages.should include('File must be set')
  end

  it 'should allow save on parent with nil association' do
    @model = Foo.new
    @model.file.should be_nil
    @model.save.should be_true
    @model.file.should be_nil
  end

  it 'should remove existing file when saving a new file' do
    @model.save.should be_true
    file_count(@model.file.dirname).should equal(1)
    original_filename = @model.file.filename
    @model.file.set(snail('png'))
    @model.file.save.should be_true
    @model.file.filename.should_not eql(original_filename)
    file_count(@model.file.dirname).should equal(1)
  end

  it 'should allow set to handle filename strings and file objects' do
    @model.save.should be_true
    file_count(@model.file.dirname).should equal(1)
    original_filename = @model.file.filename
    File.open(snail('png'), 'r') do |f|
      @model.file.set(f)
    end
    @model.save.should be_true
    @model.file.filename.should_not eql(original_filename)
    file_count(@model.file.dirname).should equal(1)
  end

  it 'should raise UrlSubdirNotSet if it\'s not' do
    @model.save.should be_true
    proc do
      @model.file.relative_url
    end.should raise_error(Cargo::Errors::UrlSubdirNotSet)
    Cargo.config.url_subdir = '/url/path'
    @model.file.relative_url.should_not be_nil
  end

  it 'should save the association when saving the parent' do
    @model.set_file(snail)
    @model.save.should be_true
    @model.new_record?.should be_false
    @model.file.set(snail)
    @model.file.changed?.should be_true
    @model.save.should be_true
    @model.file.changed?.should be_false
  end

  it 'should automatically specify the name attribute when saving' do
    @model.file.name.should be_nil
    @model.save.should be_true
    @model.file.name.should_not be_nil
  end

  it 'should prevent name collisions on the same model' do
    @model.save.should be_true
    @model.set_other(snail('png'))
    @model.save.should be_true
    @model.other(true).id.should_not eql(@model.file(true).id)
  end

  it 'should only use mtime in relative_url if the file exists' do
    @model.save.should be_true
    @model.file.relative_url.should include('?')
    @model.file.destroy
    @model.file.relative_url.should_not include('?')
  end
end
