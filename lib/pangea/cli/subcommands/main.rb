require %(pangea/cli/subcommands/pangea)
require %(pangea/cli/subcommands/infra)
require %(pangea/cli/subcommands/config)
require %(pangea/cli/config)
require %(pangea/version)

###############################################################################
# cli entrypoint
###############################################################################

class Command < PangeaCommand
  usage do
    program %(pangea)
  end

  argument :subcommand do
    desc %(subcommand for pangea)
    required
  end

  def help
    <<~HELP
      Usage: pangea command [OPTIONS] SUBCOMMAND

      Arguments:
        SUBCOMMAND  subcommand for pangea

      Options:
        -h, --help     Print usage
        -v, --version  Print version

      Subcommands:
        infra   manage infrastructure
        config  manage configuration
    HELP
  end

  def run
    argv = ARGV
    parse(argv)

    case params[:subcommand].to_s
    when %(infra)
      InfraCommand.new.run(argv)
    when %(config)
      ConfigCommand.new.run(argv)
    else
      if params[:version]
        puts Pangea::VERSION
      else
        puts help
      end
      exit
    end
  end
end

# end cli entrypoint
