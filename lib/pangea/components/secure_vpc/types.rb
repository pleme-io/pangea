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
require 'pangea/components/types'

module Pangea
  module Components
    module SecureVpc
      module Types
        # SecureVpc component attributes with comprehensive validation
        class SecureVpcAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :cidr_block, Components::Types::CidrBlock
          attribute :availability_zones, Components::Types::AvailabilityZones
          attribute :enable_dns_hostnames, Components::Types::Bool.default(true)
          attribute :enable_dns_support, Components::Types::Bool.default(true)
          attribute :enable_flow_logs, Components::Types::Bool.default(true)
          attribute :flow_log_destination, Components::Types::String.enum('cloud-watch-logs', 's3').default('cloud-watch-logs')
          attribute :instance_tenancy, Resources::Types::InstanceTenancy.default('default')
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)
          attribute :security_config, Components::Types::SecurityConfig.default({}.freeze)
          attribute :monitoring_config, Components::Types::MonitoringConfig.default({}.freeze)
          
          # Custom validation for VPC CIDR and AZ compatibility
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate CIDR block size for practical VPC use
            if attrs[:cidr_block]
              cidr_parts = attrs[:cidr_block].split('/')
              subnet_size = cidr_parts[1].to_i
              
              if subnet_size > 28
                raise Dry::Struct::Error, "VPC CIDR block #{attrs[:cidr_block]} is too small (>/28). VPCs should typically be /16 to /28."
              end
              
              if subnet_size < 16
                raise Dry::Struct::Error, "VPC CIDR block #{attrs[:cidr_block]} is too large (</16). AWS VPCs support /16 to /28."
              end
            end
            
            # Validate availability zones are from same region
            if attrs[:availability_zones] && attrs[:availability_zones].length > 1
              regions = attrs[:availability_zones].map { |az| az[0..-2] }.uniq
              if regions.length > 1
                raise Dry::Struct::Error, "All availability zones must be from the same region. Found: #{regions.join(', ')}"
              end
            end
            
            # Validate flow log destination compatibility
            if attrs[:flow_log_destination] == 's3' && (!attrs[:security_config] || !attrs[:security_config][:enable_flow_logs])
              raise Dry::Struct::Error, "S3 flow log destination requires enable_flow_logs to be true"
            end
            
            super(attrs)
          end
          
          # Computed properties
          def region
            return nil if availability_zones.empty?
            availability_zones.first[0..-2] # Remove the zone letter (e.g., 'us-east-1a' -> 'us-east-1')
          end
          
          def estimated_subnet_capacity
            cidr_parts = cidr_block.split('/')
            vpc_size = cidr_parts[1].to_i
            
            # Estimate how many /24 subnets can fit
            case vpc_size
            when 16 then 256
            when 17 then 128
            when 18 then 64
            when 19 then 32
            when 20 then 16
            when 21 then 8
            when 22 then 4
            when 23 then 2
            when 24 then 1
            else 0
            end
          end
          
          def is_rfc1918_private?
            # Check if CIDR is in private address space
            ip_parts = cidr_block.split('/')[0].split('.').map(&:to_i)
            
            # 10.0.0.0/8
            return true if ip_parts[0] == 10
            
            # 172.16.0.0/12
            return true if ip_parts[0] == 172 && (16..31).include?(ip_parts[1])
            
            # 192.168.0.0/16
            return true if ip_parts[0] == 192 && ip_parts[1] == 168
            
            false
          end
          
          def security_level
            security_features = []
            security_features << 'VPC_FLOW_LOGS' if enable_flow_logs
            security_features << 'DNS_RESOLUTION' if enable_dns_support && enable_dns_hostnames
            security_features << 'ENCRYPTION_AT_REST' if security_config[:encryption_at_rest]
            security_features << 'DETAILED_MONITORING' if monitoring_config[:enable_detailed_monitoring]
            
            case security_features.length
            when 0..1 then 'basic'
            when 2..3 then 'enhanced'
            when 4.. then 'maximum'
            end
          end
          
          def compliance_features
            features = []
            features << 'VPC Flow Logs' if enable_flow_logs
            features << 'DNS Resolution' if enable_dns_support && enable_dns_hostnames
            features << 'CloudWatch Monitoring' if monitoring_config[:enable_cloudwatch]
            features << 'Encryption at Rest' if security_config[:encryption_at_rest]
            features << 'Private CIDR Range' if is_rfc1918_private?
            features
          end
        end
      end
    end
  end
end