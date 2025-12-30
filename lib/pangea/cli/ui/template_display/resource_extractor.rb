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
  module CLI
    module UI
      module TemplateDisplay
        # Extracts and formats resource information from parsed Terraform JSON
        module ResourceExtractor
          # Resource type patterns mapped to their key attributes
          RESOURCE_ATTRIBUTE_PATTERNS = {
            /aws_route53_/ => %i[name type ttl records],
            /aws_s3_/ => %i[bucket acl],
            /aws_lambda_/ => %i[function_name runtime handler],
            /aws_rds_|aws_db_/ => %i[identifier engine instance_class],
            /aws_ec2_|aws_instance/ => %i[instance_type ami],
            /aws_vpc/ => %i[cidr_block],
            /aws_subnet/ => %i[cidr_block availability_zone]
          }.freeze

          # Generic attributes to extract when no specific pattern matches
          GENERIC_ATTRIBUTES = %w[name id identifier domain].freeze

          # Extract resources from parsed config
          def extract_resources(parsed)
            return [] unless parsed['resource']

            resources = []
            parsed['resource'].each do |resource_type, resource_instances|
              next unless resource_instances.is_a?(Hash)

              resource_instances.each do |resource_name, resource_config|
                next unless resource_config.is_a?(Hash)

                resources << build_resource_entry(resource_type, resource_name, resource_config)
              end
            end

            resources
          end

          # Extract key attributes based on resource type
          def extract_key_attributes(resource_type, resource_config)
            attrs = extract_pattern_matched_attributes(resource_type, resource_config)
            return attrs unless attrs.empty?

            extract_generic_attributes(resource_config)
          end

          # Format attribute value for display
          def format_attribute_value(value)
            case value
            when String
              value.length > 50 ? "#{value[0..47]}..." : value
            when Array
              value.join(', ')
            when Hash
              value.to_json
            else
              value.to_s
            end
          end

          private

          def build_resource_entry(resource_type, resource_name, resource_config)
            {
              type: resource_type,
              name: resource_name,
              full_name: "#{resource_type}.#{resource_name}",
              config: resource_config,
              attributes: extract_key_attributes(resource_type, resource_config)
            }
          end

          def extract_pattern_matched_attributes(resource_type, resource_config)
            RESOURCE_ATTRIBUTE_PATTERNS.each do |pattern, attrs|
              next unless resource_type.match?(pattern)

              return attrs.each_with_object({}) do |attr, hash|
                hash[attr] = resource_config[attr.to_s] if resource_config[attr.to_s]
              end
            end
            {}
          end

          def extract_generic_attributes(resource_config)
            GENERIC_ATTRIBUTES.each_with_object({}) do |attr, hash|
              hash[attr.to_sym] = resource_config[attr] if resource_config[attr]
            end
          end
        end
      end
    end
  end
end
