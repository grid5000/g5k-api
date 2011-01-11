require 'json'
require 'fileutils'

# The Deployment class represents a deployment 
# that is launched using the Kadeploy3 tool.
class Deployment < ActiveRecord::Base
  
  set_primary_key :job_id
  
  # unrestrict_primary_key
  # plugin :serialization
  # serialize_attributes :json, :nodes, :notifications, :result
  
  SERIALIZED_ATTRIBUTES = [:nodes, :notifications, :result]
  
  validates_presence_of :user_id, :site_id, :environment, :nodes
  
  before_save :json_serialize
  after_save :json_deserialize
  after_find :json_deserialize
  
  before_create do
    self.created_at = Time.now.to_i
  end
  
  before_save do
    self.updated_at = Time.now.to_i
  end
  

  def json_serialize    
    SERIALIZED_ATTRIBUTES.each do |att|
      value = send(att)
      send("#{att}=", value.to_json) unless value.nil?
    end
  end

  def json_deserialize
    SERIALIZED_ATTRIBUTES.each do |att|
      value = send(att)
      send("#{att}=", JSON.parse(value)) unless value.nil?
    end
  end
  
  validate do
    errors.add :nodes, "must be a non-empty list of node FQDN" unless (nodes.kind_of?(Array) && nodes.length > 0)
    errors.add :notifications, "must be a list of notification URIs" unless (notifications.nil? || notifications.kind_of?(Array))
  end
  
  def uid; id; end
  
  # Transforms deployment into command-line arguments
  def to_a
    args = []
    if URI.parse(environment).scheme.nil?
      env_name, env_user = environment.split("@")
      args << "-e" << env_name
      args << "-u" << env_user if env_user
    else
      args << "-a" << environment
    end
    args << "-k" << key if key
    (nodes || []).each do |node|
      args << "-m" << node
    end
    args << "-p" << partition_number.to_s if partition_number
    args << "-b" << block_device if block_device
    args << "-r" << reformat_tmp if reformat_tmp
    args << "--vlan" << vlan.to_s if vlan
    args << "--env-version" << version if version
    args << "--disable-disk-partitioning" if disable_disk_partitioning
    args << "--disable-bootloader-install" if disable_bootloader_install
    args << "--ignore-nodes-deploying" if ignore_nodes_deploying
    args
  end # def to_a
  
  
  def processing?
    status.nil? || status == "processing"
  end
  
  # Launches a connection to the Kadeploy server
  # 
  # Can reuse an existing connection if passed as the first argument.
  # Yields a Kadeploy3::Server object
  def connect!(kserver = nil, &block)
    if kserver.nil?
      Kadeploy3.connect!(Grid5000.configuration["kadeploy"], &block)
    else
      block.call(kserver)
    end
  end
  
  # Launches the deployment
  # 
  # Returns self in case of success (and sets the :uid and :status to "processing")
  # Returns false in case of failure (and cancel the deployment if needed)
  def launch!(kserver = nil)
    connect!(kserver) do |kserver|
      set(:uid => kserver.launch!(self), :status => :processing)
      if save
        self
      else
        kserver.cancel!(self) rescue nil
        false
      end
    end
  end
  
  # Cancels the deployment
  # 
  # Returns self in case of success (and sets the :status to "canceled")
  # Returns false in case of failure
  def cancel!(kserver = nil)
    connect!(kserver) do |kserver|
      update(:status => kserver.cancel!(self))
    end
  end
  
  # Refreshes the deployment by checking its status 
  # against the kadeploy server
  # 
  # Returns self in case of success (and updates the :status, as well as the :output and :result attributes)
  # Returns false in case of failure
  def touch!(kserver = nil)
    if processing?
      connect!(kserver) do |kserver|
        kstatus = kserver.status!(self)
        set(:status => kstatus)
        case kstatus
        when :terminated
          set(:result => kserver.results!(self))
          free!(kserver)
        when :canceled
          set(:output => kserver.errors.join(" "))
        when :error
          set(:output => kserver.errors.join(" "))
          free!(kserver)
        else
          # do nothing
        end
      end  
      save
    else
      self
    end
  end
  
  def free!(kserver = nil)
    connect!(kserver) do |kserver|
      begin 
        kserver.free!(self)
      rescue => e
        Grid5000.logger.warn "Received #{e.class.name}: #{e.message} "+
          "when trying to free the deployment ##{uid}."
      end
    end
  end
  
  # When some attributes such as :key are passed as text strings,
  # we must transform such strings into files 
  # and replace the attribute value by the HTTP URI 
  # where the original content can be accessed.
  # This is required since Kadeploy3 does not allow to directly
  # pass the content string for such attributes.
  def transform_blobs_into_files!(base_uri)
    tmpfiles_dir = Grid5000.configuration["tmpfiles"]
    [:key].each do |attribute|
      value = send(attribute)
      next if value.nil?
      scheme = URI.parse(value).scheme rescue nil
      if scheme.nil?
        filename = [
          user_uid, attribute, Digest::SHA1.hexdigest(value)
        ].join("-")
        # ensure the directory exists...
        FileUtils.mkdir_p(tmpfiles_dir)
        # and write the file to that location
        File.open("#{tmpfiles_dir}/#{filename}", "w") { |f| f.write(value) }
        uri = "#{base_uri}/#{filename}"
        set(attribute => uri)
      end
    end
  end # def transform_blobs_into_files!

  # Export the properties to the JSON format
  def to_json(*args)
    values_to_export = values.reject{|k,v| v.nil?}
    serialized_columns = self.class.serialization_map.keys
    serialized_columns.each do |column|
      value = values_to_export[column]
      unless value.nil? || value.empty?
        values_to_export[column] = JSON.parse(value) 
      end
    end
    values_to_export.to_json(*args)
  end # def to_json

end # class Deployment
