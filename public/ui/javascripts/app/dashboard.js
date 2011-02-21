console.log("hre")
$(document).ready(function() {
  var widgets_to_display = [
    {id: 'status', refresh:300000, total: true}
  ]
  console.log(widgets_to_display)
  Widget.display($.extend({id: 'twitter', refresh: 600000, limit: 6}, {container: '#news', api_base_uri: ".."}))
   console.log(widgets_to_display)
  $.each(widgets_to_display, function(i, widget_to_display) {
    var container_id = 'widget-'+widget_to_display.id;
    $("#widgets").append('<li id="'+container_id+'" class="widget"></li>');
     console.log(widget_to_display)
    Widget.display($.extend(widget_to_display, {container: '#'+container_id, api_base_uri: ".."}))
    console.log("error")
  })
});
