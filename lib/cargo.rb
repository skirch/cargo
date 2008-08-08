require 'rubygems'
require 'active_record'

require 'cargo/callback_handler'
require 'cargo/cargo_file'
require 'cargo/config'
require 'cargo/errors'
require 'cargo/mixin'
require 'cargo/validations'

module Cargo # :nodoc:
  mattr_accessor :config

  # Load default configuration. See cargo/config.rb for details.
  #
  Config.new
end

ActiveRecord::Base.send(:extend, Cargo::Mixin)
