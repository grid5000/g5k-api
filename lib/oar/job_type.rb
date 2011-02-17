module OAR
  class JobType < Base
    set_table_name "job_types"
    set_primary_key :job_type_id
    
    # disable inheritance guessed by Rails because of the "type" column.
    set_inheritance_column :_type_disabled
    
    def name
      type
    end
  end
end