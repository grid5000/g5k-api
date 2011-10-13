require 'uri'

class Notification

  VALID_URI_SCHEMES = %w{http https xmpp mailto}

  attr_reader :errors
  attr_accessor :to
  attr_accessor :body

  def initialize(params = {})
    @to = params[:to] || []
    @body = params[:body]
  end

  def normalize_recipients!
    unless @to.all?{|uri| uri.kind_of?(URI) }
      @to = @to.reject{|uri| uri.blank?}.map{|uri| URI.parse(uri) rescue nil}.compact
    end
    self
  end

  def valid?
    @errors = []
    if to.blank? || !to.kind_of?(Array)
      @errors.push("'to' must be an array of URI")
    else
      normalize_recipients!
      if @to.empty?
        @errors.push("'to' must be non-empty")
      else
        invalid = @to.select{|uri| uri.scheme.nil? || !VALID_URI_SCHEMES.include?(uri.scheme)}.map(&:to_s)
        @errors.push("'to' contains invalid URIs (#{invalid.join(",")})") unless invalid.empty?
      end
    end
    @errors.push("'body' can't be blank") if body.blank?
    @errors.empty?
  end

  def deliver
    return false unless valid?
    to.each do |uri|
      process_uri(uri)
    end
  end

  # Takes a <tt>uri</tt> URI as parameter.
  def process_uri(uri)
    Timeout.timeout(5) do
      case uri.scheme
      when /http/
        # RestClient.post(notification.uri.to_s, notification.body.to_s, :content_type => "application/json") unless notification.uri.host =~ /localhost/i
      when /mailto/
        # subject = notification.uri.headers.detect{|array| array.first == "subject"}
        # subject = subject.nil? ? "Grid5000 Notification" : subject.last
        # body_header = notification.uri.headers.detect{|array| array.first == "body"}
        # body_header = body_header.nil? ? "" : body_header.last
        # email_options = {
        #   :to => notification.uri.to, :from => "notifications@api.grid5000.fr", :subject => subject.to_s,
        #   :body => "#{body_header.to_s}#{notification.body.to_s}",
        #   :via => :smtp,
        #   :smtp => {
        #   :host     => "mail.#{site}.grid5000.fr",
        #   :domain => "api-server.#{site}.grid5000.fr"
        # }}
        # logger.info "[#{pid}] [#{job.hash}] Sending email with following options: #{email_options.inspect}"
        # Pony.mail(email_options)
        # job.delete
      when /xmpp/
        Rails.logger.info "XMPP URI, processing..."

        to = Blather::JID.new(uri.opaque)

        XMPP.when_ready {
          Rails.logger.info "Connected to XMPP server. Sending presence..."

          presence = Blather::Stanza::Presence.new
          presence.to = to
          presence.from = XMPP.jid
          XMPP << presence

          msg = Blather::Stanza::Message.new
          msg.body = body.to_s
          if to.domain == "conference.jabber.grid5000.fr"
            msg.to = Blather::JID.new(to.node, to.domain)
            msg.type = :groupchat
          else
            msg.to = to
            msg.type = :chat
          end

          Rails.logger.info "Sending stanza: #{msg.to_s}..."
          XMPP << msg

        }

        XMPP.run
      end
    end
  rescue RestClient::Exception, Timeout::Error, StandardError => e
    Rails.logger.warn "Failed to send notification #{self.inspect} : #{e.class.name} - #{e.message}"
    Rails.logger.debug e.backtrace.join(";")
  end
end