# Copyright (c) 2009-2011 Cyril Rohr, INRIA Rennes - Bretagne Atlantique
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'blather/client/dsl'

class MyXMPP
  include Blather::DSL
  attr_accessor :last_reconnect
  def run; client.run; end
  def handler; client; end
  def initialize 
    @last_reconnect=nil
  end
end

module Blather
  class Stream
    class Parser < Nokogiri::XML::SAX::Document
      # By default, ParseError exceptions are not rescued, which causes the
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


def reconnect
  return Proc.new { |my_xmpp|
    # Automatically reconnect
    now=Time.now
    if my_xmpp.last_reconnect != nil && now-my_xmpp.last_reconnect<5
      Rails.logger.info "XMPP disconnected again at #{now}. Waiting 5s before reconnecting to XMPP server..."
      EM.add_timer(5) do 
        reconnect.call(my_xmpp)
      end
    else
      Rails.logger.info "XMPP Disconnected at #{now}. Reconnecting..."
      begin
        XMPP.handler.connect
        my_xmpp.last_reconnect=now
      rescue StandardError => e
        Rails.logger.info "Catched XMPP error: #{e.class.name} - #{e.message}"
        EM.add_timer(10) do
          reconnect.call(my_xmpp)
        end
      end
    end
  }
end

XMPP.disconnected { 
  reconnect.call(XMPP)
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
