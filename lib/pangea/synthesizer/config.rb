require %(pangea/cli/constants)
require %(abstract-synthesizer)
require %(toml-rb)
require %(json)
require %(yaml)

###############################################################################
# read files merge config data and provide a single configuation structure
###############################################################################

class ConfigSynthesizer < AbstractSynthesizer
  include Constants

  def synthesize(content = nil, ext = nil, &block)
    if block_given?
      instance_eval(&block)
    elsif content && ext
      case ext.to_s
      when %(yaml), %(yml)
        translation[:template] = YAML.safe_load(content)
      when %(toml)
        translation[:template] = TomlRB.parse(content)
      when %(json)
        translation[:template] = JSON.parse(content)
      when %(rb)
        instance_eval(content)
      end
    else
      raise ArgumentError, "Either a block or content and extension must be provided."
    end
  end

  def method_missing(method_name, ...)
    abstract_method_missing(
      method_name,
      %i[namespace],
      ...
    )
  end
end