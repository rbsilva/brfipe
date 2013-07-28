require 'test/unit'
require 'active_support'
require 'shoulda'
require 'mocha/setup'
require 'brfipe'

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }
