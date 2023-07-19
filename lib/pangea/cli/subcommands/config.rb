require %(pangea/cli/subcommands/pangea)
require %(pangea/synthesizer/config)
require %(pangea/cli/config)
require %(json)

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
      puts JSON.pretty_generate(config)
    when %(init)
      config = Config.resolve_configurations
      config[:namespace].each_key do |ns_name|
        ns = config[:namespace][ns_name]
        ns.each_key do |ctx_name|
          ctx = ns[ctx_name]
          if ctx[:state_config][:terraform][:s3]
            # does dynamodb table exist?
          end
        end
    end
  end
end
