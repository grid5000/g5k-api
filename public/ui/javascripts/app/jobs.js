var jobRowTemplate = '\
  <tr id="{{uuid}}" class="job-row">\
    <td class="center"><input type="checkbox" name="jobs[]" value="{{uuid}}" /></td>\
    <td class="right">{{uid}}</td>\
    <td>{{site}}</td>\
    <td>{{user}}</td>\
    <td>{{state}}</td>\
    <td>{{queue}}</td>\
  </tr>\
';
// 
// <td>{{types}}</td>\
// <td class="right">{{nodes_count}}</td>\
// <td class="right">{{from}}</td>\
// <td class="right">{{to}}</td>\
// <td class="right">{{walltime}}</td>\

var jobTemplate = '\
  <div class="job-details">\
    <h2>{{uuid}}</h2>\
    <table>\
      <tr><th>User</th><td>{{user}}</td></tr>\
      <tr><th>State</th><td>{{state}}</td></tr>\
      <tr><th>Queue</th><td>{{queue}}</td></tr>\
      <tr><th>Types</th><td>{{types}}</td></tr>\
      <tr><th>From</th><td>{{from}}</td></tr>\
      <tr><th>To</th><td>{{to}}</td></tr>\
      <tr><th>Walltime</th><td>{{walltime}}</td></tr>\
      <tr class="nodes">\
        <th>Nodes</th>\
        <td>\
          <ul>\
            {{#nodes}}\
              <li>{{.}}</li>\
            {{/nodes}}\
          </ul>\
        </td>\
      </tr>\
      <tr class="events">\
        <th>Events</th>\
        <td>\
          <ul>\
            {{#events}}\
              <li>{{created_at}} - {{description}}</li>\
            {{/events}}\
          </ul>\
        </td>\
      </tr>\
    </table>\
  </div>\
';

var http = new Http();

var View = {
  defaults: {
    refresh: 10*60*1000
  },
  config: {},
  setup: function(options) {
    $.extend(this.config, this.defaults, (options || {}))
  },
  grab: function(elementId) {
    return jQuery("#"+elementId.replace(/:/g, "\\:").replace(/\./g, "\\."))
  },
  exists: function(elementId) {
    return this.grab(elementId).length != 0
  },
  selectedJobs: function(callback) {
    var jobs = $.map($("#jobs table tbody tr input:checked"), function(e,i) {
      return $(e).val()
    })
    if (jobs.length > 0) {
      if (callback) {
        return callback(jobs)
      }
    } else {
      alert("You must select at least one job.")
    }  
    return jobs
  }
}



