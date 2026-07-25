# frozen_string_literal: true

namespace :db do
  namespace :migrate do
    task :up do
      require_relative 'db'
      Sequel.extension :migration
      Sequel::Migrator.apply(DB, 'migrations')
    end
  end
  task migrate: 'db:migrate:up'
end
