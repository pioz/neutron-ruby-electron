require 'socket'
require 'json'

module Neutron

  Thread.abort_on_exception = true

  class Controller < UNIXServer

    def initialize(path = '/tmp/neutron.sock')
      File.delete(path) if File.exists?(path)

      super(path)
      @path = path
      @run = true

      trap('INT') do
        STDOUT.puts 'Closing socket...'
        self.stop
      end
    end

    def stop
      @run = false
      self.close
      File.delete(@path) if File.exists?(@path)
    end

    def run
      while @run do
        begin
          Thread.fork(self.accept) do |sock| # begin
            Thread.current[:threads] = {}
            while (data = sock.gets)
              break if data.empty?
              data.chop!
              # STDOUT.puts data
              Thread.fork(sock, data, Thread.current[:threads]) do |sock, data, threads|
                Thread.current[:sock] = sock
                Thread.current[:threads] = threads
                response = dispatch(data)
                if response
                  send_string(sock, response.to_json + "\n")
                end
              end
            end
          end
        rescue Errno::EBADF
          # socket has been closed and server is waiting on socket.accept
        end
      end
    end

    def notify(event, result = nil)
      if result.is_a?(Hash) && result[:error].is_a?(Hash)
        result[:error][:code] ||= SERVER_ERROR
        result[:error][:message] ||= 'Server error'
        response = {jsonrpc: '2.0', error: result[:error], event: event, id: -1}
      else
        response = {jsonrpc: '2.0', result: result, event: event, id: -1}
      end
      sock = Thread.current[:sock]
      if sock
        send_string(sock, response.to_json + "\n")
      end
    end

    PARSE_ERROR = -32700
    INVALID_REQUEST = -32600
    METHOD_NOT_FOUND = -32601
    INTERNAL_ERROR = -32603
    SERVER_ERROR = -32000

    protected

    def run_thread(&block)
      #c = caller[0][/`.*'/][1..-2].to_sym
      callers = caller.map{|c| c[/`.*'/][1..-2].to_sym}
      c = callers.select{|c| Thread.current[:threads].keys.include?(c)}.first
      sock = Thread.current[:sock]
      Thread.current[:threads][c] << Thread.fork do
        Thread.current[:sock] = sock
        block.call
      end
    end

    private

    def send_string(sock, s)
      while(s && s.length > 0)
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
      if jsonrpc['jsonrpc'] != '2.0' || !jsonrpc['id'].is_a?(Integer) || jsonrpc['id'] < 0
        return {jsonrpc: '2.0', error: {code: INVALID_REQUEST, message: 'Invalid request'}, id: jsonrpc['id']}
      end
      if !self.respond_to?(jsonrpc['method'])
        return {jsonrpc: '2.0', error: {code: METHOD_NOT_FOUND, message: 'Method not found'}, id: jsonrpc['id']}
      end

      # begin
      #  result = run_method(jsonrpc['method'], jsonrpc['params'], once: jsonrpc['once'])
      # rescue Exception => e
      #   return {jsonrpc: '2.0', error: {code: INTERNAL_ERROR, message: e.message}, id: jsonrpc['id']}
      # end
      result = run_method(jsonrpc['method'], jsonrpc['params'], once: jsonrpc['once'])

      if result.is_a?(Hash) && result[:error].is_a?(Hash)
        result[:error][:code] ||= SERVER_ERROR
        result[:error][:message] ||= 'Server error'
        return {jsonrpc: '2.0', error: result[:error], event: jsonrpc['method'], id: jsonrpc['id']}
      else
        r = result.is_a?(Hash) && !result[:result].nil? ? result[:result] : result
        # Reply with a non error result
        return {jsonrpc: '2.0', result: r, event: jsonrpc['method'], id: jsonrpc['id']}
      end
    end

    def run_method(method, params, once: true)
      if once
        Thread.current[:threads][method.to_sym] ||= []
        Thread.current[:threads][method.to_sym].each do |t|
          t.kill if t.alive?
          Thread.current[:threads][method.to_sym].delete(t)
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
