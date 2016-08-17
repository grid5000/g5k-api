/* TODO:
 *  taktuk command to launch stress test + fork(gmetric custom)
 *  link to display metric graphs based on submitted jobs
 *  screencast
**/
var http = new Http();

// The queuedSteps that stores the main events that have been triggered and that will need to be taken care of in the $.ajaxStop handler.
var queuedSteps = [];
var rollback = false;
var reference = {}
var retired = {}
var environments = {}
var scripts = []
var sshKeys = []
var sites = {}
var userUid;
var submittedJobs = []

/*
 * Form helpers
 */
var Form = {
  toHash: function(form) {
    var last, keys, tmp;
    var obj = {};
    _.each($(form).serializeArray(), function(element) {
      last = {}
      keys = element.name.split(/\[(.*?)\]/);
      _.each(_.reject(keys.reverse(), function(key) { 
        return key == ""; 
      }), function(key, i) {
        if (i == 0) {
          last[key] = element.value;
        } else {
          // FIXME: I'm tired...
          tmp = last; last = {}; last[key] = tmp;
        }
      });
      $.extend(true, obj, last)
    });
    return obj;
  }
}

/*
 * Payload class
 */
Payload = function(job) {
  this.job = job;
}

Payload.prototype.toHash = function() {
  var job = this.job;
  job.walltime = job.walltime > 0 ? job.walltime : 1;
  var payload = {
    resources: "nodes="+job.resources+",walltime="+job.walltime,
    project: "UI API",
    name: "Quick Start",
    properties: "cluster='"+job.cluster_uid+"'",
    stdout: "/home/"+job.user_uid+"/public/OAR.%jobid%.stdout",
    stderr: "/home/"+job.user_uid+"/public/OAR.%jobid%.stderr"
  }
  if (job.environment != "") {
    // custom image
    //var splat = job.environment.split(/-(\d+)\.\d+$/)
    var chunky = {
      environment: job.environment,
      //version: splat[1],
      key: ('key' in job) ? job.key: "",
      command: ('command' in job) ? job.command:"",
      debug: "debug",
			nodes_ok: "/home/"+job.user_uid+"/public/Kadpeloy3.%jobid%.nodes_ok",
			nodes_ko: "/home/"+job.user_uid+"/public/Kadpeloy3.%jobid%.nodes_ko",
    }
    payload.command = "kadeploy3 -f $OAR_NODEFILE -e "+job.environment+" -k "+chunky.key+" -n "+chunky["nodes_ko"]+" -o "+chunky["nodes_ok"]+" ; "+chunky.command;
    payload.types = ["deploy"]
  } else {
    payload.command = job.command
  }
  return payload;
}

/*
 * UI Console to log events
 */
var UIConsole = {
  levels: {
    "D": 0,
    "I": 1,
    "W": 2,
    "E": 3
  },
  level: 1,
  setLevel: function(severity) {
    if (typeof(severity) == "string") {
      this.level = (this.levels[severity] || 1)
    } else {
      this.level = severity;
    }
  },
  log: function(message, comment, severity) {
    severity = severity || "I";
    comment = comment || "";
    if (this.levels[severity] >= this.level) {
      var now = new Date().toISOString();
      var css = message.length > 100 ? "large" : ""
      $("#console .log table").append('<tr class="'+severity+'"><td class="meta">'+severity+', ['+now+'] '+comment+'</td><td><textarea class="'+css+'">'+message+'</textarea></td></tr>');
      $("#console .log").stop(true, true).scrollTo($("#console .log table tr:last"), 1000);
    }
    return true;
  },
  info: function(message, comment) {
    this.log(message, comment, "I");
  },
  warn: function(message, comment) {
    this.log(message, comment, "W");
  },
  error: function(message, comment) {
    this.log(message, comment, "E");
  },
  showBusyIndicator: function() {
    $("#console").addClass("loading");
    $(document).scrollTo($("#console"), 1000);
  },
  hideBusyIndicator: function() {
    $("#console").removeClass("loading")
    $(document).scrollTo($("#console"), 1000);
  }
}

String.prototype.capitalize = function() {
  return this.charAt(0).toUpperCase() + this.substring(1).toLowerCase();
}


// ========================
// = Global AJAX handlers =
// ========================

/* 
 * Called when the FIRST AJAX request is sent
 */
$(document).ajaxStart(function() {
});

/*
 * Called when an AJAX request fails
 */
