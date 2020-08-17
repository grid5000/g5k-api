# coding: utf-8
# Monkey patching Ruby's Hash class

# Extend Hash with helper methods needed to convert input data files to ruby Hash
class Hash
  # Recursively merge this Hash with another (ie. merge nested hash)
  # Returns a new hash containing the contents of other_hash and the contents of hash. The value for entries with duplicate keys will be that of other_hash:
  # a = {"key": "value_a"}
  # b = {"key": "value_b"}
  # a.deep_merge(b) -> {:key=>"value_b"}
  # b.deep_merge(a) -> {:key=>"value_a"}
  def deep_merge(other_hash)
    merger = proc { |_key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
    self.merge(other_hash, &merger)
  end

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
