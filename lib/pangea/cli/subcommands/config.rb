require %(pangea/cli/subcommands/pangea)
require %(pangea/synthesizer/config)
require %(pangea/cli/config)

class ConfigCommand < PangeaCommand
  usage do
    desc %(manage configuration)
    program %(pangea)
    command %(config)
  end

  argument :subcommand do
    desc %(subcommand for config)
    required
  end

  def help
    <<~HELP
    Usage: pangea config [OPTIONS] SUBCOMMAND

    Arguments:
      SUBCOMMAND  subcommand for config

    Options:
      -h, --help    Print usage
    HELP
  end

  def run(argv)
    case argv[1].to_s
    when %(show)
      config = Config.resolve_configurations
      puts config
    end
  end
end
