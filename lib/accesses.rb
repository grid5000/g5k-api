# frozen_string_literal: true

# Functions relating to the dynmaic generation of the dynamic accesses page
module Accesses
  NA_LABEL = 'no-access'
  NA_LEVEL = -1
  PRIOLEVEL = {
    'p1' => 40,
    'p2' => 30,
    'p3' => 20,
    'p4' => 10,
    'besteffort' => 0,
    NA_LABEL => NA_LEVEL
  }.freeze

  # An object to load and store sites and ggas from UMS
  class GgaSites
    def initialize
      @ggas, @sites = get_ggas_sites
    end

    def all_ggas
      @ggas.map { |x| x['name'] }
    end

    def expand_site(site)
      @ggas.select { |x| x['site'] == site }.map { |x| x['name'] }
    end

    def gga_exists?(group)
      @ggas.any? { |h| h['name'].eql? group }
    end

    def get_ggas_sites(version = 'stable')
      res = Net::HTTP.get_response URI("https://public-api.grid5000.fr/#{version}/users/ggas_and_sites")
      unless res.is_a?(Net::HTTPSuccess)
        raise "Unable to pull sites and groups from UMS. https://public-api.grid5000.fr/#{version}/users/ggas_and_sites responded with #{res.code} #{res.message} (error: ACCESS_UMS)"
      end

      begin
        h = JSON.parse(res.body)
      rescue JSON::ParserError => e
        raise "Couldn't parse sites and groups from UMS. (https://public-api.grid5000.fr/#{version}/users/ggas_and_sites). JSON error: #{e.message} (error: ACCESS_JSON)"
      end
      [h['ggas'], h['sites']]
    end

    def site_exists?(site)
      @sites.include? site
    end
  end

  # Main entery point for the access_controller to obtain dynamically generated accesses
  def self.build_accesses(input)
    ums = GgaSites.new

    _version = input['version']

    nodesets, _warn = dealias_sites(input.except('version'), ums)
    reformat_accesses(nodesets, ums)
  end

  # Takes a sites_and_gga nodesets access hash
  # Outputs a gga_only nodeset access hash
  def self.dealias_sites(input, ums)
    warn = []
    output = input.transform_values do |accesses_hash|
      accesses_hash.transform_values do |groups_hash|
        groups = groups_hash['ggas']

        groups_hash['sites'].each do |site|
          unless ums.site_exists?(site)
            raise "Unable to expand site '#{site}': no site by that name (error: ACCESS_NOSITE)"
          end

          groups.concat ums.expand_site(site)
        end
        groups.uniq
      end
    end
    [output, warn]
  end

  # Take a nodeset oriented access hash
  # Outputs a gga oriented access hash, with label/level formating
  def self.reformat_accesses(nodesets, ums)
    output = {}
    ums.all_ggas.each do |gga_name|
      output[gga_name] = {}
      nodesets.each do |set_name, prio_hash|
        output[gga_name][set_name] = compute_prio(gga_name, prio_hash)
      end
    end

    output
  end

  # Given a gga name and a nodeset access hash,
  # Returns a label/level hash for the gga
  def self.compute_prio(name, prio)
    label = %w[p1 p2 p3 p4 besteffort].find do |lbl|
      prio.key?(lbl) && prio[lbl].include?(name)
    end

    { 'label' => label || NA_LABEL, 'level' => PRIOLEVEL.fetch(label, NA_LEVEL) }
  end
end
