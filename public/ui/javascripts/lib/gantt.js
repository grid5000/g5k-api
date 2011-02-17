/**
 * Gantt chart library
 * @author Cyril Rohr <cyril.rohr@inria.fr>
 * Copyright 2010 INRIA Rennes-Bretagne Atlantique.
 */
function Gantt(options) {
  var now = new Date().getTime()
  var default_options = {
    resourcesPanelWidth: 250,
    gutterHeight: 70,
    barWidth: 20,
    barSpace: 0.5,
    resolution: 600000,
    resolutionWidth: 20,
    jobId: "id",
    relativeSpeed: 1,
    tooltipHeight: 80,
    tooltipWidth: 300,
    resizingCornerRadius: 20,
    resourceId: "resource_id",
    bands: [
      {relativeHeight: 2/5, relativeResolution: 24, backgroundColor: "rgb(17,17,17)", color: "rgb(255,255,255)"},
      {relativeHeight: 3/5, relativeResolution: 1, backgroundColor: "rgb(51,51,51)", color: "rgb(255,255,255)"}
    ]
  }
  
  var self                  = this;
  var currentOptions        = {};
  var displayCount          = 0;
  
  var container             = options.container;
  var canvas                = document.getElementById(container);
  var ctx                   = canvas.getContext('2d');
  
  var jobId, resourceId, resources, jobs, jobColors,
      height, width, barWidth, barSpace, gutterHeight, tooltipHeight, tooltipWidth,
      bands, bars, lastTooltip, relativeSpeed,
      resourcesPanelWidth, itemsInResourcesPanel, jobsPanelWidth,
      resolution, resolutionWidth, resourcesOffset, lastResourcesOffset, jobsOffset, timelineVisibleLength,
      lastStartDate, startDate, endDate, timelineRange,
      resizingCornerRadius;
      
  var jobsToDisplay         = [];
  // Is the mouse button down ?
  var mousedown             = false;
  // Last recorded mouse event
  var mouseevent            = null;
  var bars                  = [];
  var lastTooltip           = null;
  
  this.setOptions = function(options) {
    if (!options) { options = {} }
    $.extend(true, currentOptions, options)
    
    lastStartDate         = startDate;
    lastResourcesOffset   = resourcesOffset
    now                   = currentOptions.now || now
    jobId                 = currentOptions.jobId || default_options.jobId
    resourceId            = currentOptions.resourceId || default_options.resourceId
    if (options.resources) {
      resources             = (currentOptions.resources || [])
      resourcesOffset       = 0;
    }
    
    if (options.jobs) {
      jobs                = (currentOptions.jobs || []).sort(function(a, b) { 
        if (a.from > b.from) {
          return 1;
        } else if (a.from < b.from) {
          return -1;
        } else {
          return 0;
        }
      })
      jobColors           = {}
      var resource_ids = $.map(resources, function(item, i) {
        return item.id
      })
      // Generate colors for each job, only if a color has not already been set
      $.each(jobs, function(i, job) {
        if (!jobColors[job[jobId]]) {  
          jobColors[job[jobId]] = job.color || getColor()  
        }
        job.resourceIndex = $.inArray(job[resourceId], resource_ids)
      })
    }
    
    // Width of the jobs bars
    barWidth              = parseFloat(currentOptions.barWidth || default_options.barWidth)
    // Space between 2 job bars
    barSpace              = parseFloat(currentOptions.barSpace || default_options.barSpace)
    gutterHeight          = parseFloat(currentOptions.gutterHeight || default_options.gutterHeight)
    tooltipHeight         = parseFloat(currentOptions.tooltipHeight || default_options.tooltipHeight)
    tooltipWidth          = parseFloat(currentOptions.tooltipWidth || default_options.tooltipWidth)
    // Width of the resouces panel
    resourcesPanelWidth   = parseFloat(currentOptions.resourcesPanelWidth || default_options.resourcesPanelWidth)
    itemsInResourcesPanel = Math.floor((canvas.height-gutterHeight)/barWidth);
    // Width of the jobs panel
    jobsPanelWidth        = canvas.width-resourcesPanelWidth
    // The resolution of the timeline, in milliseconds
    resolution            = parseInt(currentOptions.resolution || default_options.resolution)
    // The number of pixels for a resolution unit
    resolutionWidth       = parseFloat(currentOptions.resolutionWidth || default_options.resolutionWidth)
    // The first displayed resource
    resourcesOffset       = parseInt(currentOptions.resourcesOffset || 0)
    resourcesOffset       = Math.min(resourcesOffset, Math.floor(resources.length-itemsInResourcesPanel/1.5))
    resourcesOffset       = Math.max(0, resourcesOffset)
    
    // Number of milliseconds displayed in the visible part of the jobs panel
    timelineVisibleLength = Math.floor( (jobsPanelWidth/resolutionWidth) * resolution )
    // Start date of the jobs panel
    startDate             = currentOptions.startDate || (now-timelineVisibleLength/2)
    // The total timeline interval
    timelineRange         = [jobs[0].from, jobs[jobs.length-1].to]
    minStartDate          = timelineRange[0]-resolution
    maxStartDate          = timelineRange[1]-timelineVisibleLength/2
    startDate             = Math.max(startDate, minStartDate)
    startDate             = Math.min(startDate, maxStartDate)
    // End date of the jobs panel
    endDate               = startDate+timelineVisibleLength
    bands                 = currentOptions.bands || default_options.bands
    relativeSpeed         = currentOptions.relativeSpeed || default_options.relativeSpeed
    resizingCornerRadius  = currentOptions.resizingCornerRadius || default_options.resizingCornerRadius
    width                 = currentOptions.width || canvas.width
    height                = currentOptions.height || canvas.height
    return self;
  }
  
  $(canvas).css('cursor', 'move')
  
  self.setOptions(options)
  
  // filter jobs to display based on startDate, endDate, and resourcesRange
  // TODO: optimize search
  function filterJobs(options) {
    var selectedItems = [];
    var job;
    var jobsRange = [0, jobs.length-1]
    for (var i = jobsRange[0]; i <= jobsRange[1]; i++) {
      job = jobs[i]
      if (!(job.from > options.endDate || job.to < options.startDate)) {
        if (job.resourceIndex >= options.resourcesRange[0] && job.resourceIndex <= options.resourcesRange[1]) {
          selectedItems.push(i)
        }
      } else {
        
      }
    }
    
    return selectedItems;
  }
  
  // Return the (x,y) coordinates of the user's mouse pointer
  function mouseXY(event) {
    var obj = (document.all ? event.srcElement : event.target);
    var e   = event;
    var x;
    var y;
    
    // Browser with offsetX and offsetY
    if (typeof(e.offsetX) == 'number' && typeof(e.offsetY) == 'number') {
        x = e.offsetX;
        y = e.offsetY;
    // FF and other
    } else {
        x = 0;
        y = 0;
    
        while (obj != document.body) {
            x += obj.offsetLeft;
            y += obj.offsetTop;
    
            obj = obj.offsetParent;
        }
    
        x = e.pageX - x;
        y = e.pageY - y;
    }
    return {x: x, y: y}
  }
  
  var resizing = false;
  
  // Bind events to the canvas
  $(canvas).mousemove(function(event) {
    var newCoordinates = mouseXY(event)
    var x = newCoordinates.x
    var y = newCoordinates.y
    if (resizing || (x > canvas.width-resizingCornerRadius && y > canvas.height-resizingCornerRadius)) {
      $(canvas).css('cursor', 'se-resize')
    } else {
      $(canvas).css('cursor', 'move')
    }

    if (mousedown) {
      if (resizing) {
        self.display({
          width: x+resizingCornerRadius,
          height: y+resizingCornerRadius
        })
      } else {
        var options = {relativeSpeed: relativeSpeed}
        if (event.shiftKey) {
          options.relativeSpeed = 5
        } else {
          options.relativeSpeed = 1
        }
        deltaX          = mouseevent.x-x
        deltaY          = mouseevent.y-y
        // Do not move if not enough movement
        if (Math.abs(deltaX) > 30 || Math.abs(deltaY) > 30) {
          deltaX *= options.relativeSpeed
          deltaY *= options.relativeSpeed
          options.resourcesOffset = resourcesOffset + Math.floor(deltaY/barWidth)
          options.startDate       = startDate + resolution*deltaX/resolutionWidth
          self.display(options)
          mouseevent = newCoordinates;
        }
      }

    } else {
      var bar, tooltip;
      // Iterate through all displayed bars to find if there is one on which the user is hovering
      for (var i=0; i < bars.length; i++) {
        bar = bars[i]
        if (x >= bar.upper_left_coordinates.x && y >= bar.upper_left_coordinates.y && x <= bar.bottom_right_coordinates.x && y <= bar.bottom_right_coordinates.y) {
          tooltip = {x: x, y: y, jobIndex: bar.job_index, tooltip: jobs[bar.job_index].tooltip}
          break;
        } else {
          tooltip = null
        }
      }
    
      if (tooltip) {
        // Draw the tooltip only if:
        // * there were no last tooltip; or
        // * the jobId of the job associated to the tooltip is different than the job id associated with the last tooltip; or
        // * the user's mouse pointer is going far away from where the last tooltip was drawn
        if (!lastTooltip || (jobs[tooltip.jobIndex][jobId] != jobs[lastTooltip.jobIndex][jobId]) || (Math.abs(lastTooltip.x-x) > 30 || Math.abs(lastTooltip.y-y) > 30)) {
          // Redraw the canvas
          self.display()
          // Draw the tooltip
          var offsetX = 0;
          var offsetY = 0;
          if (tooltip.x+tooltipWidth > canvas.width) {
            offsetX = -tooltipWidth
          }
          if (tooltip.y+tooltipHeight > canvas.height) {
            offsetY = -tooltipHeight
          }
    			var cornerRadius = 5;
          ctx.save()
    			ctx.translate(tooltip.x+offsetX, tooltip.y+offsetY);
    			// Draw rounded rectangle
          ctx.fillStyle = "rgb(255,255,255)"
          ctx.lineWidth = 2
          ctx.lineJoin = "round"

          ctx.beginPath();  
          ctx.moveTo(0,cornerRadius);  
          ctx.lineTo(0,tooltipHeight-cornerRadius);  
          ctx.quadraticCurveTo(0,tooltipHeight,cornerRadius,tooltipHeight);  
          ctx.lineTo(tooltipWidth-cornerRadius,tooltipHeight);  
          ctx.quadraticCurveTo(tooltipWidth,tooltipHeight,tooltipWidth,tooltipHeight-cornerRadius);  
          ctx.lineTo(tooltipWidth,cornerRadius);  
          ctx.quadraticCurveTo(tooltipWidth,0,tooltipWidth-cornerRadius,0);  
          ctx.lineTo(cornerRadius,0);  
          ctx.quadraticCurveTo(0,0,0,cornerRadius);  
          ctx.fill();
          ctx.stroke()
          ctx.restore()
          // Draw text inside tooltip rounded rectangle
          ctx.save()
    			ctx.translate(tooltip.x+offsetX+cornerRadius*2, tooltip.y+offsetY+cornerRadius*2);
          ctx.font = 'normal 800 12px Monaco, Courier New, sans-serif';
          ctx.fillText(tooltip.tooltip.title, 0, cornerRadius, tooltipWidth)
          ctx.font = 'normal 400 10px Monaco, Courier New, sans-serif';
          ctx.translate(0, 25)
          // Iterate over lines of content
          for (var i=0; i < tooltip.tooltip.content.length; i++) {
            ctx.fillText(tooltip.tooltip.content[i], 0, i*14, tooltipWidth)
          }
          ctx.restore()
          lastTooltip = tooltip;
        }
      } else {
        if (lastTooltip) {
          // Redraw the canvas to erase the last tooltip
          self.display()
          lastTooltip = null;
        }
      }
    }  
    return false;
  }).mousedown(function(event) {
    mouseevent = mouseXY(event);
    mousedown = true;
    resizing = (mouseevent.x > canvas.width-resizingCornerRadius && mouseevent.y > canvas.height-resizingCornerRadius)
    return false;
  }).mouseup(function(event) {
    mouseevent = null;
    mousedown = false;
    resizing = false
  }).mouseout(function(event) {
    if (lastTooltip) {
      self.display()
    }
    lastTooltip = null;
    if (!resizing) {
      mousedown = false;
      mouseevent = null;
    }
  }).dblclick(function(event) {
    var options = {}
    if (event.shiftKey) {
      // zoom out
      options.resolution = resolution*2
    } else {
      // zoom in
      options.resolution = resolution/2
    }
    self.display(options)
    return false;
  }).keypress(function(event) {
    return false;
  });
  
  $(document).mousemove(function(event) {
    if (resizing) {
      var coordinates = mouseXY(event)
      self.display({
        width: coordinates.x+resizingCornerRadius,
        height: coordinates.y+resizingCornerRadius
      })
    }
  })
  
  // $(document).keydown(function(event) {
  // })
  

  
  // Display the jobs, resources, gutter on the canvas
  Gantt.prototype.display = function(options) {
    self.setOptions(options)
    if (height != canvas.height || width != canvas.width) {
      self.resize(width, height)
    }
    bars = []
    jobsToDisplay = filterJobs({
      startDate: startDate, 
      endDate: endDate, 
      resourcesRange: [resourcesOffset, Math.min(resources.length-1, resourcesOffset+itemsInResourcesPanel)]
    })
    ctx.save();
    ctx.font = "10px Monaco, sans-serif"
    ctx.clearRect(0, 0, canvas.width, canvas.height)
    ctx.fillRect(0, 0, canvas.width, gutterHeight)
    self.draw_resources()
    self.draw_jobs()
    ctx.strokeRect(0, gutterHeight, resourcesPanelWidth, canvas.height-gutterHeight)
    ctx.strokeRect(resourcesPanelWidth, gutterHeight, jobsPanelWidth, canvas.height-gutterHeight)
    self.draw_gutter()
    self.draw_now()
    ctx.restore();
    displayCount += 1;
    return self;
  }
  
  this.draw_now = function() {
    if (now >= startDate && now < endDate) {
      ctx.save()
      ctx.lineWidth = 1
      ctx.strokeStyle = "red"
      var x = resourcesPanelWidth+(now-startDate)/resolution*resolutionWidth
      ctx.beginPath()
      ctx.moveTo(x, gutterHeight+1)
      ctx.lineTo(x, canvas.height-1)
      ctx.closePath()
      ctx.stroke()
      ctx.restore()
    }
  }
  
  this.resize = function(width, height) {
    canvas.height = height;
    canvas.width   = width;
    self.display()
    return self;
  }
  
  this.draw_resources = function(callback) {
    var resource;
    ctx.save()
    ctx.lineWidth = 0.1
    ctx.translate(0, gutterHeight)
    ctx.textAlign="start"
    ctx.font = "bold 10px verdana, sans-serif"
    ctx.textBaseline = "middle"
    var limit = Math.min(resourcesOffset+itemsInResourcesPanel, resources.length-1)
    for (var i = resourcesOffset; i <= limit; i++) {
      resource = resources[i]
      // Draw a line between each resource line
      ctx.beginPath()
      ctx.fillStyle = "#eee"
      ctx.moveTo(0, 0)
      ctx.lineTo(canvas.width-1, 0)
      ctx.closePath()
      ctx.stroke()
      // Fill rectangles with colors
      ctx.fillStyle = (i%2 == 0) ? "#f0f0ff" : "#dfdff2"
      ctx.fillRect(0, 0, resourcesPanelWidth, barWidth)
      // Draw resource name
      ctx.fillStyle = "#333"
      ctx.fillText(resource.id, 5, barWidth/2, resourcesPanelWidth-5)
      
      if (resource.enabled) {
        ctx.fillStyle = (i%2 == 0) ? "#f5f5ff" : "#f0f0ff"
      } else {
        ctx.fillStyle = "red"
      }
      ctx.fillRect(resourcesPanelWidth+1, 0, jobsPanelWidth, barWidth)
      ctx.translate(0, barWidth)
    }
    ctx.restore()
  }
  
  this.draw_jobs = function() {
    var resource, job, y, time_offset, job_width, x, text, textWidth;
    var jobsToDisplayLength = jobsToDisplay.length
    ctx.save()
    ctx.textAlign    = "start"
    ctx.textBaseline = "middle"
    ctx.translate(resourcesPanelWidth, gutterHeight)
    for (var i=0; i<jobsToDisplayLength; i++) {
      ctx.save()
      job = jobs[jobsToDisplay[i]]

      resource = resources[job.resourceIndex]
      y = (job.resourceIndex-resourcesOffset)*barWidth
      time_offset = (job.from-startDate)/resolution
      job_width = resolutionWidth*(job.to-job.from)/resolution

      if (time_offset < 0) {
        job_width   += time_offset*resolutionWidth
        time_offset = 0
      }
      
      if ((job_width+time_offset*resolutionWidth) > jobsPanelWidth) {
        job_width += (jobsPanelWidth-(job_width+time_offset*resolutionWidth))
      }
      x = time_offset*resolutionWidth
      if (!resource.enabled) {
        ctx.globalAlpha = 0.3
      }
      ctx.fillStyle = jobColors[job[jobId]];
      ctx.fillRect(x, y+barSpace, job_width, barWidth-barSpace)
      // console.log("batch_id="+job[jobId]+", job_width="+job_width+", x="+x)
      bars.push({
        upper_left_coordinates: {x: x+resourcesPanelWidth, y: y+gutterHeight},
        bottom_right_coordinates: {x: x+resourcesPanelWidth+job_width, y: y+gutterHeight+barWidth},
        job_index: jobsToDisplay[i]
      })

      ctx.fillStyle    = "rgb(0,0,0)"
      text = job[jobId]+" - "+job.user
      textWidth = ctx.measureText(text).width
      if (textWidth <= job_width) {
        ctx.fillText(text, x+job_width/2-textWidth/2, y+barWidth/2)
      }
      ctx.restore()
    }
    ctx.restore()
  }
  
  // Generates a random color
  function getColor() {
      var rgb = [];
      for (var i = 0; i < 3; i++) {
          rgb[i] = Math.round(100 * Math.random() + 155) ; // [155-255] = lighter colors
      }
      return 'rgb(' + rgb.join(',') + ')';
  }
  
  // Draw the legend
  this.draw_gutter = function() {
    ctx.save()
    var y = 0;
    $.each(bands, function(band_index, band) {
      var adjustedResolution = resolution*band.relativeResolution
      var firstRoundDate = getFirstRoundDate(adjustedResolution, startDate)
      var first_round_date_pixels_offset = (firstRoundDate.getTime()-startDate)/resolution*resolutionWidth
      var bandHeight = gutterHeight*band.relativeHeight
      ctx.strokeStyle = "rgb(255,255,255)"
      ctx.fillStyle = band.backgroundColor || "rgb(17,17,17)"
      ctx.fillRect(0, y, canvas.width, bandHeight)
      ctx.save()
      ctx.translate(resourcesPanelWidth, 0)
      var numberOfTicks = Math.ceil(jobsPanelWidth/(resolutionWidth*band.relativeResolution))
      for (var i=0; i < numberOfTicks; i++) {
        var x         = i*(band.relativeResolution*resolutionWidth)+first_round_date_pixels_offset
        var text      = humanDate(resolution*band.relativeResolution, firstRoundDate, band_index)
        var textWidth = ctx.measureText(text).width
        ctx.fillStyle = "rgb(255,255,255)"
        ctx.font      = "600 9px arial"
        ctx.textAlign = "center"
        ctx.fillText(text, x, y+2*bandHeight/3-4)
        ctx.beginPath()
        ctx.moveTo(x, y+bandHeight-bandHeight/3)
        ctx.lineTo(x, y+bandHeight+1)
        ctx.closePath()
        ctx.stroke()
        firstRoundDate.setTime(firstRoundDate.getTime()+(adjustedResolution))
      }
      y += bandHeight
      ctx.restore()
    })
    ctx.restore()
  }
  
  // TODO: make it overwritable
  var monthNames = new Array("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec");
  
  // Returns the closest date
  // TODO: clean up
  function getFirstRoundDate(resolution, date) {
    var firstRoundDate = new Date(date)
    if (resolution < 1800000) {                 // less than 30min, return the nearest date divisible per resolution
      firstRoundDate.setTime(Math.ceil(firstRoundDate.getTime()/resolution)*resolution)
    } else if (resolution < 3600000) {          // less than 1hour, return the nearest 10 minutes
      firstRoundDate.setMinutes(firstRoundDate.getMinutes()+10-firstRoundDate.getMinutes()%10)
    } else if (resolution < 24*3600000) {       // less than 1 day, return the full hour
      firstRoundDate.setHours(firstRoundDate.getHours()+1)
      firstRoundDate.setMinutes(0)
      firstRoundDate.setSeconds(0)
    } else if (resolution < 30*24*3600000) {    // less than 1 month, return the next day
      firstRoundDate.setDate(firstRoundDate.getDate()+1)
      firstRoundDate.setHours(0)
      firstRoundDate.setMinutes(0)
      firstRoundDate.setSeconds(0)
    } else if (resolution < 12*30*24*3600000) {
      firstRoundDate.setMonth(firstRoundDate.getMonth()+1)
      firstRoundDate.setDate(1)
      firstRoundDate.setHours(0)
      firstRoundDate.setMinutes(0)
      firstRoundDate.setSeconds(0)
    } else {                                    // return the first month
      firstRoundDate.setMonth(0)
      firstRoundDate.setDate(1)
      firstRoundDate.setHours(0)
      firstRoundDate.setMinutes(0)
      firstRoundDate.setSeconds(0)
    }
    return firstRoundDate;
  }
  
  // Return the correct unit according to the current resolution
  // TODO: clean up
  function humanDate(resolution, date, band_index) {
    var tmp;
    if (resolution < 60000) {             // 1 minute
      tmp = date.getSeconds()
      tmp = (tmp < 10 ? "0" : "") + tmp + "''"
    } else if (resolution < 3600000) {    // 1 hour
      tmp = date.getMinutes()
      tmp = (tmp < 10 ? "0" : "") + tmp + "'"
      if (band_index == 0) {  tmp = monthNames[date.getMonth()]+" "+date.getDate()+"th "+date.getFullYear() + ", " + date.getHours()+"h "+tmp}
    } else if (resolution < 24*3600000) { // 1 day
      tmp = date.getHours()
      tmp = tmp + "h"
      if (band_index == 0) {  tmp = monthNames[date.getMonth()]+" "+date.getDate()+"th "+" "+date.getFullYear() + ", " + tmp }
    } else if (resolution < 30*24*3600000) {
      tmp = date.getDate();
      tmp = tmp + "th"
      if (band_index == 0) {  tmp = monthNames[date.getMonth()]+" "+tmp+" "+date.getFullYear() }
    } else {
      tmp = monthNames[date.getMonth()];
    }
    return tmp
  }
}
