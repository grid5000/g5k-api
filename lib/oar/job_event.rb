module OAR
  class JobEvent < Base
    set_table_name "event_logs"
    set_primary_key :event_id
    
    # disable inheritance guessed by Rails because of the "type" column.
    set_inheritance_column :_type_disabled
    
    def as_json(*args)
      {
        :uid => event_id, 
        :created_at => date, 
        :type => type, 
        :description => description
      }
    end
  end
end