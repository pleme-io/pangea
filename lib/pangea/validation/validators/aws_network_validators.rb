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

require 'pangea/validation/base_validator'

module Pangea
  module Validation
    module Validators
      # VPC Validator
      VpcValidator = BaseValidator.for_resource(:aws_vpc) do
        params do
          required(:cidr_block).filled(:string)
          optional(:instance_tenancy).value(included_in?: %w[default dedicated host])
          optional(:enable_dns_support).filled(:bool)
          optional(:enable_dns_hostnames).filled(:bool)
          optional(:tags).hash
        end
        
        rule(:cidr_block) do
          unless valid_cidr?(value)
            key.failure('must be a valid CIDR block (e.g., 10.0.0.0/16)')
          end
        end
      end
      
      # Subnet Validator
      SubnetValidator = BaseValidator.for_resource(:aws_subnet) do
        params do
          required(:vpc_id).filled(:string)
          required(:cidr_block).filled(:string)
          required(:availability_zone).filled(:string)
          optional(:map_public_ip_on_launch).filled(:bool)
          optional(:tags).hash
        end
        
        rule(:cidr_block) do
          unless valid_cidr?(value)
            key.failure('must be a valid CIDR block')
          end
        end
        
        rule(:availability_zone) do
          # Basic pattern for AZ names
          unless value.match?(/^[a-z]{2}-[a-z]+-[0-9][a-z]$/)
            key.failure('must be a valid availability zone (e.g., us-east-1a)')
          end
        end
      end
      
      # Security Group Validator
      SecurityGroupValidator = BaseValidator.for_resource(:aws_security_group) do
        params do
          required(:name).filled(:string)
          required(:description).filled(:string)
          required(:vpc_id).filled(:string)
          optional(:ingress).array(:hash)
          optional(:egress).array(:hash)
          optional(:tags).hash
        end
        
        rule(:name) do
          if value.length > 255
            key.failure('must be 255 characters or less')
          end
          
          # Define allowed characters for security group names
          allowed_chars = [
            ('a'..'z').to_a, ('A'..'Z').to_a, ('0'..'9').to_a,
            [' ', '.', '_', '-', ':', '/', '(', ')', '#', ',', '@', 
             '[', ']', '+', '=', '&', ';', '{', '}', '!', '$', '*']
          ].flatten
          
          # Check each character is in the allowed set
          value.each_char do |char|
            unless allowed_chars.include?(char)
              key.failure("contains invalid character: '#{char}'")
              break
            end
          end
        end
        
        rule(:description) do
          if value.length > 255
            key.failure('must be 255 characters or less')
          end
        end
        
        rule(:ingress).each do
          schema do
            required(:from_port).filled(:integer)
            required(:to_port).filled(:integer)
            required(:protocol).filled(:string)
            optional(:cidr_blocks).array(:string)
            optional(:security_groups).array(:string)
            optional(:description).filled(:string)
          end
          
          rule(:from_port, :to_port) do
            if values[:from_port] > values[:to_port]
              key(:from_port).failure('must be less than or equal to to_port')
            end
          end
          
          rule(:from_port) { key.failure('invalid port') unless valid_port?(value) }
          rule(:to_port) { key.failure('invalid port') unless valid_port?(value) }
          
          rule(:protocol) do
            valid_protocols = %w[tcp udp icmp icmpv6 all -1]
            unless valid_protocols.include?(value) || value.match?(/^\d+$/)
              key.failure("must be one of: #{valid_protocols.join(', ')} or a protocol number")
            end
          end
          
          rule(:cidr_blocks).each do
            unless valid_cidr?(value)
              key.failure('must be a valid CIDR block')
            end
          end
        end
      end
    end
  end
end