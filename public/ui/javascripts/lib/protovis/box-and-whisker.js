// http://vis.stanford.edu/protovis/ex/box-and-whisker.html

Plot = function(container, width, height) {
  this.container = container;
  this.width = width;
  this.height = height;
}

Plot.prototype.boxAndWhisker = function(matrix, from, to, resolution, tooltipCallback) {
  if (matrix.length == 0) {
    return false
  }
  // Maximum max of all the timeseries
  var allTimeMax = pv.max(matrix, function(d) {
    return d.max
  })
  
  var w = this.width,
      // h = 300,
      h1 = this.height,
      h2 = 30,
      left = 80,
      x = pv.Scale.linear(matrix, function(e) {
        return e.date
      }).range(0, w-left/2),
      y = pv.Scale.linear(0, allTimeMax).range(0, h2),
      // y = pv.Scale.linear(0, allTimeMax).range(0, h1).nice(),
      s = ((w-left) / ((to-from)/resolution));

  /* Interaction state. Focus scales will have domain set on-render. */
  var i = {x:0, dx:200},
      fx = pv.Scale.linear().range(0, w-left/2),
      fy = pv.Scale.linear().range(0, h1),
      fs = pv.Scale.linear(0, (to-from)*1000).range(s*3, s / 3)

  var vis = new pv.Panel()
      .canvas(this.container.attr('id'))
      .width(w)
      .height(h1+h2+20)
      .left(left)
      .top(10)
      .bottom(20)
      
  
  /* Focus panel (zoomed in). */
  var focus = vis.add(pv.Panel)
    .def("init", function() {
        var d1 = x.invert(i.x),
            d2 = x.invert(i.x + i.dx),
            dd = matrix.slice(
                Math.max(0, pv.search.index(matrix, d1, function(d) {
                  return  d.date
                }) - 1),
                pv.search.index(matrix, d2, function(d) {
                  return d.date
                }) + 1);
        fx.domain(d1, d2);
        fy.domain($(".scale input:checked", this.container).length > 0 ? [0, pv.max(dd, function(d) {
          return d.max
        })] : y.domain());
        return dd;
      })
    .top(0)
    .height(h1);

  /* Add the y-axis rules */
  focus.add(pv.Rule)
      .data(function() {
        return fy.ticks()
      })
      .bottom(fy)
      .strokeStyle(function(d) {
        return (d == 0 || d == allTimeMax) ? "#999" : "#ccc"
      })
    .anchor("left").add(pv.Label)  
      .text(fy.tickFormat);

  /* Add the x-axis rules */
  focus.add(pv.Rule)
       .data(function() {
         return fx.ticks()
        })
       .left(fx)
       .strokeStyle("#eee")
     .anchor("bottom").add(pv.Label)
       .text(fx.tickFormat);

  var boxes = focus.add(pv.Panel)
    .overflow("hidden")

  /* Add a panel for each data point */
  var points = boxes.add(pv.Panel)
    .data(function() {
      return focus.init()
    })
    .left(function(d) {
      return fx(d.date)
    })
    .text(tooltipCallback)
    .event("mouseover", pv.Behavior.tipsy({
      gravity: "w", fade: true, html: true
    }))
    .width(function(d) {
      var domain = fx.domain()
      // return 10
      return fs(domain[1]-domain[0])
      // return 10*fx(d.date)/x(d.date)
    });

  /* Add the experiment id label */
  // points.anchor("bottom").add(pv.Label)
  //     .textBaseline("top")
  //     .text(function(d) {
  //       return d.time
  //     });

  /* Add the range line */
  points.add(pv.Rule)
      .left(function(d) {
        var domain = fx.domain()
        return fs(domain[1]-domain[0])/2
      })
      .bottom(function(d) {
        return fy(d.min)
      })
      .lineWidth(0.5)
      .height(function(d) {
        return fy(d.max) - fy(d.min)
      });

  /* Add the min and max indicators */
  points.add(pv.Rule)
      .data(function(d) {
        return [d.min, d.max]
      })
      .bottom(fy)
      .left(function(d) {
        var domain = fx.domain()
        return fs(domain[1]-domain[0])/4
      })
      .lineWidth(0.5)
      .width(function(d) {
        var domain = fx.domain()
        return fs(domain[1]-domain[0])/2
      });

  /* Add the upper/lower quartile ranges */
  points.add(pv.Bar)
      .bottom(function(d) {
        return fy(d.lq)
      })
      .height(function(d) {
        return fy(d.uq) - fy(d.lq)
      })
      .fillStyle(function(d) {
        return (d.median > (allTimeMax/2)) ? "#aec7e8" : "#ffbb78"
      })
      .strokeStyle("black")
      .lineWidth(0.5)
      .antialias(false);

  /* Add the median line */
  points.add(pv.Rule)
      .lineWidth(0.5)
      .bottom(function(d) {
        return  fy(d.median)
      });

  /* Add the median regression line */
  boxes.add(pv.Line)
      .data(function() {
        return focus.init()
      })
      .interpolate("linear")
      .left(function(d) {
        return fx(d.date) + s
      })
      .bottom(function(d) {
        return fy(d.median)
      })
      .strokeStyle("navy")
      .antialias(true)
      .lineWidth(1);

  // /* Use an invisible panel to capture pan & zoom events. */
  // vis.add(pv.Panel)
  //     .events("all")
  //     .event("mousedown", pv.Behavior.pan())
  //     .event("mousewheel", pv.Behavior.zoom())
  //     .event("pan", transform)
  //     .event("zoom", transform);
  // 
  // /** Update the x- and y-scale domains per the new transform. */
  // function transform() {
  //   var t = this.transform().invert();
  //   console.log("T")
  //   console.log(t)
  //   x.domain(t.x / 2, (t.k + t.x) * 2);
  //   y.domain(t.y / 2, (t.k + t.y) * 2);
  //   vis.render();
  // }

  /* Context panel (zoomed out). */
  var context = vis.add(pv.Panel)
      .bottom(0)
      .height(h2);

  /* X-axis ticks. */
  context.add(pv.Rule)
      .data(x.ticks())
      .left(x)
      .strokeStyle("#eee")
    .anchor("bottom").add(pv.Label)
      .text(x.tickFormat);

  /* Y-axis ticks. */
  context.add(pv.Rule)
      .bottom(0);

  /* Context area chart. */
  context.add(pv.Line)
      .data(matrix)
      .interpolate("linear")
      .left(function(d) {
        return x(d.date) + s
      })
      .bottom(1)
      .height(function(d) {
        return y(d.median)
      })
      .fillStyle("lightsteelblue")
    .anchor("top").add(pv.Line)
      .strokeStyle("steelblue")
      .lineWidth(2);

  /* The selectable, draggable focus region. */
  context.add(pv.Panel)
      .data([i])
      .cursor("crosshair")
      .events("all")
      .event("mousedown", pv.Behavior.select())
      .event("select", focus)
    .add(pv.Bar)
      .left(function(d) {
        return d.x
      })
      .width(function(d) {
        return d.dx
      })
      .fillStyle("rgba(255, 128, 128, .4)")
      .cursor("move")
      .event("mousedown", pv.Behavior.drag())
      .event("drag", focus);


  return vis;
}



