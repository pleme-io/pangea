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

require_relative 'dsl_builder/configurations'
require_relative 'dsl_builder/ec2_attributes'
require_relative 'dsl_builder/instance_groups'
require_relative 'dsl_builder/auto_scaling'
require_relative 'dsl_builder/cluster_settings'

module Pangea
  module Resources
    module AWS
      module EmrCluster
        # DSL Builder for EMR Cluster resource
        class DSLBuilder
          include Configurations
          include Ec2Attributes
          include InstanceGroups
          include AutoScaling
          include ClusterSettings

          attr_reader :attrs

          def initialize(cluster_attrs)
            @attrs = cluster_attrs
          end
        end
      end
    end
  end
end
