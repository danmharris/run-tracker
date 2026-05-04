require 'rack/unreloader'

dev = ENV['RACK_ENV'] == 'development'

Unreloader = Rack::Unreloader.new(subclasses: %w[Roda], reload: dev, autoload: dev) { App }
Unreloader.require('app.rb') { 'App' }

run(dev ? Unreloader : App.freeze.app)
