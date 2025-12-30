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
        # Rules summary methods for WebSecurityGroupAttributes
        module RulesSummary
          def inbound_rules_summary
            rules = []
            rules.concat(build_web_rules)
            rules.concat(build_ssh_rules)
            rules.concat(build_custom_port_rules)
            rules.concat(build_ping_rules)
            rules
          end

          def outbound_rules_summary
            rules = []
            rules.concat(build_internet_outbound_rules)
            rules.concat(build_vpc_outbound_rules)
            rules
          end

          private

          def build_web_rules
            rules = []

            if enable_http
              rules << {
                protocol: 'tcp',
                port: http_port,
                sources: allowed_cidr_blocks,
                description: 'HTTP web traffic'
              }
            end

            if enable_https
              rules << {
                protocol: 'tcp',
                port: https_port,
                sources: allowed_cidr_blocks,
                description: 'HTTPS web traffic'
              }
            end

            rules
          end

          def build_ssh_rules
            return [] unless enable_ssh

            [{
              protocol: 'tcp',
              port: ssh_port,
              sources: ssh_cidr_blocks,
              description: 'SSH administrative access'
            }]
          end

          def build_custom_port_rules
            custom_ports.map do |port|
              {
                protocol: 'tcp',
                port: port,
                sources: allowed_cidr_blocks,
                description: "Custom port #{port}"
              }
            end
          end

          def build_ping_rules
            return [] unless enable_ping

            [{
              protocol: 'icmp',
              port: -1,
              sources: allowed_cidr_blocks,
              description: 'ICMP ping'
            }]
          end

          def build_internet_outbound_rules
            return [] unless enable_outbound_internet

            [
              {
                protocol: 'tcp',
                ports: '0-65535',
                destinations: ['0.0.0.0/0'],
                description: 'All outbound TCP traffic to internet'
              },
              {
                protocol: 'udp',
                ports: '0-65535',
                destinations: ['0.0.0.0/0'],
                description: 'All outbound UDP traffic to internet'
              }
            ]
          end

          def build_vpc_outbound_rules
            return [] unless enable_vpc_communication

            [{
              protocol: 'tcp',
              ports: '0-65535',
              destinations: ['vpc_cidr'],
              description: 'All TCP traffic within VPC'
            }]
          end
        end
      end
    end
  end
end
