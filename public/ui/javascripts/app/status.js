var http = new Http();

var tree = {}
var domain = []

$(document).ready(function() {

  /**
   * React to a new grid event
   */
  $(document).bind("grid", function(event, grid) {
    
    http.get(http.linkTo(grid.links, "sites"), {
      ok: function(data) { 
        _.each(data.items, function(site) {
          $(document).trigger("grid:site", [grid, site])
        })
      }
    }); // GET /sites
  })

  /**
   * React to a new site event
   */
  $(document).bind("grid:site", function(event, grid, site) {
    domain.push(site.uid)
    
    tree[site.uid] = {}
    
    http.get(http.linkTo(site.links, "status"), {
      ok: function(data) {
        $(document).trigger("grid:site:status", [grid, site, data])
      }
    });
  });
  
  $(document).bind("grid:site:status", function(event, grid, site, status) {
    var stats = { soft: {},  hard: {} }
    var split
    _.each(status.items, function(nodeStatus) {
      split = nodeStatus.node_uid.split("-")
      if (!tree[site.uid][split[0]]) {
        tree[site.uid][split[0]] = {}
      }
      tree[site.uid][split[0]][nodeStatus.node_uid] = nodeStatus.system_state
    });
  })
  
  $(document).ajaxStop(function() {
    
    $("#main").removeClass("loading")
    
    var vis = new pv.Panel()
        .canvas("sunburst")
        .width(800)
        .height(800)
        .bottom(0);

    var partition = vis.add(pv.Layout.Partition.Fill)
        .nodes(pv.dom(tree).root("grid5000").sort(function(node1, node2) {
          if (node1.nodeValue && node2.nodeValue) {
            var i1 = parseInt(node1.nodeName.split("-")[1])
            var i2 = parseInt(node2.nodeName.split("-")[1])
            if (i1 == i2) {
              return 0
            } else if (i1 < i2) {
              return -1;
            } else {
              return 1;
            }  
          }
        }).nodes())
        // .size(function(d) d.nodeValue)
        .order("descending")
        .orient("radial");

        
    partition.node.add(pv.Wedge)
        .fillStyle(function(d) {
          if (d.nodeValue) {
            switch (d.nodeValue) {
              case "unknown": return "red";
              case "free": return "green";
              case "besteffort": return "orange";
              default: return "#aaa";
            }
          } else {
            if (!d.parentNode) {
              // root
            } else if (d.parentNode && !d.parentNode.parentNode) {
              // site
              d.color = (pv.Colors.category19(domain))(d.nodeName)
              d.color.opacity = 0.7
              return d.color
            } else {
              // cluster
              d.color = d.parentNode.color.brighter(0.5)
              d.color.opacity = 0.7
              return d.color
            }
          }

        })
        .event("mouseover", function(d) {
          if (d.nodeValue) {
            $(document).trigger("tooltip:show", d.nodeName+" - "+d.nodeValue)
          }
        })
        .event("mouseout", function(d) {
          $(document).trigger("tooltip:hide")
        })
        .strokeStyle("#fff")
        .lineWidth(0.2);

    partition.label.add(pv.Label)
        .visible(function(d) {
          return d.angle * d.outerRadius >= 6
        });

    vis.render()


    /* Update the layout's size method and re-render. */
    // function update(method) {
    //   switch (method) {
    //     case "byte": partition.size(function(d) d.nodeValue); break;
    //     case "file": partition.size(function(d) d.firstChild ? 0 : 1); break;
    //   }
    //   vis.render();
    // }
  })
  
  $(document).bind("tooltip:show", function(event, message) {
    $("#sidebar").html(message)
  })
  $(document).bind("tooltip:hide", function(event) {
    $("#sidebar").html("&nbsp;")
  })

  /**
   * Main trigger
   */
  http.get("../../", {
    before: function() {
      $("#main").addClass("loading")
    },
    ok: function(data) {
      $(document).trigger("grid", data)
    }
  });
});
