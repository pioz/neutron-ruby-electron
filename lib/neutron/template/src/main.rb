require 'neutron/app'
require './backend.rb'

backend = Backend.new()
app = Neutron.new(backend)
app.run
