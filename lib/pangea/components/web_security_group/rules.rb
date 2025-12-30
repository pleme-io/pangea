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
      # Rule generation logic for web security groups
      module Rules
        module_function

        # Build ingress rules based on component configuration
        # @param attrs [Types::WebSecurityGroupAttributes] The component attributes
        # @return [Array<Hash>] Array of ingress rule hashes
        def build_ingress_rules(attrs)
          rules = []
          rules.concat(http_rules(attrs)) if attrs.enable_http
          rules.concat(https_rules(attrs)) if attrs.enable_https
          rules.concat(ssh_rules(attrs)) if attrs.enable_ssh
          rules.concat(custom_port_rules(attrs))
          rules.concat(ping_rules(attrs)) if attrs.enable_ping
          rules
        end

        # Build egress rules based on component configuration
        # @param attrs [Types::WebSecurityGroupAttributes] The component attributes
        # @return [Array<Hash>] Array of egress rule hashes
        def build_egress_rules(attrs)
          rules = []
          rules.concat(outbound_internet_rules) if attrs.enable_outbound_internet
          rules.concat(vpc_communication_rules) if attrs.enable_vpc_communication && !attrs.enable_outbound_internet
          rules
        end

        # HTTP ingress rule
        def http_rules(attrs)
          [{
            from_port: attrs.http_port,
            to_port: attrs.http_port,
            protocol: "tcp",
            cidr_blocks: attrs.allowed_cidr_blocks,
            description: "HTTP web traffic"
          }]
        end

        # HTTPS ingress rule
        def https_rules(attrs)
          [{
            from_port: attrs.https_port,
            to_port: attrs.https_port,
            protocol: "tcp",
            cidr_blocks: attrs.allowed_cidr_blocks,
            description: "HTTPS web traffic"
          }]
        end

        # SSH ingress rule (with separate CIDR blocks for better security)
        def ssh_rules(attrs)
          [{
            from_port: attrs.ssh_port,
            to_port: attrs.ssh_port,
            protocol: "tcp",
            cidr_blocks: attrs.ssh_cidr_blocks,
            description: "SSH administrative access"
          }]
        end

        # Custom port ingress rules
        def custom_port_rules(attrs)
          attrs.custom_ports.map do |port|
            {
              from_port: port,
              to_port: port,
              protocol: "tcp",
              cidr_blocks: attrs.allowed_cidr_blocks,
              description: "Custom port #{port}"
            }
          end
        end

        # ICMP ping ingress rule
        def ping_rules(attrs)
          [{
            from_port: -1,
            to_port: -1,
            protocol: "icmp",
            cidr_blocks: attrs.allowed_cidr_blocks,
            description: "ICMP ping"
          }]
        end

        # Outbound internet egress rules (TCP and UDP)
        def outbound_internet_rules
          [
            {
              from_port: 0,
              to_port: 65535,
              protocol: "tcp",
              cidr_blocks: ["0.0.0.0/0"],
              description: "All outbound TCP traffic to internet"
            },
            {
              from_port: 0,
              to_port: 65535,
              protocol: "udp",
              cidr_blocks: ["0.0.0.0/0"],
              description: "All outbound UDP traffic to internet"
            }
          ]
        end

        # VPC communication egress rules
        def vpc_communication_rules
          [{
            from_port: 0,
            to_port: 65535,
            protocol: "tcp",
            cidr_blocks: ["10.0.0.0/8"], # Placeholder - should be actual VPC CIDR
            description: "All TCP traffic within VPC"
          }]
        end
      end
    end
  end
end
