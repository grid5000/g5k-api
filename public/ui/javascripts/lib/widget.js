Widget = {}
Widget.display = function(options) {
  var options = $.extend({}, options);
  var container = $(options.container);
  container.addClass("widget-"+options.id).addClass("widget");
  container.html('<div class="title"></div><div class="content"></div>').addClass("loading");
  $.ajax({
    url: "./widgets/"+options.id+"/"+options.id+".widget",
    dataType: "jsonp",
    jsonpCallback: options.id.replace("-", "_")+"_widget_callback",
    type: "GET",
    cache: true,
    global: true,
    // dataFilter: function(data) { return JSON.parse(data); },
    success: function(widget, status) {
      if (widget.stylesheet) {
        $("head").append('<link href="./widgets/'+widget.id+'/'+widget.id+'.css" rel="stylesheet" type="text/css"/>')
      }
      $(".title", container).html(widget.title);
      $(".content", container).html("");
      widget.display(container, options);
      // if (options.refresh && options.refresh > 0) {
      //   $(document).everyTime(options.refresh, function(i) {
      //     $(".content", container).html("");
      //     widget.display(container, options);
      //   });
      // }
    }
  });
}