$(document).ajaxError(function(event, xhr, options, error) {
  var message, code;
  try {
    message = JSON.parse(xhr.responseText).message
  } catch(e) {
    message = xhr.responseText
  }
  try {
    code = xhr.status;
  } catch(e) {
    code = "ERROR";
  }
  var log = options.type+' '+options.url+' => '+code;
  if (message && message != "") {
    log += ' ('+message+')';
  }
  UIConsole.warn(message);
});

/* 
 * Called when ALL AJAX requests have completed
 */
$(document).ajaxStop(function() {
  var step;
  while(step = queuedSteps.shift()) {
    switch(step) {
      case "resources:display":
        // call exhibit
        output = {  
          properties:{  
            "processor_clock_speed":{valueType:"number"},
            "available_for":{valueType:"number"},
            "processor_cache_l1d":{valueType:"number"},
            "processor_cache_l1i":{valueType:"number"},
            "processor_cache_l2":{valueType:"number"},
            "main_memory_ram_size":{valueType:"number"},
            "storage_devices_0_size":{valueType:"number"},
            "network_adapters_0_rate":{valueType:"number"},
            "network_adapters_1_rate":{valueType:"number"},
            "network_adapters_2_rate":{valueType:"number"},
            "network_adapters_3_rate":{valueType:"number"},
						"architecture_smt_size":{valueType:"number"}
          },
          types:{"node":{"pluralLabel":"nodes"}},
          items: _.values(reference)
        }
        window.database = Exhibit.Database.create();
        window.database.loadData(output);
        window.exhibit = Exhibit.create();
        window.exhibit.configureFromDOM();
        Exhibit.UI.hideBusyIndicator();
        
        $("#resources").removeClass("loading")
        $("#resources .display").slideDown()
        $("#resources .buttons").show()
        break;
      // submitting jobs
      case "form:submit":
        if (rollback) {
          _.each(submittedJobs, function(job) {
            window.clearInterval(job.pollState);
            window.clearInterval(job.pollStdout);
            window.clearInterval(job.pollStderr);
            http.del(http.linkTo(job.links, "self"), {
              before: function() {
                UIConsole.info(job.site_uid+"/"+job.uid+" cancelling...")
              },
              ok: function() {
                UIConsole.info(job.site_uid+"/"+job.uid+" canceled.")
              }
            })
          });
        } else {
          $("#actions").html('<a href="./metrics.html?jobs='+_.map(submittedJobs, function(job) {
            return [job.site_uid, job.uid].join(":")
          }).join(",")+'" class="button">Display Metrics</a>');
          $("a.button").button();
        }
        break;
      default:
        break;
    }
  }
  
});



