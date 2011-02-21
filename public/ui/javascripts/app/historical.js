
var http = new Http();

function jsonConverter( items ) {
  output = {  properties:{}, 
              types:{"version": {"pluralLabel": "versions"}}, 
              items:[]
            }
  $.each(items, function(i, version) {
    console.log(version)
    version['label'] = version.message//.substring(0, 20)
    version['author'] = version.author.replace(' <>', '')
    version['date_iso'] = new Date(Date.parse(version['date'])).toISOString()
    if ((i = version['message'].indexOf("]",0)) != -1) {
      version['tags'] = version['message'].substring(1,i).toLowerCase().split(",");
    }
    output['items'].push(version)
  })
  return output;
}

$(document).ready(function() {
  
  http.get("../../sites/versions?limit=10000", {
    before: function() {
      window.database = Exhibit.Database.create();
      window.exhibit = Exhibit.create();
      window.exhibit.configureFromDOM();
      Exhibit.UI.showBusyIndicator();
    },
    ok: function(data) {
      window.database.loadData(jsonConverter(data.items));
    },
    error: function(xhr, status, error) {
      $.jGrowl("Error when trying to get the historical data of Grid5000.");
    },
    after: function() {
      Exhibit.UI.hideBusyIndicator();
    }
  })

});
