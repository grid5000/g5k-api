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

# encoding: utf-8
require 'uri'

# This is the class that handles notifications sent to the notifications API.
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
        invalid = @to.select{|uri| uri.scheme.nil? || !VALID_URI_SCHEMES.include?(uri.scheme) || ["localhost", "127.0.0.1"].include?(uri.host)}.map(&:to_s)
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
      # HTTP processing
      when /http/
        http = EM::HttpRequest.new(uri.to_s).post(
          :timeout => 5,
          :body => body.to_s,
          :head => {
            'Content-Type' => "text/plain",
            'Accept' => "*/*"
          }
        )
        Rails.logger.info "Sent notification, received status=#{http.response_header.status}: #{http.response.inspect}"
      # EMAIL processing
      when /mailto/
        subject = uri.headers.detect{|array| array.first == "subject"}
        subject = subject.nil? ? "Grid5000 Notification" : subject.last
        body_header = uri.headers.detect{|array| array.first == "body"}
        body_header = body_header.nil? ? "" : body_header.last

        email = {
          :domain   => Rails.my_config(:smtp_domain),
          :host     => Rails.my_config(:smtp_host),
          :port     => Rails.my_config(:smtp_port),
          :starttls => false,
          :from     => Rails.my_config(:smtp_from),
          :to       => [uri.to],
          :header   => {"Subject" => subject},
          :body     => "#{body_header.to_s}#{body.to_s}"
        }
        Rails.logger.info "Sending email with following options: #{email.inspect}"
        result = EM::Synchrony.sync(EM::Protocols::SmtpClient.send(email))
        Rails.logger.info "Sent email. Result=#{result.inspect}"
      # XMPP processing
      when /xmpp/
        Rails.logger.info "XMPP URI, processing..."

        to = Blather::JID.new("#{uri.opaque}/notifier")

        presence = Blather::Stanza::Presence.new
        presence.from = XMPP.jid

        msg = Blather::Stanza::Message.new
        msg.body = body.to_s
        if to.domain == "conference.jabber.grid5000.fr"
          msg.to = Blather::JID.new(to.node, to.domain)
          msg.type = :groupchat
        else
          msg.to = to
          msg.type = :chat
        end

        presence.to = to
        Rails.logger.info "Connected to XMPP server. Sending presence: #{presence.to_s}..."
        XMPP << presence
        Rails.logger.info "Sending stanza: #{msg.to_s}..."
        XMPP << msg
      end
    end
  rescue Timeout::Error, StandardError => e
    Rails.logger.warn "Failed to send notification #{self.inspect} : #{e.class.name} - #{e.message}"
    Rails.logger.debug e.backtrace.join(";")
  end
end