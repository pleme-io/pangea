require %(pangea/cli/subcommands/pangea)
require %(pangea/synthesizer/config)
require %(pangea/cli/config)
require %(json)
require %(aws-sdk-dynamodb)
require %(aws-sdk-s3)
require %(terraform-synthesizer)

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
    true
  rescue Aws::DynamoDB::Errors::ResourceNotFoundException
    false
  end

  def s3
    @s3 ||= Aws::S3::Resource.new
  end

  def bucket_exist?(name)
    s3.bucket(name).exists?
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
      }
    }
  end

  def run(argv)
    case argv[1].to_s
    when %(show)
      config = Config.resolve_configurations
      puts JSON.pretty_generate(config)
    when %(plan)
      puts "planning pangea configuration..."
      config = Config.resolve_configurations

      config[:namespace].each_key do |ns_name|
        ns = config[:namespace][ns_name]
        ns.each_key do |ctx_name|
          ctx = ns[ctx_name]

          ###################################################################
          # setup modules
          ###################################################################

          module_dirs = %w[lib src test]
          modules     = ctx[:modules]
          synth       = TerraformSynthesizer.new

          modules.each_key do |mod_name|
            this_mod = modules[mod_name]

            if this_mod[:sandboxed]
              # TODO: setup sandboxed module
              nil
            else
              if this_mod[:path]
                # read mod from a local path
                # use terraform synthesizer to do it

                # process lib if exists

                lib_dir   = File.join(this_mod[:path], %(lib))
                lib_files = Dir.glob(File.join(this_mod[:path], %(lib), %(**/*.rb))

                system(%(mkdir -p #{lib_dir})) unless Dir.exist?(lib_dir)

                lib_files.each do |lib_file|
                  synth.synthesize(
                    File.read(
                      File.join(
                        this_mod[:path], 
                        %(lib), 
                        lib_file
                      )
                    )
                  )
                end

                # end process lib if exists
                # process src if exists

                src_dir   = File.join(this_mod[:path], %(src))
                src_files = Dir.glob(File.join(this_mod[:path], %(src), %(**/*.rb))

                system(%(mkdir -p #{src_dir})) unless Dir.exist?(src_dir)

                lib_files.each do |lib_file|
                  synth.synthesize(
                    File.read(
                      File.join(
                        this_mod[:path], 
                        %(lib), 
                        lib_file
                      )
                    )
                  )
                end
              end
            end
          end
        end
        puts JSON.pretty_generate(synth.synthesis)
      end
    when %(init)
      puts 'intializing pangea configuration...'
      config = Config.resolve_configurations

      config[:namespace].each_key do |ns_name|
        ns = config[:namespace][ns_name]
        ns.each_key do |ctx_name|
          ctx = ns[ctx_name]
          next unless ctx[:state_config][:terraform][:s3]

          ###################################################################
          # dynamodb table setup
          ###################################################################

          unless table_exists?(ctx[:state_config][:terraform][:s3][:dynamodb_table])
            begin
              result = dynamodb.create_table(
                dynamodb_terraform_lock_spec(
                  ctx[:state_config][:terraform][:s3][:dynamodb_table]
                )
              )
              puts "Created table. Status: #{result.table_description.table_status}"
            rescue Aws::DynamoDB::Errors::ServiceError => e
              puts e.message.to_s
            end
          end

          # dynamodb table setup

          ###################################################################
          # s3 bucket setup
          ###################################################################
          bucket_name =
            ctx[:state_config][:terraform][:s3][:bucket]
          if bucket_exist?(bucket_name)
            puts "bucket already exists: #{bucket_name}"
          else
            s3.create_bucket(bucket: bucket_name)
          end

          # end s3 bucket setup
          
          ###################################################################
          # setup directories
          ###################################################################

          base_dir    = File.join(ENV[%(HOME)], %(.pangea))
          context_dir = File.join(base_dir, ctx_name)
          synth_dir   = File.join(base_dir, synth_dir)

          system(%(mkdir -p #{context_dir})) unless Dir.exist?(context_dir)
          system(%(mkdir -p #{synth_dir})) unless Dir.exist?(synth_dir)

          # end setup directories
        end
      end
    end
  end
end
