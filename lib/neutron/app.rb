require 'sys/proctable'

module Neutron

  class App

    def initialize(controller:)
      raise 'Controller must be inherit from Neutron::Controller' unless controller.is_a?(::Neutron::Controller)
      @controller = controller
    end

    def run
      path = File.expand_path('..', caller[0].split(':').first)
      begin
        Thread.new { @controller.run }
        `cd '#{path}' && npm run boot`
      ensure
        process_path = File.join(path, 'node_modules/electron-prebuilt-compile/lib/es6-init.js')
        p = Sys::ProcTable.ps.select { |p| p.cmdline.include?(process_path) }.first
        Process.kill('HUP', p.pid) if p
        @controller.stop
      end
    end

  end

end
