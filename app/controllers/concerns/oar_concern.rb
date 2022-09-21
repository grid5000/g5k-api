module OarConcern
  extend ActiveSupport::Concern

  included do
    before_action :load_oarapi
  end

  def load_oarapi
    @oarapi = Grid5000::OarApi.new
    @oarapi.tls_options = tls_options_for(:out)
    @oarapi.base_uri = api_path
    @oarapi.user = @credentials[:cn]
  end
end
