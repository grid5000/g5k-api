require 'blather/client/dsl'

class MyXMPP
  include Blather::DSL
  def run; client.run; end
  def handler; client; end
end

module Blather
  class Stream
    class Parser < Nokogiri::XML::SAX::Document
      # By default, ParseError exceptions are not rescue, which causes the
      # stream to be closed, AND the reactor loop to be closed.
      def receive_data(*args)
        super(*args)
      rescue StandardError => e
        Rails.logger.error "XMPP error: #{e.class.name} - #{e.message}"
        Rails.logger.debug e.backtrace.join("; ")
      end
    end
  end
end

XMPP = MyXMPP.new
jid = Blather::JID.new(Rails.my_config(:xmpp_jid))
XMPP.setup(jid, Rails.my_config(:xmpp_password), 'jabber.grid5000.fr')

XMPP.when_ready {
  Rails.logger.info "Connected to XMPP server as #{jid.to_s}"
}

XMPP.disconnected { 
  # Automatically reconnect
  Rails.logger.info "Disconnected. Reconnecting to XMPP server..."
  XMPP.handler.connect
}

XMPP.handle :error do |error|
  Rails.logger.warn "XMPP connection encountered error: #{error.inspect}"
end

Thread.new {
  until EM.reactor_running?
    sleep 1
  end
  XMPP.run
}
