function expand(item, items, key1, value1, accepted_types, callback) {
  // var uri_regexp = /^\//;
  if ( value1 instanceof Object ) {    
    for(var key2 in value1) {
      var value2 = value1[key2];
      // if it has links, this is a new item
      if ((value2 instanceof Object) && value2.links) {
        var uri = null;
        $.each(value2.links, function(i, link) {
          if (link.rel == 'self') { uri = '..'+link.href; }
        });
        item = {label: key2, id: uri, uri: uri}
        delete value2.links
        expand(item, items, "object", value2, accepted_types, callback);
        if(item.type && $.inArray(item.type, accepted_types) != -1) {
          items.push(item);
        }
      } else {
        if (key1 == "object" || key1 == null) {
          hash_key = key2;
        } else {
          hash_key = key1+'_'+key2;
        }
        expand(item, items, hash_key, value2, accepted_types, callback);
      }
    }
  } else {
    if(callback) {
      item[key1] = callback(item, key1, value1)
    } else {
      item[key1] = value1;
    }
  }
  return;
}

function flatten(item, callback) {  
  if (item instanceof Object) {
    for (var key1 in item) {
      var value1 = item[key1];
      if (value1 instanceof Object) {
        value1 = flatten(value1)
        for (var key2 in value1) {
          var value2 = value1[key2];
          hash_key = key1+'_'+key2;
          if (callback) {
            item[hash_key] = callback(item, hash_key, flatten(value2));
          } else {
            item[hash_key] = flatten(value2);
          }
          delete item[key1];
        }
      }
    }
  }
  return item;
}



var KIBI = 1024;
var KILO = 1000;
var MEBI = 1024*1024;
var MEGA = 1000*1000;
var GIBI = MEBI*1024;
var GIGA = MEGA*1000;
