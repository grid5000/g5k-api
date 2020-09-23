# Monkey patching Ruby's Hash class

# Extend Hash with helper methods needed to convert input data files to ruby Hash
class Hash
  # Add an element composed of nested Hashes made from elements found in "array" argument
  # i.e.: from_array([a, b, c],"foo") -> {a: {b: {c: "foo"}}}
  def self.from_array(array, value)
    return array.reverse.inject(value) { |a, n| { n => a } }
  end
end

def rec_sort(h)
  case h
  when Array
    h.map{|v| rec_sort(v)}#.sort_by!{|v| (v.to_s rescue nil) }
  when Hash
    Hash[Hash[h.map{|k,v| [rec_sort(k),rec_sort(v)]}].sort_by{|k,v| [(k.to_s rescue nil), (v.to_s rescue nil)]}]
  else
    h
  end
end
