class ApidocsController < ActionController::Base
  include Swagger::Blocks

  swagger_root do
    key :openapi, '3.0.0'
    info do
      key :version, '3.0'
      key :title, "Grid'5000 API"
      key :description,<<-EOL
This is the user and developer documentation for the Grid'5000 API. The API allows
to facilitate interractions and automation with Grid'5000.

Responses are JSON formatted, and two custom media type are used to represent
the API resources:

* to represent an *item*: `application/vnd.grid5000.item+json`
* to represent a *collection* (multiple *items*): `application/vnd.grid5000.item+json`

Tutorial of Grid'5000's API can be found on the [wiki](https://www.grid5000.fr/w/API)
EOL
      contact do
        key :name, 'support-staff@lists.grid5000.fr'
      end
    end
    server do
      key :url, 'https://api.grid5000.fr'
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
      schema do
        key :type, :boolean
      end
    end

    parameter :version do
      key :name, :version
      key :in, :query
      key :description, "Specificy the reference-repository's commit hash to get. " \
        "This allow to get a specific version of the requested resource, to go back "\
        "in time."
      key :required, false
      schema do
        key :type, :string
      end
    end

    parameter :timestamp do
      key :name, :timestamp
      key :in, :query
      key :description, 'Fetch the version of reference-repository for the ' \
        'specified UNIX timestamp.'
      key :required, false
      schema do
        key :type, :integer
      end
    end

    parameter :date do
      key :name, :date
      key :in, :query
      key :description, 'Fetch the version of reference-repository for the ' \
        'specified date (ISO_8601 format).'
      key :required, false
      schema do
        key :type, :string
        key :format, :'date-time'
      end
    end

    parameter :branch do
      key :name, :branch
      key :in, :query
      key :description, "Use a specific branch of reference-repository, for example "\
        "the 'testing' branch contains the resources that are not yet in production."
      key :required, false
      schema do
        key :type, :string
        key :default, 'master'
      end
    end

    parameter :limit do
      key :name, :limit
      key :in, :query
      key :description, 'Limit the number of items to return.'
      key :required, false
      schema do
        key :type, :integer
      end
    end

    parameter :offset do
      key :name, :offset
      key :in, :query
      key :description, 'Paginate through the collection with multiple requests.'
      key :required, false
      schema do
        key :type, :integer
      end
    end

    ['cluster', 'site', 'node', 'server', 'pdu', 'network_equipment'].each do |resource|
      resource_id = (resource + '_id').camelize(:lower)

      parameter resource_id.to_sym do
        key :name, resource_id.to_sym
        key :in, :path
        key :description, "#{resource.titleize}'s ID."
        key :required, true
        schema do
          key :type, :string
        end
      end
    end

    parameter :statusDisks do
      key :name, :disks
      key :in, :query
      key :description, "Enable or disable status of disks in response. "\
        "Should be 'yes' or 'no'."
      key :required, false
      schema do
        key :type, :string
        key :pattern, '^(no|yes)$'
        key :default, 'yes'
      end
    end

    parameter :statusNodes do
      key :name, :nodes
      key :in, :query
      key :description, "Enable or disable status of nodes in response. "\
        "Should be 'yes' or 'no'."
      key :required, false
      schema do
        key :type, :string
        key :pattern, '^(no|yes)$'
        key :default, 'yes'
      end
    end

    parameter :statusVlans do
      key :name, :vlans
      key :in, :query
      key :description, "Enable or disable status of vlans in response. "\
        "Should be 'yes' or 'no'."
      key :required, false
      schema do
        key :type, :string
        key :pattern, '^(no|yes)$'
        key :default, 'yes'
      end
    end

    parameter :statusSubnets do
      key :name, :subnets
      key :in, :query
      key :description, "Enable or disable status of subnets in response. "\
        "Should be 'yes' or 'no'."
      key :required, false
      schema do
        key :type, :string
        key :pattern, '^(no|yes)$'
        key :default, 'yes'
      end
    end

    parameter :statusNetworkAddress do
      key :name, :network_address
      key :in, :query
      key :description, "Get status for specified FQDN's resources only."
      key :required, false
      schema do
        key :type, :string
      end
    end

    parameter :statusWaiting do
      key :name, :waiting
      key :in, :query
      key :description, "Get upcoming jobs on resources in 'reservations' Array "\
        "(in addition to current jobs)."
      key :required, false
      schema do
        key :type, :string
        key :pattern, '^(no|yes)$'
        key :default, 'yes'
      end
    end

    parameter :statusJobDetails do
      key :name, :job_details
      key :in, :query
      key :description, "Get jobs on resources. When disabled, 'reservations' Array " \
        "will not be present."
      key :required, false
      schema do
        key :type, :string
        key :pattern, '^(no|yes)$'
        key :default, 'yes'
      end
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

    schema :BaseStatus do
      property :hard do
        key :type, :string
        key :description, <<-EOL
The hardware state of the resource. Possible values are `dead`, `alive` (running),
`standby` (nodes only, shutdown to reduce power consumption, but available for jobs),
`absent`, or `suspected` (unknown state).'
EOL
        key :example, 'alive'
      end
      property :soft do
        key :type, :string
        key :description, <<-EOL
The system state of the resource. Possible values are `unknown` (when dead or suspected),
`free` (no job currently running on the resource), `busy` (job is running on the
resource), `besteffort` (a besteffort job is running on the resource).
        EOL
        key :example, 'busy'
      end
      property :reservations do
        key :type, :array
        items do
          key :type, :object
        end
        key :description, 'The list of current and upcoming jobs on the resource.'
      end
    end

    schema :NodeStatus do
      allOf do
        schema do
          key :'$ref', :BaseStatus
        end
        schema do
          property :free_slots do
            key :type, :integer
            key :description, 'The number of core available on the node (if the node '\
              'is not entirely reserved).'
            key :example, 0
          end
        end
        schema do
          property :freeable_slots do
            key :type, :integer
            key :description, "The node's cores number used in a besteffort job. "\
              "As they are attached to a besteffort job they can be freed."
            key :example, 0
          end
        end
        schema do
          property :busy_slots do
            key :type, :integer
            key :description, "The node's cores number used in a job."
            key :example, 32
          end
        end
      end
    end

    schema :DiskStatus do
      allOf do
        schema do
          key :'$ref', :BaseStatus
        end
        schema do
          property :diskpath do
            key :type, :string
            key :description, 'The block device path on the OS.'
            key :example, '/dev/disk/by-path/pci-0000:18:00.0-scsi-0:0:3:0'
          end
        end
      end
    end

    schema :VlanStatus do
      allOf do
        schema do
          key :'$ref', :BaseStatus
        end
        schema do
          property :type do
            key :type, :string
            key :description, 'The vlan type, can be `kavlan`, `kavlan-global-remote` '\
              '`kavlan-local`.'
            key :example, 'kavlan-local'
          end
        end
      end
    end

    schema :SubnetStatus do
      allOf do
        schema do
          key :'$ref', :BaseStatus
        end
      end
    end

    schema :ClusterStatus do
      property :uid do
        key :type, :integer
        key :description, 'The timestamp of status.'
        key :example, 1607016106
      end

      property :links do
        key :type, :array
        items do
          key :'$ref', :Links
        end
        key :example, [{
          'rel': 'self',
          'type': 'application/vnd.grid5000.item+json',
          'href': '/3.0/sites/grenoble/clusters/yeti/status'
        },
        {
          'rel': 'parent',
          'type': 'application/vnd.grid5000.item+json',
          'href': '/3.0/sites/grenoble/clusters/yeti'
        }]
      end

      property :nodes do
        key :type, :object
        key :additionalProperties, {
          :'$ref' => '#/components/schemas/NodeStatus',
          :'x-additionalPropertiesName' => 'node_fqdn'
        }
        key :example, { 'yeti-1.grenoble.grid5000.fr': {
                         hard: 'standby',
                         soft: 'free',
                         free_slots: 32,
                         freeable_slots: 0,
                         busy_slots: 0,
                         reservations: [] }
                      }
      end
      property :disks do
        key :type, :object
        key :additionalProperties, {
          :'$ref' => '#/components/schemas/DiskStatus',
          :'x-additionalPropertiesName' => 'disk+node_fqdn'
        }
        key :example, { 'sdd.yeti-1.grenoble.grid5000.fr': {
                         hard: 'alive',
                         soft: 'free',
                         diskpath: '/dev/disk/by-path/pci-0000:18:00.0-scsi-0:0:3:0',
                         reservations: [] }
                      }
      end
    end

    schema :SiteStatus do
      allOf do
        schema do
          key :'$ref', :ClusterStatus
        end
        schema do
          property :links do
            key :type, :array
            items do
              key :'$ref', :Links
            end
            key :example, [{
              'rel': 'self',
              'type': 'application/vnd.grid5000.item+json',
              'href': '/3.0/sites/grenoble/status'
            },
            {
              'rel': 'parent',
              'type': 'application/vnd.grid5000.item+json',
              'href': '/3.0/sites/grenoble'
            }]
          end
        end
        schema do
          property :vlans do
            key :type, :object
            key :additionalProperties, {
              :'$ref' => '#/components/schemas/VlanStatus',
              :'x-additionalPropertiesName' => 'vlan_id'
            }
            key :example, { 1 => {
              hard: 'alive',
              soft: 'free',
              type: 'kavlan-local',
              reservations: [] }
            }
          end
        end
        schema do
          property :subnets do
            key :type, :object
            key :additionalProperties, {
              :'$ref' => '#/components/schemas/SubnetStatus',
              :'x-additionalPropertiesName' => 'subnet'
            }
            key :example, { '10.134.92.0/22': {
              hard: 'alive',
              soft: 'free',
              reservations: [] }
            }
          end
        end
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
    EnvironmentsController,
    Grid5000::Deployment,
    Grid5000::Job,
    Grid5000::Kavlan,
    Grid5000::Environments,
    self
  ].freeze

  def index
    render json: Swagger::Blocks.build_root_json(SWAGGERED_CLASSES)
  end
end
