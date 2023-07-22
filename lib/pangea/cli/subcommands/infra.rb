require %(pangea/cli/subcommands/pangea)
require %(pangea/cli/constants)
require %(pangea/cli/config)
require %(pangea/errors/namespace_not_found_error)
require %(pangea/errors/site_not_found_error)
require %(pangea/errors/project_not_found_error)
require %(pangea/errors/no_infra_target_error)
require %(pangea/errors/incorrect_subcommand_error)
require %(pangea/say/init)
require %(terraform-synthesizer)
require %(json)

class InfraCommand < PangeaCommand
  include Constants
  NAME = :infra

  usage do
    desc %(manage infrastructure)
    program %(pangea)
    command %(infra)
  end

  argument :subcommand do
    desc %(the subcommand)
  end

  argument :target do
    desc %(target like ${namespace}.${site}.${project})
  end

  def run(argv)
    parse(argv)

    # grab a config synth
    cfg_synth = Config.resolve_configurations

    # reject empty configurations
    if cfg_synth.empty?
      Say.terminal %(configuration empty, exiting...)
      exit
    end

    # preflight checks for the command execution
    check_run
    check_target(params[:target], cfg_synth)

    targets = params[:target].split('.').map(&:to_sym)
    process_target(targets, cfg_synth)

    # provide some kind of default exit of the command execution
    exit
  end

  private

  # process stage for target
  def process_target(targets, cfg_synth)
    namespaces    = cfg_synth[:namespace].keys.map(&:to_sym)
    environments  = []

    namespaces.each do |ns_name|
      environments.concat(cfg_synth[:namespace][ns_name].keys.map(&:to_sym))
    end

    case targets.length.to_i
      # only provided namespace
    when 1
      nil
      # only provided namespace.site
    when 2
      nil
      # only provided namespace.site.project
    when 3
      announce_preflight_info(targets, cfg_synth)
      environments.each do |e_name|
        projects = cfg_synth[:namespace][targets[0]][e_name][:projects]
        projects.each do |project|
          announce_project(project)

          synth = TerraformSynthesizer.new
          case project[:src][:type].to_sym
          when :local
            system %(mkdir -p #{CACHE_DIR}) unless Dir.exist?(CACHE_DIR)
            PROJECT_SRC_DIRS.each do |src_dir|
              next unless File.exist?(File.join(
                                        project[:src][:location].to_s,
                                        %(src),
                                        src_dir.to_s
                                      ))

              synth_files = Dir.glob("#{File.join(
                project[:src][:location].to_s,
                %(src),
                src_dir.to_s
              )}/**/*.rb")
              synth_files.each do |synth_file|
                synth.synthesize(File.read(synth_file))
              end
            end

            Say.terminal JSON.pretty_generate(synth.synthesis)

            project_cache_dir = File.join(CACHE_DIR, project[:name].to_s)

            system %(mkdir -p #{project_cache_dir}) unless Dir.exist?(project_cache_dir)
            File.write(File.join(project_cache_dir, ARTIFACT_FILE), synth.synthesis.to_json)
            system %(cd #{project_cache_dir} && terraform init)
            system %(cd #{project_cache_dir} && terraform plan)

          when :git
            nil
          end
        end
      end

      # fetch project data
      # projet_data = cfg_synth[:namespace][targets[0]]
    end
  end

  def announce_project(project)
    msg = []
    msg << %(project: #{project[:name]})
    msg << %(src:     #{project[:src]})
    Say.terminal msg.map(&:strip).join(%(\n))
  end

  def announce_preflight_info(targets, cfg_synth)
    namespaces    = cfg_synth[:namespace].keys.map(&:to_sym)
    environments  = []

    namespaces.each do |ns_name|
      environments.concat(cfg_synth[:namespace][ns_name].keys.map(&:to_sym))
    end

    preflight_info = []
    preflight_info << %(environments: #{environments})
    preflight_info << %(\n)
    preflight_info << %(namespace: #{targets[0]})
    preflight_info << %(site:      #{targets[1]})
    preflight_info << %(project:   #{targets[2]})

    Say.terminal preflight_info.map(&:strip).join(%(\n))
  end

  # targets can be...
  # ${namespace}
  # ${namespace}.${site}
  # ${namespace}.${site}.${project}
  def check_target(target, config)
    raise NamespaceNotFoundError if target.nil?

    targets       = target.split('.').map(&:to_sym)
    namespaces    = config[:namespace].keys.map(&:to_sym)
    runtype       = nil
    environments  = []

    namespaces.each do |ns_name|
      environments.concat(config[:namespace][ns_name].keys.map(&:to_sym))
    end

    raise NamespaceNotFoundError unless namespaces.include?(targets[0])

    namespaces.each do |ns_name|
      environments.each do |e_name|
        sites = config[:namespace][ns_name][e_name][:sites] || []

        next if sites.empty?

        site_names = []
        sites.each do |site|
          site_names << site[:name]
        end

        raise SiteNotFoundError unless site_names.include?(targets[1].to_sym)

        projects = config[:namespace][ns_name][e_name][:projects] || []

        next if projects.empty?

        project_names = []
        projects.each do |project|
          project_names << project[:name]
        end

        raise ProjectNotFoundError \
        unless project_names
               .include?(
                 targets[2].to_sym
               )
      end
    end
  end

  def check_run
    raise IncorrectSubcommandError unless correct_subcommand?(
      params[:subcommand]
    )
    raise NoInfraTargetError unless params[:target]
  end

  def correct_subcommand?(sbcmd)
    NAME.to_s.eql?(sbcmd.to_s)
  end
end
