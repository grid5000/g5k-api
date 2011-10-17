require 'blather/client/dsl'

class MyXMPP
  include Blather::DSL
  def run; client.run; end
end

XMPP = MyXMPP.new
jid = Blather::JID.new(Rails.my_config(:xmpp_jid))
XMPP.setup(jid, Rails.my_config(:xmpp_password), 'jabber.grid5000.fr')