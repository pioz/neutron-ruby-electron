module Neutron

  class App

    def initialize(backend, electron_entry_point_file = 'main_window.js')
      @backend = backend
      @electron_entry_point_file = electron_entry_point_file
    end

    def run
      backend.run
      `electron #{@electron_entry_point_file}`
      backend.stop
    end

  end

end
