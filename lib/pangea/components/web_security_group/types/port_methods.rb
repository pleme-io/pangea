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

module Pangea
  module Components
    module WebSecurityGroup
      module Types
        # Port computation methods for WebSecurityGroupAttributes
        module PortMethods
          def enabled_ports
            ports = []
            ports << http_port if enable_http
            ports << https_port if enable_https
            ports << ssh_port if enable_ssh
            ports + custom_ports
          end

          def web_ports
            ports = []
            ports << http_port if enable_http
            ports << https_port if enable_https
            ports + custom_ports.select { |port| [80, 8080, 443, 8443].include?(port) }
          end

          def admin_ports
            ports = []
            ports << ssh_port if enable_ssh
            ports + custom_ports.select { |port| [22, 3389, 5985, 5986].include?(port) }
          end

          def port_usage_analysis
            {
              web_ports: web_ports.length,
              admin_ports: admin_ports.length,
              custom_ports: custom_ports.length,
              total_ports: enabled_ports.length,
              has_ssl: enable_https,
              has_admin_access: enable_ssh || admin_ports.any?,
              internet_accessible: allowed_cidr_blocks.include?("0.0.0.0/0")
            }
          end
        end
      end
    end
  end
end
