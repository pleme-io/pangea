require %(pangea/cli/subcommands/pangea)

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
    parse(argv)
    puts argv
    print help

    case params[:subcommand].to_s
    when %(show)
      nil
    end

  end
end
