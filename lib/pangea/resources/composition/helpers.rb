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

require 'base64'
require 'ipaddr'

module Pangea
  module Resources
    module Composition
      # Private helper methods for composition patterns
      module Helpers
        private

        # Helper to base64 encode strings
        def base64encode(str)
          Base64.strict_encode64(str)
        end

        # Calculate subnet CIDR for a given index
        def calculate_subnet_cidr(base_ip, vpc_size, subnet_index)
          ip_parts = base_ip.split('.').map(&:to_i)

          # Assume /24 subnets within larger VPC
          subnet_increment = subnet_index

          # Adjust third octet
          ip_parts[2] += subnet_increment

          "#{ip_parts.join('.')}/24"
        end

        # Better subnet CIDR calculation that works with any VPC size
        def calculate_subnet_cidr_v2(base_ip, vpc_size, subnet_size, index)
          vpc_network = IPAddr.new("#{base_ip}/#{vpc_size}")

          # Calculate the increment based on subnet size
          subnet_hosts = 2**(32 - subnet_size)
          offset = index * subnet_hosts

          # Create the subnet
          subnet_ip = vpc_network.to_i + offset
          subnet_network = IPAddr.new(subnet_ip, Socket::AF_INET)

          "#{subnet_network}/#{subnet_size}"
        end

        # Default user data for web servers
        def default_web_server_user_data
          base64encode(<<~USERDATA)
            #!/bin/bash
            yum update -y
            yum install -y httpd
            systemctl start httpd
            systemctl enable httpd
            echo "<h1>Hello from Pangea!</h1>" > /var/www/html/index.html
            echo "<p>This server was created with type-safe resource composition.</p>" >> /var/www/html/index.html
          USERDATA
        end
      end
    end
  end
end
