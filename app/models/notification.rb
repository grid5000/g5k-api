class Notification
  include ConfigurationHelper
  
  attr_accessor :recipients, :message
  
  def initialize(message, options = {})
    @recipients = options[:to] || []
    @message = message
  end
  
  def deliver!
    url = uri_to("/notifications", :out)
    http = EM::HttpRequest.new(url).post(
      :timeout => 5,
      :body => self.to_json,
      :head => {
        'Content-Type' => media_type(:json),
        'Accept' => "*/*",
        'X-Api-User-Privileges' => 'server'
      }
    )
    if http.response_header.status == 202
      Rails.logger.info "Successfully sent notification #{self.inspect}"
    else
      Rails.logger.warn "Error when trying to send notification #{self.inspect}: #{http.response_header.status} - #{http.response.inspect}"
    end
  end
  
  def to_json(*args)
    {
      :to => recipients,
      :body => message
    }.to_json(*args)
  end
end