$(document).ready(function() {
  $("#sidebar ul.actions a, #content ul.actions a").button();

  // enable or disable automatic refresh
  $("#action-toggle-refresh").bind("click", function(event) {
    if (View.config.refresh) {
      View.config.refresh = false
      $(event.target).html("start automatic refreshing");
    } else {
      View.config.refresh = View.defaults.refresh
      $(event.target).html("stop automatic refreshing");
    }
  });
  
  $("#action-refresh").bind("click", function(event) {
    $(document).trigger("view:refresh")
  });

  $("#jobs a[rel=deselect]").click(function(event) {
    $.each($("#jobs table tbody tr input:checkbox"), function(i, element) {
      element.checked = false
    });
    return false;
  })

  $("#jobs ul.actions li a[rel=details]").click(function(event) {
    var done = 0
    var html = []
    View.selectedJobs(function(jobs) {
      $.facebox(function() { 
        _.each(jobs, function(jobUuid) {
          var job = View.grab(jobUuid).data("job")
          http.get(http.linkTo(job.links, "self"), {
            ok: function(data) {
              $.extend(job, data)
              job.from = (job.started_at && job.started_at > 0) ? new Date(job.started_at * 1000) : null
              job.to = (job.from && job.walltime) ? new Date((job.started_at + job.walltime)*1000) : null
              html.push(
                Mustache.to_html(jobTemplate, {
                  uuid: job.uuid,
                  user: job.user,
                  state: job.state,
                  queue: job.queue,
                  nodes: job.assigned_nodes,
                  types: (job.types || []).sort().join(", "),
                  from: job.from ? job.from.toISOString() : "",
                  to: job.to ? job.to.toISOString() : "",
                  walltime: (job.walltime || ""),
                  events: job.events
                })
              )
            },
            after: function() {
              done++;
              if (done == jobs.length) {
                $.facebox(html.join(""))
              }
            }
          }); // GET /job

        });
      })
    });

    return false;
  });



  $("#jobs ul.actions li a[rel=metrics]").click(function(event) {
    return View.selectedJobs(function(jobs) {
      var link = $(event.currentTarget)
      var query = _.map(jobs, function(value) {
        // remove gridId
        return value.replace(/^\w+:/, '')
      }).join(",")
      link.attr('href', "./metrics.html?jobs="+query)
      link.attr('target', "_blank")
      return true;
    });
  });
  
  
  
  
  $("#jobs ul.actions li a[rel=kill]").click(function(event) {
    View.selectedJobs(function(jobs) {
      if (confirm("Are you sure you want to delete these "+jobs.length+" jobs ?")) {
        _.each(jobs, function(jobUuid) {
          var job = View.grab(jobUuid).data("job")
          http.del(http.linkTo(job.links, "self"), {
            before: function() {
              $("h1").addClass("loading")
            },
            ok: function(data) {
              View.grab(jobUuid).fadeOut(function() {
                $(this).remove()
                // $.jGrowl("Job #"+jobUuid+" successfully deleted")
                $(document).trigger("view:update")
              })
            }
          });
        });
      }
    });
    return true;
  });
  
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

    http.get(http.linkTo(site.links, "jobs"), {
      ok: function(data) {
        // var count = data.items.length
        // var done = 0;
        _.each(data.items, function(job, i) {
          $(document).trigger("grid:site:job", [grid, site, job])
          // http.get(http.linkTo(job.links, "self"), {
          //   ok: function(data) {
          //     $(document).trigger("grid:site:job", [grid, site, data])
          //   },
          //   ko: function(xhr, status, error) {
          //     $.jGrowl("["+status+"] Cannot load the job #"+job.uid+" located in "+site.uid+".", {theme: "error"})
          //   }, 
          //   after: function() {
          //     done++;
          //     if (done == count) {
          //       $(document).trigger("facets:draw")
          //     }
          //   }
          // }); // GET /job
        });
        $(document).trigger("view:update")
      }
    }); // GET /jobs
    
  });
  
  
  /**
   * Refreshes or appends a job to the table
   */
  $(document).bind("grid:site:job", function(event, grid, site, job) {
    job.uuid = [grid.uid, site.uid, job.uid].join(":")
    // job.from = (job.started_at && job.started_at > 0) ? new Date(job.started_at * 1000) : null
    // job.to = (job.from && job.walltime) ? new Date((job.started_at + job.walltime)*1000) : null
    job.site = site.uid
    job.grid = grid.uid
    
    var row = Mustache.to_html(jobRowTemplate, {
      uuid: job.uuid,
      uid: job.uid,
      site: site.uid,
      user: job.user,
      state: job.state,
      queue: job.queue,
      // nodes_count: job.assigned_nodes.length,
      // types: (job.types || []).sort().join(", "),
      // from: job.from ? job.from.toISOString() : "",
      // to: job.to ? job.to.toISOString() : "",
      // walltime: (job.walltime || "")
    })
    if (View.exists(job.uuid)) {
      // refresh
      View.grab(job.uuid).replaceWith(row);
    } else {  
      // append to table
      $("#jobs table tbody").append(row);
    }  
    View.grab(job.uuid).addClass("existing").data("job", job);
  });
  
  
  /**
   * Triggers the filter event when selecting a facet
   */
  $("#facets ul li a").live("click", function(event) {
    $(this).toggleClass("selected")
    $(document).trigger("filter")
  })
  
  
  function drawQueryFilters() {
    _.each(['state', 'site', 'user'], function(facet) {
      var filters = $.query.get(facet)
      if (filters instanceof Array) {
        // do nothing
      } else {
        filters = filters.split(",")
      }
      _.each(filters, function(filter) {
        $("ul[rel='"+facet+"'] li a[title='"+filter+"']").addClass('selected')
      })
    })
  }
  
  /**
   * Filters jobs based on selected facets
   * TODO: clean up, refactor
   */
  var startupFiltersTakenIntoAccount = false;
  $(document).bind("filter", function(event) {
    if (!startupFiltersTakenIntoAccount) {
      startupFiltersTakenIntoAccount = true;
      drawQueryFilters()
    }
    
    var facets = []
    $.each($("#facets ul li a"), function(i, element) {
      facets.push({
        name: $(element).attr("title"),
        type: $(element).attr("rel"),
        selected: $(element).hasClass("selected")
      })
    })
    
    var job;
    if (_(facets).any(function(facet){return facet.selected})) {
      $.each($("#jobs table tbody tr"), function(i, element) {
        job = $(element).data("job")
        var selected = _(facets).any(function(facet) { 
          return facet.selected && _([
            job.site, 
            job.state, 
            job.user
          ]).include(facet.name); 
        })
        if (selected) {
          $(element).removeClass("filtered").show();
        } else {
          $(element).addClass("filtered").hide();
        }
      })
    } else {
      $("#jobs table tbody tr").show();
    }
    return false;
  });

  
  /**
   * Renders the facets
   * TODO: clean up, refactor
   */
  $(document).bind("facets:draw", function(event) {
    var facets = {sites:{}, users:{}, states: {}}
    var job;
    
    $.each($("#jobs table tbody tr"), function(i, element) {
      job = $(element).data("job")
      facets.sites[job.site] = (facets.sites[job.site] || 0) + 1
      facets.users[job.user] = (facets.users[job.user] || 0) + 1
      facets.states[job.state] = (facets.states[job.state] || 0) + 1
    })
    
    // redraw the list of filters
    _(facets).each(function(dico, facet_type) {
      var selectedFacets = $.map($("#facets ul."+facet_type+" li a.selected"), function(e,i) {
        return $(e).attr("title");
      })
      $("#facets ul."+facet_type+" li").remove()
      var facet_names = _.keys(dico).sort();
      var count, classes;
      _.each(facet_names, function(facet_name) {
        count = dico[facet_name]
        classes = _.include(selectedFacets, facet_name) ? ["selected"] : []
        $("#facets ul."+facet_type).append('\
          <li>\
            <a href="#" rel="'+facet_type+'" class="'+classes.join(",")+'" title="'+facet_name+'">\
              '+facet_name+' <span class="count">('+count+')</span>\
            </a>\
          </li>\
        ')
      });
    });  
    $(document).trigger("filter");
    return false;
  });
  
  
  /**
   * Refreshes the jobs table
   */
  $(document).bind("view:refresh", function(event) {
    $("body").addClass("loading")
    $("#jobs table tbody tr").removeClass("existing")
    http.get("../", {
      ok: function(data) {
        $(document).trigger("grid", [data])
      }
    }); // GET /grid5000
  })
  
  $(document).bind("view:update", function(event) {
    $("#jobs table").trigger("update"); 
    $("#jobs table").trigger("sorton",[[[4,0]]]);
    $(document).trigger("facets:draw")
  })
  
  /** 
   * Called when all AJAX requests are terminated
   */
  $(document).ajaxStop(function() {
    $("body").removeClass("loading")
    $("#jobs table tbody tr:not(.existing)").fadeOut(function() {
      $(this).remove()
    })  
    $(document).trigger("view:update")
  })


  /**
   * Main trigger
   */
  // $.tablesorter.addParser({ 
  //   id: 'datetime', 
  //   is: function(s) { 
  //     // return false so this parser is not auto detected 
  //     return false; 
  //   }, 
  //   format: function(s, table, node) { 
  //     var element = $(node)
  //     element.html(element.html().replace(/\.000Z$/, 'Z'))
  //     return s ? Date.parse(s) : null;
  //   }, 
  //   type: 'numeric' 
  // });
  
  $("#jobs table").tablesorter({ 
    // headers: { 
    //   8: { sorter:'datetime' },
    //   9: { sorter:'datetime' }
    // } 
  }); 
  
  View.setup()
  
  $(document).trigger("view:refresh")
  
  setInterval(function() {
    if (View.config.refresh) {
      $(document).trigger("view:refresh")
    } else {
      // do nothing
    }
  }, View.defaults.refresh)
});
