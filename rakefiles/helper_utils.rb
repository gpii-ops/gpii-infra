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

class InfraUtils

  def self.merge_yaml(a,b)
    YAML.dump(recurse_merge_hash(YAML.load(a), YAML.load(b)))
  end

  def self.recurse_merge_hash(a,b)
    a.merge(b) do |_,x,y|
      (x.is_a?(Hash) && y.is_a?(Hash)) ? recurse_merge_hash(x,y) : y
    end
  end

end

