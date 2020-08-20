var http = new Http();

var now = new Date().getTime()

var optionalize = function(search) {
  var queryString = search.replace(/^.*\?/, '')
  if ($("#link-to-self").length > 0) {
    $("#link-to-self").val(window.location.href.replace(/\?.*$/, "?"+queryString))
  }
  var queryParameters = queryString.split(/&/)
  var splittedQueryParameter;
  var options      = {}
  $.each(queryParameters, function(i, queryParameter) {
    splittedQueryParameter = queryParameter.split("=")
    if (splittedQueryParameter[0] == "startDate" && splittedQueryParameter[1] == "now") {
      splittedQueryParameter[1] = now-(2*3600*1000)
    }
    options[splittedQueryParameter[0]] = splittedQueryParameter[1]
  })
  return options;
}


$(document).ready(function() {
  var gantt;
  var loaded_sites = 0
  var total_sites = 0
  var resources_by_site = {}
  var jobs = []
  $("#facets li.facet a, #actions li a").live('click', function(event) {
    var target       = $(event.target);    
    if (gantt) {
      gantt.display(optionalize(target.attr('href')))
    }  
    return false;
  })
  $.ajax({
    url: "../../sites",
    dataType: "json", type: "GET", cache: true, global: true,
    beforeSend: function() {
      $("#main").addClass("loading")
    },
    success: function(data) {
      total_sites = data.total
      $.each(data.items, function(i, site) {
        resources_by_site[site.uid] = {}
        
        var status_link = http.linkTo(site.links, 'status')
        $.ajax({
          url: status_link+"?reservations_limit=100",
          dataType: "json", type: "GET", global: true,
          success: function(data) {
            $.each(data.nodes, function(node_uid, item) {
              var short_node_uid = node_uid.split(".")[0]
              var cluster = short_node_uid.split("-")[0]
              var index = short_node_uid.split("-")[1]
              if (!resources_by_site[site.uid][cluster]) {
                resources_by_site[site.uid][cluster] = []
              }
              resources_by_site[site.uid][cluster].push({
                id: node_uid,
                index: parseInt(index),
                enabled: (item.hard == "alive")
              })
              $.each(item.reservations, function(i, resa) {
                if (resa.started_at) {
                  resa.from = resa.started_at*1000
                  if (resa.queue == "besteffort" && resa.from < now) {
                    resa.to = now
                  } else {
                    resa.to = (resa.started_at+resa.walltime)*1000
                  }
                  resa.resource = node_uid
                  resa.tooltip = {
                    title: site.uid + " / " + resa.user + " / " +resa.uid,
                    content: [
                      "From  : " + new Date(resa.from).toLocaleString(), 
                      "To    : " + new Date((resa.started_at+resa.walltime)*1000).toLocaleString(),
                      "State : " + resa.state,
                      "Queue : " + resa.queue
                    ]
                  }
                  jobs.push(resa)
                }
              })
            })
          },
          complete: function() { 
            loaded_sites+=1
            if (loaded_sites == total_sites) {
              $("#main").removeClass("loading")
              if (jobs.length > 0) {
                jobs = jobs.sort(function(a, b) { 
                  if (a.from > b.from) {
                    return 1;
                  } else if (a.from < b.from) {
                    return -1;
                  } else {
                    return 0;
                  }
                })
                // display gantt
                var offset = 0
                var resources = []
                var hasAtLeastOneResource = false;
                $.each(resources_by_site, function(site_uid,resources_by_cluster) {
                  $("ul#siteFacet").append('<li class="facet siteFacet"><a href="?resourcesOffset='+offset+'">'+site_uid+'</a><ul id="clusterFacet"></ul></li>')
                  $.each(resources_by_cluster, function(cluster_uid, cluster_resources) {
                    $("ul#siteFacet li.siteFacet:last ul").append('<li class="facet clusterFacet"><a href="?resourcesOffset='+offset+'">'+cluster_uid+'</a></li>')
                    $.each(cluster_resources.sort(function(a,b) {return a.index - b.index;}), function(i, cluster_resource) {
                      resources[offset++] = cluster_resource
                    })
                  })
                })
                var resolution = 3600*1000
                gantt = new Gantt({
                  container: "gantt",
                  resolution: resolution,
                  barSpace: 0.2,
                  barWidth: 20,
                  tooltipHeight: 100,
                  now: now,
                  bands: [
                    {relativeHeight: 2/5, relativeResolution: 24, backgroundColor: "rgb(17,17,17)", color: "rgb(255,255,255)"},
                    {relativeHeight: 3/5, relativeResolution: 1, backgroundColor: "rgb(51,51,51)", color: "rgb(255,255,255)"}
                  ],
                  resourceId: "resource",
                  jobId: "uid",
                  resources: resources,
                  jobs: jobs
                })
                gantt.display(optionalize(window.location.search))
              } else {
                alert('No jobs found')
              }

            }
          }
        }) // ajax
      }) // each
    } // success
  }) // ajax

  $("#customize-form").submit(function(event) {
    if (gantt) {
      gantt.display(optionalize($("#link-to-self").val()))
    }
    return false;
  })
  
})
