module Vlans
  extend ActiveSupport::Concern

  included do
    before_action :load_kavlan, :vlan_exist
  end

  private

  def api_path(path = '')
    uri_to(
      File.join(
        site_path(params[:site_id]),
        '/internal/kavlanapi/',
        path
      ),
      :out
    )
  end

  def load_kavlan
    @kavlan = Grid5000::Kavlan.new
    @kavlan.tls_options = tls_options_for(:out)
    @kavlan.base_uri = api_path
  end

  def vlan_exist
    vlan_param = params[:controller] == 'vlans' ? :id : :vlan_id

    if params[vlan_param]
      raise ApplicationController::NotFound, "Vlan #{params[vlan_param]} does not exist" unless @kavlan.vlan_exist?(params[vlan_param])
    end
  end
end
