module Neutron

  class App

    def initialize(controller:)
      raise 'Controller must be inherit from Neutron::Controller' unless controller.is_a?(::Neutron::Controller)
      @controller = controller
    end

    def run
      path = File.expand_path('..', caller[0].split(':').first)
      Thread.new { @controller.run }
      begin
        `cd '#{path}' && npm run boot`
      ensure
        @controller.stop
      end
    end

  end

end
