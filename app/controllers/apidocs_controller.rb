class ApidocsController < ActionController::Base
  include Swagger::Blocks

  swagger_root do
    key :openapi, '3.0.0'
    info do
      key :version, '3.0'
      key :title, "Grid'5000 API"
      key :description, "This is the user and developer documentation for the Grid'5000 "\
        "API. The API allows to facilitate interractions and automation with Grid'5000."
      contact do
        key :name, 'support-staff@lists.grid5000.fr'
      end
    end
    server do
      key :url, 'https://api.grid5000.fr/'
    end

    security do
      key :BasicAuth, []
    end

    tag do
      key :name, 'reference-api'
      key :description, "Reference-api expose Grid'5000's reference-repository, "\
        "the single source of truth about sites, clusters, nodes, and network topology."
    end

    tag do
      key :name, 'version'
      key :description, 'The version API allows to consult reference-repository history.'
    end

    tag do
      key :name, 'status'
      key :description, "Status API allows to known the state of OAR's resources "\
        "(like nodes, disks, vlans, subnets). The current and upcoming "\
        "reservations are also returned by this API."
    end

    tag do
      key :name, 'job'
      key :description, "The job API is used to submit a job on Grid'5000 "\
        "or to manage an existing one. This API use OAR, more informations "\
        "about job management on Grid'5000 can be found on [the wiki]"\
        "(https://www.grid5000.fr/w/Advanced_OAR)"
    end

    tag do
      key :name, 'deployment'
      key :description, 'The deployment API is use if you want to deploy a specific '\
        'environment image on the nodes you have reserved. It uses the Kadeploy tool.'
    end

    tag do
      key :name, 'vlan'
      key :description, "The vlan API allows to get informations about vlans and to "\
        "manipulate them. For example, it is possible to put deployed nodes in "\
        "reserved vlans, to fetch current vlans and nodes status or to start or "\
        "stop dhcp servers.\nThe associated documentation about Kavlan can be found "\
        "on [Grid'5000's wiki](https://www.grid5000.fr/w/KaVLAN)"
    end
  end

  swagger_component do
    parameter :deep do
      key :name, :deep
      key :in, :query
      key :description, 'Fetch a full view of reference-repository, under this path.'
      key :required, false
      key :type, :boolean
    end

    parameter :version do
      key :name, :version
      key :in, :query
      key :description, "Specificy the reference-repository's commit hash to get. " \
        "This allow to get a specific version of the requested resource, to go back "\
        "in time."
      key :required, false
      key :type, :string
    end

    parameter :timestamp do
      key :name, :timestamp
      key :in, :query
      key :description, 'Fetch the version of reference-repository for the ' \
        'specified UNIX timestamp.'
      key :required, false
      key :type, :integer
    end

    parameter :date do
      key :name, :date
      key :in, :query
      key :description, 'Fetch the version of reference-repository for the ' \
        'specified date (ISO_8601 format).'
      key :required, false
      key :type, :string
      key :format, :'date-time'
    end

    parameter :branch do
      key :name, :branch
      key :in, :query
      key :description, "Use a specific branch of reference-repository, for example "\
        "the 'testing' branch contains the resources that are not yet in production."
      key :required, false
      key :type, :string
      key :default, 'master'
    end

    parameter :limit do
      key :name, :limit
      key :in, :query
      key :description, 'Limit the number of items to return.'
      key :required, false
      key :type, :integer
    end

    parameter :offset do
      key :name, :offset
      key :in, :query
      key :description, 'Paginate through the collection with multiple requests.'
      key :required, false
      key :type, :integer
    end

    parameter :clusterId do
      key :name, :clusterId
      key :in, :path
      key :description, 'ID of cluster to fetch.'
      key :required, true
      key :type, :string
    end

    parameter :siteId do
      key :name, :siteId
      key :in, :path
      key :description, 'ID of site to fetch.'
      key :required, true
      key :type, :string
    end

    parameter :nodeId do
      key :name, :nodeId
      key :in, :path
      key :description, 'ID of node to fetch.'
      key :required, true
      key :type, :string
    end

    parameter :pduId do
      key :name, :pduId
      key :in, :path
      key :description, 'ID of pdu to fetch.'
      key :required, true
      key :type, :string
    end

    parameter :serverId do
      key :name, :serverId
      key :in, :path
      key :description, 'ID of server to fetch.'
      key :required, true
      key :type, :string
    end

    parameter :networkEquipmentId do
      key :name, :networkEquipmentId
      key :in, :path
      key :description, 'ID of network equipment to fetch.'
      key :required, true
      key :type, :string
    end

    parameter :statusDisks do
      key :name, :disks
      key :in, :query
      key :description, "Enable or disable status of disks in response. "\
        "Should be 'yes' or 'no'."
      key :required, false
      key :type, :string
      key :pattern, '^(no|yes)$'
      key :default, 'yes'
    end

    parameter :statusNodes do
      key :name, :nodes
      key :in, :query
      key :description, "Enable or disable status of nodes in response. "\
        "Should be 'yes' or 'no'."
      key :required, false
      key :type, :string
      key :pattern, '^(no|yes)$'
      key :default, 'yes'
    end

    parameter :statusVlans do
      key :name, :vlans
      key :in, :query
      key :description, "Enable or disable status of vlans in response. "\
        "Should be 'yes' or 'no'."
      key :required, false
      key :type, :string
      key :pattern, '^(no|yes)$'
      key :default, 'yes'
    end

    parameter :statusSubnets do
      key :name, :subnets
      key :in, :query
      key :description, "Enable or disable status of subnets in response. "\
        "Should be 'yes' or 'no'."
      key :required, false
      key :type, :string
      key :pattern, '^(no|yes)$'
      key :default, 'yes'
    end

    schema :BaseApiCollection do
      key :required, [:total, :offset]

      property :total do
        key :type, :integer
        key :description, 'The number of items in collection.'
      end
      property :offset do
        key :type, :integer
        key :description, 'The offset (for pagination).'
      end
    end

    schema :Links do
      key :required, [:rel, :href, :type]
      property :rel do
        key :type, :string
        key :description, "The relationship's name."
        key :example, 'parent'
      end
      property :href do
        key :type, :string
        key :description, "The link to the resource."
        key :example, '/3.0/sites/grenoble'
      end
      property :type do
        key :type, :string
        key :description, "The resource's type, can be an item or an item collection."
        key :example, 'application/vnd.grid5000.item+json'
      end
    end

    security_scheme :BasicAuth do
      key :type, :http
      key :scheme, :basic
    end
  end

  # A list of all classes that have swagger_* declarations.
  SWAGGERED_CLASSES = [
    SitesController,
    ClustersController,
    ResourcesController,
    VersionsController,
    DeploymentsController,
    JobsController,
    VlansController,
    VlansUsersController,
    VlansUsersAllController,
    VlansNodesController,
    VlansNodesAllController,
    Grid5000::Deployment,
    Grid5000::Job,
    Grid5000::Kavlan,
    self
  ].freeze

  def index
    render json: Swagger::Blocks.build_root_json(SWAGGERED_CLASSES)
  end
end
