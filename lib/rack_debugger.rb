class RackDebugger
  def initialize(app, logger)
    @app = app
    @logger = logger
  end
  def call(env)
    # Do not output debugging info for pings originating from Squid proxy.
    unless env['HTTP_USER_AGENT'] =~ /^squid/i
      @logger.info ["  HEAD:", env['REQUEST_METHOD'], env['PATH_INFO'], "-", env.reject{|k,v|
        k !~ /^HTTP\_/ || ["HTTP_X_FORWARDED_HOST", "HTTP_VIA", "HTTP_X_FORWARDED_SERVER", "HTTP_X_FORWARDED_FOR", "HTTP_AUTHORIZATION"].include?(k)
      }.inspect].join(" ")

      if env['rack.input']
        @logger.info ["  BODY:", env['rack.input'].read(10_000).inspect].join(" ")
        env['rack.input'].rewind
      end
    end

    @app.call(env)
  end
end