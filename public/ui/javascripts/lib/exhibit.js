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

function create_and_increment(item, property) {
    if (property in item) {
	item[property]++;
    } else {
	item[property]=1 ;
    }
}

var KIBI = 1024;
var KILO = 1000;
var MEBI = 1024*1024;
var MEGA = 1000*1000;
var GIBI = MEBI*1024;
var GIGA = MEGA*1000;

/*
 * Function that receives a node description from the API
 * add creates any additional attributes required for
 * display
 * 
 */
function nodeConverter( item ) {
  item.label = item.uid;
  item.processor_clock_speed = 0;
  _.each(item.network_adapters, function(network_adapter) {
    if (!network_adapter.management && (network_adapter.enabled || network_adapter.mountable)) {
		  if ('interface' in network_adapter) {
	switch(network_adapter.interface.toLowerCase()) {
	case "ethernet":
	    create_and_increment(item, 'nb_ethernet') ;
            switch (network_adapter.rate) {
	    case 10000000000:
		create_and_increment(item,'nb_10G_ethernet');
		break;
	    case 1000000000:
		create_and_increment(item,'nb_1G_ethernet');
		break;
	    } 
	    break;
	case "infiniband":
	    create_and_increment(item, 'nb_infiniband') ;
            switch (network_adapter.rate) {
	    case 10000000000:
		create_and_increment(item,'nb_infiniband_SDR')
		break;
	    case 20000000000:
		create_and_increment(item,'nb_infiniband_DDR')
		break;
	    case 40000000000:
		create_and_increment(item,'nb_infiniband_QDR')
		break;
	    case 80000000000:
		create_and_increment(item,'nb_infiniband_FDR')
		break;
	    }
	    break;
	case "myrinet":
	    create_and_increment(item, 'nb_myrinet') ;
	    break;
	} 
    } else {
			console.log("nodeConverter could not parse network_adapter description for" + network_adapter.network_address);
		}
		}
  });
  _.each(item.storage_devices, function(storage_device) {
      create_and_increment(item,'nb_storage_devices');
      create_and_increment(item,'nb_storage_devices_'+storage_device["storage"]);
			if ('interface' in storage_device) {
					create_and_increment(item,'nb_storage_devices_'+(storage_device["interface"].replace(' ','_')));
			} else {
					console.log("nodeConverter could not parse (interface missing) storage_device description for" + item.label);
			}
      var capacity=parseInt(("B"+storage_device["size"]).replace('B',''))*GIBI/GIGA/GIGA ;
      if ('max_storage_capacity_device' in item) {
	  if (item['max_storage_capacity_device'] < capacity) {
	      item['max_storage_capacity_device']=capacity.toFixed(0);
	  }
      } else {
	  item['max_storage_capacity_device']=capacity.toFixed(0);
      }	 
      if ('storage_capacity_node' in item) {
	  item['storage_capacity_node']+=capacity;
      } else {
	  item['storage_capacity_node']=capacity ;
      }	 
  });
  if ('storage_capacity_node' in item) {
    item['storage_capacity_node']=item['storage_capacity_node'].toFixed(0);
  }
  delete item['links']
  return flatten(item, function(item, property, value) {
    switch(property) {
      case "network_adapters_0_rate":
        return (value/GIGA).toFixed(0);
      case "network_adapters_1_rate":
        return (value/GIGA).toFixed(0);
      case "network_adapters_2_rate":
        return (value/GIGA).toFixed(0);
      case "network_adapters_3_rate":
        return (value/GIGA).toFixed(0);
      case "storage_devices_0_size":
	//avoid bug #6132
	value=("B"+value).replace('B','');
        return (parseInt(value)*GIBI/GIGA/GIGA).toFixed(0);
      case "architecture_smt_size":
	return parseInt(value) ;
      case "main_memory_ram_size":
        return (parseInt(value)/MEBI);
      case "processor_clock_speed":
        return parseFloat(value)/GIGA.toFixed(2);
      case "processor_cache_l1d":
      case "processor_cache_l1i":
        if (value) {  return (value/KIBI);  } else {  return value;  }
      case "processor_cache_l2":
        if (value) {  return (value/KIBI);  } else {  return value;  }
      default:
        return value;
    }
  })
}
