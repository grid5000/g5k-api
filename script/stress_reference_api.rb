#!/usr/bin/env ruby

# (c) 2017 Inria by David Margery (david.margery@inria.fr) for the Grid'5000 project

require "eventmachine"
require 'em-http-request'
require 'json'
require 'pp'

base_url="http://127.0.0.1:8000"
entry_point="/sites"
base_url="https://api.grid5000.fr"
entry_point="/stable/sites"

def fetch_link(description, relation)
  found=description["links"].find{|l| l["rel"]==relation}
  if found
    return found["href"]
  end
end

EventMachine.run do 
  get_params={
    :query   => {'branch' => 'master'},
    :timeout => 20,
    :head    => {'Accept' => "application/json", 'Authorization' => ['dmargery','xxxx']}
    
  }
  http = EM::HttpRequest.new("#{base_url}#{entry_point}").get(get_params)
  http.errback { puts "Request failed #{ http.response_header.status}"; EM.stop }
  http.callback {
    puts "Request for list of sites succeeded with code #{http.response_header.status}"
    sites= JSON.parse(http.response)
    expected_sites=sites['items'].size
    expected_sites_net=sites['items'].size
    expected_sites_pdu=sites['items'].size
    expected_clusters={}
    sites['items'].each do |site|
      clusters_url=fetch_link(site,"clusters")
      http_cluster= EM::HttpRequest.new("#{base_url}#{clusters_url}").get(get_params)
      http_cluster.errback { puts "Request to clusters of site #{site["name"]} at #{base_url}/#{clusters_url} failed #{ http_cluster.response_header.status}"; EM.stop }
      http_cluster.callback {
        expected_sites=expected_sites-1
        puts "Request to clusters of site #{site["name"]} (#{base_url}/#{clusters_url}) returned #{http_cluster.response_header.status}. #{expected_sites} sites still expected"
        clusters=JSON.parse(http_cluster.response)
        expected_clusters[site["name"]]=clusters["items"].size
        clusters["items"].each do |cluster|
          nodes_url=fetch_link(cluster,"nodes")
          http_node=EM::HttpRequest.new("#{base_url}/#{nodes_url}").get(get_params)
          http_node.errback { puts "Request to nodes of cluster #{cluster["uid"]} at #{base_url}/#{nodes_url} failed #{ http_node.response_header.status}"; EM.stop }
          http_node.callback {
            expected_clusters[site["name"]]=expected_clusters[site["name"]]-1
            puts "Request to cluster #{cluster["uid"]} returned #{http_node.response_header.status}. #{expected_clusters[site["name"]]} clusters still expected for #{site["name"]}"
            if expected_sites==0 && expected_sites_net==0 && expected_sites_pdu==0 && expected_clusters.all? {|k,v| v == 0}
              EventMachine.stop 
            end
          }
        end
      }
      nets_url=fetch_link(site,"network_equipments")
      http_net=EM::HttpRequest.new("#{base_url}/#{nets_url}").get(get_params)
      http_net.errback { puts "Request to network_equipments of site #{site["name"]} at #{base_url}/#{nets_url} failed #{ http_net.response_header.status}"; EM.stop }
      http_net.callback {
        expected_sites_net=expected_sites_net-1
         puts "Request to network_equipments of site #{site["name"]} returned #{http_net.response_header.status}. #{expected_sites_net} sites still expected"
      }
      pdus_url=fetch_link(site,"pdus")
      http_pdu=EM::HttpRequest.new("#{base_url}/#{pdus_url}").get(get_params)
      http_pdu.errback { puts "Request to pdus of site #{site["name"]} at #{base_url}/#{pdus_url} failed #{ http_pdu.response_header.status}"; EM.stop }
      http_pdu.callback {
        expected_sites_pdu=expected_sites_pdu-1
         puts "Request to pdus of site #{site["name"]} returned #{http_pdu.response_header.status}. #{expected_sites_pdu} sites still expected"
      }
    end
  }
end
puts "Finished"

