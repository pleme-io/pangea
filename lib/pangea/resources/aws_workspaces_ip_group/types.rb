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
        # WorkSpaces IP Group resource attributes with validation
        class WorkspacesIpGroupAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :group_name, Resources::Types::String.constrained(
            min_size: 1,
            max_size: 100,
            format: /\A[a-zA-Z0-9\s._-]+\z/
          )
          
          attribute :group_desc, Resources::Types::String.constrained(
            min_size: 0,
            max_size: 256
          ).default('')
          
          attribute :user_rules, Resources::Types::Array.of(IpRuleType).constrained(
            max_size: 10
          ).default([].freeze)
          
          # Optional attributes
          attribute :tags, Resources::Types::AwsTags
          
          # Validation for IP rules
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Check for duplicate IP rules
            if attrs[:user_rules] && attrs[:user_rules].is_a?(Array)
              ip_rules = attrs[:user_rules].map { |rule| rule[:ip_rule] || rule['ip_rule'] }
              if ip_rules.uniq.length != ip_rules.length
                raise Dry::Struct::Error, "Duplicate IP rules are not allowed"
              end
            end
            
            super(attrs)
          end
          
          # Computed properties
          def total_rules
            user_rules.length
          end
          
          def has_public_ips?
            user_rules.any? { |rule| !is_private_ip?(rule.ip_rule) }
          end
          
          def has_private_ips?
            user_rules.any? { |rule| is_private_ip?(rule.ip_rule) }
          end
          
          def ip_ranges
            user_rules.map(&:ip_rule)
          end
          
          private
          
          def is_private_ip?(cidr)
            ip = cidr.split('/')[0]
            octets = ip.split('.').map(&:to_i)
            
            # Check for private IP ranges
            return true if octets[0] == 10  # 10.0.0.0/8
            return true if octets[0] == 172 && (16..31).include?(octets[1])  # 172.16.0.0/12
            return true if octets[0] == 192 && octets[1] == 168  # 192.168.0.0/16
            return true if octets[0] == 127  # 127.0.0.0/8 (loopback)
            
            false
          end
        end
        
        # IP rule configuration
        class IpRuleType < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :ip_rule, Resources::Types::CidrBlock
          attribute :rule_desc, Resources::Types::String.constrained(
            max_size: 100
          ).default('')
          
          # Validation for CIDR format and range
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Additional CIDR validation
            if attrs[:ip_rule]
              cidr_parts = attrs[:ip_rule].split('/')
              if cidr_parts.length == 2
                prefix = cidr_parts[1].to_i
                
                # WorkSpaces supports /16 to /32 for IP groups
                if prefix < 16 || prefix > 32
                  raise Dry::Struct::Error, "CIDR prefix must be between /16 and /32 for WorkSpaces IP groups"
                end
              end
            end
            
            super(attrs)
          end
          
          # Helper methods
          def cidr_prefix
            ip_rule.split('/')[1].to_i
          end
          
          def network_address
            ip_rule.split('/')[0]
          end
          
          def is_single_host?
            cidr_prefix == 32
          end
          
          def is_broad_range?
            cidr_prefix <= 20  # /20 or broader
          end
          
          def estimated_hosts
            # Calculate number of hosts in the CIDR range
            32 - cidr_prefix == 0 ? 1 : 2 ** (32 - cidr_prefix) - 2
          end
        end
      end
    end
  end
end