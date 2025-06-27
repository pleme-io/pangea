# frozen_string_literal: true

require %(pangea/cli/config)

describe Pangea::Cli::Config do
  context %(#resolve_configuration) do
    defaults = { ignore_default_paths: true }
    it %(empty when paths ignored) do
      expect(
        Pangea::Cli::Config.resolve_configurations(**defaults.merge(
          { extra_paths: [] }
        ))
      ).to be_empty
    end
  end
end
