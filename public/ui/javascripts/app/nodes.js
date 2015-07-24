function jsonConverter(allNodes){
	output={
		properties:{
			processor_clock_speed:{valueType:"number"},
      processor_cache_l1d:{valueType:"number"},
      processor_cache_l1i:{valueType:"number"},
      processor_cache_l2:{valueType:"number"},
      main_memory_ram_size:{valueType:"number"},
      storage_devices_0_size:{valueType:"number"},
      network_adapters_0_rate:{valueType:"number"},
      network_adapters_1_rate:{valueType:"number"},
      network_adapters_2_rate:{valueType:"number"},
      network_adapters_3_rate:{valueType:"number"},
			architecture_smt_size:{valueType:"number"},
			max_storage_capacity_device:{valueType:"number"},
			storage_capacity_node:{valueType:"number"}
		},
		types:{node:{pluralLabel:"nodes"}},
		items:[]};
	$.each(allNodes,function(node_index,item){
		var c=$.grep(item.links,function(f,e){return f.rel=="self"})[0];
		splitted_uri=c.href.split("/");
		item.id=item.uid;
		item.label=item.uid;
		item.site=splitted_uri[4];
		item.cluster=splitted_uri[6];
		$.each(item.network_adapters, function(net_index,network_adapter) {
      if (!network_adapter.management && (network_adapter.enabled || network_adapter.mountable) ) {
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
			}
		});
		$.each(item.storage_devices, function(disk_index,storage_device) {
      create_and_increment(item,'nb_storage_devices');
      create_and_increment(item,'nb_storage_devices_'+storage_device["storage"]);
      create_and_increment(item,'nb_storage_devices_'+(storage_device["interface"].replace(' ','_')));
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
		delete item.links;
		output.items.push(flatten(item,function(item,property,value){
			switch(property){
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
			}}))});
	return output
}

var sites_already_loaded=0;
var sites_count=0;
var clusters_already_loaded=0;
var clusters_count=0;
var all_nodes=[];

$(document).ready(function(){
	$.ajax({url:"../../sites",
					dataType:"json",
					type:"GET",
					cache:true,
					ifModified:true,
					global:false,
					beforeSend:function(){
						Exhibit.UI.showBusyIndicator()},
					error:function(a,c,b){
						$.jGrowl("Error when trying to get the description of Grid5000.")},
					success:function(sites,status){
						$.each(sites.items,function(index,site){
							sites_count+=1;
							var site_clusters=$.grep(site.links,function(link,index){return link.rel=="clusters"})[0];
							$.ajax({url:site_clusters.href+"?version="+site.version,
											dataType:"json",
											type:"GET",
											cache:true,
											ifModified:true,
											global:false,
											success:function(clusters,status){
												$.each(clusters.items,function(index,cluster){
													clusters_count+=1;
													var cluster_nodes=$.grep(cluster.links,function(m,l){return m.rel=="nodes"})[0];
													$.ajax({url:cluster_nodes.href+"?version="+cluster.version,
																	dataType:"json",
																	type:"GET",
																	cache:true,
																	ifModified:true,
																	global:false,
																	success:function(nodes,i){
																		$.merge(all_nodes,nodes.items)},
																	complete:function(l,i){
																		clusters_already_loaded+=1;
																		if(sites_already_loaded==sites_count&&clusters_already_loaded==clusters_count){
																				window.database=Exhibit.Database.create();
																			window.database.loadData(jsonConverter(all_nodes));
																				window.exhibit=Exhibit.create();
																				window.exhibit.configureFromDOM();
																			Exhibit.UI.hideBusyIndicator()}}})})},
											error:function(f,h,g){
												$.jGrowl("Error when trying to get the description of the "+c.uid+" clusters.")},
											complete:function(f,g){sites_already_loaded+=1}})
						})
							}})});
