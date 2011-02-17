Helper = {
  idFor: function(args, prefix) {
    var id = args.join("-")
    return prefix ? (prefix + id) : id
  },
  arrayParam: function(value, delimiter) {    
    switch(typeof(value)) {
      case "string":
        if (value.length == 0) {
          return []
        } else {
          return value.split(delimiter || ",")
        }
      break;
      case "boolean":
        return []
      break;
      case "object":
        return value
      break;
      default:
        return []
      break;
    }
  }
}