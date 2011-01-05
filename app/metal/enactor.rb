# require 'xml'
# 
class Enactor < Sinatra::Base
#   include ConfigurationHelper
#   
#   CREDENTIALS = ['igor', '4bdc0be7f244cfbee53cff556634383eca4a17ce']
#   disable :show_exceptions
#   
#   
#   get '/enactor/locations/:location_id/:resource_type' do |location_id, resource_type|
#     find_location!
#     rtype = type(resource_type)
#     url = uri_to(@location, rtype)
#     http = EM::HttpRequest.new(url).get(:head => {
#       'authorization' => CREDENTIALS,
#       'X-Bonfire-Asserted-Id' => request.env['HTTP_X_BONFIRE_ASSERTED_ID']
#     })
#     xml = XML::Document.string(http.response)
# 
#     output = '<collection xmlns="http://api.bonfire-project.eu/doc/schemas/occi"><items>'
#     xml.find("//#{rtype.upcase}").each do |element|
#       up(element, "/locations/#{location_id}")
#       output << element.to_s
#     end    
#     
#     output << '</items></collection>'
#     status 200
#     output.to_s
#   end
#   
#   post '/enactor/locations/:location_id/:resource_type' do |location_id, resource_type|
#     find_location!
#     rtype = type(resource_type)
#     url = uri_to(@location, rtype)
#     xml = XML::Document.io(request.body)
#     down(xml.root, "")
#     payload = "<#{rtype.upcase}>"
#     xml.root.each_element do |element|
#       payload << element.to_s
#     end
#     payload << "</#{rtype.upcase}>"
#     Rails.logger.debug [:payload_to_testbed, payload]
#     http = EM::HttpRequest.new(url).post(
#       :body => payload.to_s,
#       :head => {
#         'authorization' => CREDENTIALS,
#         'X-Bonfire-Asserted-Id' => request.env['HTTP_X_BONFIRE_ASSERTED_ID']
#       }
#     )
#     Rails.logger.debug [:testbed_response, http]
#     if [200,201,202].include?(http.response_header.status)
#       output = XML::Document.string(http.response)
#       Rails.logger.debug [:response_enactor_xml, output]
#       output.root.name = output.root.name.downcase
#       id = output.root["href"].split("/").last rescue nil
#       up(output.root, "/locations/#{location_id}")
#     
#       status http.response_header.status
#       response.headers['Location'] = "/locations/#{location_id}/#{resource_type}/#{id}"
#       output.to_s
#     else
#       status http.response_header.status
#       http.response
#     end
#   end 
#   
#   get '/enactor/locations/:location_id/:resource_type/:resource_id' do |location_id, resource_type, resource_id|
#     find_location!
#     rtype = type(resource_type)
#     url = uri_to(@location, rtype, resource_id)
#     http = EM::HttpRequest.new(url).get(
#       :head => {
#         'authorization' => CREDENTIALS,
#         'X-Bonfire-Asserted-Id' => request.env['HTTP_X_BONFIRE_ASSERTED_ID']
#       }
#     )
#     if http.response_header.status == 200
#       xml = XML::Document.string(http.response)
#       xml.root["xmlns"] = default_xml_namespace
#       up(xml.root, "/locations/#{location_id}")
#       status 200
#       xml.to_s
#     else
#       status http.response_header.status
#       http.response
#     end
#   end
#   
#   delete '/enactor/locations/:location_id/:resource_type/:resource_id' do |location_id, resource_type, resource_id|
#     find_location!
#     rtype = type(resource_type)
#     url = uri_to(@location, rtype, resource_id)
#     http = EM::HttpRequest.new(url).delete(
#       :head => {
#         'authorization' => CREDENTIALS,
#         'X-Bonfire-Asserted-Id' => request.env['HTTP_X_BONFIRE_ASSERTED_ID']
#       }
#     )
#     Rails.logger.debug [:testbed_status, http.response_header.status]
#     Rails.logger.debug [:testbed_http, http]
#     if [200, 202, 204, 404].include?(http.response_header.status)
#       status 204
#       ""
#     else
#       status http.response_header.status
#       http.response
#     end
#   end
#   
#   protected
#   def uri_to(location, *paths)
#     [location.url,paths.join("/")].join("/")
#   end
#   
#   def type(resource_type)
#     resource_type.gsub(/s$/, '')
#   end
#   
#   def down(element, path)
#     element.name = element.name.upcase
#     element.attributes.each do |attribute|
#       if attribute.name == "href"
#         href = attribute.value.gsub(/.*(compute|network|storage)s\/(.*)$/, '/\1/\2')
#         element["href"] = href
#       end
#     end
#     element.each_element do |e|
#       down(e, path)
#     end
#   end
#   
#   def up(element, path)
#     element.name = element.name.downcase
#     element.attributes.each do |attribute|
#       if attribute.name == "href"
#         href = attribute.value.gsub(/.*(compute|network|storage)\/(.*)$/, path+'/\1s/\2')
#         element["href"] = href
#       end
#     end
#     element.each_element do |e|
#       up(e, path)
#     end
#   end
#   
#   def find_location!
#     @location = Location.find_by_name(params[:location_id])
#     halt 404, "Cannot find location #{params[:location_id].inspect}" if @location.nil?
#   end
end
