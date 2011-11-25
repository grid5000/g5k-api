$(document).ready(function() {
  var widgets_to_display = [
    {id: 'status', refresh:300000, total: true}
  ]
  Widget.display($.extend({id: 'twitter', refresh: 600000, limit: 6}, {container: '#news', api_base_uri: ".."}))
  $.each(widgets_to_display, function(i, widget_to_display) {
    var container_id = 'widget-'+widget_to_display.id;
    $("#widgets").append('<li id="'+container_id+'" class="widget"></li>');
    Widget.display($.extend(widget_to_display, {container: '#'+container_id, api_base_uri: ".."}))
  })
});
