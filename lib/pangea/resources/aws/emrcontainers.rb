# frozen_string_literal: true
# Copyright 2025 The Pangea Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


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