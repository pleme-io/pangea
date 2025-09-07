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

require_relative '../base'
require_relative '../capabilities'

module Pangea
  module Components
    class SecureVPC < Base
      include Capabilities::HighAvailability
      include Capabilities::Monitoring
      include Capabilities::Security
      
      component_type :secure_vpc
      
      # Parameters
      option :cidr_block, Types::Registry[:cidr_block]
      option :enable_flow_logs, default: -> { true }
      option :tags, default: -> { {} }
      
      # Resources
      resource :vpc, :aws_vpc do
        {
          cidr_block: cidr_block,
          enable_dns_hostnames: true,
          enable_dns_support: true,
          tags: tags.merge("Name" => "#{name}-vpc")
        }
      end
      
      resource :flow_logs, :aws_flow_log do
        next unless enable_flow_logs
        {
          resource_type: "VPC",
          resource_id: resources[:vpc].id,
          traffic_type: "ALL",
          log_destination_type: "cloud-watch-logs",
          tags: tags.merge("Name" => "#{name}-flow-logs")
        }
      end
      
      # Outputs
      output :vpc_id do
        resources[:vpc].id
      end
      
      output :vpc_cidr do
        cidr_block
      end
      
      output :flow_logs_enabled do
        enable_flow_logs
      end
      
      # Validations
      validation :cidr_block_size do
        cidr = IPAddr.new(cidr_block)
        if cidr.prefix < 16
          raise ValidationError, "CIDR block too large. Maximum size: /16"
        end
      end
      
      validation :cidr_block_private do
        cidr = IPAddr.new(cidr_block)
        private_ranges = [
          IPAddr.new("10.0.0.0/8"),
          IPAddr.new("172.16.0.0/12"),
          IPAddr.new("192.168.0.0/16")
        ]
        
        unless private_ranges.any? { |range| range.include?(cidr) }
          raise ValidationError, "CIDR block must be in private IP range"
        end
      end
    end
  end
end