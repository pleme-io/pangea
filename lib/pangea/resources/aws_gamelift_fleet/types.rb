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


require "dry-struct"
require "pangea/types"

module Pangea
  module Resources
    module AwsGameliftFleet
      module Types
        # IP permission configuration for the fleet
        class IpPermission < Dry::Struct
          attribute :from_port, Pangea::Types::Integer
          attribute :to_port, Pangea::Types::Integer
          attribute :ip_range, Pangea::Types::String
          attribute :protocol, Pangea::Types::String.enum("TCP", "UDP")
        end

        # Runtime configuration for fleet instances
        class ServerProcess < Dry::Struct
          attribute :concurrent_executions, Pangea::Types::Integer
          attribute :launch_path, Pangea::Types::String
          attribute :parameters?, Pangea::Types::String
        end

        class RuntimeConfiguration < Dry::Struct
          attribute :game_session_activation_timeout_seconds?, Pangea::Types::Integer.constrained(gteq: 1, lteq: 600)
          attribute :max_concurrent_game_session_activations?, Pangea::Types::Integer.constrained(gteq: 1, lteq: 2147483647)
          attribute :server_process?, Pangea::Types::Array.of(ServerProcess)
        end

        # Resource creation limit policy
        class ResourceCreationLimitPolicy < Dry::Struct
          attribute :new_game_sessions_per_creator?, Pangea::Types::Integer
          attribute :policy_period_in_minutes?, Pangea::Types::Integer
        end

        # Certificate configuration for TLS
        class CertificateConfiguration < Dry::Struct
          attribute :certificate_type, Pangea::Types::String.enum("DISABLED", "GENERATED")
        end

        # Main attributes for GameLift fleet
        class Attributes < Dry::Struct
          # Required attributes
          attribute :name, Pangea::Types::String
          attribute :build_id?, Pangea::Types::String
          attribute :script_id?, Pangea::Types::String
          attribute :ec2_instance_type, Pangea::Types::String
          
          # Optional attributes
          attribute :description?, Pangea::Types::String
          attribute :ec2_inbound_permission?, Pangea::Types::Array.of(IpPermission)
          attribute :fleet_type?, Pangea::Types::String.enum("ON_DEMAND", "SPOT")
          attribute :instance_role_arn?, Pangea::Types::String
          attribute :certificate_configuration?, CertificateConfiguration
          attribute :metric_groups?, Pangea::Types::Array.of(Pangea::Types::String)
          attribute :new_game_session_protection_policy?, Pangea::Types::String.enum("NoProtection", "FullProtection")
          attribute :resource_creation_limit_policy?, ResourceCreationLimitPolicy
          attribute :runtime_configuration?, RuntimeConfiguration
          attribute :peer_vpc_aws_account_id?, Pangea::Types::String
          attribute :peer_vpc_id?, Pangea::Types::String
          attribute :tags?, Pangea::Types::Hash.map(Pangea::Types::String, Pangea::Types::String)

          # Compute configuration
          attribute :compute_type?, Pangea::Types::String.enum("EC2", "ANYWHERE")
          attribute :anywhere_configuration?, Pangea::Types::Hash

          # Scaling configuration
          attribute :desired_ec2_instances?, Pangea::Types::Integer
          attribute :min_size?, Pangea::Types::Integer
          attribute :max_size?, Pangea::Types::Integer

          def self.from_dynamic(d)
            d = Pangea::Types::Hash[d]
            new(
              name: d.fetch(:name),
              build_id: d[:build_id],
              script_id: d[:script_id],
              ec2_instance_type: d.fetch(:ec2_instance_type),
              description: d[:description],
              ec2_inbound_permission: d[:ec2_inbound_permission]&.map { |p| IpPermission.from_dynamic(p) },
              fleet_type: d[:fleet_type],
              instance_role_arn: d[:instance_role_arn],
              certificate_configuration: d[:certificate_configuration] ? CertificateConfiguration.from_dynamic(d[:certificate_configuration]) : nil,
              metric_groups: d[:metric_groups],
              new_game_session_protection_policy: d[:new_game_session_protection_policy],
              resource_creation_limit_policy: d[:resource_creation_limit_policy] ? ResourceCreationLimitPolicy.from_dynamic(d[:resource_creation_limit_policy]) : nil,
              runtime_configuration: d[:runtime_configuration] ? RuntimeConfiguration.from_dynamic(d[:runtime_configuration]) : nil,
              peer_vpc_aws_account_id: d[:peer_vpc_aws_account_id],
              peer_vpc_id: d[:peer_vpc_id],
              tags: d[:tags],
              compute_type: d[:compute_type],
              anywhere_configuration: d[:anywhere_configuration],
              desired_ec2_instances: d[:desired_ec2_instances],
              min_size: d[:min_size],
              max_size: d[:max_size]
            )
          end
        end

        # Reference for GameLift fleet resources
        class Reference < Dry::Struct
          attribute :id, Pangea::Types::String
          attribute :arn, Pangea::Types::String
          attribute :build_arn, Pangea::Types::String
          attribute :creation_time, Pangea::Types::String
          attribute :operating_system, Pangea::Types::String
          attribute :status, Pangea::Types::String
          attribute :log_paths, Pangea::Types::Array.of(Pangea::Types::String)
        end
      end
    end
  end
end