module Neutron

  class App

    def initialize(controller:)
      raise 'Controller must be inherit from Neutron::Controller' unless controller.is_a?(::Neutron::Controller)
      @controller = controller
    end

    def run
      Thread.new { @controller.run }
      begin
        `npm run boot`
      ensure
        @controller.stop
      end
    end

  end

end
