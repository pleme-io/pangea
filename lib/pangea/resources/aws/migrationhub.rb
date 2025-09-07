# frozen_string_literal: true

require 'pangea/resources/aws/migrationhub/progress_update_stream'

module Pangea
  module Resources
    module AWS
      # AWS Migration Hub resources module
      # Includes all Migration Hub resource implementations for tracking
      # and managing application migrations.
      module MigrationHub
        include ProgressUpdateStream
      end
    end
  end
end