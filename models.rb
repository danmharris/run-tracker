# frozen_string_literal: true

require_relative 'db'
require 'sequel/model'

Unreloader.autoload('models') { |f| Sequel::Model.send(:camelize, File.basename(f).sub(/\.rb\z/, '')) }
