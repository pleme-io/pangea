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


require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsNeptuneClusterInstance resources
      # Provides a Neptune Cluster Instance resource.
      class NeptuneClusterInstanceAttributes < Dry::Struct
        attribute :identifier, Resources::Types::String
        attribute :cluster_identifier, Resources::Types::String
        attribute :instance_class, Resources::Types::String
        attribute :engine, Resources::Types::String.optional
        attribute :engine_version, Resources::Types::String.optional
        attribute :availability_zone, Resources::Types::String.optional
        attribute :preferred_maintenance_window, Resources::Types::String.optional
        attribute :apply_immediately, Resources::Types::Bool.optional
        attribute :auto_minor_version_upgrade, Resources::Types::Bool.optional
        attribute :promotion_tier, Resources::Types::Integer.optional
        attribute :neptune_parameter_group_name, Resources::Types::String.optional
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_neptune_cluster_instance

      end
    end
      end
    end
  end
end