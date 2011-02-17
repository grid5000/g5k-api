/**
 * This class abstracts asynchronous HTTP requests
 */

function Http(options) {
  this.options = options || {}
  this.count = 0;
}

Http.prototype.setup = function(options) {
  var params = {
    cache: true,
    timeout: 10000,
    dataType: "json", 
    global: true,
    ifModified: false,
  }
  
  $.extend(params, this.options, options)
  
  params.beforeSend = params.before || function(xhr) {};
  params.complete   = params.after || function(xhr, textStatus) {};
  params.error      = params.ko || function(xhr, textStatus, errorThrown) {};
  params.success    = params.ok || function(data, textStatus, xhr) {};
  
  return params;
}

Http.prototype.get = function(url, options) {
  var params  = this.setup(options)
  params.type = "GET";
  params.url  = url;
  
  $.ajax(params);
}

Http.prototype.del = function(url, options) {
  var params  = this.setup(options)
  params.type = "DELETE";
  params.url  = url;
  
  $.ajax(params);
}

Http.prototype.post = function(url, data, options) {
  var params  = this.setup(options)
  params.type = "POST";
  params.url  = url;
  params.data = data;

  $.ajax(params);
}

Http.prototype.linkTo = function(links, title_or_rel) {
  var link = _.detect(links, function(link) {
    return (link.rel == title_or_rel || link.title == title_or_rel)
  })
  return link ? link.href : null;
}
