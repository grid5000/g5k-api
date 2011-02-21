require 'json'

module Rack
  class PrettyJSON
    def initialize(app, options = {})
      @app = app
      @unless_header = (
        options[:unless_header] || 'X-Rack-PrettyJSON-Skip'
      )
      @unless_query = (
        options[:unless_query] || 'compact'
      )
    end

    def call(env)
      p env
      skip_client = env['HTTP_'+@unless_header.gsub(/-/,'_').upcase]
      
      code, head, body = @app.call(env)

      skip_server = head.delete(@unless_query) || env['QUERY_STRING'].split("&").include?{|x| x.split("=")[0] == @unless_query}
      
      if !skip_client && !skip_server && head['Content-Type'] &&
          head['Content-Type'].split(";")[0] =~ /[\+|\/]json$/i
        payload = ""
        body.each{|chunk| payload << chunk}
        body = JSON.pretty_generate(
          JSON.load(payload)
        )
        head['Content-Length'] = body.size.to_s
        body = [body]
      end

      [code, head, body]
    end
  end
end