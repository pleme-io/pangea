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

require 'json'

module Pangea
  module CLI
    module Commands
      # JSON analysis and extraction for plan command
      module JsonAnalysis
          private

          def analyze_terraform_json(terraform_json)
            config = JSON.parse(terraform_json)
            analysis = {
              providers: extract_providers(config),
              resources: extract_resources(config),
              variables: extract_variables(config),
              outputs: extract_outputs(config),
              backend: extract_backend(config)
            }
            analysis[:summary] = generate_summary(analysis)
            analysis
          rescue JSON::ParserError => e
            ui.error "Failed to analyze Terraform JSON: #{e.message}"
            { error: e.message }
          end

          def extract_providers(config)
            return [] unless config['provider']

            result = []
            config['provider'].each do |provider_type, provider_configs|
              configs = provider_configs.is_a?(Array) ? provider_configs : [provider_configs]

              configs.each do |provider_config|
                result << {
                  type: provider_type,
                  alias: provider_config&.dig('alias'),
                  region: provider_config&.dig('region'),
                  config: provider_config
                }
              end
            end
            result
          end

          def extract_resources(config)
            return [] unless config['resource']

            resources = []
            config['resource'].each do |resource_type, resource_instances|
              next unless resource_instances.is_a?(Hash)

              resource_instances.each do |resource_name, resource_config|
                next unless resource_config.is_a?(Hash)

                resources << {
                  type: resource_type,
                  name: resource_name,
                  full_name: "#{resource_type}.#{resource_name}",
                  config: resource_config,
                  attributes: extract_key_attributes(resource_type, resource_config)
                }
              end
            end
            resources
          end

          def extract_variables(config)
            return [] unless config['variable']&.is_a?(Hash)

            config['variable'].map do |var_name, var_config|
              var_config = {} unless var_config.is_a?(Hash)
              {
                name: var_name,
                type: var_config['type'],
                description: var_config['description'],
                default: var_config['default']
              }
            end
          end

          def extract_outputs(config)
            return [] unless config['output']&.is_a?(Hash)

            config['output'].map do |output_name, output_config|
              output_config = {} unless output_config.is_a?(Hash)
              {
                name: output_name,
                description: output_config['description'],
                value: output_config['value']
              }
            end
          end

          def extract_backend(config)
            return nil unless config['terraform']&.dig('backend')

            backend_type = config['terraform']['backend'].keys.first
            backend_config = config['terraform']['backend'][backend_type]

            { type: backend_type, config: backend_config }
          end

          def extract_key_attributes(resource_type, resource_config)
            key_attrs = {}

            case resource_type
            when /aws_route53_/
              key_attrs[:domain] = resource_config['name']
              key_attrs[:type] = resource_config['type']
              key_attrs[:ttl] = resource_config['ttl']
              key_attrs[:records] = resource_config['records']
            when /aws_s3_/
              key_attrs[:bucket] = resource_config['bucket']
            when /aws_lambda_/
              key_attrs[:function_name] = resource_config['function_name']
              key_attrs[:runtime] = resource_config['runtime']
            when /aws_rds_/
              key_attrs[:identifier] = resource_config['identifier']
              key_attrs[:engine] = resource_config['engine']
            else
              %w[name id identifier domain].each do |attr|
                key_attrs[attr.to_sym] = resource_config[attr] if resource_config[attr]
              end
            end

            key_attrs
          end

          def generate_summary(analysis)
            summary = {
              total_resources: analysis[:resources].count,
              resource_types: analysis[:resources].group_by { |r| r[:type] }.transform_values(&:count),
              providers: analysis[:providers].map { |p| p[:type] }.uniq,
              has_backend: !analysis[:backend].nil?,
              variables_count: analysis[:variables].count,
              outputs_count: analysis[:outputs].count
            }

            summary[:estimated_cost] = estimate_monthly_cost(analysis[:resources])
            summary
          end

          def estimate_monthly_cost(resources)
            total = 0.0

            resources.each do |resource|
              cost = case resource[:type]
                     when 'aws_route53_zone' then 0.50
                     when 'aws_route53_record' then 0.001
                     when 'aws_s3_bucket' then 5.00
                     when 'aws_lambda_function' then 10.00
                     when 'aws_rds_cluster' then 100.00
                     else 1.00
                     end
              total += cost
            end

            total.round(2)
          end
        end
      end
    end
  end
