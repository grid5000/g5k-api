# http://apidock.com/rails/ActiveRecord/Serialization/to_json
ActiveRecord::Base.include_root_in_json = false

Api::Application.config.middleware.use RackDebugger, Rails.logger