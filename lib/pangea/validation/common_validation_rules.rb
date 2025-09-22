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

require 'ipaddr'

module Pangea
  module Validation
    # Common validation rules that can be shared across resources
    module CommonValidationRules
      # CIDR block validation
      def valid_cidr?(value)
        return false unless value.is_a?(String)
        
        ip, prefix = value.split('/')
        return false unless prefix
        
        prefix_int = prefix.to_i
        return false if prefix_int < 0 || prefix_int > 32
        
        IPAddr.new(value)
        true
      rescue IPAddr::InvalidAddressError
        false
      end
      
      # AWS region validation
      def valid_aws_region?(value)
        aws_regions = %w[
          us-east-1 us-east-2 us-west-1 us-west-2
          eu-west-1 eu-west-2 eu-west-3 eu-central-1 eu-north-1
          ap-northeast-1 ap-northeast-2 ap-northeast-3
          ap-southeast-1 ap-southeast-2 ap-south-1
          sa-east-1 ca-central-1
          me-south-1 af-south-1
        ]
        aws_regions.include?(value)
      end
      
      # DNS name validation
      def valid_dns_name?(value)
        return false unless value.is_a?(String)
        return false if value.empty? || value.length > 253
        
        # Check each label
        labels = value.split('.')
        labels.all? do |label|
          # Label must be 1-63 characters
          next false if label.empty? || label.length > 63
          
          # Must start and end with alphanumeric
          next false unless label.match?(/^[a-z0-9]/i) && label.match?(/[a-z0-9]$/i)
          
          # Can contain alphanumeric and hyphens
          label.match?(/^[a-z0-9-]+$/i)
        end
      end
      
      # Port validation
      def valid_port?(value)
        value.is_a?(Integer) && value >= 0 && value <= 65535
      end
      
      # ARN validation
      def valid_arn?(value)
        return false unless value.is_a?(String)
        
        # Basic ARN pattern
        value.match?(/^arn:aws(-[a-z]+)?:[a-z0-9-]+:[a-z0-9-]*:[0-9]*:.*/)
      end
      
      # Instance type validation
      def valid_instance_type?(value)
        return false unless value.is_a?(String)
        
        # Basic pattern for EC2 instance types
        value.match?(/^[a-z][0-9][a-z]?\.(nano|micro|small|medium|large|xlarge|[0-9]+xlarge)$/)
      end
    end
  end
end