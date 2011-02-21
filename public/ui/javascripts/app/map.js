var http = new Http();

function jsonConverter( site ) {
  output = {  properties:{'nodes_count': { valueType: "number"} }, 
              types:{'site': {pluralLabel: 'sites'}}, 
              items:[]
            }
  site['label'] = site['uid']
  site['id'] = site['label']
  site['latlng'] = ''+site['latitude']+','+site['longitude']+'';
  output['items'].push(site);
  return output;
}

var sites_already_loaded = 0;
var sites = [];
var clusters_already_loaded = 0;
var clusters = [];
$(document).ready(function() {
  // Widget.display({id: 'grid-status', refresh: 300000, container: '#widget-grid-status', api_base_uri: Grid5000.api_base_uri});
  
  window.database = Exhibit.Database.create();
  window.exhibit = Exhibit.create();
  window.exhibit.configureFromDOM();
  Exhibit.UI.showBusyIndicator();
  
  $.ajax({
    url: "../../sites",
    dataType: "json", type: "GET", cache: true, ifModified: true,
    error: function(XMLHttpRequest, textStatus, errorThrown) {
      $.jGrowl("Error when trying to get the description of Grid5000.");
    },
    success: function(sites_collection, textStatus) {
      $.each(sites_collection.items, function(i, site) {
        sites.push(site)
        var site_clusters_href = http.linkTo(site.links, 'clusters');
        $.ajax({
          url: site_clusters_href+"?version="+site.version,
          dataType: "json", type: "GET", cache: true, global: false, ifModified: true,
          site_index: i,
          success: function(clusters_collection, status) {
            var site_index = this.site_index;
            $.each(clusters_collection.items, function(i, cluster) {
              clusters.push(cluster.uid)
              
              var cluster_nodes_href = http.linkTo(cluster.links, 'nodes');
              $.ajax({
                url: cluster_nodes_href+"?version="+cluster.version,
                dataType: "json", type: "GET", cache: true, global: false, ifModified: true,
                site_index: site_index,
                success: function(nodes_collection, status) {
                  var site_index = this.site_index;
                  $.each(nodes_collection.items, function(i, node) {
                    sites[site_index]['nodes_count'] = (sites[site_index].nodes_count || 0) + 1;
                    sites[site_index]['cores_count'] = (sites[site_index].cores_count || 0) + node.architecture.smt_size;
                  }); // each node
                }, // success
                error: function(XMLHttpRequest, textStatus, errorThrown) {
                  $.jGrowl("Error when trying to get the list of the nodes of "+sites[this.site_index].uid+".");
                },
                complete: function(xOptions, textStatus) {
                  clusters_already_loaded += 1;
                  // bug in jquery: complete function is called twice when using thr jsonp type, thus incrementing twice the counters
                  if (sites_already_loaded == sites.length && clusters_already_loaded == clusters.length) { 
                    $.each(sites, function(i, site) {
                      window.database.loadData(jsonConverter(site));
                    })
                    Exhibit.UI.hideBusyIndicator(); 
                  }
                }
              }); // ajax nodes
            }); // each cluster
          }, // success
          error: function(XMLHttpRequest, textStatus, errorThrown) {
            $.jGrowl("Error when trying to get the list of the clusters of "+sites[this.site_index].uid+".");
          },
          complete: function(xOptions, textStatus) {
            sites_already_loaded += 1;
          }
        }) // ajax clusters
      })
    }
  });
});