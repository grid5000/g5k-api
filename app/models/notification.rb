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
        'X-Api-User-Cn' => 'g5kapi',
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
