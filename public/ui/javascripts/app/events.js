var http = new Http();

var facets = []
var selected_facets = [];
function display_selected_facets(selected_facets) {
  $("#facets li a").removeClass("highlighted");
  if (selected_facets.length == 0) {
    $("#events tbody tr").fadeIn(function() {
      $(this).attr('style', 'display: normal')
    });
  } else {
    $("#events tbody tr").removeClass("selected");
    $.each(selected_facets, function(i, facet) {
      $("#facets li a[href='#"+facet+"']").addClass("highlighted");
      $("#events tbody tr."+facet).addClass("selected");
    });
    $("#events tbody tr:not(.selected)").fadeOut();
    $("#events tbody tr.selected").fadeIn(function() {
      $(this).attr('style', 'display: normal')
    });
  }
}

var template = "Bonjour,\n\n"+
  "Une session de maintenance est programmée du {{start_date}} au {{end_date}}.\n"+
  "Motif: {{title}}\n\n"+
  "***** DESCRIPTION GOES HERE\n\n"+
  "Pour suivre cette opération, vous pouvez vous référer à <{{link}}>, et vous inscrire en CC du bug si vous désirez être informé de la fin de l'opération de maintenance qui ne sera pas annoncée sur cette liste.\n\n"+
  "Des informations à jour sont aussi disponibles sur <https://api.grid5000.fr/ui/events.html>.\n\n"+
  "Merci de votre compréhension,\n\n"+
  "support-staff@lists.grid5000.fr <mailto:support-staff@lists.grid5000.fr>\n\n"+
  "==================\n\n"+
  "Hello,\n\n"+
  "A maintenance session is scheduled from {{start_date}} to {{end_date}}.\n"+
  "Reason: {{title}}\n\n"+
  "***** DESCRIPTION GOES HERE\n\n"+
  "To follow the progress of this maintenance operation, please refer to <{{link}}>, and add yourself as CC of this bug if you want to be informed of the end of the operation, as it will not be announced on this list.\n\n"+
  "Up to date information can also be found at <https://api.grid5000.fr/ui/events.html>.\n\n"+
  "Thanks for your comprehension,\n\n"+
  "support-staff@lists.grid5000.fr <mailto:support-staff@lists.grid5000.fr>";

$(document).ready(function() {
  $("a[rel*=facebox]").live('click', function(event) {
    var row = $(event.target).parent().parent().parent();
    var view = {
      start_date:   $('.starts_at', row).html(),
      end_date:     $('.ends_at', row).html(),
      title:        $('.title', row).html(),
      link:         $('.link', row).attr('href')
    }
    $.facebox('<textarea cols="60" rows="20">'+Mustache.to_html(template, view)+'</textarea>')
    return false;
  })
  $("#facets li a").live("click", function(event) {
    target = $(event.target);
    var facet = target.html();
    var index = $.inArray(facet, selected_facets)
    if (index == -1) {
      selected_facets.push(facet);
    } else {
      selected_facets.splice(index, 1)
    }
    display_selected_facets(selected_facets);
    window.location.hash = '#'+selected_facets.join(",");
    return false;
  });
  
  var feeds = {
    'current-events': {title: 'In progress', statuses: ['REOPENED','ASSIGNED']},
    'planned-events': {title: 'Planned', statuses: ['NEW','UNCONFIRMED']},
    'past-events': {title: 'Done', statuses: ['VERIFIED','RESOLVED', 'CLOSED']}
  }
  var feed_lookup_by_status = {}
  for (var feed_id in feeds) {
    var html = '<h2>'+feeds[feed_id].title+'</h2>'+
      '<div id="'+feed_id+'" style="display: none"><table cellspacing=0>'+
        '<thead>'+
          '<th width="35%">Description</th><th width="14%">Tags</th><th width="15%">Beginning</th><th width="15%">Ending</th><th width="15%">Last update</th><th width="6%">Bug</th>'+
        '</thead>'+
        '<tbody>'+
        '</tbody>'+
      '</table></div>';
    $("#events").append(html)
    $.each(feeds[feed_id].statuses, function(i, status) {
      feed_lookup_by_status[status] = feed_id;
    });
  }
  $.ajax({
    url: "../events.json", 
    dataType: "json",
    type: "GET", 
    cache: true, 
    beforeSend: function() {
      $("body").addClass("loading");
    },
    success: function(events, status) {
      $.each(events, function(i, event) {
        var start_date = event.start_date ? new Date(event.start_date*1000) : null
        var end_date = event.end_date ? new Date(event.end_date*1000) : null
        var updated = new Date(event.updated*1000)
        var component = event.component.replace("@","").toUpperCase().replace(/\s/, "_");
        var tags = $.map(event.tags, function(event, i) {
          return event.toUpperCase().replace(/\s/, "_");
        });
        if ($.inArray(component, tags) == -1) { tags.push(component);  }
        $.each(tags, function(i, event) {
          if ($.inArray(event, facets) == -1) { facets.push(event);  }
        })
        var link = 'http://www.grid5000.fr/bugzilla/show_bug.cgi?id='+event.id;
        var link_to_mail_to_platform = ""
        if ($.inArray("MAINTENANCE", tags) != -1 && feed_lookup_by_status[event.status] != 'past-events') { 
          link_to_mail_to_platform = '<br /><a href="#mail_to_platform_for_event_'+event.id+'" rel="facebox"><img src="./images/email-icon.png" border=0 /></a>';
        }
        var row = '<tr class="'+tags.join(" ")+'" id="event_'+event.id+'">'+
          '<td class="text title">'+event.title+'</td>'+
          '<td class="center tags">'+tags.join(", ")+'</td>'+
          '<td class="center date starts_at">'+(start_date || "?").toString()+'</td>'+
          '<td class="center date ends_at">'+(end_date || "?").toString()+'</td>'+
          // '<td class="center severity">'+event.severity+'</td>'+
          // '<td class="center resolution">'+(event.resolution || "-")+'</td>'+
          '<td class="date center">'+updated.toString()+'</td>'+
          '<td class="center"><a href="'+link+'" class="link">'+event.id+'</a>'+link_to_mail_to_platform+'</td>'+
          '</tr>';
        $("tbody", $("#"+feed_lookup_by_status[event.status])).append(row);
      });
    },
    error: function(XMLHttpRequest, textStatus, errorThrown) {
      $("#events").prepend("Error when trying to get the events: "+XMLHttpRequest.status);
    },
    complete: function(xOptions, textStatus) {
      $("tr:odd", $("#events tbody")).addClass("odd");
      $("body").removeClass("loading");
      $("#facets ul").html('')
      $.each(facets.sort(), function(i, facet) {
        $("#facets ul").append('<li class="facet"><a href="#'+facet+'">'+facet+'</a></li>')
      })
      if (matches = window.location.href.match(/#(.+)/)) {
        selected_facets = matches[1].split(",")
      }
      $("#events div").slideDown();
      display_selected_facets(selected_facets)
    }
  });

});