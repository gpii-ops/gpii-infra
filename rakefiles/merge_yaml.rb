require 'yaml'

# Monkey patch the output format of the date to avoid kops failures
#
# YAML module dumps the date in an incorrect format, causing Kops fails
#
# https://github.com/ruby/ruby/blob/ruby_2_4/ext/psych/lib/psych/visitors/yaml_tree.rb#L522-L528
#
Psych::Visitors::YAMLTree.class_eval do
  def format_time time
    time.strftime("%Y-%m-%dT%H:%M:%SZ")
  end
end

class MergeYaml

  def self.merge_yaml(a,b)
    YAML.dump(recurse_merge_hash(YAML.load(a), YAML.load(b)))
  end

  # Merges the hash b in the hash a. The items of the hash b have preference over 
  # the items of the hash a. This function won't remove the child items of the
  # parent item if such parent is found in the hash b, it will add the child items
  # instead.
  # Params:
  # - a: Destination hash
  # - b: Hash to be merged in a hash
  def self.recurse_merge_hash(a,b)
    a.merge(b) do |_,x,y|
      (x.is_a?(Hash) && y.is_a?(Hash)) ? recurse_merge_hash(x,y) : y
    end
  end

end
