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
        # Type-safe attributes for AWS Security Group resources
        #
        # @example
        #   SecurityGroupAttributes.new({
        #     name_prefix: "web-sg-",
        #     vpc_id: "${aws_vpc.main.id}",
        #     description: "Web server security group",
        #     ingress_rules: [{
        #       from_port: 443,
        #       to_port: 443,
        #       protocol: "tcp",
        #       cidr_blocks: ["0.0.0.0/0"]
        #     }]
        #   })
        class SecurityGroupAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Optional attributes with defaults
          attribute :name_prefix, Resources::Types::String.optional.default(nil)
          attribute :vpc_id, Resources::Types::String.optional.default(nil)
          attribute :description, Resources::Types::String.optional.default(nil)
          attribute :ingress_rules, Resources::Types::Array.of(Resources::Types::SecurityGroupRule).default([].freeze)
          attribute :egress_rules, Resources::Types::Array.of(Resources::Types::SecurityGroupRule).default([].freeze)
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)
        
        # Custom validation
        def self.new(attributes)
          # Validate security group rules
          if attributes[:ingress_rules]
            attributes[:ingress_rules].each { |rule| validate_rule(rule, "ingress") }
          end
          
          if attributes[:egress_rules]
            attributes[:egress_rules].each { |rule| validate_rule(rule, "egress") }
          end
          
          super
        end
        
          private
          
          # Validate individual security group rule
          def self.validate_rule(rule, rule_type)
          return unless rule.is_a?(Hash)
          
          # Validate required fields
          required_fields = [:from_port, :to_port, :protocol]
          missing_fields = required_fields - rule.keys
          
          unless missing_fields.empty?
            raise Dry::Struct::Error, "#{rule_type.capitalize} rule missing required fields: #{missing_fields.join(', ')}"
          end
          
          # Validate port ranges
          from_port = rule[:from_port]
          to_port = rule[:to_port]
          
          if from_port && to_port && from_port > to_port
            raise Dry::Struct::Error, "#{rule_type.capitalize} rule from_port (#{from_port}) cannot be greater than to_port (#{to_port})"
          end
          
          # Validate protocol
          valid_protocols = %w[tcp udp icmp icmpv6 -1]
          protocol = rule[:protocol]
          
          unless valid_protocols.include?(protocol.to_s.downcase)
            raise Dry::Struct::Error, "#{rule_type.capitalize} rule protocol '#{protocol}' is not valid. Must be one of: #{valid_protocols.join(', ')}"
          end
          
          # Validate CIDR blocks if present
          if rule[:cidr_blocks]
            rule[:cidr_blocks].each do |cidr|
              unless valid_cidr_format?(cidr)
                raise Dry::Struct::Error, "#{rule_type.capitalize} rule contains invalid CIDR block: #{cidr}"
              end
            end
          end
        end
        
          # Validate CIDR block format
          def self.valid_cidr_format?(cidr)
            cidr.match?(/\A\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2}\z/)
          end
        end
      end
    end
  end
end