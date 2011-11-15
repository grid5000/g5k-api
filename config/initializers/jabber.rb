require 'blather/client/dsl'

class MyXMPP
  include Blather::DSL
  def run; client.run; end
  def handler; client; end
end


XMPP = MyXMPP.new
jid = Blather::JID.new(Rails.my_config(:xmpp_jid))
XMPP.setup(jid, Rails.my_config(:xmpp_password), 'jabber.grid5000.fr')

XMPP.when_ready {
  Rails.logger.info "Connected to XMPP server as #{jid.to_s}"
}

XMPP.disconnected { 
  # Automatically reconnect
  XMPP.handler.connect
}

Thread.new {
  until EM.reactor_running?
    sleep 1
  end
  XMPP.run
}
