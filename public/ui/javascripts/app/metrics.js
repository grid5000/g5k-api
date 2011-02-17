var http = new Http();

var Timeseries = {
  resolutions: [15, 360, 2520, 10080, 86400],
  metrics: {
    "ambient_temp": { 
      unit: "°C", multiplier: 1, yAxis: {title: {text: "°C"}} 
    },
    "boottime": { 
      unit: "s", multiplier: 1, yAxis: {title: {text: "s"}} 
    },
  	"bytes_in": { 
  	  unit: "bytes", multiplier: 1, yAxis: {title: {text: "bytes"}} 
  	},
  	"bytes_out": { 
  	  unit: "bytes", multiplier: 1, yAxis: {title: {text: "bytes"}} 
  	},
    "cpu_aidle": { 
      unit: "%", multiplier: 1, yAxis: {title: {text: "%"}, max: 100} 
    },
    "cpu_idle": { 
      unit: "%", multiplier: 1, yAxis: {title: {text: "%"}, max: 100} 
    },
    "cpu_nice": { 
      unit: "%", multiplier: 1, yAxis: {title: {text: "%"}, max: 100} 
    },
    "cpu_num": { 
      unit: "", multiplier: 1, yAxis: {title: {text: ""}} 
    },
    "cpu_speed": { 
      unit: "MHz", multiplier: 1, yAxis: {title: {text: "MHz"}} 
    },
    "cpu_system": { 
      unit: "%", multiplier: 1, yAxis: {title: {text: "%"}} 
    },
    "cpu_user": { 
      unit: "%", multiplier: 1, yAxis: {title: {text: "%"}} 
    },
    "cpu_wio": { 
      unit: "%", multiplier: 1, yAxis: {title: {text: "%"}} 
    },
  	"disk_free": { 
  	  unit: "GB", multiplier: 1, yAxis: {title: {text: "GB"}} 
  	},
  	"disk_total": { 
  	  unit: "GB", multiplier: 1, yAxis: {title: {text: "GB"}} 
  	},
  	"load_fifteen": { 
  	  unit: "", multiplier: 1, yAxis: {title: {text: ""}} 
  	},
  	"load_five": { 
  	  unit: "", multiplier: 1, yAxis: {title: {text: ""}} 
  	},
  	"load_one": { 
  	  unit: "", multiplier: 1, yAxis: {title: {text: ""}} 
  	},
  	"mem_buffers": { 
  	  unit: "MB", multiplier: 1/1000, yAxis: {title: {text: "MB"}} 
  	},
  	"mem_cached": { 
  	  unit: "MB", multiplier: 1/1000, yAxis: {title: {text: "MB"}} 
  	},
    "mem_free": {
      unit: "MB", multiplier: 1/1000, yAxis: {title: {text: "MB"}} 
    },
  	"mem_shared": { 
  	  unit: "MB", multiplier: 1/1000, yAxis: {title: {text: "MB"}} 
  	},
  	"mem_total": { 
  	  unit: "MB", multiplier: 1/1000, yAxis: {title: {text: "MB"}} 
  	},
  	"part_max_used": { 
  	  unit: "", multiplier: 1, yAxis: {title: {text: ""}} 
  	},
  	"pkts_in": { 
  	  unit: "", multiplier: 1, yAxis: {title: {text: ""}} 
  	},
  	"pkts_out": { 
  	  unit: "", multiplier: 1, yAxis: {title: {text: ""}} 
  	},
  	"proc_run": { 
  	  unit: "", multiplier: 1, yAxis: {title: {text: ""}} 
  	},
  	"proc_total": { 
  	  unit: "", multiplier: 1, yAxis: {title: {text: ""}} 
  	},
  	"swap_free": { 
  	  unit: "MB", multiplier: 1/1000, yAxis: {title: {text: "MB"}} 
  	},
  	"swap_total": { 
  	  unit: "MB", multiplier: 1/1000, yAxis: {title: {text: "MB"}} 
  	}
  }
}

var jobs = {}
var metrics = []
var timeseries = {}


var dateFormat = pv.Format.date("%Y/%m/%d %H:%M:%S")
var numberFormat = pv.Format.number()
numberFormat.fractionDigits(2)

