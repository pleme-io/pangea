# frozen_string_literal: true

require_relative 'emrcontainers/virtual_cluster'
require_relative 'emrcontainers/job_run'
require_relative 'emrcontainers/managed_endpoint'
require_relative 'emrcontainers/job_template'

module Pangea
  module Resources
    module AWS
      # EMR Containers resources for running big data workloads on Amazon EKS
      module EMRContainers
        include VirtualCluster
        include JobRun
        include ManagedEndpoint
        include JobTemplate
      end
    end
  end
end