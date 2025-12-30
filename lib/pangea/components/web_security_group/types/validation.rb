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
        # Validation methods for WebSecurityGroupAttributes
        module Validation
          def self.validate(attrs)
            validate_web_protocol_enabled(attrs)
            validate_ssh_security(attrs)
            validate_custom_ports(attrs)
            validate_cidr_blocks(attrs)
          end

          def self.validate_web_protocol_enabled(attrs)
            return if attrs[:enable_http] || attrs[:enable_https] || (attrs[:custom_ports] || []).any?

            raise Dry::Struct::Error, "Web security group must enable at least HTTP, HTTPS, or custom ports"
          end

          def self.validate_ssh_security(attrs)
            return unless attrs[:enable_ssh] && attrs[:ssh_cidr_blocks]
            return unless attrs[:ssh_cidr_blocks].include?("0.0.0.0/0")

            puts "WARNING: SSH access from 0.0.0.0/0 is a security risk. Consider restricting to specific IP ranges."
          end

          def self.validate_custom_ports(attrs)
            custom_ports = attrs[:custom_ports] || []
            standard_ports = []
            standard_ports << attrs[:http_port] if attrs[:enable_http]
            standard_ports << attrs[:https_port] if attrs[:enable_https]
            standard_ports << attrs[:ssh_port] if attrs[:enable_ssh]

            duplicates = custom_ports & standard_ports
            return if duplicates.empty?

            raise Dry::Struct::Error, "Custom ports #{duplicates} conflict with enabled standard ports"
          end

          def self.validate_cidr_blocks(attrs)
            all_cidrs = (attrs[:allowed_cidr_blocks] || []) + (attrs[:ssh_cidr_blocks] || [])
            all_cidrs.each do |cidr|
              next if cidr.match?(/\A\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2}\z/)

              raise Dry::Struct::Error, "Invalid CIDR block format: #{cidr}"
            end
          end
        end
      end
    end
  end
end