$(document).ready(function() {

  $("input[type=submit]").button();

  $(document).ajaxStop(function() {
    $("h1").removeClass("loading")
  })
  
  /**
   * Fetch the timeseries associated to the nodes of a job
   */
  $(document).bind("site:metric:timeseries", function(event, siteId, metricId, jobId) {
    
    var job = jobs[siteId][jobId]
    var now = new Date().getTime()/1000
    
    if (!timeseries[metricId]) {
      timeseries[metricId] = []
      var siteContainer = $("#"+siteId)
      var graphCanvasId = [siteId, jobId, metricId, "graph"].join("-")
      siteContainer.append('<div>\
        <h2>['+metricId+'] '+siteId+':'+job.user+':'+jobId+' from '+dateFormat.format(new Date(job.from*1000))+' to '+dateFormat.format(new Date(job.to*1000))+'</h2>\
        <div id="'+graphCanvasId+'"></div>\
      </div>')
    }
    
    if (job.nodes.length > 0) {
      http.post(
        "../sites/"+siteId+"/metrics/"+metricId+"/timeseries", 
        {
          from: job.from,
          to: ((job.to > now) ? now : job.to),
          resolution: job.resolution,
          only: job.nodes.join(",")
        },
        {
          ok: function(data) {
            job.loadedMetrics.push(metricId)
            _.each(data.items, function(series) {
              timeseries[metricId].push(series)
            })
            $(document).trigger("site:metric:draw", [siteId, metricId])
          }
        }
      ); // POST timeseries
    } else {
      $.jGrowl("No assigned nodes for job "+siteId+":"+jobId+".", {theme:'error'});
    }
    
  })
  
  /**
   Fetch the details of a job
   */
  $(document).bind("site:job", function(event, siteId, jobId) {
    http.get("../sites/"+siteId+"/jobs/"+jobId, {
      before: function() {
        $("h1").addClass("loading")
      },
      ok: function(data) {
        jobs[siteId][jobId].from = data.started_at
        jobs[siteId][jobId].to = data.started_at+data.walltime
        jobs[siteId][jobId].nodes = data.assigned_nodes
        jobs[siteId][jobId].user = data.user_uid
        _.each(metrics, function(metricId) {
          $(document).trigger("site:metric:timeseries", [
            siteId, 
            metricId, 
            jobId
          ])
        });
      },
      ko: function(xhr, status, errorThrown) {
        delete jobs[siteId][jobId]
      }
    }); // GET job
  })
  
  
  /**
   * 
   */
  $(document).bind("site:metric:draw", function(event, siteId, metricId) {
    var siteContainer = $("#"+siteId)
    
    if (_.all(jobs[siteId], function(job, jobId) {
      return job.nodes && _.include(job.loadedMetrics, metricId);
    })) {
      _.each(jobs[siteId], function(job, jobId) {
        var graphCanvasId = [siteId, jobId, metricId, "graph"].join("-")

        
        var graphContainer = $("#"+graphCanvasId)

        // <div class="scale" style="text-align:right;padding-right:20;">\
        //   <input name="scale" type="checkbox">\
        //   <label for="scale">Scale to fit</label>\
        // </div>\

        var ts, from, to, resolution;
        var matrix,siteUid,time,
            max,min,median,lq,uq,
            medianIndex,sortedColumn;
        
        // TODO: clean up all that stuff
        matrix = _.select(timeseries[metricId], function(series) {
          return _.include(job.nodes, series.hostname)
        })
        

        matrix = _.map(matrix, function(series) {
          resolution = series.resolution;
          from = series.from;
          to = series.to;
          return series.values;
        })
        
        if (matrix.length > 0) {
          var series = []
          var column;

          for (var i=0; i < matrix[0].length; i++) {
            column = []
            for(var j=0; j < matrix.length; j++) {
              column.push(matrix[j][i])
            }
            series.push(column)
          }
          
          time = from-resolution

          series = _.map(series, function(column) {
            // Remove null values, don't know if it makes sense
            column = _.compact(column).sort(pv.naturalOrder)
            column = column.sort(pv.naturalOrder)
            time += resolution
            date = new Date(time*1000)

            if (column.length > 0) {
              medianIndex = Math.floor(column.length/2)
              if (column.length%2 == 0) {
                lq = pv.median(column.slice(0, medianIndex))
                uq = pv.median(column.slice(medianIndex, column.length))
              } else {
                lq = pv.median(column.slice(0, medianIndex))
                uq = pv.median(column.slice(medianIndex+1, column.length))
              }

              max = pv.max(column)
              min = pv.min(column)

              return {
                metric: metricId,
                date: date,
                max: max,
                min: min,
                std: pv.deviation(column),
                mean: pv.mean(column),
                median: pv.median(column),
                lq: lq,
                uq: uq,
                values: column
              }
            } else {
              return {
                metric: metricId,
                date: date,
                max: null,
                min: null,
                std: null,
                mean: null,
                median: null,
                lq: null,
                uq: null,
                values: column
              }
            }
          });

          var lastColumn = _.last(series)
          while(lastColumn && lastColumn.values.length == 0) {
            lastColumn = series.pop()
          }

          var vis = new Plot(graphContainer, 500, 200).boxAndWhisker(series, from, to, resolution, function(d) {
            return '\
              <table class="stats">\
                <tr><th>Date</th><td>'+dateFormat.format(d.date)+'</td></tr>\
                <tr><th>Mean</th><td>'+numberFormat.format(d.mean)+'  </td></tr>\
                <tr><th>Std</th><td>'+numberFormat.format(d.std)+'</td></tr>\
                <tr><th>Min</th><td>'+numberFormat.format(d.min)+'</td></tr>\
                <tr><th>Max</th><td>'+numberFormat.format(d.max)+'</td></tr>\
                <tr><th>Q1</th><td>'+numberFormat.format(d.lq)+'</td></tr>\
                <tr><th>Q2</th><td>'+numberFormat.format(d.median)+'</td></tr>\
                <tr><th>Q3</th><td>'+numberFormat.format(d.uq)+'</td></tr>\
              </table>\
            ';
          })
          if (vis) {
            vis.render()
          } else {
            graphContainer.html("No Data Available")
          }
        } else {
          graphContainer.html("No Data Available")
        }
        
        
        // $(".scale input:checkbox", container).bind("change", function(event) {
        //   vis.render()
        // })
        // checked = container.append(document.createElement("div"))
        // $("div:last", container).html('\
        //   <input class="scale" type="checkbox">\
        //   <label for="scale">Scale to fit</label>\
        // ')
      })
    } else {
      // not ready
      // setTimeout(1000, function() {
      //   $(document).trigger("")
      // })
    }
  })

  /**
   * Build the URL when user submits the form
   */
  var form = $("form#control")
  form.submit(function() {
    var jobs = _.uniq($("input[name=jobs]", form).val().split(/,/))
    var metrics = _($.makeArray($("input[name=metrics]:checked", form))).map(function(e) {return $(e).val()});
    var aggregation = $("input[name=aggregation]:checked", form).val();

    var url = "?jobs="+jobs.join(",")+"&metrics="+metrics.join(",");
    
    window.location.href=url
    return false;
  });
  
  $("#sidebar a[rel=select-all-metrics]").bind("click", function(event) {
    $("#control input[name=metrics]").attr("checked", "checked")
    return false;
  });
  $("#sidebar a[rel=deselect-all-metrics]").bind("click", function(event) {
    $("#control input[name=metrics]").attr("checked", "")
    return false;
  });
  $("#sidebar a[rel=add-custom-metric]").bind("click", function(event) {
    var metric = window.prompt("Enter the name of your metric")
    if (metric) {
      $("#control ul#metrics-list").append('<li class="metric"><input type="checkbox" name="metrics" value="'+metric+'" id="'+metric+'" /><label for="'+metric+'">'+metric+'</label></li>')
    }
    return false;
  });
  /**
   * Main 
   */
  metrics = Helper.arrayParam($.query.get("metrics"))
  if (metrics.length == 0) {
    metrics = ["bytes_in","bytes_out","cpu_system","mem_free"]
  }
  
  _.each(_.uniq($.merge(_.keys(Timeseries.metrics), metrics)), function(metric) {
    $("#control ul#metrics-list").append('<li class="metric"><input type="checkbox" name="metrics" value="'+metric+'" id="'+metric+'" /><label for="'+metric+'">'+metric+'</label></li>')
  })
  
  var inputJobs = Helper.arrayParam($.query.get("jobs"))
  _.each(inputJobs, function(job) {
    if (typeof(job) == "string") {
      var splat = job.split("@")
      var resolution = splat[1] || Timeseries.resolutions[0]
      splat = splat[0].split(":")
      var jobId = splat[1]
      var siteId = splat[0]
      jobs[siteId] = jobs[siteId] || {}
      jobs[siteId][jobId] = {
        loadedMetrics: [],
        resolution: resolution
      }
    }
  });

  _(metrics).each(function(metric) {
    $("input[name=metrics][value="+metric+"]", form).attr("checked", "checked");
  })  
  $("input[name=jobs]", form).val(inputJobs.join(","));
  
  _.each(jobs, function(siteJobs, siteId) {
    var container = $("#"+siteId)
    if (!container.id) {
      $("#charts").append('<div id="'+siteId+'"></div>')
    }
    _.each(siteJobs, function(job, jobId) {
      $(document).trigger("site:job", [siteId, jobId])
    })
  });

});
