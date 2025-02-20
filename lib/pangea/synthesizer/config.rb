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

  def synthesize(content, ext)
    case ext.to_s
    when %(yaml), %(yml)
      translation[:template] = YAML.safe_load(content)
    when %(toml)
      translation[:template] = TomlRB.parse(content)
    when %(json)
      translation[:template] = JSON.parse(content)
    when %(rb)
      if block_given?
        yield
      else
        instance_eval(content)
      end
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
