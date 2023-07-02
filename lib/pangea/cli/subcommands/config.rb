require_relative %(./pangea)

class ConfigCommand < StitchesCommand
  usage do
    desc %(manage configuration)
    program %(pangea)
    command %(config)
  end

  def run(argv)
    parse(argv)
    print help
  end
end
