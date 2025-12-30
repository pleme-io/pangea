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

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # EKS node group attributes with validation
        class EksNodeGroupAttributes < Dry::Struct
          transform_keys(&:to_sym)

          AMI_TYPES = %w[
            AL2_x86_64 AL2_x86_64_GPU AL2_ARM_64
            BOTTLEROCKET_ARM_64 BOTTLEROCKET_x86_64
            BOTTLEROCKET_ARM_64_NVIDIA BOTTLEROCKET_x86_64_NVIDIA
            CUSTOM
          ].freeze

          CAPACITY_TYPES = %w[ON_DEMAND SPOT].freeze

          # Required attributes
          attribute :cluster_name, Pangea::Resources::Types::String
          attribute :node_role_arn, Pangea::Resources::Types::String.constrained(
            format: /\Aarn:aws:iam::\d{12}:role\/.+\z/
          )
          attribute :subnet_ids, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).constrained(min_size: 1)

          # Optional attributes
          attribute :node_group_name, Pangea::Resources::Types::String.optional.default(nil)
          attribute :scaling_config, ScalingConfig.default(ScalingConfig.new({}))
          attribute :update_config, UpdateConfig.optional.default(nil)
          attribute :instance_types, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).default(['t3.medium'].freeze)
          attribute :capacity_type, Pangea::Resources::Types::String.constrained(included_in: CAPACITY_TYPES).default('ON_DEMAND')
          attribute :ami_type, Pangea::Resources::Types::String.constrained(included_in: AMI_TYPES).default('AL2_x86_64')
          attribute :release_version, Pangea::Resources::Types::String.optional.default(nil)
          attribute :version, Pangea::Resources::Types::String.optional.default(nil)
          attribute :disk_size, Pangea::Resources::Types::Integer.default(20).constrained(gteq: 20, lteq: 1000)
          attribute :remote_access, RemoteAccess.optional.default(nil)
          attribute :launch_template, LaunchTemplate.optional.default(nil)
          attribute :labels, Pangea::Resources::Types::Hash.default({}.freeze)
          attribute :taints, Pangea::Resources::Types::Array.of(Taint).default([].freeze)
          attribute :tags, Pangea::Resources::Types::Hash.default({}.freeze)
          attribute :force_update_version, Pangea::Resources::Types::Bool.default(false)

          # Validate instance types match AMI type
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}

            # Validate ARM instance types with ARM AMIs
            if attrs[:ami_type] && attrs[:instance_types]
              ami_type = attrs[:ami_type]
              instance_types = attrs[:instance_types]

              if ami_type.include?('ARM') && instance_types.any? { |t| !t.include?('g') && !t.include?('a1') }
                raise Dry::Struct::Error, 'ARM AMI types require ARM-compatible instance types'
              end

              if ami_type.include?('GPU') && instance_types.none? { |t| t.include?('p') || t.include?('g4') }
                raise Dry::Struct::Error, 'GPU AMI types require GPU instance types'
              end
            end

            super(attrs)
          end

          # Computed properties
          def spot_instances?
            capacity_type == 'SPOT'
          end

          def custom_ami?
            ami_type == 'CUSTOM'
          end

          def has_remote_access?
            !remote_access.nil?
          end

          def has_taints?
            taints.any?
          end

          def has_labels?
            labels.any?
          end

          def to_h
            hash = {
              cluster_name: cluster_name,
              node_role_arn: node_role_arn,
              subnet_ids: subnet_ids,
              scaling_config: scaling_config.to_h,
              instance_types: instance_types,
              capacity_type: capacity_type,
              ami_type: ami_type,
              disk_size: disk_size,
              force_update_version: force_update_version
            }

            hash[:node_group_name] = node_group_name if node_group_name
            hash[:update_config] = update_config.to_h if update_config && !update_config.to_h.empty?
            hash[:release_version] = release_version if release_version
            hash[:version] = version if version
            hash[:remote_access] = remote_access.to_h if remote_access && !remote_access.to_h.empty?
            hash[:launch_template] = launch_template.to_h if launch_template
            hash[:labels] = labels if labels.any?
            hash[:taints] = taints.map(&:to_h) if taints.any?
            hash[:tags] = tags if tags.any?

            hash
          end
        end
      end
    end
  end
end
