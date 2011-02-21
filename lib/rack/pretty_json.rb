require 'json'

module Rack
  class PrettyJSON
    def initialize(app, options = {})
      @app = app
      @only_if_header = (
        options[:only_if_header] || 'X-Rack-PrettyJSON'
      )
      @only_if_query = (
        options[:only_if_query] || 'pretty'
      )
      @warning = !!options[:warning]
    end

    def call(env)
      client = env['HTTP_'+@only_if_header.gsub(/-/,'_').upcase]
      
      code, head, body = @app.call(env)

      server = head.delete(@only_if_header) || env['QUERY_STRING'].
        split("&").find{|x| x.split("=")[0] == @only_if_query}
      
      if head['Content-Type'] && head['Content-Type'].
          split(";")[0] =~ /[\+|\/]json$/i
        if (client || server) 
          payload = ""
          body.each{|chunk| payload << chunk}
          body = JSON.pretty_generate(
            JSON.load(payload)
          )
          head['Content-Length'] = body.size.to_s
          body = [body]
        elsif @warning
          head['X-Info'] ||= []
          head['X-Info'].push('Use `?pretty=yes` or add the HTTP header `X-Rack-PrettyJSON: yes` if you want pretty output.')
        end
      end

      [code, head, body]
    end
  end
end