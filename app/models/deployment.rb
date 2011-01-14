require 'json'
require 'fileutils'

# The Deployment class represents a deployment 
# that is launched using the Kadeploy3 tool.
class Deployment < ActiveRecord::Base
  
  set_primary_key :uid
  
  attr_accessor :links
  
  SERIALIZED_ATTRIBUTES = [:nodes, :notifications, :result]
  
  validates_presence_of :user_uid, :site_uid, :environment, :nodes
  validates_uniqueness_of :uid
  
  before_save :json_serialize
  after_save :json_deserialize
  after_find :json_deserialize
  
  
  before_create do
    self.created_at ||= Time.now.to_i
  end
  
  before_save do
    self.updated_at = Time.now.to_i
    errors.add(:uid, "must be set") if uid.nil?
    errors.empty?
  end
  
  
  # Experiment states
  state_machine :status, :initial => :processing do
    
    after_transition :processing => :canceled, :do => :deliver_notification
    after_transition :processing => :error, :do => :deliver_notification
    after_transition :processing => :terminated, :do => :deliver_notification

    event :process do
      transition :processing => :processing
    end
    event :cancel do
      transition :processing => :canceled
    end
    event :terminate do
      transition :processing => :terminated
    end
    event :fail do
      transition :processing => :error
    end
  end
  
  def active?
    status?(:processing)
  end
  
  validate do
    errors.add :nodes, "must be a non-empty list of node FQDN" unless (nodes.kind_of?(Array) && nodes.length > 0)
    errors.add :notifications, "must be a list of notification URIs" unless (notifications.nil? || notifications.kind_of?(Array))
  end
  
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
    args << "--env-version" << version.to_s if version
    args << "--disable-disk-partitioning" if disable_disk_partitioning
    args << "--disable-bootloader-install" if disable_bootloader_install
    args << "--ignore-nodes-deploying" if ignore_nodes_deploying
    args
  end # def to_a
  
  
  def processing?
    status.nil? || status == "processing"
  end
  
  
  def deliver_notification
    unless notifications.nil?
      Notification.new(
        self.as_json, 
        :to => notifications
      ).deliver!
    end
  end
  
  # Refreshes the deployment by checking its status 
  # against the kadeploy server
  # 
  # Returns self in case of success (and updates the :status, as well as the :output and :result attributes)
  # Returns false in case of failure
  # def touch!(kserver = nil)
  #   if processing?
  #     connect!(kserver) do |kserver|
  #       kstatus = kserver.status!(self)
  #       set(:status => kstatus)
  #       case kstatus
  #       when :terminated
  #         set(:result => kserver.results!(self))
  #         free!(kserver)
  #       when :canceled
  #         set(:output => kserver.errors.join(" "))
  #       when :error
  #         set(:output => kserver.errors.join(" "))
  #         free!(kserver)
  #       else
  #         # do nothing
  #       end
  #     end  
  #     save
  #   else
  #     self
  #   end
  # end
  
  # When some attributes such as :key are passed as text strings,
  # we must transform such strings into files 
  # and replace the attribute value by the HTTP URI 
  # where the original content can be accessed.
  # This is required since Kadeploy3 does not allow to directly
  # pass the content string for such attributes.
  def transform_blobs_into_files!(storage_path, base_uri)
    tmpfiles_dir = File.expand_path(storage_path)
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
        send("#{attribute}=".to_sym, uri)
      end
    end
  end # def transform_blobs_into_files!
  
  def as_json(*args)
    attributes.merge(:links => links).reject{|k,v| v.nil?}
  end

  
  def json_serialize    
    SERIALIZED_ATTRIBUTES.each do |att|
      value = send(att)
      send("#{att}=".to_sym, value.to_json) unless value.blank?
    end
  end
  
  def json_deserialize
    SERIALIZED_ATTRIBUTES.each do |att|
      value = send(att) rescue nil
      send("#{att}=".to_sym, (JSON.parse(value) rescue value)) unless value.blank?
    end
  end
  
end # class Deployment
