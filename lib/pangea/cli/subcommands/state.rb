# require %(pangea/cli/subcommands/pangea)
# require %(pangea/cli/constants)
# require %(pangea/cli/config)
# require %(pangea/errors/namespace_not_found_error)
# require %(pangea/errors/site_not_found_error)
# require %(pangea/errors/project_not_found_error)
# require %(pangea/errors/no_infra_target_error)
# require %(pangea/errors/incorrect_subcommand_error)
# require %(pangea/shell/terraform)
# require %(pangea/say/init)
# require %(pangea/modules)

class StateCommand < PangeaCommand
  include Constants
  NAME = :state

  usage do
    desc %(manage infrastructure state)
    program %(pangea)
    command %(state)
  end

  argument :subcommand do
    desc %(manage infrastructure state)
  end

  def run
    nil
  end
end