// =====================================
// = What is loaded after DOM is ready =
// =====================================
$(document).ready(function() {
  
  $("button, input:submit").button();
  
  // Poor man's hook!
  Exhibit.UI.hideBusyIndicator2 = Exhibit.UI.hideBusyIndicator;
  Exhibit.UI.hideBusyIndicator = function() {
		$(document).trigger("exhibit:refresh") ;

		// go a bit further than native exhibit by hiding empty properties
		$(".exhibit-flowingFacet .exhibit-flowingFacet-body:not(:empty)").parents(".exhibit-flowingFacet").show() ;
		$(".exhibit-flowingFacet .exhibit-flowingFacet-body:empty").parents(".exhibit-flowingFacet").hide() ;
    Exhibit.UI.hideBusyIndicator2() ;
  }
  
  // Fix to force sliders to call the busy indicator when values change
  Exhibit.SliderFacet.slider.prototype._notifyFacet2 = Exhibit.SliderFacet.slider.prototype._notifyFacet;
  Exhibit.SliderFacet.slider.prototype._notifyFacet = function() {
    Exhibit.UI.showBusyIndicator();
    this._notifyFacet2();
    Exhibit.UI.hideBusyIndicator()
  };

  // =========================
  // = Initial HTTP requests =
  // =========================
  /**
   * React to a new grid event
   */
  $(document).bind("grid", function(event, grid) {
    
    http.get(http.linkTo(grid.links, "sites"), {
      before: function() { 
        UIConsole.info("Fetching sites of "+grid.uid+"...")
      },
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
    sites[site.uid] = site;
    
    http.get(http.linkTo(site.links, "status"), {
      before: function() { 
        UIConsole.info("Fetching node status of "+grid.uid+"/"+site.uid+"...")
      },
      ok: function(data) {
        var hostname, resa, available_for;
        var now = new Date().getTime()/1000;
        _.each(data.nodes, function(node_status, node_uid) {
	  hostname = node_uid ;
	  if (!node_status.comment.toLowerCase().startsWith('retired')) {
            reference[hostname] = reference[hostname] || {
              id: hostname,
              label: hostname.split(".")[0],
              grid_uid: grid.uid,
              site_uid: site.uid,
              cluster_uid: hostname.split("-")[0]
            }
            resa = node_status.reservations[0] || {
              started_at: Infinity, 
              walltime: 0
            }
            if (resa.started_at < now && (resa.started_at+resa.walltime) >= now) {
              available_for = 0;
            } else {  
              available_for = Math.min((resa.started_at-now)/3600, 23).toFixed(2);
            }
            $.extend(reference[hostname], {
              hard_state: node_status.hard,
              syst_state: node_status.soft,
              available_for: available_for
            })
	  } else {
	      retired[hostname]={hard_state: 'retired'} ;
	      if (hostname in reference) {
		  reference[hostname]['hard_state']='retired' ;
	      }
	  }
        })
      }
    }); // GET /grid5000/sites/:site/status
    
    http.get(http.linkTo(site.links, "self")+"/public/~/", {
      dataType: "html",
      global: false,
      ok: function(data) {
        var dom = $(data);
        userUid = dom.siblings("h1").text().replace(/(.*)\/~(\w+)/, '$2');
        $.each(dom.siblings("table").find("tr td a"), function(i, item) {
          var basename = $(item).attr("href")
          if (!basename.match(/\/$/)) {
            scripts.push({
              uri: "https://api.grid5000.fr"+http.linkTo(site.links, "self")+"/public/"+userUid+"/"+basename,
              uid: basename,
              site_uid: site.uid,
              user_uid: userUid
            })
          }
        })
      }
    }); // GET /grid5000/sites/:site/public
    
    http.get(http.linkTo(site.links, "clusters"), {
      timeout: 15000,
      before: function() { 
        UIConsole.info("Fetching clusters of "+grid.uid+"/"+site.uid+"...")
      },
      ok: function(data) {
        _.each(data.items, function(cluster) {
          $(document).trigger("grid:site:cluster", [grid, site, cluster])
        });
			},
			ko: function(data) {
					UIConsole.info("Error fetching clusters"); 
      }
    }); // GET /grid5000/sites/:site/clusters
    
		var site_environments=http.linkTo(site.links, "environments");
	  if (site_environments != null) {
      http.get(site_environments, {
        timeout: 15000,
        before: function() { 
          UIConsole.info("Fetching environments deployable on "+grid.uid+"/"+site.uid+"...")
        },
        ok: function(data) {
			  	site_environments = $.map(data.items, function(env) {
					  return env.uid.split(/-(\d+)\.\d+$/)[0]
				  }) ;
				  environments[site.uid] = site_environments.filter(function(elem, pos,arr) {
					  return arr.indexOf(elem) == pos;
				  }); 
			  },
			  ko: function(data) {
					UIConsole.info("Could not get environment of "+grid.uid+"/"+site.uid); 
        }
      }); // GET /grid5000/sites/:site/environments
    }
  });
  
  $(document).bind("grid:site:cluster", function(event, grid, site, cluster) {
    http.get(http.linkTo(cluster.links, "nodes"), {
      timeout: 30000,
      before: function() { 
        UIConsole.info("Fetching nodes of "+grid.uid+"/"+site.uid+"/"+cluster.uid+"...")
      },
      ok: function(data) {
        var hostname;
        _.each(data.items, function(node) {
          hostname = [node.uid, site.uid, grid.uid, 'fr'].join(".")
	    reference[hostname] = reference[hostname] || {
            id: hostname,
            label: node.uid,
            grid_uid: grid.uid,
            site_uid: site.uid,
            cluster_uid: hostname.split("-")[0],
          }
	  if (hostname in retired) {
	      reference[hostname]['hard_state']='retired' ;
	  }  
          $.extend(reference[hostname], nodeConverter(node))
        });
      }
    }); // GET /grid5000/sites/:site/clusters/:cluster/nodes
  })



  // ===================
  // = exhibit:refresh =
  // ===================
  $(document).bind("exhibit:refresh", function() {
    $(".exhibit-collectionView-header-sortControls, .exhibit-collectionView-footer").hide()
		var site_groups = $.find(".exhibit-collectionView-group h1") ;
		if (site_groups.length == 0) {
			var viewPanelBody=$.find(".exhibit-collectionView-body");
			var content=$("ol",viewPanelBody);
			content.detach();
			var resources=$.map($("li .node",content), function(e) {
				return $(e).attr('ex:itemid')
			}) ;
      var siteUid    = resources[0].split(".")[1];
      var clusterUid = resources[0].split("-")[0];
			$(".exhibit-collectionView-body").append('<div class="exhibit-collectionView-group"> \
                              <h1>'+siteUid+'<span class="exhibit-collectionView-group-count"> \
                               (<span>1</span>)</span></h1>\
                              <div class="exhibit-collectionView-group-content">') ;
			$(".exhibit-collectionView-group-content",viewPanelBody).append(content);
			
		}
    $.each($(".exhibit-collectionView-group-content ol"), function(i, item) {
      var group       = $(item).closest(".exhibit-collectionView-group")
      var nodesCount  = $("li", group).length
      var resources   = $.map($("li .node", group), function(e) { 
        return $(e).attr('ex:itemid')
      });
      var siteUid    = resources[0].split(".")[1];
      var clusterUid = resources[0].split("-")[0];

		  //In some cases, group can point to the whole site
			// rather than to the cluster level
			if (group.children("h1").length > 0) {
				//recreate a cluster level in the dom
				$(item).detach() ;
				$(".exhibit-collectionView-group-content",group).append('<div class="exhibit-collectionView-group"> \
                             <h2>'+clusterUid+'<span class="exhibit-collectionView-group-count"> \
                             (<span>1</span>)</span></h2>\
                              <div class="exhibit-collectionView-group-content">') ;
				group=$(".exhibit-collectionView-group",group) ;
			}
      group.addClass("choice clear").attr('id', clusterUid).html('\
        <div class="slider">\
          <input type="hidden" name="jobs['+clusterUid+'][site_uid]" value="'+siteUid+'" />\
          <div class="title">'+clusterUid+'</div>\
          <div class="sticker">\
            <input type="text" size="4" name="jobs['+clusterUid+'][resources]" value="0" class="value no-border" />\
            <span class="delimiter">/</span>\
            <span class="total">'+nodesCount+'</span>\
          </div>\
          <div class="handler clear"></div>\
        </div>\
        <div class="options">\
          <div class="environment">\
            <label for="jobs['+clusterUid+'][environment]">Environment to deploy:</label><br/>\
            <select name="jobs['+clusterUid+'][environment]">\
              <option value="" selected="selected">production</option>\
              '+_.map(environments[siteUid] || [], function(env) { 
                return '<option value="'+env+'">'+env+'</option>'
              }).join("")+'\
            </select>\
          </div>\
          <div class="command">\
            <label for="jobs['+clusterUid+'][command]">Command to launch from the cluster\'s frontend after the instances are reserved:</label><br/>\
            <textarea name="jobs['+clusterUid+'][command]" class="command"></textarea>\
            ...or select one of your existing public scripts<span class="script_link"></span>:\
            <select>\
              <option value="" selected="selected"></option>\
              '+_.map(scripts || [], function(script) { 
                return '<option value="'+script.uri+'">'+script.site_uid+'/'+script.uid+'</option>'
              }).join("")+'\
            </select>\
          </div>\
          <div class="ssh-public-key" style="display:none">\
            <label for="jobs['+clusterUid+'][key]">Select a specific SSH Public Key(s) (will use your ~/.ssh/authorized_key by default):</label><br/>\
            <select>\
              <option value="" selected="selected"></option>\
              '+_.map(scripts || [], function(script) { 
                return '<option value="'+script.uri+'">'+script.site_uid+'/'+script.uid+'</option>'
              }).join("")+'\
            </select>\
          </div>\
        </div>\
      ');
      $(".slider .handler", group).slider({
        min: 0,
        max: nodesCount
      }).bind("slide slidechange", function(event, ui) {
        $(".slider .sticker .value", group).val(ui.value)
        $(".options", group).toggle(ui.value > 0);
        $(document).trigger("grid:total")
      })
    });
  })
  
  $(".choice .options .environment select").live("change", function(event) {
    var selectedEnvironment = $(event.target).val()
    $(".ssh-public-key", $(event.target).closest(".options")).toggle(selectedEnvironment != "")
  })

  $(".choice .options .command select").live("change", function(event) {
    var selectedScript = $(event.target).val()
    if (selectedScript != "") {
      $(event.target).siblings("textarea.command").val('curl -k '+selectedScript+' | sh');
      $(event.target).siblings("span.script_link").html(' [<a href="'+selectedScript+'" target="_blank">view selected</a>]');
    } else {
      $(event.target).siblings("textarea.command").val('');
      $(event.target).siblings("span.script_link").html('');
    }    
  })
  
  $(".choice .options .ssh-public-key select").live("change", function(event) {
    var selectedScript = $(event.target).val()
    if (selectedScript != "") {
      $(event.target).siblings("textarea.key").val(selectedScript);
      $(event.target).siblings("span.key_link").html(' [<a href="'+selectedScript+'" target="_blank">view selected</a>]');
    } else {
      $(event.target).siblings("textarea.key").val('');
      $(event.target).siblings("span.key_link").html('');
    }    
  })
  
  
  // ===================================
  // = Submit form, instantiate timers =
  // ===================================
  $('form').bind("submit whatever", function() {
    queuedSteps.push("form:submit")
    rollback = false;
    
    // Create a JSON object from form fields
    var obj = Form.toHash(this)
    
    obj.jobs = obj.jobs || []

    if (_.size(obj.jobs) > 0) {
      UIConsole.showBusyIndicator() ;
      _.each(obj.jobs, function(job, cluster_uid) {
        job.user_uid = userUid;
        job.cluster_uid = cluster_uid;
      
        if (parseInt(job.resources) > 0) {
          job.walltime = parseFloat($(".exhibit-slider-display input[type=text]:eq(0)").val())
          var payload = new Payload(job);
          var site = sites[job.site_uid];
        
          http.post(http.linkTo(site.links, "jobs"), JSON.stringify(payload.toHash()), {
            contentType: "application/json",
            before: function() {
              UIConsole.info("Submitting job on "+site.uid+" using "+http.linkTo(site.links, "jobs")+"...");
            },
            ok: function(data) {
              UIConsole.info("Successfully submitted job #"+data.uid+" in "+site.uid+".")
              data.site_uid = site.uid
              data.user_uid = userUid
              data.cluster_uid = cluster_uid

							data.state="waiting" ; //true until we get more news 
              submittedJobs.push(data);
              // Check job STATE
              data.pollState = window.setInterval(function() {
                http.get(http.linkTo(data.links, "self"), {
                  ok: function(job) {
                    $.extend(true, data, job)
                    if ($.inArray(data.state, ["running", "launching", "waiting"]) == -1) {
                      UIConsole.info("Job #"+data.uid+" is no longer waiting of running. Final state="+data.state+".")
                      window.clearInterval(data.pollState)
                      window.clearInterval(data.pollStdout)
                      window.clearInterval(data.pollStderr)
                    }
										if (data.state == "waiting") {
											UIConsole.info("Job #"+data.uid+" is waiting. Expected start is "+ new Date(data.scheduled_at*1000)) ;
										}
										if (data.state == "running") {
											if (!("pollStderr" in data)) {
												UIConsole.info("Job #"+data.uid+" is running. Setup polling of stdout and stderr") ;			
												// polling of STDOUT and STDERR not setup
												// Check STDOUT and STDERR
												_.each(["stdout", "stderr"], function(out) {
													data[out] = ""
													data["poll"+out.capitalize()] = window.setInterval(function() {
														http.get(http.linkTo(site.links, "self")+"/public/"+data.user_uid+"/OAR."+data.uid+"."+out, {
															cache: false,
															dataType: "text",
															ok: function(output) {
																var diff = output.substring(data[out].length).split("\n")
																data[out] = output
																_.each(diff, function(line) {
																	if (line != "") {
																		UIConsole.info(line, data.site_uid+"/"+data.uid+"/"+out.toUpperCase())
																	}
																});
															}
														})
													}, 3000)
												});
											}
										}
                    if (_.all(submittedJobs, function(job) {
                      return $.inArray(job.state, ["running", "launching", "waiting"]) == -1;
                    })) {
                      UIConsole.info("=> All jobs have terminated !")
                      UIConsole.hideBusyIndicator();
                    }
                  }
                })
              }, 5000);
            
            },
            ko: function() {
              UIConsole.info("Cannot submit the job on "+site.uid+". Cancelling all jobs...")
              rollback = true;
            }
          })
        }
      });
    } else {
      UIConsole.error("Nothing to launch!")
    }
    return false;
  });
  
  
  /**
   * Main trigger
   */
  http.get("../", {
    before: function() {
      queuedSteps.push("resources:display")
      Exhibit.UI.showBusyIndicator();
      $("#resources").addClass("loading")
      UIConsole.info("Fetching API entry point...")
    },
    ok: function(data) {
      $(document).trigger("grid", data)
    }
  });
});
