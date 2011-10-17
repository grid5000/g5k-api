module Grid5000
# Abstracts the way to send notifications by forwarding every notification to
# the notifications API. Even if this notifications API is located in the same
# app, it helps decoupling, albeit making the process a bit less efficient.
# So, use this class from any model/lib/controller other than one related to
# the notifications API.
class Notification
  class << self
    attr_accessor :uri
  end
  
  attr_accessor :recipients, :message
  
  def initialize(message, options = {})
    @recipients = options[:to] || []
    @message = message
  end
  
  def deliver!
    http = EM::HttpRequest.new(self.class.uri).post(
      :timeout => 5,
      :body => self.to_json,
      :head => {
        'Content-Type' => "application/json",
        'Accept' => "*/*",
        'X-Api-User-Privileges' => 'server',
        'X-Api-User-Cn' => 'g5k-api',
      }
    )
    if http.response_header.status == 202
      Rails.logger.info "Successfully sent notification #{self.inspect}"
      true
    else
      Rails.logger.warn "Error when trying to send notification #{self.inspect}: #{http.response_header.status} - #{http.response.inspect}"
      false
    end
  end
  
  def to_json(*args)
    JSON.pretty_generate({
      :to => recipients,
      :body => message
    })
  end
end
end
