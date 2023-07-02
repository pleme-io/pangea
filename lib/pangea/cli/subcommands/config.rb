require %(pangea/cli/subcommands/pangea)

class ConfigCommand < PangeaCommand
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
