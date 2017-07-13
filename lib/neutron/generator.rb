require 'thor'
require 'json'
require 'etc'


module Neutron

  TEMPLATE_PATH = File.expand_path('../template', __FILE__)
  NEUTRON_NPM_PACKAGE_PATH = File.expand_path('../neutron_npm_package', __FILE__)

  class Generator < Thor::Group
    include Thor::Actions
    argument :name

    def initialize(options)
      super([options[:project_name] || 'neutron'])
      @options = options
    end

    def self.source_root
      File.dirname(__FILE__)
    end

    def generate!
      self.copy_template
      self.generate_package_json
    end

    def copy_template
      directory(TEMPLATE_PATH, name, exclude_pattern: /Gemfile|components/)
      if options[:react]
        directory(File.join(TEMPLATE_PATH, 'src/assets/javascripts/components'), File.join(name, 'src/assets/javascripts/components'))
      end
      if options[:development]
        copy_file(File.join(TEMPLATE_PATH, 'src/Gemfile'), File.join(name, 'src/Gemfile'))
        inside(File.join(name, 'src')) do
          system 'bundle install'
        end
      end
    end

    def generate_package_json
      say_status :generate, File.join(name, 'src', 'package.json')
      inside(File.join(name, 'src')) do
        # Init NPM
        `npm init -y`
        # Install local neutron npm package
        system "npm install #{NEUTRON_NPM_PACKAGE_PATH}"
        # Install NPM packages
        %w(electron electron-prebuilt-compile).each do |package|
          system "npm install --save-dev #{package}"
        end
        if options[:jquery] || options[:bootstrap]
          system "npm install --save jquery"
        end
        if options[:bootstrap]
          system "npm install --save bootstrap"
        end
        if options[:react]
          system "npm install --save react"
          system "npm install --save react-dom"
        end
        # Edit package.json
        username = Etc.getlogin.downcase
        json = JSON.parse(File.read('package.json'))
        json['name'] = name
        json['description'] = 'Another Neutron app'
        json['repository'] = "https://github.com/#{username}/#{name}"
        json['author'] = username
        json['license'] = 'MIT'
        json['main'] = 'main_window.js'
        json['scripts']['boot'] = './node_modules/.bin/electron .'
        #json['babel'] = {'presets' => ['es2015']}
        File.open('package.json', 'w') {|f| f << json.to_json}
      end
    end

  end

end
