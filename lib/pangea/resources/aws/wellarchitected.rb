# frozen_string_literal: true

require 'pangea/resources/aws/wellarchitected/workload'

module Pangea
  module Resources
    module AWS
      # AWS Well-Architected Tool resources module
      # Includes all Well-Architected resource implementations for managing
      # workloads and architectural reviews.
      module WellArchitected
        include Workload
      end
    end
  end
end