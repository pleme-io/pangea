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
      # Type-safe attributes for AwsEipAssociation resources
      # Provides an AWS EIP Association as a top level resource, to associate and disassociate Elastic IPs from AWS Instances and Network Interfaces.
      class EipAssociationAttributes < Dry::Struct
        attribute :allocation_id, Resources::Types::String.optional
        attribute :allow_reassociation, Resources::Types::Bool.optional
        attribute :instance_id, Resources::Types::String.optional
        attribute :network_interface_id, Resources::Types::String.optional
        attribute :private_ip_address, Resources::Types::String.optional
        attribute :public_ip, Resources::Types::String.optional
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Either allocation_id or public_ip must be specified
          # Cannot specify both instance_id and network_interface_id
          # private_ip_address requires network_interface_id
          # Either allocation_id or public_ip must be specified
if !attrs.allocation_id && !attrs.public_ip
  raise Dry::Struct::Error, "Either 'allocation_id' or 'public_ip' must be specified"
end

# Cannot specify both instance_id and network_interface_id
if attrs.instance_id && attrs.network_interface_id
  raise Dry::Struct::Error, "Cannot specify both 'instance_id' and 'network_interface_id'"
end

# private_ip_address requires network_interface_id
if attrs.private_ip_address && !attrs.network_interface_id
  raise Dry::Struct::Error, "'private_ip_address' requires 'network_interface_id'"
end

          
          attrs
        end
        
        # Check if using VPC allocation
def vpc_allocation?
  !allocation_id.nil?
end

# Check if using EC2-Classic
def ec2_classic?
  !public_ip.nil? && allocation_id.nil?
end

# Determine association target
def target_type
  if instance_id
    :instance
  elsif network_interface_id
    :network_interface
  else
    :none
  end
end

      end
    end
      end
    end
  end
end