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
        # EKS cluster encryption configuration
        class EncryptionConfig < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :resources, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).constrained(
            min_size: 1,
            max_size: 1
          ).default(['secrets'].freeze)
          
          # Provider configuration for encryption
          class Provider < Dry::Struct
            transform_keys(&:to_sym)
            
            attribute :key_arn, Pangea::Resources::Types::String.constrained(
              format: /\Aarn:aws:kms:[a-z0-9-]+:\d{12}:key\/[a-f0-9-]+\z/
            )
            
            def to_h
              { key_arn: key_arn }
            end
          end
          
          attribute :provider, Provider
          
          def to_h
            {
              resources: resources,
              provider: provider.to_h
            }
          end
        end
        
        # VPC configuration for EKS cluster
        class VpcConfig < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :subnet_ids, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).constrained(
            min_size: 2
          )
          attribute :security_group_ids, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).default([].freeze)
          attribute :endpoint_private_access, Pangea::Resources::Types::Bool.default(false)
          attribute :endpoint_public_access, Pangea::Resources::Types::Bool.default(true)
          attribute :public_access_cidrs, Pangea::Resources::Types::Array.of(
            Pangea::Resources::Types::String.constrained(format: /\A\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2}\z/)
          ).default(['0.0.0.0/0'].freeze)
          
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate subnet count
            if attrs[:subnet_ids] && attrs[:subnet_ids].size < 2
              raise Dry::Struct::Error, "EKS cluster requires at least 2 subnets in different availability zones"
            end
            
            # Validate public access configuration
            if attrs[:endpoint_public_access] == false && attrs[:endpoint_private_access] == false
              raise Dry::Struct::Error, "At least one of endpoint_public_access or endpoint_private_access must be true"
            end
            
            super(attrs)
          end
          
          def to_h
            hash = {
              subnet_ids: subnet_ids,
              endpoint_private_access: endpoint_private_access,
              endpoint_public_access: endpoint_public_access
            }
            
            hash[:security_group_ids] = security_group_ids if security_group_ids.any?
            hash[:public_access_cidrs] = public_access_cidrs if endpoint_public_access
            
            hash
          end
        end
        
        # Kubernetes network configuration
        class KubernetesNetworkConfig < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :service_ipv4_cidr, Pangea::Resources::Types::String.optional.default(nil).constrained(
            format: /\A10\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2}\z|
                    \A172\.(1[6-9]|2[0-9]|3[0-1])\.\d{1,3}\.\d{1,3}\/\d{1,2}\z|
                    \A192\.168\.\d{1,3}\.\d{1,3}\/\d{1,2}\z/
          )
          attribute :ip_family, Pangea::Resources::Types::String.default('ipv4').constrained(included_in: ['ipv4', 'ipv6'])
          
          def to_h
            hash = { ip_family: ip_family }
            hash[:service_ipv4_cidr] = service_ipv4_cidr if service_ipv4_cidr
            hash
          end
        end
        
        # EKS cluster logging configuration
        class ClusterLogging < Dry::Struct
          transform_keys(&:to_sym)
          
          VALID_LOG_TYPES = %w[api audit authenticator controllerManager scheduler].freeze
          
          attribute :enabled_types, Pangea::Resources::Types::Array.of(
            Pangea::Resources::Types::String.constrained(included_in: VALID_LOG_TYPES)
          ).default([].freeze)
          
          def to_h
            return {} if enabled_types.empty?
            
            {
              enabled_cluster_log_types: enabled_types.map { |type| { types: [type], enabled: true } }
            }
          end
        end
        
        # EKS cluster attributes with validation
        class EksClusterAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          SUPPORTED_VERSIONS = %w[1.24 1.25 1.26 1.27 1.28 1.29].freeze
          
          # Required attributes
          attribute :name, Pangea::Resources::Types::String.optional.default(nil)
          attribute :role_arn, Pangea::Resources::Types::String.constrained(
            format: /\Aarn:aws:iam::\d{12}:role\/.+\z/
          )
          attribute :vpc_config, VpcConfig
          
          # Optional attributes
          attribute :version, Pangea::Resources::Types::String.constrained(included_in: SUPPORTED_VERSIONS).default('1.28')
          attribute :enabled_cluster_log_types, Pangea::Resources::Types::Array.of(
            Pangea::Resources::Types::String.constrained(included_in: ClusterLogging::VALID_LOG_TYPES)
          ).default([].freeze)
          attribute :encryption_config, Pangea::Resources::Types::Array.of(EncryptionConfig).default([].freeze)
          attribute :kubernetes_network_config, KubernetesNetworkConfig.optional.default(nil)
          attribute :tags, Pangea::Resources::Types::Hash.default({}.freeze)
          
          # Computed properties
          def encryption_enabled?
            encryption_config.any?
          end
          
          def logging_enabled?
            enabled_cluster_log_types.any?
          end
          
          def private_endpoint?
            vpc_config.endpoint_private_access
          end
          
          def public_endpoint?
            vpc_config.endpoint_public_access
          end
          
          def to_h
            hash = {
              role_arn: role_arn,
              version: version,
              vpc_config: vpc_config.to_h
            }
            
            hash[:name] = name if name
            hash[:enabled_cluster_log_types] = enabled_cluster_log_types if enabled_cluster_log_types.any?
            hash[:encryption_config] = encryption_config.map(&:to_h) if encryption_config.any?
            hash[:kubernetes_network_config] = kubernetes_network_config.to_h if kubernetes_network_config
            hash[:tags] = tags if tags.any?
            
            hash
          end
        end
      end
    end
  end
end