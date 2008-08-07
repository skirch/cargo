require 'rubygems'
require 'active_record'

require 'cargo/cargo_file'
require 'cargo/callback_handler'
require 'cargo/config'
require 'cargo/errors'
require 'cargo/mixin'
require 'cargo/validations'

module Cargo # :nodoc:
end

ActiveRecord::Base.send(:extend, Cargo::Mixin)
