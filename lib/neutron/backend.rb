require 'socket'
require 'json'

module Neutron

  Thread.abort_on_exception = true

  class Backend < UNIXServer

    def initialize(path)
      super(path)
      @path = path
      @run = true

      trap('INT') do
        STDOUT.puts 'Stopping server...'
        self.stop
      end
    end

    def stop
      @run = false
      @disconnect = true
      self.close
      File.delete(@path)
    end

    def disconnect
      @disconnect = true
    end

    def run
      while @run do
        begin
          Thread.fork(self.accept) do |sock| # begin
            Thread.current[:threads] = {}
            @disconnect = false
            while (data = sock.gets) && !@disconnect
              break if data.empty?
              data.chop!
              STDOUT.puts data
              Thread.fork(sock, data, Thread.current[:threads]) do |sock, data, threads|
                Thread.current[:sock] = sock
                Thread.current[:threads] = threads
                response = dispatch(data)
                if response
                  send_string(sock, response.to_json + "\n")
                end
              end
            end
            if @disconnect
              sock.close
              break
            end
          end
        rescue Errno::EBADF
        end
      end
    end

    def notify(event, result)
      if result.is_a?(Hash) && result[:error].is_a?(Hash)
        result[:error][:code] ||= UNKNOWN_ERROR
        result[:error][:message] ||= 'Unknown error'
        response = {jsonrpc: '2.0', error: result[:error], event: event, id: -1}
      else
        response = {jsonrpc: '2.0', result: result, event: event, id: -1}
      end
      sock = Thread.current[:sock]
      if sock
        send_string(sock, response.to_json + "\n")
      end
    end

    UNKNOWN_ERROR = -1
    JSONRPC_INVALID_VERSION = -2
    METHOD_NOT_FOUND = -3
    PARSE_ERROR = -4

    protected

    def run_thread(&block)
      c = caller[0][/`.*'/][1..-2].to_sym
      sock = Thread.current[:sock]
      Thread.current[:threads][c] << Thread.fork do
        Thread.current[:sock] = sock
        block.call
      end
    end

    private

    def send_string(sock, s)
      while(s.length > 0)
        sent = sock.send(s, 0)
        s = s[sent..-1]
      end
      sock.flush
    end

    def dispatch(data)
      begin
        jsonrpc = JSON.parse(data)
      rescue JSON::ParserError
        return {jsonrpc: '2.0', error: {code: PARSE_ERROR, message: 'Parse error'}, id: nil}
      end
      if jsonrpc['jsonrpc'] == '2.0'
        begin
          result = run_method(jsonrpc['method'], jsonrpc['params'], jsonrpc['multi'])
        rescue NoMethodError
          return {jsonrpc: '2.0', error: {code: METHOD_NOT_FOUND, message: 'Method not found'}, id: jsonrpc['id']}
        end
        return nil unless jsonrpc['id'].is_a?(Integer) # we have a notification request, do not reply
        if result.is_a?(Hash) && result[:error].is_a?(Hash)
          result[:error][:code] ||= UNKNOWN_ERROR
          result[:error][:message] ||= 'Unknown error'
          return {jsonrpc: '2.0', error: result[:error], event: jsonrpc['method'], id: jsonrpc['id']}
        else
          r = result.is_a?(Hash) && !result[:result].nil? ? result[:result] : result
          # Reply with a non error result
          return {jsonrpc: '2.0', result: r, event: jsonrpc['method'], id: jsonrpc['id']}
        end
      else
        return {jsonrpc: '2.0', error: {code: JSONRPC_INVALID_VERSION, message: 'JSON-RPC invalid version'}, id: jsonrpc['id']}
      end
    end

    def run_method(method, params, multi)
      unless multi
        Thread.current[:threads][method.to_sym] ||= []
        Thread.current[:threads][method.to_sym].each do |t|
          if t.alive?
            t.kill
          else
            Thread.current[:threads][method.to_sym].delete(t)
          end
        end
        Thread.current[:threads][method.to_sym] << Thread.current
      end
      if params
        return self.__send__(method, *params)
      else
        return self.__send__(method)
      end
    end

  end
end
