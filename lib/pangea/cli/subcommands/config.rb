require %(pangea/cli/subcommands/pangea)
require %(pangea/synthesizer/config)
require %(pangea/cli/config)
require %(json)
require %(aws-sdk-dynamodb)

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

  # check if dynamodb table exists
  def table_exists?(table_name)
    dynamodb.describe_table({ table_name: table_name })
    return true

  rescue Aws::DynamoDB::Errors::ResourceNotFoundException
    return false
  end

  def dynamodb
    @dynamodb ||= Aws::DynamoDB::Client.new
  end

  def dynamodb_terraform_lock_spec(table_name)
    {
      table_name: table_name,
      key_schema: [
        {
          attribute_name: %(LockID),
          key_type: %(HASH)
        }
      ],
      attribute_definitions: [
        {
          attribute_name: %(LockID),
          attribute_type: %(S)
        }
      ],
      provisioned_throughput: {
        read_capacity_units: 5,
        write_capacity_units: 5
      },
    }
  end

  def run(argv)
    case argv[1].to_s
    when %(show)
      config = Config.resolve_configurations
      puts JSON.pretty_generate(config)
    when %(init)
      puts "intializing pangea configuration..."
      config = Config.resolve_configurations

      config[:namespace].each_key do |ns_name|
        ns = config[:namespace][ns_name]
        ns.each_key do |ctx_name|
          ctx = ns[ctx_name]
          if ctx[:state_config][:terraform][:s3]
            unless table_exists?(ctx[:state_config][:terraform][:s3][:dynamodb_table])
              begin
                result = dynamodb.create_table(
                  dynamodb_terraform_lock_spec(
                    ctx[:state_config][:terraform][:s3][:dynamodb_table]
                  )
                )
                puts "Created table. Status: #{result.table_description.table_status}"
              rescue Aws::DynamoDB::Errors::ServiceError => error
                puts error.message.to_s
              end
            end
          end
        end

    end
  end
end
